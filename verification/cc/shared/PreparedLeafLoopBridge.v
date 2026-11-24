(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VerifDetected VerifChildVisit VerifEnabledSiblings EnabledCall
 OverlapColumnState OverlapChildState OverlapView SiblingCounters EnabledLoopFacts
 PreparedRootStages PreparedSeedDispatch PreparedDepthSpec PreparedBudgetContract PreparedNativeCallees
 PreparedChildCall PreparedChildMode PreparedRecursiveCall PreparedSiblingScan PreparedSiblingRestore PreparedInstalledUndo
 PreparedPairDispatch.
Require flag_level_ast.
Import flag_level_ast.
#[local] Existing Instance VerifDetected.CompSpecs.
Local Open Scope Z_scope.

Section AtTwoMoves.
Context {Espec:OracleKind}.
Variables (c:policy_state) (heap:node_storage) (dfs_heap:budget_heap) (report:budget_report)
 (s cp children:val) (bits:int) (xs:list Z) (root:snapshot) (path:list int) (depth:Z) (loan:mpred).
Let w:=depth+2.
Let g:=geometry c.
Variable observe: snapshot->list int->Z->Z->list int->Prop.

(* The fast leaf does not call dfs. Its independent contract is proved
   in pair_delta with just detected and closing_qubit. Install that
   contract in the real sibling loop, using flip in the wider call map. *)
Theorem complete_fast_sibling_search:
 1<=depth<=Int.max_signed-2 -> w<=Zlength path -> Zlength xs<=Int.max_signed ->
 0<Zlength (blocked root)<=Int.max_signed -> in_array (Zlength (blocked root)) xs ->
 is_pointer_or_null (callback_owner c) ->
 (forall i,0<=i<Zlength xs -> Znth i xs+1<Zlength (column_offsets g)) ->
 (forall node,Zlength node=depth+1 -> dfs_heap w s node=(heap s node * loan)%logic) ->
 (forall i st cur,0<=i<Zlength xs -> same_search st (sibling_state root xs i) ->
  Zlength cur=Zlength path -> active_prefix depth cur=active_prefix depth path ->
  let q:=Znth i xs in let post_flip:=selected st q in let node:=append_qubit cur depth q in
  let locs:=descent_loc c s depth q children (Zlength xs) i bits false in
  semax pair_delta (PROPx [] (LOCALx (temp _result (Vint Int.zero)::locs)
   (SEPx [enabled_memory c s cp w cur post_flip;heap s node;(loan * child_array children xs)%logic])))
   child_bracket (normal_ret_assert (EX tail:list int,EX code:Z,PROPx [0<=code<=3;
    Zlength tail=Zlength cur;active_prefix (depth+1) tail=node;observe post_flip cur q code tail]
    (LOCALx (temp _result (Vint (Int.repr code))::locs)
      (SEPx [enabled_memory c s cp w tail post_flip;heap s node;(loan * child_array children xs)%logic]))))) ->
 (forall i st cur code tail,0<=i<Zlength xs -> same_search st (sibling_state root xs i) ->
   Zlength cur=Zlength path -> active_prefix depth cur=active_prefix depth path ->
   let q:=Znth i xs in let seen:=selected st q in observe seen cur q code tail ->
   report w g seen (append_qubit cur depth q) code tail /\
   (witness_status code -> returned_trace (nested c) (blocked seen) q tail)) ->
 semax (func_tycontext f_dfs prepared_vars (policy_callees c heap dfs_heap report bits) [])
 (PROPx [] (LOCALx (scan_loc_mode false c s children depth (Zlength xs) 0 0 bits)
  (SEPx [enabled_memory c s cp w path root;heap s (active_prefix depth path);loan;child_array children xs])))
 (Ssequence search_children undo_children)
 (normal_ret_assert (EX i:Z,EX r:Z,EX st:snapshot,EX tail:list int,
  PROPx [scan_outcome_mode false (report w) g root xs (active_prefix depth path) i r tail;
    keeps_witness_mode false c root xs i r tail;0<=r<=3;same_search st root;
    Zlength tail=Zlength path;active_prefix depth tail=active_prefix depth path]
  (LOCALx (scan_loc_mode false c s children depth (Zlength xs) i r bits)
    (SEPx [enabled_memory c s cp w tail st;heap s (active_prefix depth path);loan;child_array children xs])))).
Proof.
 intros dep room bound sizes valid owner offset join run interpret.
 apply installed_scan_and_undo;[unfold w;lia|unfold w;lia|exact room|exact bound|exact sizes|exact valid|
     exact owner|exact offset|exact join|].
   intros i st cur range same len prefix q selected_parent node locs.
   assert (nlen:Zlength node=depth+1).
   { unfold node,append_qubit,active_prefix;rewrite Zlength_app,Zlength_sublist by (unfold w in room;lia);cbn;lia. }
   pose proof (run i st cur range same len prefix) as actual.
   eapply semax_Delta_subsumption;[exact (proj2 (installed_recursive_context c heap dfs_heap report bits))|].
   eapply semax_post'.
   2:{ eapply semax_pre;[|exact actual];unfold locs,descent_loc;rewrite (join _ nlen);entailer!;cancel;apply derives_refl. }
   Intros tail code.
   assert (evaluation:observe selected_parent cur q code tail) by assumption.
   destruct (interpret i st cur code tail range same len prefix evaluation) as [report_ok trace].
   Exists selected_parent tail code;rewrite (join _ nlen);unfold locs,descent_loc;cbn [entered_mode].
   assert (unchanged:same_search selected_parent selected_parent) by (split;reflexivity).
   entailer!;try cancel;try apply derives_refl.
Qed.
End AtTwoMoves.
