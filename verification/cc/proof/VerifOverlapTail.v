(* Actual overlap rule guard and complete later phase0/finish continuation. *)
Require Import VST.floyd.proofauto.
Require Import CCV.ccv_core CCV.CCSearchSpecs CCV.CCSearchContext CCV.CCSearchFragments
 CCV.CCSearchMemory CCV.CCSearchHeap CCV.CCRowHeap CCV.CCLoopInvariant CCV.CCStackInvariant
 CCV.CCModel CCV.CCFunctional CCV.CCRepresentation CCV.CCJournalArray CCV.CCJournalTrace CCV.CCRootArray
 CCV.CCSearchExit CCV.CCPhaseZeroFacts CCV.CCPhaseZeroPrunerFacts CCV.CCAPIBridge
 CCV.CCOverlapArray CCV.CCOverlapInvariant CCV.CCOverlapCoverage CCV.CCSearchPolicies
 CCV.CCStatsInvariant CCV.CCBlockReturn CCV.VerifZeroKernel CCV.VerifZeroRemaining
 CCV.VerifOverlapHeap CCV.VerifOverlapStateCall CCV.VerifOverlapConditions CCV.VerifOverlapCounter
 CCV.VerifBoundsTail CCV.VerifZeroClosedSuffix.
Import ListNotations. Open Scope Z_scope.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
Definition zero_overlap_enabled:=search_fragment(phase_zero_path++
 [SeqNext;SeqNext;SeqNext;SeqNext;SeqNext;SeqFirst;SeqNext;ThenBranch]).
Definition zero_overlap_negative:=search_fragment(phase_zero_path++
 [SeqNext;SeqNext;SeqNext;SeqNext;SeqNext;SeqFirst;SeqNext;ThenBranch;SeqNext;SeqFirst]).
Lemma zero_overlap_enabled_layout:zero_overlap_enabled=Ssequence zero_overlap_call
 (Ssequence zero_overlap_negative
 (Sifthenelse(Ebinop Oeq(Etempvar _ov tint)(Econst_int(Int.repr 0)tint)tint)zero_overlap_reject Sskip)).
Proof. reflexivity. Qed.
Lemma zero_overlap_negative_layout:zero_overlap_negative=
 Sifthenelse(Ebinop Olt(Etempvar _ov tint)(Econst_int(Int.repr 0)tint)tint)
 (search_fragment(phase_zero_path++[SeqNext;SeqNext;SeqNext;SeqNext;SeqNext;SeqFirst;SeqNext;ThenBranch;SeqNext;SeqFirst;ThenBranch]))Sskip.
