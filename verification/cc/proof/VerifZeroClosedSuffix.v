(* Every actual remaining phase0 suffix skips mutating work once finish=1.
   This lets every safe pruner rejection reach the same verified pop caller. *)
Require Import VST.floyd.proofauto.
Require Import CCV.ccv_core CCV.CCSearchSpecs CCV.CCSearchContext CCV.CCSearchFragments
 CCV.CCSearchHeap CCV.CCRowHeap CCV.CCLoopInvariant CCV.CCStackInvariant CCV.CCBlockFrame
 CCV.CCJournalArray CCV.CCRootArray CCV.CCPhaseZeroFacts CCV.VerifZeroKernel
 CCV.VerifZeroRemaining CCV.VerifZeroTailClosed CCV.VerifFinishTaken.
Import ListNotations. Open Scope Z_scope.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
Definition zero_phase_suffix(k:nat):=search_fragment(phase_zero_path++repeat SeqNext k).
Section Empty.
Context{Espec:OracleKind}.
Lemma block_zero_suffix_closed_empty:forall k,(5<=k<=8)%nat ->
 semax CCSearchContext.Delta finish_one_frame(zero_phase_suffix k)(normal_ret_assert finish_one_frame).
Proof.
 intros k K;assert(Cases:(k=5\/k=6\/k=7\/k=8)%nat)by lia.
 destruct Cases as[-> | [-> | [-> | ->]]].
 { change(semax CCSearchContext.Delta finish_one_frame zero_phase_tail(normal_ret_assert finish_one_frame)).
   apply block_zero_tail_closed_empty. }
 all:(unfold CCSearchContext.Delta;abbreviate_semax;unfold finish_one_frame).
 all:lazymatch goal with|-semax ?D ?P ?stmt ?R=>
 let C:=eval cbv -[Int.repr]in stmt in change(semax D P C R)end.
 all:repeat first[closed_guard_false|progress(apply seq_assoc1)|progress forward|
 progress(apply semax_if_seq)|progress forward_if].
 all:unfold finish_one_frame;entailer!.
Qed.
End Empty.
Section Heap.
Context{Espec:OracleKind}.
Lemma block_zero_suffix_closed:forall k sh a p tp rp cap seed budget rules s path log buf xs ys zs pk frames row,
 (5<=k<=8)%nat ->
 semax CCSearchContext.Delta
 (zero_row_state sh a p tp rp cap seed budget rules s path log buf xs ys zs pk frames row 1)
 (zero_phase_suffix k)
 (normal_ret_assert(zero_row_state sh a p tp rp cap seed budget rules s path log buf xs ys zs pk frames row 1)).
Proof.
 intros k sh a p tp rp cap seed budget rules s path log buf xs ys zs pk frames row K.
 eapply semax_post' with(R':=(finish_one_frame*zero_tail_rest sh a p tp rp cap seed budget rules s
 path log buf xs ys zs pk frames row)%logic).
 - apply andp_left2;apply zero_tail_closed_elim.
 - eapply semax_pre;[apply andp_left2;apply zero_tail_closed_intro|].
   apply semax_normal_block_frame.
   + assert(Cases:(k=5\/k=6\/k=7\/k=8)%nat)by lia.
     destruct Cases as[-> | [-> | [-> | ->]]];unfold zero_tail_rest,zero_phase_suffix;auto 50 with closed.
   + apply block_zero_suffix_closed_empty;assumption.
Qed.
Lemma block_zero_closed_suffix_iteration:forall k sh a p tp rp cap seed budget rules s0 s
 path prefix g log buf xs ys zs pk frames row,
 (5<=k<=8)%nat ->readable_share sh ->legal_model a ->0<=seed<=model_n a ->
 legal_stats budget s ->stats_monotone s0 s ->ghost_phase g=0%nat ->
 loop_shape a cap seed path(prefix++[g])log buf xs ys zs pk frames ->
 zero_closed_top a cap seed path prefix g log ->
 semax CCSearchContext.Delta
 (zero_row_state sh a p tp rp cap seed budget rules s path log buf xs ys zs pk frames row 1)
 (Ssequence(zero_phase_suffix k)search_finish)
 (normal_ret_assert(search_while_invariant sh a p tp rp cap seed budget rules s0)).
Proof.
 intros k sh a p tp rp cap seed budget rules s0 s path prefix g log buf xs ys zs pk frames row
 K SH Legal Seed Stats Mono Phase Whole Closed.
 pose proof(phase_zero_path_facts a cap seed path prefix g log buf xs ys zs pk frames Phase Whole)
 as[Nonempty More].
 assert(PathSplit:path=removelast path++[last path 0%nat])by(apply app_removelast_last;assumption).
 eapply semax_seq' with(P':=zero_row_state sh a p tp rp cap seed budget rules s path log buf xs ys zs pk frames row 1).
 - apply block_zero_suffix_closed;assumption.
 - rewrite PathSplit in Whole,Closed|-*;unfold zero_closed_top in Closed.
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
End Heap.
Print Assumptions block_zero_closed_suffix_iteration.
