(* Actual complete iteration: normal continuation has strict counter progress;
   the exhausted branch returns UNKNOWN and has no normal continuation. *)
Require Import VST.floyd.proofauto.
Require Import CCV.ccv_core CCV.CCSearchSpecs CCV.CCSearchContext CCV.CCSearchFragments
 CCV.CCSearchMemory CCV.CCSearchHeap CCV.CCLoopInvariant CCV.CCJournalArray
 CCV.CCRootArray CCV.CCSearchExit CCV.CCStatsInvariant CCV.CCReturnCompose
 CCV.VerifSearchEnter CCV.VerifUnknownResult CCV.VerifMainIteration CCV.VerifMainProgress.
Import ListNotations. Open Scope Z_scope.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
Section Proof.
Context{Espec:OracleKind}.
Theorem block_guarded_iteration_progress:forall sh a p tp rp cap seed budget rules s0 s
 path prefix g log buf xs ys zs pk frames,
 readable_share sh ->legal_model a ->1<=cap<=model_n a ->0<=seed<=model_n a ->0<=rules<=63 ->
 legal_stats budget s ->stats_monotone s0 s ->
 loop_shape a cap seed path(prefix++[g])log buf xs ys zs pk frames ->
 semax CCSearchContext.Delta
 (iteration_head sh a p tp rp cap seed budget rules s path log buf xs ys zs pk frames)
 search_main_iteration
 (overridePost(search_while_invariant sh a p tp rp cap seed budget rules(step_stats s))
 (function_body_ret_assert tint(search_return sh a p tp rp cap budget s0))).
Proof.
 intros sh a p tp rp cap seed budget rules s0 s path prefix g log buf xs ys zs pk frames
 SH Legal Cap Seed Rules Stats Mono Whole.
 destruct(Z_lt_dec(stat_steps s)budget)as[Room|Exhausted].
 - apply(block_main_iteration_progress sh a p tp rp cap seed budget rules s0 s
   path prefix g log buf xs ys zs pk frames);assumption.
 - assert(OutOfFuel:budget<=stat_steps s)by lia.
   rewrite enter_actual_layout.
   eapply returned_sequence with(R:=function_body_ret_assert tint(search_return sh a p tp rp cap budget s0));[reflexivity|].
   eapply semax_pre.
   2:{ apply(block_exhausted_guard_result sh a p tp rp(Zlength log)xs
   (journal_bitmap(root_mask(model_n a)seed)log)ys zs pk buf frames(Zrepeat 0(model_n a))s cap budget s0);
   try assumption;try(unfold loop_shape in Whole;tauto).
   - apply journal_bitmap_length;[apply root_mask_length;assumption|].
     assert(Trace:CCJournalTrace.journal_trace(model_n a)(root_mask(model_n a)seed)log buf)by(unfold loop_shape in Whole;tauto).
     unfold CCJournalTrace.journal_trace in Trace;tauto.
   - rewrite Zlength_Zrepeat;lia.
   }
   unfold iteration_head;go_lowerx;normalize;cancel;try(apply andp_right;[apply prop_right;tauto|cancel]).
Qed.
End Proof.
Print Assumptions block_guarded_iteration_progress.
