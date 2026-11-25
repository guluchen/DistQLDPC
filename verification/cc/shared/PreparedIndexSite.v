(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VerifDetected VerifFlipBody VerifClosesBody VerifLookup HashLookup
 BuiltLookup FlipRoundtrip SyndromeHash NativeFlipPayload NativeDepthFlip EnabledCall OverlapColumnState
 PreparedPlainReachable PreparedPCMLeafVisit PreparedMatrixResponse PreparedMatrixPath PreparedIndexWords
 PreparedLeafAtPath PreparedUniformIndex PreparedIndexAdmission SparseSyndrome SparseFlipBits.
From mathcomp Require Import all_ssreflect all_algebra.
Require Import LevelSearch LeafMatrix NativePackingScan.
Set Implicit Arguments.
Unset Strict Implicit.
Local Open Scope ring_scope.
Local Delimit Scope Z_scope with coqZ.

Section Site.
Variables m n k:nat.
Variables (H:'M['F_2]_(m,n)) (G:'M['F_2]_(k,n)) (checks:'I_m->seq 'I_n) (columns:'I_n->seq 'I_m)
 (rowkey:'I_m->int64) (keys:seq int64) (initial:packed_support).
Variables (offsets:seq Z) (entries:seq Integers.int) (stride:Z).
Hypotheses (mfit:(Z.of_nat m<=Int.max_signed)%coqZ) (nfit:(0<Z.of_nat n<=Int.max_signed)%coqZ)
 (cover:forall r q,H r q!=0 -> q \in checks r) (offset_size:Zlength offsets=(Z.of_nat m+1)%coqZ)
 (csr:forall r:'I_m,let lo:=Znth (Z.of_nat r) offsets in let hi:=Znth (Z.of_nat r+1)%coqZ offsets in
    (0<=lo<=hi)%coqZ /\ (hi<=Int.max_unsigned)%coqZ /\ (hi<=Zlength entries)%coqZ /\ sublist lo hi entries=encoded checks r)
 (capacity:forall r:'I_m,(Znth (Z.of_nat r+1)%coqZ offsets-Znth (Z.of_nat r) offsets<=stride)%coqZ)
 (stride_fits:(stride<=Int.max_signed)%coqZ)
 (distinct:forall q,uniq (columns q)) (incidence:forall q,[set r in columns q]=support (col q H))
 (keyed:forall q:'I_n,Znth (Z.of_nat q) keys=signature rowkey (support (col q H)))
 (storage:@encoded_at m n k G columns Bare initial) (zero:pcm_response H G rowkey (0:'cV['F_2]_n) initial)
 (zero_words:forall i,(0<=i<Zlength (syndrome (words_at initial)))%coqZ -> Znth i (syndrome (words_at initial))=Int64.zero)
 (word_cap:(Zlength (syndrome (words_at initial))<=Int.max_signed)%coqZ).

Lemma no_padding_from_literal_path (ids:seq 'I_n):
 clear_padding (Z.of_nat m) (syndrome (words_at (payload_after Bare keys initial (literal_path ids)))).
Proof.
 apply reachable_index_padding.
 - have [[room _] _]:=zero;cbn [fst] in room;lia.
 - move=>word;rewrite /literal_path=> /List.in_map_iff[q [<- used]].
   have within:=elimT ltP (ltn_ord q).
   rewrite Int.signed_repr;last by change Int.min_signed with (-2147483648)%coqZ;lia.
   have [row_encoded _]:=storage q;rewrite row_encoded;apply Forall_forall=>r /List.in_map_iff[j [<- member]].
   have bounded:=elimT ltP (ltn_ord j);rewrite /encode Int.unsigned_repr;first lia.
   change Int.max_unsigned with 4294967295%coqZ;change Int.max_signed with 2147483647%coqZ in mfit;lia.
 - apply initialized_padding;[lia|exact zero_words].
Qed.

Variables (gv:globals) (sh:share) (level op qp bp mp buf:Values.val).
Variables (st:snapshot) (ids:seq 'I_n) (moves:nat) (old:seq Integers.int) (last nc pk:int64) (tags:seq int64).
Let input:=payload_after Bare keys initial (literal_path ids).
Let depth:=Z.of_nat (size ids).
Let weight:=Z.of_nat (size ids+moves)%N.
Definition reached_site:=@Site n gv sh level (psyn (words_at input)) op qp bp mp buf offsets entries (blocked st)
 depth weight (syndrome (words_at input)) nc pk old last tags (indicator [set q:'I_n | q \in ids]) (@available_now n st)
 moves (odd_count input).

Theorem reached_choice_is_legal:
 uniq ids -> Zlength (blocked st)=Z.of_nat n -> Zlength tags=Z.of_nat n -> Zlength old=stride ->
 readable_share sh -> (1<=depth)%coqZ -> (weight<=Int.max_signed)%coqZ -> odd_count input<>0%coqZ ->
 legal_choice H checks reached_site.
Proof.
 move=>unique block_size marks_size scratch readable depth_pos signed live.
 have dim:(Z.of_nat m<=Int.modulus)%coqZ.
 { change Int.modulus with 4294967296%coqZ;change Int.max_signed with 2147483647%coqZ in mfit;lia. }
 have [_ [off rs wid msk same] physical]:=@emitted_path_matches_pcm m n k H G rowkey columns Bare keys
    (proj2 nfit) ids initial dim distinct incidence (fun _=>List.Forall_nil _) keyed unique storage zero.
 have [odd _]:=physical;fold input in odd,same.
 have [_ [_ count]]:=odd;cbn [snd] in count.
 have room:(depth<=weight)%coqZ by rewrite /depth /weight Nat2Z.inj_add;lia.
 constructor.
 - exact mfit.
 - exact nfit.
 - exact:(@available_in_view n st).
 - exact block_size.
 - exact marks_size.
 - exact cover.
 - exact offset_size.
 - exact csr.
 - change ((weight-depth)%coqZ=Z.of_nat moves);rewrite /weight /depth Nat2Z.inj_add;lia.
 - exact odd.
 - change (clear_padding (Z.of_nat m) (syndrome (words_at input))).
   exact (@no_padding_from_literal_path ids).
 - change (0<odd_count input)%coqZ;lia.
 - change (forall r:'I_m,(Znth (Z.of_nat r+1)%coqZ offsets-Znth (Z.of_nat r) offsets<=Zlength old)%coqZ).
   move=>r;have enough:=@capacity r;lia.
 - change (Zlength old<=Int.max_signed)%coqZ;lia.
 - exact readable.
 - change (1<=depth<=weight)%coqZ;lia.
 - exact signed.
 - change (Zlength (syndrome (words_at input))<=Int.max_signed)%coqZ;lia.
Qed.
End Site.
