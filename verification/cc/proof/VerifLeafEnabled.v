(* Complete actual enabled leaf branch: certified hit returns FOUND; certified
   unit-budget miss sets finish and closes all compatible minimum targets. *)
Require Import VST.floyd.proofauto.
Require Import CCV.ccv_core CCV.CCSearchSpecs CCV.CCSearchContext CCV.CCSearchFragments
 CCV.CCSearchMemory CCV.CCSearchHeap CCV.CCRowHeap CCV.CCLoopInvariant CCV.CCStackInvariant
 CCV.CCModel CCV.CCFunctional CCV.CCRepresentation CCV.CCJournalArray CCV.CCJournalTrace CCV.CCRootArray
 CCV.CCPhaseZeroFacts CCV.CCPhaseZeroLeafFacts CCV.CCPhaseZeroLeafHit CCV.CCSearchExit
 CCV.CCReturnCompose CCV.CCAPIBridge CCV.CCLeaf CCV.VerifPhaseOneTail
 CCV.VerifZeroKernel CCV.VerifZeroRemaining CCV.VerifLeafHeap CCV.VerifLeafStateCall CCV.VerifLeafFoundHeap.
Import ListNotations. Open Scope Z_scope.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
Definition zero_leaf_enabled:=search_fragment(phase_zero_path++
 [SeqNext;SeqNext;SeqNext;SeqNext;SeqNext;SeqNext;SeqNext;SeqFirst;SeqNext;ThenBranch]).
