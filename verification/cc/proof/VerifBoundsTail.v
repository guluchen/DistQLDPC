(* Actual bounds guard, native call, row choice, rejection, and full leaf/finish
   continuation. No pruning policy or helper implementation is assumed. *)
Require Import VST.floyd.proofauto.
Require Import CCV.ccv_core CCV.CCSearchSpecs CCV.CCSearchContext CCV.CCSearchFragments
 CCV.CCSearchMemory CCV.CCSearchHeap CCV.CCRowHeap CCV.CCLoopInvariant CCV.CCStackInvariant
 CCV.CCModel CCV.CCFunctional CCV.CCRepresentation CCV.CCJournalArray CCV.CCRootArray
 CCV.CCSearchExit CCV.CCPhaseZeroFacts CCV.CCPhaseZeroPrunerFacts CCV.CCAPIBridge
 CCV.CCBoundsArray CCV.CCBoundsLoop CCV.CCBoundsPolicy CCV.CCSearchPolicies CCV.CCPhaseZeroBoundsFacts
 CCV.CCPhaseZeroStats CCV.CCStatsInvariant CCV.CCBlockReturn
 CCV.VerifZeroKernel CCV.VerifZeroRemaining CCV.VerifBoundsHeap CCV.VerifBoundsStateCall
 CCV.VerifLeafTail CCV.VerifZeroClosedSuffix.
