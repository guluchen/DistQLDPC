(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VerifDetected VerifChildVisit VerifClosesBody VerifFlipBody VerifLookup
 HashLookup BuiltLookup NativeFlipPayload NativeDepthFlip EnabledCall OverlapColumnState OverlapView
 LeafAPI PackedDetector PreparedDepthSpec PreparedChildCall PreparedPairDispatch PreparedPairLedger PreparedPairStorage
 PreparedPairEvent PreparedLeafWorkspace PreparedWitnessRegister PreparedAnswerFrame.
Require flag_level_ast.
Import flag_level_ast.
#[local] Existing Instance VerifDetected.CompSpecs.
Local Open Scope Z_scope.

Definition scanned_leaf odd (accept:Z->Prop) n (event:option Z) :=
 match event with Some z=>odd<>0 /\ leaf_answer accept n z | None=>odd=0 end.
Definition pair_observation t accept n depth q path code tail :=
 let seen:=packed_detects (parities (words_at t)) in let next:=upd_Znth depth path (Int.repr q) in
 exists e,scanned_leaf (odd_count t) accept n e /\ code=pair_code seen e /\ tail=pair_path depth next e.

Section Visit.
Context {Espec:OracleKind}.
Variables (c:policy_state) (policy:row_policy) (p:lookup_ptrs) (keys:list int64) (mask:int64)
 (tab links:list Z) (initial:packed_support) (frame:val->mpred) (loan:mpred) (s cp:val)
 (depth q i n:Z) (st:snapshot) (path:list int) (children:val) (count:Z) (bits:int) (accept:Z->Prop).
Let w:=depth+2.
Let node:=append_qubit path depth q.
Let next:=upd_Znth depth path (Int.repr q).
Let t:=payload_after policy keys initial node.
Let seen:=packed_detects (parities (words_at t)).
Let locs:=descent_loc c s depth q children count i bits false.
Let heap:=leaf_flip_heap c policy p keys mask tab links initial frame.
Let store:=fun path closed leaves saved=>pair_storage c s cp w st path t policy p keys mask tab links closed leaves saved.
Let output:=fun e closed leaves saved=>let totals:=pair_counts closed leaves e in
 store (pair_path depth next e) (fst totals) (snd totals) (pair_size depth saved seen e).

Theorem fast_search_with_flip_heap:
 (forall closed leaves saved,
 semax pair_delta (PROPx [] (LOCALx (temp _result (Vint Int.zero)::locs) (SEPx [store path closed leaves saved])))
 child_bracket (normal_ret_assert (EX e:option Z,PROPx
  [scanned_leaf (odd_count t) accept n e;
   active_prefix (depth+1) (pair_path depth next e)=node;
   Zlength (pair_path depth next e)=Zlength path;0<=pair_code seen e<=3;
   witness_at_limit w saved (pair_code seen e) (pair_size depth saved seen e) (pair_path depth next e)]
  (LOCALx (temp _result (Vint (Int.repr (pair_code seen e)))::locs) (SEPx [output e closed leaves saved]))))) ->
 semax pair_delta (PROPx [] (LOCALx (temp _result (Vint Int.zero)::locs)
    (SEPx [enabled_memory c s cp w path st;heap s node;loan]))) child_bracket
 (normal_ret_assert (EX tail:list int,EX code:Z,PROPx [0<=code<=3;Zlength tail=Zlength path;
    active_prefix (depth+1) tail=node;pair_observation t accept n depth q path code tail]
    (LOCALx (temp _result (Vint (Int.repr code))::locs) (SEPx [enabled_memory c s cp w tail st;heap s node;loan])))).
Proof.
 intro run.
 assert (unpack:forall cells,(enabled_memory c s cp w cells st * heap s node)%logic=
  (!!physical_prefix c node && (EX cl:int64,EX lv:int64,EX sv:int,store cells cl lv sv * frame s))%logic).
 { intro cells;apply unpack_leaf_owner. }
 eapply semax_pre with (P':=(PROPx [] (LOCALx (temp _result (Vint Int.zero)::locs)
    (SEPx [(enabled_memory c s cp w path st * heap s node)%logic;loan])))).
 { unfold locs,descent_loc;entailer!;cancel. }
 rewrite unpack;Intros cl lv sv.
 pose proof (frame_answer _ _ _ _ _ _ _ _ (frame s * loan)%logic (run cl lv sv)) as keep.
 eapply semax_post'.
 2:{ eapply semax_pre;[|exact keep];unfold locs,descent_loc;entailer!;cancel. }
 Intros e;Exists (pair_path depth next e) (pair_code seen e).
 assert (actual:pair_observation t accept n depth q path (pair_code seen e) (pair_path depth next e))
    by (exists e;split;[assumption|auto]).
 unfold locs,descent_loc;entailer!.
 unfold heap,leaf_flip_heap,physical_store,mutable_leaf_workspace,static_leaf_index,output,store,pair_storage;
  cbn [table_book slots HashLookup.mask HashLookup.links];unfold lookup_index;
  Exists (fst (pair_counts cl lv e)) (snd (pair_counts cl lv e)) (pair_size depth sv seen e);entailer!;cancel;apply derives_refl.
Qed.
End Visit.
