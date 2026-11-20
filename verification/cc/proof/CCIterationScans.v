(* Check the complete frozen search iteration, including all calls, inline
   scans, early returns and the short-circuit candidate-cursor loop. *)
Require Import VST.floyd.proofauto.
Require Import compcert.lib.Maps compcert.cfrontend.Clight.
Require Import CCV.CCSearchFragments CCV.ccv_core CCV.CCLinkedProgram CCV.CCActualScans
 CCV.CCStructuredRuns CCV.CCScanFrames CCV.CCScanGuard CCV.CCCountedScan
 CCV.CCScanCallees CCV.CCCursorScan.
Import ListNotations.
Local Notation ge := (Clight.globalenv linked_prog).
Lemma clear_scan_settles : call_settles ge f_clear.
Proof. internal_body f_clear. Qed.
Lemma nontrivial_scan_settles : call_settles ge f_nontrivial.
Proof. internal_body f_nontrivial. Qed.
Lemma alloc_keeps_globals g old m vars env' m' :
 Clight.alloc_variables g old m vars env' m' -> forall id,
 ~In id (map fst vars) -> PTree.get id env'=PTree.get id old.
Proof.
 intro A;induction A;intros j Outside;[reflexivity|].
 rewrite IHA;[rewrite PTree.gso;[reflexivity|]|];simpl in Outside;intuition congruence.
Qed.
Definition search_locals (e:Clight.env) :=
 forall id, id<>_top -> id<>_row -> PTree.get id e=None.
Lemma search_entry_locals args m e le m' :
 Clight.function_entry2 ge f_search args m e le m' -> search_locals e.
Proof.
 intros Entry id T R;inversion Entry;subst.
 match goal with A:Clight.alloc_variables _ _ _ _ _ _ |- _ =>
 rewrite (alloc_keeps_globals _ _ _ _ _ _ A);[apply PTree.gempty|simpl;intuition] end.
Qed.
Ltac iteration_structure :=
 lazymatch goal with
 | |- framed _ _ _ (Ssequence _ _) => apply framed_seq;iteration_structure
 | |- framed _ _ _ (Sifthenelse _ _ _) => apply framed_if;iteration_structure
 | |- framed _ _ _ (Sloop (Ssequence _ _) (Sset ?id _)) =>
   apply (bounded_scan _ _ _ id);[closed_guard|iteration_structure|vm_compute;intuition congruence]
 | |- framed _ _ _ (Sloop (Ssequence _ (Sset ?id _)) Sskip) =>
   apply (while_increment _ _ _ id);
   [apply short_guard;apply produce_prefix;[closed_frame|apply short_comparison;[reflexivity|vm_compute;intuition congruence|closed_frame]]|
    vm_compute;intuition congruence]
 | |- framed _ _ _ (Scall _ (Evar ?id _) _) =>
    let target := lazymatch id with
     | _clear => constr:(f_clear) | _nontrivial => constr:(f_nontrivial)
     | _restore => constr:(f_restore) | _forbid => constr:(f_forbid)
     | _overlap => constr:(f_overlap) | _bounds => constr:(f_bounds)
     | _toggle => constr:(f_toggle) | _leaf => constr:(f_leaf)
     end in
    eapply (framed_direct_call linked_prog id _ target _ _ _);
    [reflexivity|match goal with H:search_locals _ |- _ => apply H;discriminate end|
     first [assumption|apply clear_scan_settles|apply nontrivial_scan_settles|apply forbid_body_settles|
      apply overlap_body_settles|apply bounds_body_settles|apply leaf_body_settles|apply toggle_body_settles]]
 | _ => first [closed_frame|match goal with |- ?G => idtac "unhandled" G;fail 5 end]
 end.
Theorem actual_iteration_scans e :
 search_locals e -> call_settles ge f_restore ->
 framed ge f_search e search_main_iteration.
Proof.
 intros Locals Restore.
 let s := eval cbv -[Int.repr tptr tuint tint tuchar tbool _clear _nontrivial _forbid _restore _overlap _bounds _toggle _leaf _top _row] in search_main_iteration in
 change (framed ge f_search e s).
 iteration_structure.
Qed.
Print Assumptions actual_iteration_scans.