Import ListNotations. Open Scope Z_scope.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
Definition bounds_return_flag:=Sset _t'4(Ecast(Eunop Onotbool(Etempvar _t'5 tint)tint)tbool).
Lemma zero_bounds_suffix_layout:zero_phase_suffix 6=
 Ssequence(Ssequence
 (Sifthenelse(Eunop Onotbool(Etempvar _finish tint)tint)
 (Ssequence zero_bounds_call bounds_return_flag)(Sset _t'4(Econst_int(Int.repr 0)tint)))
 (Sifthenelse(Etempvar _t'4 tint)(Sset _finish(Econst_int(Int.repr 1)tint))Sskip))
 (zero_phase_suffix 7).
Proof. reflexivity. Qed.
Section Proof.
Context{Espec:OracleKind}.
Lemma block_bounds_tail:forall sh a p tp rp cap seed budget rules s0 s path prefix g log buf xs ys zs pk frames row,
 readable_share sh ->legal_model a ->1<=cap<=model_n a ->0<=seed<=model_n a ->
 legal_stats budget s ->stats_monotone s0 s ->stat_pack s<stat_nodes s ->stat_charge s<stat_nodes s ->
 ghost_phase g=0%nat ->loop_shape a cap seed path(prefix++[g])log buf xs ys zs pk frames ->
 0<=row<model_m a ->Znth row ys=1 ->0<cap-Z.of_nat(length path) ->
 semax CCSearchContext.Delta
 (zero_row_state sh a p tp rp cap seed budget rules s path log buf xs ys zs pk frames row 0)
 (Ssequence(zero_phase_suffix 6)search_finish)
 (overridePost(search_while_invariant sh a p tp rp cap seed budget rules s0)
 (function_body_ret_assert tint(search_return sh a p tp rp cap budget s0))).
Proof.
 intros sh a p tp rp cap seed budget rules s0 s path prefix g log buf xs ys zs pk frames row
 SH Legal Cap Seed Stats Mono PackFresh ChargeFresh Phase Whole Row Odd Room.
 pose proof(legal_model_ranges a Legal)as[NR[MR[LR[KR[HP Rest]]]]].
 pose proof(phase_zero_path_facts a cap seed path prefix g log buf xs ys zs pk frames Phase Whole)
 as[Nonempty[Weight[Selected Depth]]].
 destruct(loop_bitmap_facts a cap seed path(prefix++[g])log buf xs ys zs pk frames Legal Seed Whole)
 as[BL[BB[FL FB]]].
 assert(HC:cached(model_n a)(model_m a)xs ys(model_h a))by(unfold loop_shape in Whole;tauto).
 assert(Unfinished:~model_good a(decode xs))by(apply(cached_odd_row_not_good a xs ys row MR HC Row Odd)).
 assert(NoZero:odd_count(model_m a)ys<>0).
 { intro Zero;pose proof(odd_count_zero_row(model_m a)ys row MR Row Zero);congruence. }
 assert(Rem:0<=cap-Z.of_nat(length path)<=model_n a)by lia.
 assert(RowUnsigned:0<=row<=Int.max_unsigned)by(assert(M:0<=model_m a<=Int.max_signed)by nia;rep_lia).
 assert(PC:0<=stat_pack s<Int.max_unsigned)by(unfold legal_stats in Stats;lia).
 assert(CC:0<=stat_charge s<Int.max_unsigned)by(unfold legal_stats in Stats;lia).
 pose(Bad:=bounds_rejects_all(model_n a)(model_m a)(model_h a)(model_l_rows a)cap xs
 (journal_bitmap(root_mask(model_n a)seed)log)).
 assert(Policy:bounds_policy(model_n a)(model_m a)(model_h a)xs
 (journal_bitmap(root_mask(model_n a)seed)log)ys(cap-Z.of_nat(length path))Bad).
 { unfold Bad;apply(phase0_bounds_policy a cap seed path prefix g log buf xs ys zs pk frames);assumption. }
 rewrite zero_bounds_suffix_layout;apply seq_assoc1;apply seq_assoc1.
 unfold zero_row_state at 1.
 unfold CCSearchContext.Delta;abbreviate_semax.
 apply semax_if_seq. forward_if.
 2:{ contradiction. }
 apply seq_assoc1.
 eapply semax_seq' with(P':=bounds_state_result sh a p tp rp cap seed budget rules s path log buf xs ys zs pk frames Bad).
 - eapply semax_pre.
   2:{ apply(block_bounds_state_call sh a p tp rp cap seed budget rules s path log buf xs ys zs pk frames row Bad);
   try assumption;unfold loop_shape in Whole;tauto. }
   unfold zero_row_state;go_lowerx;normalize;cancel;try(apply andp_right;[apply prop_right;tauto|cancel]).
 - unfold bounds_state_result;Intros ret newrow newpk pc cc.
   rewrite andp_assoc;apply semax_extract_prop.
   intros[Ret[Rejected[NewRow[Choice[NewOdd[PKL[PKB[PCNew CCNew]]]]]]]].
   pose proof(bounds_stats_safe budget s pc cc Stats PackFresh ChargeFresh PCNew CCNew)as[NewStats NewMono].
   pose proof(stats_monotone_trans s0 s(bounds_stats s pc cc)Mono NewMono)as TotalMono.
   pose proof(loop_shape_replace_packed a cap seed path(prefix++[g])log buf xs ys zs pk newpk frames Whole PKL PKB)as NewShape.
   unfold zero_row_state at 1;rewrite insert_local.
   destruct Ret as[-> | ->].
   + assert(Closed:zero_closed_top a cap seed path prefix g log).
     { intros e Min Within;apply(bounds_rejects_no_critical_top(model_n a)(model_m a)(model_h a)(model_l_rows a)
       cap(root_mask(model_n a)seed)log path prefix g xs ltac:(lia)Phase(Rejected eq_refl)Selected e Min Within). }
     unfold bounds_return_flag. forward.
     apply semax_if_seq. forward_if.
     2:{ discriminate. }
     forward.
     apply normal_block_enclosing_return.
     eapply semax_pre.
     2:{ apply(block_zero_closed_suffix_iteration 7 sh a p tp rp cap seed budget rules s0(bounds_stats s pc cc)
       path prefix g log buf xs ys zs newpk frames newrow);try assumption;lia. }
     unfold zero_row_state;go_lowerx;normalize;cancel;try(apply andp_right;[apply prop_right;tauto|cancel]).
   + assert(Inside:0<=newrow<model_m a).
     { destruct(Z.eq_dec newrow(model_m a))as[Eq|Ne];[|lia].
       pose proof(proj1(Choice eq_refl)Eq);contradiction. }
     assert(NewRowNat:(Z.to_nat newrow<Z.to_nat(model_m a))%nat)by(apply Z2Nat.inj_lt;lia).
     assert(RoomNat:(length path<Z.to_nat cap)%nat)by(apply Nat2Z.inj_lt;rewrite Z2Nat.id by lia;lia).
     pose proof(phase0_cached_odd_row a cap seed path prefix g log buf xs ys zs newpk frames newrow
       Legal Phase NewShape Inside(NewOdd eq_refl ltac:(lia)))as NewOddRow.
     unfold bounds_return_flag. forward.
     apply semax_if_seq. forward_if.
     { discriminate. }
     eapply semax_pre.
     2:{ apply(block_leaf_tail sh a p tp rp cap seed budget rules s0(bounds_stats s pc cc)
       path prefix g log buf xs ys zs newpk frames(Z.to_nat newrow));assumption. }
     unfold zero_row_state;rewrite Z2Nat.id by lia.
     go_lowerx;normalize;cancel;try(apply andp_right;[apply prop_right;tauto|cancel]).
Qed.
End Proof.
Print Assumptions block_bounds_tail.
