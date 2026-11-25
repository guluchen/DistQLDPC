(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VerifDetected VerifChildVisit SiblingCounters EnabledCall EnabledLoopFacts
 OverlapColumnState PreparedSeedDispatch PreparedRootStages PreparedChildCall PreparedDepthSpec
 PreparedBudgetContract PreparedPlainDescent PreparedPlainSiblings PreparedPlainUndo PreparedSiblingScan
 PreparedRecursiveCall PreparedSiblingRestore PreparedWitnessRegister PreparedIndexWitnessCall PreparedIndexWitnessScan
 PreparedArenaContext PreparedPairDispatch PreparedNativeCallees flag_level_ast.
#[local] Existing Instance VerifDetected.CompSpecs.
Local Open Scope Z_scope.

Lemma visit_contexts flip dfs:
 let D:=func_tycontext f_dfs prepared_vars (visit_calls flip dfs) nil in
 tycontext_sub (func_tycontext f_dfs prepared_vars (prepared_calls flip dfs) nil) D /\
 tycontext_sub pair_delta D.
Proof.
 intro D;unfold D;split.
 - add_checked_calls (prepared_calls flip dfs) (visit_calls flip dfs).
 - unfold pair_delta;add_checked_calls PairG (visit_calls flip dfs).
Qed.

(* Pass the actual written size back through the deep recursive branch.
   The chosen row and the unused portion of the arena stay in the caller. *)
Theorem deep_registered_visit {Espec:OracleKind} (entry:entry_domain) c (heap:node_storage)
 (subheap:budget_heap) (report:budget_report) (valid_witness:Z->list int->Prop) bits
 s cp bp w d q st cur saved children count i loan (path:list int):
 1<=d<w-2 -> w<=Int.max_signed -> w<=Zlength cur -> Zlength cur=Zlength path ->
 let node:=append_qubit cur d q in let locs:=plain_descent_loc s d q children count i bits in
 let callee:=index_dfs_with_witness entry subheap report valid_witness bits in
 let D:=func_tycontext f_dfs prepared_vars (visit_calls (snd (depth_flip c heap bits)) (snd callee)) nil in
 entry (geometry c) s cp bp w st node -> subheap w s node=(heap s node * loan)%logic ->
 forall frame:mpred,
 let owned tail written:=(child_fields s cp bp w (blocked st) tail * heap s node *
        witness_register s written * frame * loan)%logic in
 semax D (PROPx nil (LOCALx (temp _result (Vint Int.zero)::locs) (SEPx [owned cur saved]))) child_bracket
  (normal_ret_assert (EX tail:list int,EX code:Z,EX written:int,PROPx
    [0<=code<=3;Zlength tail=Zlength path;active_prefix (d+1) tail=node;
     report w (geometry c) st node code tail;witness_at_limit w saved code written tail /\
      (witness_status code -> valid_witness (Int.signed written) tail)]
    (LOCALx (temp _result (Vint (Int.repr code))::locs) (SEPx [owned tail written])))).
Proof.
 intros deep cap room len node locs callee D reached partition frame owned.
 pose proof (@compiled_child_returns_register Espec entry (snd (depth_flip c heap bits)) subheap report
    valid_witness bits (geometry c) s cp bp w d q st cur saved children count i frame deep cap room reached) as raw.
 cbn zeta in raw;fold node locs in raw;rewrite partition in raw.
 eapply semax_Delta_subsumption;[exact (proj1 (visit_contexts _ _))|].
 eapply semax_post'.
 2:{ eapply semax_pre;[|exact raw];unfold locs,plain_descent_loc,owned;entailer!;cancel. }
 Intros tail code written;Exists tail code written;unfold owned,locs,plain_descent_loc;entailer!;cancel.
Qed.

Theorem undo_keeps_registered_result {Espec:OracleKind} flip dfs s cp bp children d w bits
 xs base path stop code written (keep:mpred):
 Zlength xs<=Int.max_signed -> Zlength base<=Int.max_signed ->
 in_array (Zlength base) xs -> 0<=stop<=Zlength xs ->
 let regs:=plain_scan_regs s children d (Zlength xs) stop code bits in
 let own blocks:=(child_fields s cp bp w blocks path * child_array children xs * keep *
       witness_register s written)%logic in
 semax (func_tycontext f_dfs prepared_vars (visit_calls flip dfs) nil)
 (PROPx nil (LOCALx regs (SEPx [own (added xs base stop)]))) undo_children
 (normal_ret_assert (PROPx nil (LOCALx regs (SEPx [own base])))).
Proof.
 intros cap limit range bounds regs own;eapply semax_Delta_subsumption;[exact (proj1 (visit_contexts _ _))|].
 pose proof (@null_policy_undo Espec flip dfs s cp bp children d w bits xs base path stop code
     (keep*witness_register s written)%logic cap limit range bounds) as rollback.
 eapply semax_post'.
 2:{ eapply semax_pre;[|exact rollback];unfold regs,plain_scan_regs,own;entailer!;cancel. }
 unfold regs,plain_scan_regs,own;entailer!;cancel.
Qed.
