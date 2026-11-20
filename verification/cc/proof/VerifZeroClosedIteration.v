(* The actual phase0 tail and common finish return to the complete while
   invariant once the current phase0 frame has been certified closed. *)
Require Import VST.floyd.proofauto.
Require Import CCV.ccv_core CCV.CCSearchSpecs CCV.CCSearchContext CCV.CCSearchFragments
 CCV.CCSearchHeap CCV.CCRowHeap CCV.CCLoopInvariant CCV.CCStackInvariant
 CCV.CCJournalArray CCV.CCRootArray CCV.CCPhaseZeroFacts
 CCV.VerifZeroKernel CCV.VerifZeroRemaining CCV.VerifZeroTailClosed CCV.VerifFinishTaken.
Import ListNotations. Open Scope Z_scope.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
Section Proof.
Context{Espec:OracleKind}.
Lemma block_zero_closed_iteration:forall sh a p tp rp cap seed budget rules s0 s
 path prefix g log buf xs ys zs pk frames row,
 readable_share sh ->legal_model a ->0<=seed<=model_n a ->legal_stats budget s ->stats_monotone s0 s ->
 ghost_phase g=0%nat ->loop_shape a cap seed path(prefix++[g])log buf xs ys zs pk frames ->
 zero_closed_top a cap seed path prefix g log ->
 semax CCSearchContext.Delta
 (zero_row_state sh a p tp rp cap seed budget rules s path log buf xs ys zs pk frames row 1)
 (Ssequence zero_phase_tail search_finish)
 (normal_ret_assert(search_while_invariant sh a p tp rp cap seed budget rules s0)).
Proof.
 intros sh a p tp rp cap seed budget rules s0 s path prefix g log buf xs ys zs pk frames row
 SH Legal Seed Stats Mono Phase Whole Closed.
 pose proof(phase_zero_path_facts a cap seed path prefix g log buf xs ys zs pk frames Phase Whole)
 as[Nonempty More].
 assert(PathSplit:path=removelast path++[last path 0%nat])by(apply app_removelast_last;assumption).
 eapply semax_seq' with(P':=zero_row_state sh a p tp rp cap seed budget rules s
 path log buf xs ys zs pk frames row 1).
 - apply block_zero_tail_closed.
 - rewrite PathSplit in Whole,Closed|-*.
   unfold zero_closed_top in Closed.
   eapply semax_pre.
   2:{ apply(block_finish_taken sh a p tp rp cap seed budget rules s0 s(removelast path)prefix g
   log buf xs ys zs pk frames(last path 0%nat));try assumption.
   - left;assumption.
   - intros e Min Within Hit;apply Closed;assumption.
   }
   unfold zero_row_state;go_lowerx;normalize.
   sep_apply(row_heap_forget sh a p tp rp(Zlength log)row xs
   (journal_bitmap(root_mask(model_n a)seed)log)ys zs pk buf frames(Zrepeat 0(model_n a))s).
   normalize;cancel;try(apply andp_right;[apply prop_right;tauto|cancel]).
Qed.
End Proof.
Print Assumptions block_zero_closed_iteration.
