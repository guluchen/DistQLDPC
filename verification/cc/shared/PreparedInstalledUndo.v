(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.floyd.reassoc_seq VST.zlist.list_solver.
Require Import level_ast VerifDetected VerifChildVisit VerifVisitRestoration VerifSiblingRollback
 EnabledCall VerifEnabledVisit OverlapView OverlapChildState OverlapColumnState OverlapSharedBlocks
 ChildColumn EnabledLoopFacts SiblingCounters VerifEnabledSiblings UniversalRootSearch PreparedRecursiveCall
 PreparedRootStages PreparedSeedDispatch PreparedDepthSpec PreparedChildCall.
Require Import VerifEnabledUndo PreparedBudgetContract PreparedChildMode PreparedSiblingScan PreparedSiblingRestore PreparedNativeCallees PreparedInstalledScan.
Require flag_level_ast.
Import flag_level_ast.
Local Open Scope Z_scope.
#[local] Existing Instance VerifDetected.CompSpecs.

Theorem installed_scan_and_undo {Espec:OracleKind} c heap (dfs_heap:budget_heap) (loan:mpred) (report:budget_report) bits s cp children xs root path w depth (update:bool):
 1<=depth<=w-2 -> w<=Int.max_signed -> w<=Zlength path -> Zlength xs<=Int.max_signed ->
 0<Zlength (blocked root)<=Int.max_signed -> in_array (Zlength (blocked root)) xs ->
 is_pointer_or_null (callback_owner c) ->
 (forall i,0<=i<Zlength xs -> mode_ready update (geometry c) (Znth i xs) (sibling_state root xs (i+1))) ->
 (forall node,Zlength node=depth+1 -> dfs_heap w s node=(heap s node * loan)%logic) ->
 (forall i st cur,0<=i<Zlength xs -> same_search st (sibling_state root xs i) ->
   Zlength cur=Zlength path -> active_prefix depth cur=active_prefix depth path ->
   let q:=Znth i xs in let parent:=selected st q in let node:=append_qubit cur depth q in
   let locs:=descent_loc c s depth q children (Zlength xs) i bits update in
   let entered:=entered_mode update (geometry c) q parent in
   semax (func_tycontext f_dfs prepared_vars (policy_callees c heap dfs_heap report bits) [])
    (PROPx [] (LOCALx (temp _result (Vint Int.zero)::locs)
     (SEPx [enabled_memory c s cp w cur parent;dfs_heap w s node;child_array children xs])))
    child_bracket (normal_ret_assert (EX final:snapshot,EX tail:list int,EX r:Z,
     PROPx [same_search final parent;0<=r<=3;Zlength tail=Zlength cur;active_prefix (depth+1) tail=node;
      report w (geometry c) entered node r tail;witness_status r->returned_trace (nested c) (blocked entered) q tail]
     (LOCALx (temp _result (Vint (Int.repr r))::locs)
      (SEPx [enabled_memory c s cp w tail final;dfs_heap w s node;child_array children xs]))))) ->
 semax (func_tycontext f_dfs prepared_vars (policy_callees c heap dfs_heap report bits) [])
 (PROPx [] (LOCALx (scan_loc_mode update c s children depth (Zlength xs) 0 0 bits)
 (SEPx [enabled_memory c s cp w path root;heap s (active_prefix depth path);loan;child_array children xs])))
 (Ssequence PreparedChildCall.search_children undo_children)
 (normal_ret_assert (EX i:Z,EX r:Z,EX st:snapshot,EX tail:list int,
  PROPx [scan_outcome_mode update (report w) (geometry c) root xs (active_prefix depth path) i r tail;
   keeps_witness_mode update c root xs i r tail;0<=r<=3;same_search st root;Zlength tail=Zlength path;
   active_prefix depth tail=active_prefix depth path]
  (LOCALx (scan_loc_mode update c s children depth (Zlength xs) i r bits)
    (SEPx [enabled_memory c s cp w tail st;heap s (active_prefix depth path);loan;child_array children xs])))).
Proof.
 intros deep cap room bound total keys own safe join invoke;eapply semax_seq'.
 { apply installed_sibling_loop;assumption. }
 Intros i r st tail.
 assert (seen:0<=i<=Zlength xs) by (match goal with H:scan_outcome_mode _ _ _ _ _ _ i r tail |- _=>
  destruct H as [_ [[e _]|[p _]]];pose proof (Zlength_nonneg xs);lia end).
 eapply semax_post'.
 2:{ eapply semax_Delta_subsumption;[exact (proj1 (installed_recursive_context c heap dfs_heap report bits))|].
     eapply semax_pre;[|apply (@undo_with_cached_flag Espec (snd (depth_flip c heap bits)) (snd (budget_dfs c dfs_heap report bits)) c
       (fun s prefix=>(heap s prefix * loan)%logic) bits s cp children xs root st tail w depth i r (active_prefix depth path) update)];
       try eassumption;unfold scan_loc_mode;entailer!;cancel. }
 assert (restored:same_search (restore_fields st (blocked root)) root).
 { split;[match goal with H:same_search st _ |- _=>exact (proj1 H) end|reflexivity]. }
 Exists i r (restore_fields st (blocked root)) tail;unfold scan_loc_mode;entailer!;apply derives_refl.
Qed.

