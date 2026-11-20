(* Parameterized proofs of the search context around the inner loop.
   The local proof statements below retain the canonical seed invariant,
   all early returns, and ownership of both addressable stack cells. *)
Require Import VST.floyd.proofauto CCV.CCExpandedBody CCV.CCBoundedMain CCV.CCSearchExpansion CCV.CCLoopInvariant
CCV.CCAPIBridge CCV.CCFrameForget CCV.CCRawTopHeap CCV.CCRootArray CCV.CCRootInvariant CCV.CCRootScratchForget CCV.CCSearchContext CCV.CCSearchEntryState CCV.CCSearchExit CCV.CCSearchFragments CCV.CCSearchHeap CCV.CCSearchResults CCV.CCSearchSpecs CCV.CCSeedCoverage CCV.CCSeedLoopState CCV.VerifClearRawTop CCV.VerifMainLoop CCV.VerifRootFrame CCV.VerifRootFrameContinuation CCV.VerifRootMask CCV.VerifRootPreparation CCV.VerifRootSeedBody CCV.VerifRootToggle CCV.VerifSearchCleanup CCV.VerifSearchCore CCV.VerifSearchEntry CCV.VerifSearchSeedInit CCV.VerifSeedLoop CCV.ccv_core.
Import ListNotations. Open Scope Z_scope.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
Section ContextProof.
Context {Espec:OracleKind}.
Variable middle:statement.
Hypothesis middle_verified:forall sh a p tp rp cap seed budget rules s0,
 readable_share sh ->legal_model a ->1<=cap<=model_n a ->0<=seed<=model_n a ->0<=rules<=63 ->
 semax CCSearchContext.Delta (search_while_invariant sh a p tp rp cap seed budget rules s0) middle
 (overridePost (main_loop_finished sh a p tp rp cap seed budget rules s0)
 (function_body_ret_assert tint (search_return sh a p tp rp cap budget s0))).
Theorem parameterized_block_root_seed_body:forall sh a p tp rp cap seed budget rules top xs fs ys zs pk buf frames out s0 s,
 readable_share sh ->legal_model a ->1<=cap<=model_n a ->0<=seed<model_n a ->0<=rules<=63 ->
 legal_stats budget s ->stats_monotone s0 s ->
 seeds_before_clear(Z.to_nat(model_n a))(model_h_rows a)(model_l_rows a)(Z.to_nat cap)(Z.to_nat seed) ->
 Zlength xs=model_n a ->Zlength fs=model_n a ->Zlength ys=model_m a ->Zlength zs=model_l a ->
 Zlength pk=model_n a ->Zlength out=model_n a ->
 semax CCSearchContext.Delta
 (root_state_raw sh a p tp rp cap seed budget rules top xs fs ys zs pk buf frames out s)
 (root_with middle)
 (overridePost(main_loop_finished sh a p tp rp cap seed budget rules s0)
 (function_body_ret_assert tint(search_return sh a p tp rp cap budget s0))).
Proof.
 intros sh a p tp rp cap seed budget rules top xs fs ys zs pk buf frames out s0 s
 SH Legal Cap Seed Rules Stats Mono Before XL FL YL ZL PL OL.
 pose proof(legal_model_ranges a Legal)as[NR[MR[LR[KR Rest]]]].
 unfold root_with.
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
     * 
       eapply semax_pre.
       2:{ apply(block_root_frame_continuation sh a p tp rp cap seed budget rules top s0 s middle
       (overridePost(main_loop_finished sh a p tp rp cap seed budget rules s0)
       (function_body_ret_assert tint(search_return sh a p tp rp cap budget s0))));try assumption.
       apply middle_verified;try assumption;lia. }
       unfold root_state_raw;go_lowerx;normalize.
       sep_apply(raw_top_forget_root_scratch sh a p tp rp top
       (root_xs(model_n a)seed)(root_mask(model_n a)seed)
       (root_cache(model_n a)(model_m a)seed(model_h a))(root_cache(model_n a)(model_l a)seed(model_lg a))
       (Zrepeat 0(model_n a))buf frames(Zrepeat 0(model_n a))s).
       normalize;cancel;try(apply andp_right;[apply prop_right;tauto|cancel]).
Qed.
Theorem parameterized_block_seed_loop:forall sh a p tp rp cap budget rules s0,
 readable_share sh ->legal_model a ->1<=cap<=model_n a ->0<=rules<=63 ->
 semax CCSearchContext.Delta(seed_loop_invariant sh a p tp rp cap budget rules s0)
 (seeds_with middle)
 (overridePost(seed_loop_finished sh a p tp rp cap budget rules s0)
 (function_body_ret_assert tint(search_return sh a p tp rp cap budget s0))).
