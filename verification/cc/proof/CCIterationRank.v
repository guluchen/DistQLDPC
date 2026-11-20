(* Extract the strict budget rank from the actual iteration's normal
   postcondition. No operational-termination claim is introduced. *)
Require Import VST.floyd.proofauto.
Require Import CCV.CCSearchSpecs CCV.CCSearchHeap CCV.CCSearchContext
 CCV.CCStatsInvariant CCV.CCLoopInvariant CCV.CCFuelRank CCV.VerifMainProgress
 CCV.VerifGuardedProgress CCV.CCSearchExit CCV.CCSearchFragments.
Import ListNotations. Open Scope Z_scope.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
Lemma iteration_post_has_decreasing_rank sh a p tp rp cap seed budget rules before:
 legal_stats budget before ->
 search_while_invariant sh a p tp rp cap seed budget rules(step_stats before) |--
 (EX after:stats_model,
 PROP(continuing_step budget before after;
      (fuel_rank budget after<fuel_rank budget before)%nat)
 LOCAL()
 SEP(TT))%assert.
Proof.
 intros Before;unfold search_while_invariant.
 Intros path ghosts log buf xs ys zs pk frames after.
 Exists after;go_lowerx;normalize.
 assert(Step:continuing_step budget before after)by(unfold continuing_step;tauto).
 pose proof(continuing_step_rank _ _ _ Step)as Decrease.
 entailer!.
Qed.
Print Assumptions iteration_post_has_decreasing_rank.

Section ActualIteration.
Context{Espec:OracleKind}.
Theorem actual_iteration_decreases_fuel:forall sh a p tp rp cap seed budget rules s0 s
 path prefix g log buf xs ys zs pk frames,
 readable_share sh ->legal_model a ->1<=cap<=model_n a ->0<=seed<=model_n a ->0<=rules<=63 ->
 legal_stats budget s ->stats_monotone s0 s ->
 loop_shape a cap seed path(prefix++[g])log buf xs ys zs pk frames ->
 semax CCSearchContext.Delta
 (VerifMainIteration.iteration_head sh a p tp rp cap seed budget rules s path log buf xs ys zs pk frames)
 search_main_iteration
 (overridePost
  (EX after:stats_model,
   PROP(continuing_step budget s after;(fuel_rank budget after<fuel_rank budget s)%nat)
   LOCAL()SEP(TT))%assert
  (function_body_ret_assert tint(search_return sh a p tp rp cap budget s0))).
Proof.
 intros sh a p tp rp cap seed budget rules s0 s path prefix g log buf xs ys zs pk frames
 SH Legal Cap Seed Rules Stats Mono Whole.
 eapply semax_post with(R':=overridePost
 (search_while_invariant sh a p tp rp cap seed budget rules(step_stats s))
 (function_body_ret_assert tint(search_return sh a p tp rp cap budget s0))).
 - cbn[RA_normal overridePost];apply andp_left2;apply iteration_post_has_decreasing_rank;exact Stats.
 - cbn[RA_break overridePost function_body_ret_assert];normalize.
 - cbn[RA_continue overridePost function_body_ret_assert];normalize.
 - intros vl;cbn[RA_return overridePost function_body_ret_assert];apply andp_left2;apply derives_refl.
 - apply(block_guarded_iteration_progress sh a p tp rp cap seed budget rules s0 s
   path prefix g log buf xs ys zs pk frames);assumption.
Qed.
End ActualIteration.
Print Assumptions actual_iteration_decreases_fuel.
