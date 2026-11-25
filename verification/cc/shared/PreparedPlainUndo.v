(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.zlist.list_solver VerifDetected VerifChildVisit
 SiblingCounters VerifVisitRestoration EnabledCall PreparedSeedDispatch PreparedRootStages
 PreparedChildCall PreparedDepthSpec PreparedBudgetContract PreparedPlainDescent PreparedPlainSiblings
 PreparedSiblingRestore PreparedSiblingScan OverlapColumnState flag_level_ast.
#[local] Existing Instance VerifDetected.CompSpecs.
Local Open Scope Z_scope.

Section Restore.
Context {Espec:OracleKind}.
Variables (flip dfs:funspec) (s cp bp children:val) (d w:Z) (bits:int)
 (xs:list Z) (base path:list int) (stop code:Z) (keep:mpred).
Let D:=func_tycontext f_dfs prepared_vars (prepared_calls flip dfs) nil.
Let regs:=plain_scan_regs s children d (Zlength xs) stop code bits.
Let state blocks:=(child_fields s cp bp w blocks path * child_array children xs * keep)%logic.
Theorem null_policy_undo :
 Zlength xs<=Int.max_signed -> Zlength base<=Int.max_signed ->
 in_array (Zlength base) xs -> 0<=stop<=Zlength xs ->
 semax D (PROPx nil (LOCALx regs (SEPx [state (added xs base stop)]))) undo_children
  (normal_ret_assert (PROPx nil (LOCALx regs (SEPx [state base])))).
Proof.
 intros count cap range stopped;unfold undo_children,regs,plain_scan_regs;abbreviate_semax.
 forward_for_simple_bound stop
   (EX i:Z,PROPx [0<=i<=stop] (LOCALx regs (SEPx [state (replay base xs stop i)]))).
 - try forward;try (Exists 0);unfold regs,plain_scan_regs,replay;rewrite ?sublist_nil by lia;cbn [sweep fold_left];entailer!;try apply derives_refl.
 - assert (width:Zlength (replay base xs stop i)=Zlength base) by (apply replay_size;exact range).
   assert (valid:0<=Znth i xs<Zlength base) by
     (apply Forall_forall with (x:=Znth i xs) in range;[exact range|apply Znth_In;lia]).
   assert (un:Int.unsigned (Int.repr (Znth i xs))=Znth i xs) by (apply Int.unsigned_repr;rep_lia).
   unfold regs,plain_scan_regs,state,child_fields,child_array;Intros;do 5 forward;forward.
   unfold regs,plain_scan_regs,state,child_fields,child_array;rewrite replay_next by lia;unfold adjust;
     rewrite upd_Znth_Zlength,upd_Znth_map by lia;rewrite decrement_word,?un;entailer!.
 - rewrite replay_stop by exact range;unfold regs,plain_scan_regs;entailer!.
Qed.
End Restore.

Theorem plain_scan_and_restore {Espec:OracleKind} c (heap:node_storage) (recursive_heap:budget_heap) loan report bits
 s cp bp children xs root path w d :
 let base:=blocked root in let parent:=active_prefix d path in
 let regs:=plain_scan_regs s children d (Zlength xs) in
 let state tail:=(child_fields s cp bp w base tail * child_array children xs * heap s parent * loan)%logic in
 nested_policy (nested c)=nullval -> 1<=d<w-2 -> w<=Int.max_signed -> w<=Zlength path ->
 Zlength xs<=Int.max_signed -> Zlength base<=Int.max_signed -> in_array (Zlength base) xs ->
 Zlength base<Zlength (column_offsets (geometry c)) ->
 (forall node,Zlength node=d+1 -> recursive_heap w s node=(heap s node * loan)%logic) ->
 semax (func_tycontext f_dfs prepared_vars (prepared_calls (snd (depth_flip c heap bits))
   (snd (plain_dfs_contract recursive_heap report bits))) nil)
 (PROPx nil (LOCALx (regs 0 0 bits) (SEPx [state path])))
 (Ssequence search_children undo_children)
 (normal_ret_assert (EX i:Z,EX code:Z,EX tail:list int,
   PROPx [scan_outcome_mode false (report w) (geometry c) root xs parent i code tail;
          0<=code<=3;Zlength tail=Zlength path;active_prefix d tail=parent]
    (LOCALx (regs i code bits) (SEPx [state tail])))).
Proof.
 intros base parent regs state plain deep cap room count limit range cols lend.
 eapply semax_seq'.
 { eapply semax_pre;[|exact (@null_policy_sibling_scan Espec c heap recursive_heap loan report bits s cp bp children
       xs root path w d plain deep cap room count limit range cols lend)].
   unfold state,added;rewrite sublist_nil by lia;cbn [sweep fold_left];apply andp_left2;apply derives_refl. }
 Intros i code tail.
 assert (bounds:0<=i<=Zlength xs).
 { match goal with H:scan_outcome_mode _ _ _ _ _ _ _ _ _ |- _=>pose proof H as ran end.
   destruct ran as [_ [[-> _]|[within _]]];[pose proof (Zlength_nonneg xs)|];lia. }
 eapply semax_post'.
 2:{ eapply semax_pre;[|apply (@null_policy_undo Espec (snd (depth_flip c heap bits)) (snd (plain_dfs_contract recursive_heap report bits))
      s cp bp children d w bits xs base tail i code (heap s parent * loan)%logic count limit range bounds)].
     unfold regs,parent,base,plain_scan_regs;go_lowerx;normalize;cancel. }
 Exists i code tail;unfold state,regs,plain_scan_regs,parent,base;entailer!;cancel.
Qed.
