(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto.
From mathcomp Require Import all_ssreflect all_algebra.
Require Import LeafMatrix MinimumPrefix LevelSearch IndexRowBridge IndexPacking
 NativePackingScan RowTally CSRWordTraversal SparseFlipBits SparseSyndrome
 PreparedIndexWords PreparedRowCoverage PreparedResidualIndex.

Set Implicit Arguments.
Unset Strict Implicit.
Local Open Scope ring_scope.
Local Delimit Scope Z_scope with coqZ.

Section IndexChoice.
Variables m n:nat.
Variables (H:'M['F_2]_(m,n)) (rows:'I_m -> seq 'I_n)
          (prefix:'cV['F_2]_n) (free:{set 'I_n})
          (blocks:seq Integers.int) (stamp:int64) (marks:seq int64).
Let active:=support (H*m prefix).
Hypotheses (fits:(Z.of_nat n<=Int.max_unsigned)%coqZ)
 (available:forall q:'I_n,Znth (Z.of_nat q) blocks=Int.zero <-> q \in free)
 (covers:forall r q,H r q!=0 -> q \in rows r)
 (width:forall r,(Zlength (encoded rows r)<=Int.max_unsigned)%coqZ).

(* The native scanner can cut as soon as an odd row is unavailable or
   its disjoint packing exceeds the remaining budget. Otherwise it
   gathers the unblocked columns of the first row. *)
Definition index_picks budget (order:seq 'I_m) :=
 if order is first::rest then
   if cpu_scan rows blocks stamp budget (first::rest) marks 0 then
     free_row blocks (encoded rows first)
   else [::]
 else [::].

Lemma compatible_target_survives budget first rest (target:'cV['F_2]_n) marked:
 @tags_for n stamp marks marked ->
 {subset first::rest <= active} ->
 support prefix \subset support target -> H*m target=0 ->
 (support target :\: support prefix) \subset free ->
 (#|support target :\: support prefix|<=budget)%N ->
 exists q:'I_n, q \in support target :\: support prefix /\
   List.In (Z.of_nat q) (map Int.unsigned (index_picks budget (first::rest))).
Proof.
 move=> tags scanned inside kernel unused room.
 pose T:=support target :\: support prefix.
 have touch:forall r,r \in active -> exists2 q,q \in T & q \in neighbors rows r.
 { move=>r;rewrite /active /support inE=> odd.
   have [q [live hit]]:=@odd_row_hits_residual m n H prefix target r inside kernel odd.
   exists q=> //;by rewrite /neighbors inE covers. }
 have survives:=@scan_keeps_target _ _ (neighbors rows) free T active budget
                        unused room touch (first::rest) marked 0 scanned (leq0n _).
 have cpu:=@agrees_with_packing n _ rows free blocks stamp fits available width
                 budget (first::rest) marks marked 0 tags.
 have passes:cpu_scan rows blocks stamp budget (first::rest) marks 0
   by rewrite cpu.
 have odd_first:first \in active by apply:scanned;rewrite inE eqxx.
 rewrite /active /support inE in odd_first.
 have member:=@odd_candidate_buffer_hits m n H prefix target first (rows first)
   blocks free fits available (@covers first) inside kernel odd_first unused.
 change (exists q, q \in T /\ List.In (Z.of_nat q) (map Int.unsigned
   (if cpu_scan rows blocks stamp budget (first::rest) marks 0 then free_row blocks (encoded rows first) else [::]))).
 by rewrite passes.
Qed.

Theorem choice_from_packed_pcm words count raw budget marked:
 stores_odd (words,count) active ->
 (forall j,(Z.of_nat m<=j<64*Zlength words)%coqZ -> syndrome_bit words j=false) ->
 row_order 0 words raw -> (0<count)%coqZ -> @tags_for n stamp marks marked ->
 exists (first:'I_m) rest,raw=map (fun r:'I_m=>Z.of_nat r) (first::rest) /\
 forall target:'cV['F_2]_n,support prefix \subset support target -> H*m target=0 ->
 (support target :\: support prefix) \subset free -> (#|support target :\: support prefix|<=budget)%N ->
 exists q:'I_n,q \in support target :\: support prefix /\
 List.In (Z.of_nat q) (map Int.unsigned (index_picks budget (first::rest))).
Proof.
 move=> stored padding trace positive tags.
 have [first [rest [actual [scanned _]]]]:=
    @physical_branch_from_words m words count active raw stored padding trace positive.
 exists first,rest;split=> // target sub closed allowed room.
 exact:(compatible_target_survives tags scanned sub closed allowed room).
Qed.
End IndexChoice.

Require Import VerifClosesBody VerifFlipBody NativeFlipPayload NativeDepthFlip FlipRoundtrip
 SyndromeHash RedundantState PreparedZeroPCM PreparedMatrixResponse PreparedMatrixPath.

Section Reachable.
Variables m n k:nat.
Variables (H:'M['F_2]_(m,n)) (G:'M['F_2]_(k,n)) (keys:seq int64)
 (rowkey:'I_m->int64) (columns:'I_n->seq 'I_m) (rows:'I_m->seq 'I_n)
 (initial:packed_support).
Hypotheses (mfit:(Z.of_nat m<=Int.modulus)%coqZ) (nfit:(Z.of_nat n<=Int.max_signed)%coqZ)
 (distinct:forall q,uniq (columns q)) (incidence:forall q,[set r in columns q]=support (col q H))
 (cover:forall r q,H r q!=0 -> q \in rows r)
 (row_width:forall r,(Zlength (encoded rows r)<=Int.max_unsigned)%coqZ)
 (hash:forall q:'I_n,Znth (Z.of_nat q) keys=signature rowkey (support (col q H)))
 (csr:encoded_at G columns Bare initial).
Let first_words:=syndrome (words_at initial).
Let first_parities:=parities (words_at initial).
Hypotheses (zeros:Forall (fun x=>x=Int64.zero) first_words)
 (clear_parities:Forall (fun x=>x=Int64.zero) first_parities)
 (mroom:(Z.of_nat m<=64*Zlength first_words)%coqZ) (kroom:(k<=64*size first_parities)%N)
 (no_odd:odd_count initial=0%coqZ) (no_hash:checksum initial=Int64.zero).

(* No caller-provided row choice or packing certificate. Starting from
   zeroed buffers, use the physical column flips of the C-only search. *)
Theorem index_choice_after_flips path raw stamp (blocks:seq Integers.int) (marks:seq int64)
 budget:
 let state:=payload_after Bare keys initial (literal_path path) in
 let prefix:=vector_on (0:'cV['F_2]_n) path in
 let free:=[set q:'I_n | Int.eq (Znth (Z.of_nat q) blocks) Int.zero] in
 Zlength marks=Z.of_nat n -> Zlength blocks=Z.of_nat n ->
 (0<odd_count state)%coqZ -> row_order 0 (syndrome (words_at state)) raw ->
 exists (first:'I_m) rest,raw=map (fun r:'I_m=>Z.of_nat r) (first::rest) /\
 forall target:'cV['F_2]_n,support prefix \subset support target -> H*m target=0 ->
 (support target :\: support prefix) \subset free -> (#|support target :\: support prefix|<=budget)%N ->
 exists q:'I_n,q \in support target :\: support prefix /\
 List.In (Z.of_nat q) (map Int.unsigned (index_picks rows blocks stamp marks budget (first::rest))).
Proof.
 move=>state prefix free mark_size block_size active trace.
 have init_rep:=@zeroed_level_represents_pcm m n k H G rowkey initial zeros clear_parities mroom kroom no_odd no_hash.
 have no_extra (q:'I_n):Forall (fun r=>(Z.of_nat m<=Int.unsigned r)%coqZ) (extra_rows Bare (Z.of_nat q)) by constructor.
 have [stored _]:=@native_path_matrix_response m n k H G rowkey columns Bare keys mfit nfit distinct
   incidence no_extra hash path _ initial csr init_rep.
 have padded:clear_padding (Z.of_nat m) (syndrome (words_at state)).
 { apply reachable_index_padding;first by split;[lia|exact mroom].
   - move=>i /List.in_map_iff [q [<- used]].
     rewrite Int.signed_repr;last by move:(elimT ltP (ltn_ord q));change Int.min_signed with (-2147483648)%coqZ;lia.
     have [column _]:=csr q;rewrite column.
     apply Forall_forall=>r /List.in_map_iff [a [<- _]].
     rewrite /encode Int.unsigned_repr;have bound:=elimT ltP (ltn_ord a);unfold Int.max_unsigned;lia.
   - apply initialized_padding;first lia.
     move=>i within;apply (proj1 (Forall_forall _ _) zeros);apply Znth_In;exact within. }
 pose marked:=[set q:'I_n | Int64.eq (@Znth int64 ltac:(typeclasses eauto) (Z.of_nat q) marks) stamp].
 have tags:@tags_for n stamp marks marked.
 { split=> // q;rewrite /marked inE;split;[move=> ->;apply Int64.eq_true|apply Int64.same_if_eq]. }
 have unsigned:(Z.of_nat n<=Int.max_unsigned)%coqZ by
   change Int.max_signed with 2147483647%coqZ in nfit;change Int.max_unsigned with 4294967295%coqZ;lia.
 have available (q:'I_n):Znth (Z.of_nat q) blocks=Int.zero <-> q \in free.
 { rewrite /free inE;split;[move=> ->;apply Int.eq_true|apply Int.same_if_eq]. }
 exact:(@choice_from_packed_pcm m n H rows prefix free blocks stamp marks unsigned available cover row_width
   _ _ raw budget marked stored padded trace active tags).
Qed.
End Reachable.