Proof. reflexivity. Qed.
Lemma zero_overlap_suffix_layout:zero_phase_suffix 5=
 Ssequence(Ssequence zero_overlap_conditions(Sifthenelse(Etempvar _t'3 tint)zero_overlap_enabled Sskip))
 (zero_phase_suffix 6).
Proof. reflexivity. Qed.
Section Proof.
Context{Espec:OracleKind}.
Lemma block_overlap_tail:forall sh a p tp rp cap seed budget rules s0 s path prefix g log buf xs ys zs pk frames row,
 readable_share sh ->legal_model a ->1<=cap<=model_n a ->0<=seed<=model_n a ->
 legal_stats budget s ->stats_monotone s0 s ->stat_pack s<stat_nodes s ->stat_charge s<stat_nodes s ->
 stat_overlap s<stat_nodes s ->ghost_phase g=0%nat ->
 loop_shape a cap seed path(prefix++[g])log buf xs ys zs pk frames ->
 0<=row<model_m a ->Znth row ys=1 ->0<cap-Z.of_nat(length path) ->
 semax CCSearchContext.Delta
 (zero_row_state sh a p tp rp cap seed budget rules s path log buf xs ys zs pk frames row 0)
 (Ssequence(zero_phase_suffix 5)search_finish)
 (overridePost(search_while_invariant sh a p tp rp cap seed budget rules s0)
 (function_body_ret_assert tint(search_return sh a p tp rp cap budget s0))).
Proof.
 intros sh a p tp rp cap seed budget rules s0 s path prefix g log buf xs ys zs pk frames row
 SH Legal Cap Seed Stats Mono PackFresh ChargeFresh OverlapFresh Phase Whole Row Odd Room.
 pose proof(legal_model_ranges a Legal)as[NR More].
 pose proof(phase_zero_path_facts a cap seed path prefix g log buf xs ys zs pk frames Phase Whole)
 as[Nonempty[Weight[Selected Depth]]].
 destruct(loop_bitmap_facts a cap seed path(prefix++[g])log buf xs ys zs pk frames Legal Seed Whole)
 as[BL[BB[FL FB]]].
 assert(XL:Zlength xs=model_n a)by(unfold loop_shape in Whole;tauto).
 assert(XB:Forall(fun z:Z=>z=0\/z=1)xs)by(unfold loop_shape in Whole;tauto).
 assert(Trace:journal_trace(model_n a)(root_mask(model_n a)seed)log buf)by(unfold loop_shape in Whole;tauto).
 pose(Bad:=overlap_rejects_all(model_n a)(model_h_rows a)(model_l_rows a)cap xs).
 pose(Allowed:=overlap_allows_all(model_n a)(model_h_rows a)(model_l_rows a)cap xs).
 assert(Policy:overlap_policy(model_n a)(model_k a)xs(model_g a)Bad Allowed).
 { unfold Bad,Allowed;apply(phase0_overlap_policy a cap seed path prefix g log buf xs ys zs pk frames);assumption. }
 rewrite zero_overlap_suffix_layout;apply seq_assoc1;apply seq_assoc1.
 eapply semax_seq' with(P':=overlap_condition_result sh a p tp rp cap seed budget rules s path log buf xs ys zs pk frames row).
 - apply block_overlap_conditions.
 - unfold overlap_condition_result;Intros enabled;destruct enabled.
   + unfold zero_row_state at 1;rewrite insert_local.
     unfold CCSearchContext.Delta;abbreviate_semax.
     apply semax_if_seq. forward_if.
     2:{ discriminate. }
     rewrite zero_overlap_enabled_layout;apply seq_assoc1.
     eapply semax_seq' with(P':=overlap_state_result sh a p tp rp cap seed budget rules s path log xs ys zs pk frames row Bad Allowed).
     * eapply semax_pre.
       2:{ apply(block_overlap_state_call sh a p tp rp cap seed budget rules s path log buf xs ys zs pk frames row Bad Allowed);assumption. }
       unfold zero_row_state;go_lowerx;normalize;cancel;try(apply andp_right;[apply prop_right;tauto|cancel]).
     * unfold overlap_state_result;Intros ret lognew bufnew.
       rewrite andp_assoc;apply semax_extract_prop;intros[Ret[Rejected[NewTrace Ext]]].
       pose proof(loop_shape_overlap a cap seed path prefix g log lognew buf bufnew xs ys zs pk frames
       Legal Seed Phase Whole NewTrace Ext)as NewShape.
       assert(RetRange:0<=ret<=1)by lia.
       unfold zero_row_state at 1;rewrite insert_local.
       rewrite zero_overlap_negative_layout;apply seq_assoc1;apply semax_if_seq. forward_if.
       { try rewrite Int.signed_repr in * by rep_lia;lia. }
       destruct Ret as[-> | ->].
       -- assert(Closed:zero_closed_top a cap seed path prefix g lognew).
          { intros e Min Within;apply(overlap_rejects_no_critical_top(model_n a)(model_h_rows a)(model_l_rows a)
          cap(root_mask(model_n a)seed)lognew path prefix g xs ltac:(lia)Phase(Rejected eq_refl)Selected e Min Within). }
          pose proof(overlap_prune_safe budget s Stats OverlapFresh)as[NewStats NewMono].
          pose proof(stats_monotone_trans s0 s(overlap_stats s)Mono NewMono)as TotalMono.
          apply semax_if_seq. forward_if.
          2:{ contradiction. }
          eapply semax_seq' with(P':=zero_row_state sh a p tp rp cap seed budget rules(overlap_stats s)
          path lognew bufnew xs ys zs pk frames row 1).
          ++ eapply semax_pre.
             2:{ apply block_overlap_counter;assumption. }
             unfold zero_row_state;go_lowerx;normalize;cancel;try(apply andp_right;[apply prop_right;tauto|cancel]).
          ++ apply normal_block_enclosing_return.
             apply(block_zero_closed_suffix_iteration 6 sh a p tp rp cap seed budget rules s0(overlap_stats s)
             path prefix g lognew bufnew xs ys zs pk frames row);try assumption;lia.
       -- apply semax_if_seq. forward_if.
          { discriminate. }
          eapply semax_pre.
          2:{ apply(block_bounds_tail sh a p tp rp cap seed budget rules s0 s path prefix g lognew bufnew xs ys zs pk frames row);assumption. }
          unfold zero_row_state;go_lowerx;normalize;cancel;try(apply andp_right;[apply prop_right;tauto|cancel]).
   + unfold zero_row_state at 1;rewrite insert_local.
     unfold CCSearchContext.Delta;abbreviate_semax.
     apply semax_if_seq. forward_if.
     { contradiction. }
     eapply semax_pre.
     2:{ apply(block_bounds_tail sh a p tp rp cap seed budget rules s0 s path prefix g log buf xs ys zs pk frames row);assumption. }
     unfold zero_row_state;go_lowerx;normalize;cancel;try(apply andp_right;[apply prop_right;tauto|cancel]).
Qed.
End Proof.
Print Assumptions block_overlap_tail.