Proof.
 intros sh a p tp rp cap budget rules s0 SH Legal Cap Rules.
 pose proof(legal_model_ranges a Legal)as[NR More].
 unfold CCSearchContext.Delta;abbreviate_semax.
 unfold seeds_with.
 forward_loop(seed_loop_invariant sh a p tp rp cap budget rules s0)
 continue:(seed_loop_continue sh a p tp rp cap budget rules s0)
 break:(seed_loop_finished sh a p tp rp cap budget rules s0).
 - apply andp_left2;apply derives_refl.
 - unfold seed_loop_invariant;Intros seed top xs fs ys zs pk buf frames out s.
   unfold search_heap_raw_top,problem_repr. Intros.
   unfold seed_limit_read,seed_limit_test. forward.
   apply semax_if_seq. forward_if.
   + repeat apply -> semax_skip_seq.
     assert(Inside:0<=seed<model_n a)by(try rewrite !Int.unsigned_repr in * by rep_lia;lia).
     eapply semax_post with(R':=overridePost(main_loop_finished sh a p tp rp cap seed budget rules s0)
     (function_body_ret_assert tint(search_return sh a p tp rp cap budget s0))).
     * unfold POSTCONDITION,abbreviate.
       cbn[RA_normal loop1_ret_assert overridePost function_body_ret_assert].
       apply andp_left2;apply seed_finished_to_continue;assumption.
     * cbn[RA_break overridePost function_body_ret_assert];normalize.
     * cbn[RA_continue overridePost function_body_ret_assert];normalize.
     * intros vl;cbn[RA_return overridePost function_body_ret_assert];apply andp_left2;apply derives_refl.
     * eapply semax_pre.
       2:{ apply(parameterized_block_root_seed_body sh a p tp rp cap seed budget rules top xs fs ys zs pk buf frames out s0 s);
       assumption. }
       unfold root_state_raw,search_heap_raw_top,problem_repr.
       go_lowerx;normalize;cancel;try(apply andp_right;[apply prop_right;tauto|cancel]).
   + assert(AtEnd:seed=model_n a)by(try rewrite !Int.unsigned_repr in * by rep_lia;lia).
     subst seed. forward.
     unfold seed_loop_finished,search_heap_raw_top,problem_repr.
     Exists top xs fs ys zs pk buf frames out s.
     entailer!;cancel.
 - unfold seed_loop_continue;Intros seed top xs fs ys zs pk buf frames out s.
   assert(Add:Int.add(Int.repr seed)(Int.repr 1)=Int.repr(seed+1)).
   { unfold Int.add;rewrite !Int.unsigned_repr by rep_lia;reflexivity. }
   assert(NextNat:Z.to_nat(seed+1)=S(Z.to_nat seed))by(rewrite Z2Nat.inj_add by lia;cbn;lia).
   unfold seed_increment. forward. rewrite Add.
   unfold seed_loop_invariant. Exists(seed+1)top xs fs ys zs pk buf frames out s.
   rewrite NextNat. entailer!;cancel.
 - cbn[RA_normal overridePost function_body_ret_assert];apply andp_left2;apply derives_refl.
Qed.
Theorem parameterized_block_search_bounded_tail:forall sh a p tp rp cap budget rules s0,
 readable_share sh ->legal_model a ->1<=cap<=model_n a ->0<=rules<=63 ->legal_stats budget s0 ->
 semax CCSearchContext.Delta(search_entry_state sh a p tp rp cap budget rules s0)
 (tail_with middle)(function_body_ret_assert tint(search_return sh a p tp rp cap budget s0)).
Proof.
 intros sh a p tp rp cap budget rules s0 SH Legal Cap Rules Stats.
 unfold tail_with. apply seq_assoc1.
 eapply semax_seq' with(P':=seed_loop_invariant sh a p tp rp cap budget rules s0).
 - apply block_search_seed_init;assumption.
 - eapply semax_seq with(Q:=seed_loop_finished sh a p tp rp cap budget rules s0).
   + apply parameterized_block_seed_loop;assumption.
   + apply block_search_cleanup;try assumption;lia.
Qed.
Theorem parameterized_block_search_positive_tail:forall sh a p tp rp cap budget rules s0,
 readable_share sh ->legal_model a ->1<=cap<=Int.max_unsigned ->0<=rules<=63 ->legal_stats budget s0 ->
 semax CCSearchContext.Delta(search_entry_state sh a p tp rp cap budget rules s0)
 (positive_with middle)(function_body_ret_assert tint(search_return sh a p tp rp cap budget s0)).
