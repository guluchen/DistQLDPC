(* Complete actual body for one canonical root seed: clear, exclusion mask,
   toggle, frame initialization and the verified full inner search loop. *)
Require Import VST.floyd.proofauto.
Require Import CCV.ccv_core CCV.CCSearchSpecs CCV.CCSearchContext CCV.CCSearchFragments
 CCV.CCSearchHeap CCV.CCRawTopHeap CCV.CCRootArray CCV.CCRootInvariant CCV.CCRootScratchForget
 CCV.CCFrameForget CCV.CCSeedCoverage CCV.CCSearchExit CCV.CCAPIBridge
 CCV.VerifClearRawTop CCV.VerifRootMask CCV.VerifRootPreparation CCV.VerifRootToggle
 CCV.VerifRootFrame CCV.VerifRootFrameContinuation CCV.VerifMainLoop.
Import ListNotations. Open Scope Z_scope.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
Definition root_seed_body:=search_fragment(seed_loop_path++[LoopBody;SeqNext]).
Lemma root_seed_body_actual:root_seed_body=Ssequence raw_top_clear_call
 (Ssequence root_mask_block(Ssequence root_toggle_call root_after_toggle)).
Proof. reflexivity. Qed.
Section Proof.
Context{Espec:OracleKind}.
Theorem block_root_seed_body:forall sh a p tp rp cap seed budget rules top xs fs ys zs pk buf frames out s0 s,
 readable_share sh ->legal_model a ->1<=cap<=model_n a ->0<=seed<model_n a ->0<=rules<=63 ->
 legal_stats budget s ->stats_monotone s0 s ->
 seeds_before_clear(Z.to_nat(model_n a))(model_h_rows a)(model_l_rows a)(Z.to_nat cap)(Z.to_nat seed) ->
 Zlength xs=model_n a ->Zlength fs=model_n a ->Zlength ys=model_m a ->Zlength zs=model_l a ->
 Zlength pk=model_n a ->Zlength out=model_n a ->
 semax CCSearchContext.Delta
 (root_state_raw sh a p tp rp cap seed budget rules top xs fs ys zs pk buf frames out s)
 root_seed_body
 (overridePost(main_loop_finished sh a p tp rp cap seed budget rules s0)
 (function_body_ret_assert tint(search_return sh a p tp rp cap budget s0))).
Proof.
 intros sh a p tp rp cap seed budget rules top xs fs ys zs pk buf frames out s0 s
 SH Legal Cap Seed Rules Stats Mono Before XL FL YL ZL PL OL.
 pose proof(legal_model_ranges a Legal)as[NR[MR[LR[KR Rest]]]].
 rewrite root_seed_body_actual.
 eapply semax_seq' with(P':=root_state_raw sh a p tp rp cap seed budget rules top
 (Zrepeat 0(model_n a))(Zrepeat 0(model_n a))(Zrepeat 0(model_m a))(Zrepeat 0(model_l a))
 (Zrepeat 0(model_n a))buf frames(Zrepeat 0(model_n a))s).
 - apply block_clear_root_state;assumption.
 - eapply semax_seq' with(P':=root_state_raw sh a p tp rp cap seed budget rules top
   (Zrepeat 0(model_n a))(root_mask(model_n a)seed)(Zrepeat 0(model_m a))(Zrepeat 0(model_l a))
   (Zrepeat 0(model_n a))buf frames(Zrepeat 0(model_n a))s).
   + eapply semax_pre.
     2:{ apply(block_mask_root_state sh a p tp rp cap seed budget rules top
     (Zrepeat 0(model_n a))(Zrepeat 0(model_m a))(Zrepeat 0(model_l a))(Zrepeat 0(model_n a))buf frames
     (Zrepeat 0(model_n a))s);try assumption;lia. }
     rewrite root_mask_start;apply andp_left2;apply derives_refl.
   + eapply semax_seq' with(P':=root_state_raw sh a p tp rp cap seed budget rules top
     (root_xs(model_n a)seed)(root_mask(model_n a)seed)
     (root_cache(model_n a)(model_m a)seed(model_h a))(root_cache(model_n a)(model_l a)seed(model_lg a))
     (Zrepeat 0(model_n a))buf frames(Zrepeat 0(model_n a))s).
     * apply block_root_toggle;try assumption;try(rewrite Zlength_Zrepeat;lia);apply root_zero_bits.
     * rewrite <-root_frame_then_actual.
       eapply semax_pre.
       2:{ apply(block_root_frame_continuation sh a p tp rp cap seed budget rules top s0 s search_main_loop
       (overridePost(main_loop_finished sh a p tp rp cap seed budget rules s0)
       (function_body_ret_assert tint(search_return sh a p tp rp cap budget s0))));try assumption.
       apply block_main_loop;try assumption;lia. }
       unfold root_state_raw;go_lowerx;normalize.
       sep_apply(raw_top_forget_root_scratch sh a p tp rp top
       (root_xs(model_n a)seed)(root_mask(model_n a)seed)
       (root_cache(model_n a)(model_m a)seed(model_h a))(root_cache(model_n a)(model_l a)seed(model_lg a))
       (Zrepeat 0(model_n a))buf frames(Zrepeat 0(model_n a))s).
       normalize;cancel;try(apply andp_right;[apply prop_right;tauto|cancel]).
Qed.
End Proof.
Print Assumptions block_root_seed_body.
