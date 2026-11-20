(* Exact syndrome-row test joined with the logical-return and no-room gates.
   This is the complete first decision of phase0, not its later pruning tail. *)
Require Import VST.floyd.proofauto.
Require Import CCV.ccv_core CCV.CCSearchSpecs CCV.CCSearchContext CCV.CCSearchFragments
 CCV.CCSearchHeap CCV.CCRowHeap CCV.CCLoopInvariant CCV.CCStackInvariant CCV.CCModel
 CCV.CCRepresentation CCV.CCPhaseZeroFacts CCV.CCSearchExit CCV.CCAPIBridge CCV.CCBlockReturn
 CCV.VerifZeroKernel CCV.VerifZeroRemaining.
Import ListNotations. Open Scope Z_scope.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
Definition zero_kernel_gate:=search_fragment(phase_zero_path++
 [SeqNext;SeqNext;SeqNext;SeqNext;SeqFirst]).
Lemma zero_kernel_gate_layout:zero_kernel_gate=
 Ssequence(Sset _t'35(Evar _row tuint))
 (Ssequence(Sset _t'36(Efield(Ederef(Etempvar _p(tptr(Tstruct _ccv_problem noattr)))
 (Tstruct _ccv_problem noattr))_checks tuint))
 (Sifthenelse(Ebinop Oeq(Etempvar _t'35 tuint)(Etempvar _t'36 tuint)tint)
 zero_kernel_then zero_remaining_else)).
Proof. reflexivity. Qed.
Definition zero_gate_result sh a p tp rp cap seed budget rules s path prefix g log buf xs ys zs pk frames row:assert:=
 (EX finish:Z,
 !!((finish=0\/finish=1)/\(finish=1 ->zero_closed_top a cap seed path prefix g log)/\
 (finish=0 ->0<cap-Z.of_nat(length path)/\row<model_m a/\~model_good a(decode xs)))&&
 zero_row_state sh a p tp rp cap seed budget rules s path log buf xs ys zs pk frames row finish)%logic.
Lemma kernel_closed_gate_result sh a p tp rp cap seed budget rules s path prefix g log buf xs ys zs pk frames:
 zero_kernel_closed sh a p tp rp cap seed budget rules s path prefix g log buf xs ys zs pk frames |--
 zero_gate_result sh a p tp rp cap seed budget rules s path prefix g log buf xs ys zs pk frames(model_m a).
Proof.
 unfold zero_kernel_closed,zero_gate_result,zero_kernel_state,zero_row_state.
 go_lowerx;normalize;Exists 1;normalize;cancel;
 try(apply andp_right;[apply prop_right;intuition lia|cancel]).
Qed.
Lemma remaining_gate_result sh a p tp rp cap seed budget rules s path prefix g log buf xs ys zs pk frames row:
 row<model_m a ->~model_good a(decode xs) ->
 zero_remaining_result sh a p tp rp cap seed budget rules s path prefix g log buf xs ys zs pk frames row |--
 zero_gate_result sh a p tp rp cap seed budget rules s path prefix g log buf xs ys zs pk frames row.
Proof.
 intros Inside Unfinished;unfold zero_remaining_result,zero_gate_result.
 go_lowerx;normalize.
 match goal with H:(?f=0\/?f=1)|-_=>Exists f end.
 unfold zero_row_state;normalize;cancel;
 try(apply andp_right;[apply prop_right;tauto|cancel]).
Qed.
Section Proof.
Context{Espec:OracleKind}.
Lemma block_zero_gate:forall sh a p tp rp cap seed budget rules s0 s path prefix g log buf xs ys zs pk frames row,
 readable_share sh ->legal_model a ->1<=cap<=model_n a ->legal_stats budget s ->stats_monotone s0 s ->
 ghost_phase g=0%nat ->loop_shape a cap seed path(prefix++[g])log buf xs ys zs pk frames ->
 0<=row<=model_m a ->(forall j,0<=j<row ->Znth j ys=0) ->(row<model_m a ->Znth row ys=1) ->
 semax CCSearchContext.Delta
 (zero_row_state sh a p tp rp cap seed budget rules s path log buf xs ys zs pk frames row 0)
 zero_kernel_gate
 (overridePost(zero_gate_result sh a p tp rp cap seed budget rules s path prefix g log buf xs ys zs pk frames row)
 (function_body_ret_assert tint(search_return sh a p tp rp cap budget s0))).
Proof.
 intros sh a p tp rp cap seed budget rules s0 s path prefix g log buf xs ys zs pk frames row
 SH Legal Cap Stats Mono Phase Whole Row Zero Odd.
 pose proof(legal_model_ranges a Legal)as[NR[MR[LR[KR[HP Rest]]]]].
 assert(M:0<=model_m a<=Int.max_signed)by(split;[lia|nia]).
 rewrite zero_kernel_gate_layout;unfold zero_row_state at 1.
 unfold CCSearchContext.Delta;abbreviate_semax.
 unfold row_heap,search_core_heap,problem_repr. Intros.
 forward. forward.
 destruct(Z.eq_dec row(model_m a))as[Eq|Ne].
 - subst row;forward_if.
   2:{ contradiction. }
   eapply semax_pre with(P':=zero_kernel_state sh a p tp rp cap seed budget rules s
   path log buf xs ys zs pk frames 0).
   { unfold zero_kernel_state,row_heap,search_core_heap,problem_repr;go_lowerx;normalize;cancel. }
   eapply semax_post with(R':=overridePost
   (zero_kernel_closed sh a p tp rp cap seed budget rules s path prefix g log buf xs ys zs pk frames)
   (function_body_ret_assert tint(search_return sh a p tp rp cap budget s0))).
   + cbn[RA_normal overridePost];apply andp_left2;apply kernel_closed_gate_result.
   + cbn[RA_break overridePost function_body_ret_assert];normalize.
   + cbn[RA_continue overridePost function_body_ret_assert];normalize.
   + intros vl;cbn[RA_return overridePost function_body_ret_assert];apply andp_left2;apply derives_refl.
   + apply(block_zero_kernel sh a p tp rp cap seed budget rules s0 s path prefix g log buf xs ys zs pk frames);
     assumption.
 - assert(NeInt:Int.repr row<>Int.repr(model_m a)).
   { intro Eq;pose proof(f_equal Int.unsigned Eq)as Bad.
     rewrite !Int.unsigned_repr in Bad by rep_lia;apply Ne;lia. }
   assert(Inside:0<=row<model_m a)by lia.
   assert(HC:cached(model_n a)(model_m a)xs ys(model_h a))by(unfold loop_shape in Whole;tauto).
   assert(Unfinished:~model_good a(decode xs)).
   { apply(cached_odd_row_not_good a xs ys row MR HC Inside(Odd ltac:(lia))). }
   forward_if.
   { contradiction. }
   eapply semax_pre with(P':=zero_row_state sh a p tp rp cap seed budget rules s
   path log buf xs ys zs pk frames row 0).
   { unfold zero_row_state,row_heap,search_core_heap,problem_repr;go_lowerx;normalize;cancel. }
   apply normal_block_enclosing_return.
   eapply semax_post' with(R':=zero_remaining_result sh a p tp rp cap seed budget rules s
   path prefix g log buf xs ys zs pk frames row).
   + apply andp_left2;apply remaining_gate_result;[lia|assumption].
   + apply(block_zero_remaining sh a p tp rp cap seed budget rules s path prefix g log buf xs ys zs pk frames row);
     assumption.
Qed.
End Proof.
Print Assumptions block_zero_gate.