Lemma zero_leaf_enabled_layout:zero_leaf_enabled=
 Ssequence(Ssequence zero_leaf_call(Sifthenelse(Etempvar _t'6 tint)leaf_found_branch Sskip))
 (Sset _finish(Econst_int(Int.repr 1)tint)).
Proof. reflexivity. Qed.
Definition zero_leaf_closed sh a p tp rp cap seed budget rules s path prefix g log buf xs ys zs pk frames row:assert:=
 (!!zero_closed_top a cap seed path prefix g log&&
 zero_row_state sh a p tp rp cap seed budget rules s path log buf xs ys zs pk frames row 1)%logic.
Section Proof.
Context{Espec:OracleKind}.
Lemma block_leaf_enabled:forall sh a p tp rp cap seed budget rules s0 s path prefix g log buf xs ys zs pk frames row,
 readable_share sh ->legal_model a ->0<=seed<=model_n a ->legal_stats budget s ->stats_monotone s0 s ->
 ghost_phase g=0%nat ->loop_shape a cap seed path(prefix++[g])log buf xs ys zs pk frames ->
 ~model_good a(decode xs) ->cap-Z.of_nat(length path)=1 ->
 semax CCSearchContext.Delta
 (zero_row_state sh a p tp rp cap seed budget rules s path log buf xs ys zs pk frames row 0)
 zero_leaf_enabled
 (overridePost(zero_leaf_closed sh a p tp rp cap seed budget rules s path prefix g log buf xs ys zs pk frames row)
 (function_body_ret_assert tint(search_return sh a p tp rp cap budget s0))).
Proof.
 intros sh a p tp rp cap seed budget rules s0 s path prefix g log buf xs ys zs pk frames row
 SH Legal Seed Stats Mono Phase Whole Unfinished One.
 pose proof(legal_model_ranges a Legal)as[NR More].
 assert(N:0<=model_n a<=Int.max_signed)by lia.
 assert(XL:Zlength xs=model_n a)by(unfold loop_shape in Whole;tauto).
 assert(YL:Zlength ys=model_m a)by(unfold loop_shape in Whole;tauto).
 assert(ZL:Zlength zs=model_l a)by(unfold loop_shape in Whole;tauto).
 assert(XB:Forall(fun z:Z=>z=0\/z=1)xs)by(unfold loop_shape in Whole;tauto).
 assert(YB:Forall(fun z:Z=>z=0\/z=1)ys)by(unfold loop_shape in Whole;tauto).
 assert(ZB:Forall(fun z:Z=>z=0\/z=1)zs)by(unfold loop_shape in Whole;tauto).
 assert(Trace:journal_trace(model_n a)(root_mask(model_n a)seed)log buf)by(unfold loop_shape in Whole;tauto).
 assert(LogRange:Forall(fun q:Z=>0<=q<model_n a)log)by(unfold journal_trace in Trace;tauto).
 assert(BaseLen:Zlength(root_mask(model_n a)seed)=model_n a)by(apply root_mask_length;assumption).
 assert(FL:Zlength(journal_bitmap(root_mask(model_n a)seed)log)=model_n a)
 by(apply journal_bitmap_length;assumption).
 assert(FB:Forall(fun z:Z=>z=0\/z=1)(journal_bitmap(root_mask(model_n a)seed)log))
 by(apply journal_bitmap_bits;apply root_mask_bits;assumption).
 assert(OL:Zlength(Zrepeat 0(model_n a))=model_n a)by(rewrite Zlength_Zrepeat;lia).
 rewrite zero_leaf_enabled_layout;apply seq_assoc1.
 eapply semax_seq' with(P':=leaf_state_result sh a p tp rp cap seed budget rules s path log buf xs ys zs pk frames row).
 - exact(block_leaf_state_call sh a p tp rp cap seed budget rules s path log buf xs ys zs pk frames row
 SH Legal XL FL YL ZL XB FB YB ZB).
 - unfold leaf_state_result;Intros hit chosen. destruct hit;cbn[if_true if_false].
   + unfold zero_row_state at 1. rewrite andp_assoc,insert_local,insert_prop. Intros.
     unfold CCSearchContext.Delta;abbreviate_semax.
     apply semax_if_seq. forward_if.
     2:{ match goal with H:Int.repr 1=Int.zero|-_=>
          let Bad:=fresh"Bad"in pose proof(f_equal Int.unsigned H)as Bad;
          change(1=0)%Z in Bad;discriminate end. }
     assert(Hit:0<=chosen<model_n a /\leaf_candidate(model_n a)(model_m a)(model_l a)xs
     (journal_bitmap(root_mask(model_n a)seed)log)ys zs(model_h a)(model_lg a)chosen=true)by tauto.
     destruct Hit as[Chosen Hit].
     destruct(phase0_leaf_hit a cap seed path prefix g log buf xs ys zs pk frames chosen
     Legal Phase Whole One Chosen Hit)as[Good[Weight[Len Bits]]].
     eapply returned_sequence with(R:=function_body_ret_assert tint(search_return sh a p tp rp cap budget s0));
     [reflexivity|].
     eapply semax_pre.
     2:{ exact(block_leaf_found_heap sh a p tp rp(Zlength log)row cap budget(chosen_xs chosen xs)
     (journal_bitmap(root_mask(model_n a)seed)log)
     (chosen_ys(model_n a)(model_m a)chosen(model_h a)ys)
     (chosen_ys(model_n a)(model_l a)chosen(model_lg a)zs)
     pk buf frames(Zrepeat 0(model_n a))s s0 SH N Len OL Bits Stats Mono Good Weight). }
     go_lowerx;normalize;cancel;try(apply andp_right;[apply prop_right;tauto|cancel]).
   + unfold zero_row_state at 1. rewrite andp_assoc,insert_local,insert_prop. Intros.
     assert(Miss:forall q,0<=q<model_n a ->leaf_candidate(model_n a)(model_m a)(model_l a)xs
     (journal_bitmap(root_mask(model_n a)seed)log)ys zs(model_h a)(model_lg a)q=false)by assumption.
     pose proof(phase_zero_path_facts a cap seed path prefix g log buf xs ys zs pk frames Phase Whole)
     as[Nonempty[OldWeight MoreFacts]].
     assert(Closed:zero_closed_top a cap seed path prefix g log).
     { intros e Min Within;apply(leaf_miss_no_critical_top a cap seed path prefix g log buf xs ys zs pk frames
       Legal Seed Phase Whole Unfinished ltac:(lia)Miss e Min Within). }
     unfold CCSearchContext.Delta;abbreviate_semax.
     apply semax_if_seq. forward_if.
     { contradiction. }
     forward.
     unfold zero_leaf_closed,zero_row_state.
     go_lowerx;normalize;cancel;try(apply andp_right;[apply prop_right;tauto|cancel]).
Qed.
End Proof.
Print Assumptions block_leaf_enabled.
