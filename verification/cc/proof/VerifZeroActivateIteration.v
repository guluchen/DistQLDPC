(* Actual final phase0 activation guard and shared finish continuation. When
   finish=0, valid odd-row activation reaches the complete while invariant. *)
Require Import VST.floyd.proofauto.
Require Import CCV.ccv_core CCV.CCSearchSpecs CCV.CCSearchContext CCV.CCSearchFragments
 CCV.CCSearchHeap CCV.CCSearchMemory CCV.CCRowHeap CCV.CCLoopInvariant CCV.CCStackInvariant
 CCV.CCModel CCV.CCFunctional CCV.CCJournalArray CCV.CCRootArray CCV.CCBlockFrame
 CCV.VerifZeroRemaining CCV.VerifActivateFrame CCV.VerifActivateLoop CCV.VerifFinishSkip.
Import ListNotations. Open Scope Z_scope.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
Definition zero_activate_guard:=search_fragment(phase_zero_path++
 [SeqNext;SeqNext;SeqNext;SeqNext;SeqNext;SeqNext;SeqNext;SeqNext]).
Lemma zero_activate_guard_layout:zero_activate_guard=
 Sifthenelse(Eunop Onotbool(Etempvar _finish tint)tint)zero_activate Sskip.
Proof. reflexivity. Qed.
Section Proof.
Context{Espec:OracleKind}.
Lemma block_zero_activate_iteration:forall sh a p tp rp cap seed budget rules s0 s
 path prefix g log buf xs ys zs pk frames(row:nat),
 legal_model a ->1<=cap<=model_n a ->legal_stats budget s ->stats_monotone s0 s ->
 ghost_phase g=0%nat ->(row<Z.to_nat(model_m a))%nat ->(length path<Z.to_nat cap)%nat ->
 parity(Z.to_nat(model_n a))(nth row(model_h_rows a)zero_vector)
 (prefix_selected path(length prefix))=true ->
 loop_shape a cap seed path(prefix++[g])log buf xs ys zs pk frames ->
 semax CCSearchContext.Delta
 (zero_row_state sh a p tp rp cap seed budget rules s path log buf xs ys zs pk frames(Z.of_nat row)0)
 (Ssequence zero_activate_guard search_finish)
 (normal_ret_assert(search_while_invariant sh a p tp rp cap seed budget rules s0)).
Proof.
 intros sh a p tp rp cap seed budget rules s0 s path prefix g log buf xs ys zs pk frames row
 Legal Cap Stats Mono Phase Row Room Odd Whole.
 pose(P2:=zero_row_state sh a p tp rp cap seed budget rules s path log buf xs ys zs pk frames(Z.of_nat row)0).
 rewrite zero_activate_guard_layout.
 unfold CCSearchContext.Delta;abbreviate_semax.
 unfold zero_row_state at 1.
 apply semax_if_seq. forward_if.
 2:{ contradiction. }
 eapply semax_seq' with(P':=(search_while_invariant sh a p tp rp cap seed budget rules s0&&finish_zero)%logic).
 - eapply semax_post' with(R':=(search_while_invariant sh a p tp rp cap seed budget rules s0*finish_zero_frame)%logic).
   + apply andp_left2;apply finish_zero_frame_elim.
   + eapply semax_pre with(P':=(P2*finish_zero_frame)%logic).
     { eapply derives_trans;[|apply finish_zero_frame_intro].
       unfold P2,zero_row_state,finish_zero;go_lowerx;normalize;entailer!. }
     apply semax_normal_block_frame.
     { unfold finish_zero_frame,zero_activate;auto 50 with closed. }
     unfold P2,zero_row_state.
     eapply semax_pre.
     2:{ exact(block_activate_loop sh a p tp rp cap seed budget rules s0 s path prefix g log
     buf xs ys zs pk frames row Legal Cap Stats Mono Phase Row Room Odd Whole). }
     go_lowerx;normalize;cancel;try(apply andp_right;[apply prop_right;tauto|cancel]).
 - apply block_finish_skip.
Qed.
End Proof.
Print Assumptions block_zero_activate_iteration.
