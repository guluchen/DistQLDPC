(* Complete actual phase0 decisions after syndrome scanning, through common
   finish or a valid bounded FOUND return. *)
Require Import VST.floyd.proofauto.
Require Import CCV.ccv_core CCV.CCSearchSpecs CCV.CCSearchContext CCV.CCSearchFragments
 CCV.CCSearchHeap CCV.CCRowHeap CCV.CCLoopInvariant CCV.CCStackInvariant CCV.CCSearchExit
 CCV.CCJournalArray CCV.CCRootArray CCV.CCBlockReturn CCV.VerifPhaseZeroPrefix
 CCV.VerifZeroKernel CCV.VerifZeroRemaining CCV.VerifZeroGate CCV.VerifOverlapTail CCV.VerifZeroClosedSuffix.
Import ListNotations. Open Scope Z_scope.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
Lemma zero_after_row_layout:zero_after_row=Ssequence zero_kernel_gate(zero_phase_suffix 5).
Proof. reflexivity. Qed.
Section Proof.
Context{Espec:OracleKind}.
Lemma block_zero_after_row:forall sh a p tp rp cap seed budget rules s0 s path prefix g log buf xs ys zs pk frames row,
 readable_share sh ->legal_model a ->1<=cap<=model_n a ->0<=seed<=model_n a ->
 legal_stats budget s ->stats_monotone s0 s ->stat_pack s<stat_nodes s ->stat_charge s<stat_nodes s ->
 stat_overlap s<stat_nodes s ->ghost_phase g=0%nat ->
 loop_shape a cap seed path(prefix++[g])log buf xs ys zs pk frames ->
 0<=row<=model_m a ->(forall j,0<=j<row ->Znth j ys=0) ->(row<model_m a ->Znth row ys=1) ->
 semax CCSearchContext.Delta
 (zero_row_state sh a p tp rp cap seed budget rules s path log buf xs ys zs pk frames row 0)
 (Ssequence zero_after_row search_finish)
 (overridePost(search_while_invariant sh a p tp rp cap seed budget rules s0)
 (function_body_ret_assert tint(search_return sh a p tp rp cap budget s0))).
Proof.
 intros sh a p tp rp cap seed budget rules s0 s path prefix g log buf xs ys zs pk frames row
 SH Legal Cap Seed Stats Mono PackFresh ChargeFresh OverlapFresh Phase Whole Row Zero Odd.
 rewrite zero_after_row_layout;apply seq_assoc1.
 eapply semax_seq with(Q:=zero_gate_result sh a p tp rp cap seed budget rules s path prefix g log buf xs ys zs pk frames row).
 - apply(block_zero_gate sh a p tp rp cap seed budget rules s0 s path prefix g log buf xs ys zs pk frames row);assumption.
 - unfold zero_gate_result;Intros finish;apply semax_extract_prop;intros[Kind[Closed Continue]].
   destruct Kind as[Eq | Eq];subst finish.
   + destruct(Continue eq_refl)as[Room[Inside Unfinished]].
     apply(block_overlap_tail sh a p tp rp cap seed budget rules s0 s path prefix g log buf xs ys zs pk frames row);
     try assumption;try lia;apply Odd;lia.
   + apply normal_block_enclosing_return.
     apply(block_zero_closed_suffix_iteration 5 sh a p tp rp cap seed budget rules s0 s
     path prefix g log buf xs ys zs pk frames row);try assumption;try lia;apply Closed;reflexivity.
Qed.
End Proof.
Print Assumptions block_zero_after_row.
