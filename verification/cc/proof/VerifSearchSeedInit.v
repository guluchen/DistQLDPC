(* Actual seed initialization establishes the all-root coverage invariant. *)
Require Import VST.floyd.proofauto.
Require Import CCV.ccv_core CCV.CCSearchSpecs CCV.CCSearchContext CCV.CCSearchFragments
 CCV.CCSearchHeap CCV.CCRawTopHeap CCV.CCSearchEntryState CCV.CCRootInvariant CCV.CCFrameForget
 CCV.CCSeedCoverage CCV.CCSeedLoopState CCV.CCAPIBridge.
Import ListNotations. Open Scope Z_scope.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
Definition search_seed_init:=search_fragment[SeqNext;SeqNext;SeqFirst;SeqFirst].
Lemma search_seed_init_actual:search_seed_init=Sset _seed(Econst_int(Int.repr 0)tuint).
Proof. reflexivity. Qed.
Section Proof.
Context{Espec:OracleKind}.
Lemma block_search_seed_init:forall sh a p tp rp cap budget rules s0,
 legal_model a ->legal_stats budget s0 ->
 semax CCSearchContext.Delta(search_entry_state sh a p tp rp cap budget rules s0)
 search_seed_init(normal_ret_assert(seed_loop_invariant sh a p tp rp cap budget rules s0)).
Proof.
 intros sh a p tp rp cap budget rules s0 Legal Stats.
 pose proof(legal_model_ranges a Legal)as[NR[MR[LR More]]].
 assert(Mono:stats_monotone s0 s0)by(unfold stats_monotone;lia).
 pose proof(seeds_initial(Z.to_nat(model_n a))(model_h_rows a)(model_l_rows a)(Z.to_nat cap))as Before.
 rewrite search_seed_init_actual;unfold search_entry_state at 1.
 unfold CCSearchContext.Delta;abbreviate_semax. forward.
 unfold seed_loop_invariant.
 Exists 0 Vundef(Zrepeat 0(model_n a))(Zrepeat 0(model_n a))(Zrepeat 0(model_m a))
 (Zrepeat 0(model_l a))(Zrepeat 0(model_n a))(root_buf(model_n a))
 (Zrepeat(default_frame:frame_value)(model_n a))(Zrepeat 0(model_n a))s0.
 rewrite <-entry_memory_raw.
 entailer!;rewrite !Zlength_Zrepeat by lia;repeat split;reflexivity.
Qed.
End Proof.
Print Assumptions block_search_seed_init.
