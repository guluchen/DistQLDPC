(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto.
From mathcomp Require Import all_ssreflect all_algebra.
Require Import VerifDetected VerifChildVisit VerifClosesBody VerifFlipBody VerifLookup VerifOneLeft
 HashLookup HashProbe LeafMatrix LevelSearch ClosureMatrix SyndromeHash LeafAPI PCMLeafAPI
 TableFlow BuiltLookup BuiltPCM RedundantState SparseSyndrome NativeFlipPayload EnabledCall OverlapSharedBlocks
 OverlapView OverlapColumnState PreparedMatrixResponse PreparedMatrixPath PreparedChildCall PreparedTerminalTrace
 PreparedPairDispatch PreparedPairStorage PreparedOpenPair PreparedLookupMatrix PreparedPairBracket
 PreparedPairLedger PreparedPairEvent PreparedClosedBracket PreparedClosedPair PreparedClosedPairMemory PreparedAnswerFrame PreparedPhysicalPair PackedDetector
 LeafShortcut CSSLevelDistance PreparedDepthSpec PreparedPairCSS PreparedWitnessRegister.
Require Import PreparedRankedChildren PreparedLeafVisit PreparedObservedWitness PreparedInteriorReport PreparedPCMLeafVisit PreparedRecursiveCall.
Require Import PreparedPlainPair PreparedPlainDescent PreparedPlainPhysicalPair PreparedPlainClosedBracket.
Require flag_level_ast.
Import flag_level_ast.
#[local] Existing Instance VerifDetected.CompSpecs.
Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.
Local Open Scope ring_scope.
Local Delimit Scope Z_scope with coqZ.

Definition index_pair_storage s cp w st path t p ks mask tab links nc leaves size:=
 (child_fields s cp (pb p) w (OverlapColumnState.blocked st) path * packed_mem s (pk p) Bare ks t *
  lookup_index s (table_book ks mask (checksum t) tab links (OverlapColumnState.blocked st)) p *
  pair_registers s nc leaves size)%logic.

Lemma index_pair_open s cp w st path t p ks mask tab links nc leaves size:
 let b:=table_book ks mask (checksum t) tab links (OverlapColumnState.blocked st) in
 index_pair_storage s cp w st path t p ks mask tab links nc leaves size=
 (open_pair_storage s cp w path t Bare b p leaves size *
  @field_at VerifDetected.CompSpecs Tsh level_type [StructField _closed] (Vlong nc) s)%logic.
Proof.
 move=>b;unfold index_pair_storage,open_pair_storage,pair_statistics,pair_registers,witness_register,b.
 cbn [table_book keys HashLookup.blocked];apply pred_ext;cancel.
Qed.

Lemma index_pair_closed s cp w st path t p ks mask tab links nc leaves size:
 index_pair_storage s cp w st path t p ks mask tab links nc leaves size=
 (closed_plain_storage s cp (pb p) w (OverlapColumnState.blocked st) path t Bare (pk p) ks nc size *
  outside_closed_lookup s p mask tab links leaves)%logic.
Proof.
 unfold index_pair_storage,closed_plain_storage,pair_registers,closed_stats,witness_register,outside_closed_lookup,lookup_index.
 cbn [table_book slots HashLookup.mask HashLookup.links];apply pred_ext;cancel.
Qed.

Section LiveTraversal.
Variable Espec:OracleKind.
#[local] Existing Instance Espec.
Variables m n k:nat.
Variables (H:'M['F_2]_(m,n)) (L:'M['F_2]_(k,n)) (P F:{set 'I_n})
 (rs:'I_n->seq 'I_m) (rowkey:'I_m->int64).
Variables (c:policy_state) (st:snapshot) (t:packed_support) (ks:seq int64)
 (mask:int64) (cap bits:Z) (tab links:seq Z) (s cp:Values.val) (p:lookup_ptrs).
Let policy:=Bare.
Let v:=words_at t.
Let b:=table_book ks mask (checksum t) tab links (OverlapColumnState.blocked st).
Let has_completion:=pcm_completion H L P F.
Hypotheses (built:history ks mask cap (-1)%coqZ tab links) (npositive:(0<Zlength ks)%coqZ)
 (qubits:Zlength ks=Z.of_nat n) (spare:(Zlength ks<cap)%coqZ)
 (period:cap=(2^bits)%coqZ) (bits_ok:(0<=bits<64)%coqZ) (mask_ok:mask=Int64.repr (Z.ones bits))
 (disjoint:[disjoint F & P]) (free:forall q:'I_n,Znth (Z.of_nat q) (OverlapColumnState.blocked st)=Int.zero <-> q \in F)
 (fits:(Z.of_nat m<=Int.modulus)%coqZ) (unique:forall q,uniq (rs q))
 (incidence:forall q,[set r in rs q]=support (col q H))
 (enc:@encoded_at m n k L rs policy t)
 (colkeys:forall q:'I_n,Znth (Z.of_nat q) ks=signature rowkey (support (col q H)))
 (response:pcm_response H L rowkey (indicator P) t)
 (safe:odd_count t<>0%coqZ -> book_safe b v (odd_count t)) (plain:nested_policy (nested c)=nullval).


(* Use one allocation through each branch. The unused statistic and
   hash table are returned intact even after a shorter logical closure. *)
Theorem both_index_leaf_branches depth q children count i options cells closed leaves saved:
 (1<=depth<=Int.max_signed-2)%coqZ -> (depth+1<Zlength cells)%coqZ ->
 (0<=odd_count t<=Int.max_signed)%coqZ -> (Zlength (parities v)<=Int.max_signed)%coqZ ->
 let w:=(depth+2)%coqZ in let next:=upd_Znth depth cells (Int.repr q) in
 let seen:=packed_detects (parities v) in let locs:=plain_descent_loc s depth q children count i options in
 let store:=index_pair_storage s cp w st in
 let before:=store cells t p ks mask tab links closed leaves saved in
 let after:=fun a=>let counts:=pair_counts closed leaves a in
    store (pair_path depth next a) t p ks mask tab links counts.1 counts.2 (pair_size depth saved seen a) in
 semax pair_delta (PROPx nil (LOCALx (temp _result (Vint Int.zero)::locs) (SEPx [::before]))) child_bracket
 (normal_ret_assert (EX a:option Z,PROPx
 [::match a with Some z=>odd_count t<>0%coqZ /\ leaf_answer has_completion (Z.of_nat n) z | None=>odd_count t=0%coqZ end;
    active_prefix (depth+1)%coqZ (pair_path depth next a)=append_qubit cells depth q;
    Zlength (pair_path depth next a)=Zlength cells;
    (0<=pair_code seen a<=3)%coqZ;
    witness_at_limit w saved (pair_code seen a) (pair_size depth saved seen a) (pair_path depth next a)]
 (LOCALx (temp _result (Vint (Int.repr (pair_code seen a)))::locs) (SEPx [::after a])))).
Proof.
 move=> depth_ok room odd_bounds word_bounds w next seen locs store before after.
 destruct (Z.eq_dec (odd_count t) 0) as [zero|nonzero].
 - have raw:=@closed_plain_bracket Espec c s cp (pb p) (OverlapColumnState.blocked st) t (pk p) ks closed saved depth q
     children count i options cells plain depth_ok room zero word_bounds.
   have framed:=@semax_frame' Espec VerifDetected.CompSpecs _ _ _ _ _ _ _ _
        (outside_closed_lookup s p mask tab links leaves) raw.
   eapply semax_post'.
   2:{ eapply semax_pre;last exact framed.
       unfold before,store,locs,plain_descent_loc;rewrite index_pair_closed;cbn [app];entailer!;cancel;try apply derives_refl. }
   have [length_ok [prefix [range reg]]]:=@stored_child_survives_pair depth q cells seen None saved depth_ok room.
   Exists (@None Z);unfold after,store,locs,plain_descent_loc;cbn [pair_code pair_path pair_size pair_counts fst snd];
    rewrite index_pair_closed;entailer!;try cancel;try apply derives_refl;auto.
 - have with_lookup:=safe nonzero.
   have raw:=@physical_plain_pair Espec m n k H L P F rs rowkey c st t ks mask cap bits tab links
     s cp p built npositive qubits spare period bits_ok mask_ok disjoint free fits unique incidence enc colkeys
     response with_lookup plain depth q children count i options cells leaves saved depth_ok room ltac:(lia).
   have framed:=frame_answer _ _ _ _ _ _ _ _
     (@field_at VerifDetected.CompSpecs Tsh level_type [StructField _closed] (Vlong closed) s) raw.
   eapply semax_post'.
   2:{ eapply semax_pre;last exact framed.
       unfold before,store,locs,plain_descent_loc;rewrite index_pair_open;cbn [app];entailer!;cancel;try apply derives_refl. }
   Intros z.
   have [length_ok [prefix [range reg]]]:=@stored_child_survives_pair depth q cells seen (Some z) saved depth_ok room.
   Exists (Some z);unfold after,store,locs,plain_descent_loc;cbn [pair_code pair_path pair_size pair_counts fst snd];
    rewrite index_pair_open;entailer!;try cancel;try apply derives_refl;auto.
Qed.

(* For the two-move base case no recursive DFS specification is needed.
   Its inline lookup/closure supplies the child's own matrix verdict. *)
Lemma written_pair_weight depth saved seen last:
 (1<=depth<=Int.max_signed-2)%coqZ -> witness_status (pair_code seen last) ->
 Int.signed (pair_size depth saved seen last) =
   (if Z.eq_dec (pair_code seen last) 3 then depth+1 else depth+2)%coqZ.
Proof.
 move=>bound;case:last=>[z|];unfold pair_code,pair_size,witness_status,final_pick,last_size.
 - destruct (Z_lt_dec z 0);intro witness;first lia.
   change (Int.signed (Int.repr (depth+2))=depth+2)%coqZ.
   apply Int.signed_repr;change Int.min_signed with (-2147483648)%coqZ;lia.
 - destruct seen;intro witness;last lia.
   change (Int.signed (Int.repr (depth+1))=depth+1)%coqZ.
   apply Int.signed_repr;change Int.min_signed with (-2147483648)%coqZ;lia.
Qed.

Theorem inline_child_verdict r (S:'M['F_2]_(r,n)) (ids:seq 'I_n)
 (eligible:seq Integers.int->'cV['F_2]_n->Prop)
 depth q children count i options cells closed leaves saved:
 H*m S^T=0 -> L*m S^T=0 -> (\rank (col_mx H L)+\rank S=n)%N ->
 (Z.of_nat n<=Int.max_signed)%coqZ -> uniq ids ->
 P=[set a:'I_n | a \in ids] -> F=@available_now n st ->
 (1<=depth<=Int.max_signed-2)%coqZ -> (depth+1<Zlength cells)%coqZ ->
 (depth+1)%coqZ=Z.of_nat (size ids) -> append_qubit cells depth q=literal_path ids ->
 (0<=odd_count t<=Int.max_signed)%coqZ -> (Zlength (parities v)<=Int.max_signed)%coqZ ->
 let w:=(depth+2)%coqZ in let next:=upd_Znth depth cells (Int.repr q) in
 let seen:=packed_detects (parities v) in let locs:=plain_descent_loc s depth q children count i options in
 let store:=index_pair_storage s cp w st in
 let before:=store cells t p ks mask tab links closed leaves saved in
 let after:=fun a=>let totals:=pair_counts closed leaves a in
    store (pair_path depth next a) t p ks mask tab links totals.1 totals.2 (pair_size depth saved seen a) in
 semax pair_delta (PROPx nil (LOCALx (temp _result (Vint Int.zero)::locs) (SEPx [::before]))) child_bracket
 (normal_ret_assert (EX e:option Z,PROPx
    [::recursive_result H S L eligible w st (literal_path ids) (pair_code seen e) (pair_path depth next e);
       active_prefix (depth+1)%coqZ (pair_path depth next e)=literal_path ids;
       Zlength (pair_path depth next e)=Zlength cells;(0<=pair_code seen e<=3)%coqZ;
       witness_at_limit w saved (pair_code seen e) (pair_size depth saved seen e) (pair_path depth next e);
       witness_status (pair_code seen e) ->
        stored_css_prefix H S (Int.signed (pair_size depth saved seen e)) (pair_path depth next e)]
  (LOCALx (temp _result (Vint (Int.repr (pair_code seen e)))::locs) (SEPx [::after e])))).
Proof.
 move=>ortho detects dimension index_cap distinct inside offered deep room size_ok physical odd_bounds word_bounds
     w next seen locs store before after.
 eapply semax_post';last exact:(@both_index_leaf_branches depth q children count i options cells
   closed leaves saved deep room odd_bounds word_bounds).
 Intros e.
 have event:pair_observation t has_completion (Z.of_nat n) depth q cells (pair_code seen e) (pair_path depth next e).
 { exists e;split;[by destruct e|by split]. }
 rewrite /has_completion inside offered in event.
 have physical_response:=response;rewrite inside in physical_response.
 have reported:reports_at H S L eligible 1 w (geometry c) st (append_qubit cells depth q)
        (pair_code seen e) (pair_path depth next e).
 { unfold w;eapply pair_observation_supplies_child with (ids:=ids) (rowkey:=rowkey) (packed:=t);
     try eassumption;lia. }
 rewrite physical in reported.
 have depth_eq:Zlength (literal_path ids)=(depth+1)%coqZ by rewrite /literal_path Zlength_map Zlength_correct size_ok.
 have answer:=@recursive_reports_by_remaining_depth m n r k H S L eligible ortho detects dimension index_cap 1 w
     (geometry c) st (literal_path ids) (pair_code seen e) (pair_path depth next e) ltac:(unfold w;lia) reported.
 have stored_weight:witness_status (pair_code seen e) ->
   stored_css_prefix H S (Int.signed (pair_size depth saved seen e)) (pair_path depth next e).
 { move=>found;rewrite (@written_pair_weight depth saved seen e deep found).
   eapply observed_witness_has_valid_length with (ids:=ids) (F:=@available_now n st)
       (rowkey:=rowkey) (t:=t) (q:=q) (cur:=cells);try eassumption;lia. }
 Exists e;unfold locs,plain_descent_loc,after,store;rewrite <-physical;entailer!;try apply derives_refl;try congruence.
Qed.
End LiveTraversal.

Require Import NativeDepthFlip PreparedLeafWorkspace.
(* This is the same packed state the verified C flip updates on descent
   and restores on return. The path and exclusions are disjoint from it. *)
Lemma unpack_plain_leaf_owner c p ks mask tab links initial frame s cp w path st prefix:
 let t:=payload_after Bare ks initial prefix in
 (child_fields s cp (pb p) w (OverlapColumnState.blocked st) path *
  leaf_flip_heap c Bare p ks mask tab links initial frame s prefix)%logic =
 (!!physical_prefix c prefix &&
  (EX closed:int64,EX leaves:int64,EX size:Integers.int,
    index_pair_storage s cp w st path t p ks mask tab links closed leaves size * frame s))%logic.
Proof.
 move=>t;unfold leaf_flip_heap,physical_store,mutable_leaf_workspace,static_leaf_index,index_pair_storage,lookup_index,t.
 cbn [table_book slots HashLookup.mask HashLookup.links];apply pred_ext;
 Intros nc nl sz;Exists nc nl sz;entailer!;cancel.
Qed.
