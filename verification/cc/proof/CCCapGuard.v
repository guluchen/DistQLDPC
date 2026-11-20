(* In the verification program only, require space for a cap increment
   after the inclusive cap <= n test. All legal dimensions leave room. *)
Require Import VST.floyd.proofauto compcert.lib.Maps.
Require Import CCV.ccv_core CCV.CCScanGuard CCV.CCScanFrames CCV.CCCountedScan
 CCV.CCStructuredRuns CCV.CCBoundedMain CCV.CCExpandedBody.
Import ListNotations.
Definition cap_test := less_guard _cap (Econst_int (Int.repr Int.max_unsigned) tuint).
Definition cap_dead := Sset _cap (Ebinop Odiv (Econst_int Int.one tuint) (Econst_int Int.zero tuint) tuint).
Definition cap_check := Sifthenelse cap_test Sskip cap_dead.
Lemma cap_dead_stuck ge f k e l m t next : ~ step2 ge (State f cap_dead k e l m) t next.
Proof.
 intro Step;inversion Step;subst;try solve[intuition discriminate].
 match goal with E:Clight.eval_expr _ _ _ _ (Ebinop _ _ _ _) _ |- _=>inversion E;subst end;
 try match goal with L:Clight.eval_lvalue _ _ _ _ (Ebinop _ _ _ _) _ _ _ |- _=>inversion L end.
 repeat match goal with E:Clight.eval_expr _ _ _ _ (Econst_int _ _) _ |- _=>
 inversion E;subst;clear E;try match goal with L:Clight.eval_lvalue _ _ _ _ (Econst_int _ _) _ _ _ |- _=>inversion L end end.
 match goal with H:Cop.sem_binary_operation _ _ _ _ _ _ _=Some _ |- _=>discriminate H end.
Qed.
Fixpoint guard_cap_loops (s:statement) :=
 match s with
 | Ssequence x y=>Ssequence (guard_cap_loops x) (guard_cap_loops y)
 | Sloop (Ssequence g body) incr=>Sloop (Ssequence (Ssequence g cap_check) body) incr
 | _=>s end.
Definition guarded_distance := with_body f_ccv_distance (guard_cap_loops (fn_body f_ccv_distance)).
Lemma cap_check_guard ge f e : checked_guard ge f e _cap cap_check.
Proof.
 intro l;unfold cap_check;apply runs_if.
 - intros l' m [Eq Take] k done N B R;subst l';apply N;split;[apply preserves_self|].
   exact (uint_test_room ge e l m _cap (Econst_int (Int.repr Int.max_unsigned) tuint) eq_refl Take).
 - intros l' m H k done N B R.
   eapply blocked_settles;[constructor;reflexivity|];intros t next Step;eapply cap_dead_stuck;exact Step.
Qed.