Proof.
 intros sh a p tp rp cap budget rules s0 SH Legal Cap Rules Stats.
 pose proof(legal_model_ranges a Legal)as[NR More].
 unfold positive_with,search_clamp,search_fragment,clamp_path;cbn[statement_at].
 unfold search_entry_state at 1;unfold search_entry_memory,problem_repr.
 unfold CCSearchContext.Delta;abbreviate_semax. Intros. apply seq_assoc1. forward.
 apply semax_if_seq. forward_if.
 - assert(Above:model_n a<cap)by(try rewrite !Int.unsigned_repr in * by rep_lia;lia).
   forward.
   eapply semax_post with(R':=function_body_ret_assert tint(search_return sh a p tp rp(model_n a)budget s0)).
   + cbn[RA_normal function_body_ret_assert];normalize.
   + cbn[RA_break function_body_ret_assert];normalize.
   + cbn[RA_continue function_body_ret_assert];normalize.
   + intros vl;cbn[RA_return function_body_ret_assert].
     apply andp_left2. unfold POSTCONDITION,abbreviate.
     change(bind_ret vl tint(search_return sh a p tp rp(model_n a)budget s0) |--
       bind_ret vl tint(search_return sh a p tp rp cap budget s0)).
     unfold bind_ret. destruct vl as[v|].
     * unfold liftx;intro rho;unfold_lift.
       change((!!tc_val tint v && search_return sh a p tp rp(model_n a)budget s0(make_args[ret_temp][v]rho)) |--
       (!!tc_val tint v && search_return sh a p tp rp cap budget s0(make_args[ret_temp][v]rho)))%logic.
       apply andp_derives;[apply derives_refl|]. apply search_return_clamp_cap;lia.
     * apply derives_refl.
   + eapply semax_pre.
     2:{ apply(parameterized_block_search_bounded_tail sh a p tp rp(model_n a)budget rules s0);try assumption;lia. }
     unfold search_entry_state,search_entry_memory,problem_repr.
     go_lowerx;normalize;cancel;try(apply andp_right;[apply prop_right;tauto|cancel]).
 - assert(Below:cap<=model_n a)by(try rewrite !Int.unsigned_repr in * by rep_lia;lia).
   repeat apply -> semax_skip_seq.
   eapply semax_pre.
   2:{ apply(parameterized_block_search_bounded_tail sh a p tp rp cap budget rules s0);try assumption;lia. }
   unfold search_entry_state,search_entry_memory,problem_repr.
   go_lowerx;normalize;cancel;try(apply andp_right;[apply prop_right;tauto|cancel]).
Qed.
Theorem parameterized_block_search_body:forall sh a p tp rp cap budget rules s0,
 readable_share sh ->legal_model a ->0<=cap<=Int.max_unsigned ->0<=rules<=63 ->legal_stats budget s0 ->
 semax CCSearchContext.Delta(search_entry_state sh a p tp rp cap budget rules s0)
 (body_with middle)(function_body_ret_assert tint(search_return sh a p tp rp cap budget s0)).
Proof.
 intros sh a p tp rp cap budget rules s0 SH Legal Cap Rules Stats.
 pose proof(legal_model_ranges a Legal)as[NR More].
 assert(Mono:stats_monotone s0 s0)by(unfold stats_monotone;lia).
 unfold body_with. unfold search_cap_zero,search_fragment,cap_zero_path;cbn[statement_at].
 unfold search_entry_state at 1. unfold CCSearchContext.Delta;abbreviate_semax.
 apply semax_if_seq. forward_if.
 - assert(Zero:cap=0)by(try rewrite !Int.unsigned_repr in * by rep_lia;lia). subst cap.
   assert(Query:query_result a 0 0(Zrepeat 0(model_n a))).
   { right;left;repeat split;try reflexivity. apply zero_cap_empty. }
   eapply semax_pre.
   2:{ eapply semax_seq with(Q:=FF).
       - apply(block_raw_empty_return sh a p tp rp 0 budget Vundef(root_buf(model_n a))
        (Zrepeat(default_frame:frame_value)(model_n a))s0 s0);assumption.
       - apply semax_ff. }
   rewrite <-entry_memory_raw. go_lowerx;normalize;cancel;try(apply andp_right;[apply prop_right;tauto|cancel]).
 - assert(Positive:1<=cap)by(try rewrite !Int.unsigned_repr in * by rep_lia;lia).
   repeat apply -> semax_skip_seq. eapply semax_pre.
   2:{ apply(parameterized_block_search_positive_tail sh a p tp rp cap budget rules s0);try assumption;lia. }
   unfold search_entry_state;go_lowerx;normalize;cancel;try(apply andp_right;[apply prop_right;tauto|cancel]).
Qed.
End ContextProof.
