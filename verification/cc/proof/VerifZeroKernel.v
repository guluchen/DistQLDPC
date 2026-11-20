(* Actual zero-syndrome/logical gate. Kernel/logical hit returns a valid bounded
   witness; a trivial zero-syndrome prefix closes without losing a minimum
   target. This is not the complete phase0 or search body. *)
Require Import VST.floyd.proofauto.
Require Import CCV.ccv_core CCV.CCSearchSpecs CCV.CCSearchContext CCV.CCSearchFragments
 CCV.CCSearchMemory CCV.CCSearchHeap CCV.CCRowHeap CCV.CCLoopInvariant CCV.CCStackInvariant
 CCV.CCModel CCV.CCFunctional CCV.CCRepresentation CCV.CCJournalArray CCV.CCRootArray
 CCV.CCPhaseZeroFacts CCV.CCSearchResults CCV.CCSearchExit CCV.CCAPIBridge CCV.CCReadBorrow
 CCV.CCReturnCompose CCV.VerifToggle CCV.VerifZeroLogicalCall CCV.VerifNontrivial CCV.VerifFoundHeap CCV.VerifOutputFound.
Import ListNotations. Open Scope Z_scope.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
Definition zero_kernel_then:=search_fragment(phase_zero_path++
 [SeqNext;SeqNext;SeqNext;SeqNext;SeqFirst;SeqNext;SeqNext;ThenBranch]).
Lemma zero_kernel_then_layout:zero_kernel_then=
 Ssequence(Ssequence zero_logical_call(Sifthenelse(Etempvar _t'1 tint)found_branch Sskip))
 (Sset _finish(Econst_int(Int.repr 1)tint)).
Proof. reflexivity. Qed.
Definition zero_closed_top a cap seed path prefix g log:Prop:=forall e,
 model_minimum a e ->(weight(Z.to_nat(model_n a))e<=Z.to_nat cap)%nat ->
 ~critical_at(Z.to_nat(model_n a))(model_h_rows a)(root_mask(model_n a)seed)log
 path(prefix++[g])e(length prefix).
Definition zero_kernel_state sh a p tp rp cap seed budget rules s(path:list nat)log buf xs ys zs pk frames finish:assert:=
 (PROP()LOCAL(temp _p(ptr_problem p);temp _w(ptr_workspace p);temp _out(ptr_out p);
 temp _stats(ptr_stats p);temp _cap(Vint(Int.repr cap));temp _seed(Vint(Int.repr seed));
 temp _budget(Vint(Int.repr budget));temp _rules(Vint(Int.repr rules));
 temp _depth(Vint(Int.repr(Z.of_nat(length path))));temp _finish(Vint(Int.repr finish));
 temp _remaining(Vint(Int.repr(cap-Z.of_nat(length path))));
 temp _f(active_frame_address p(model_n a)(Z.of_nat(length path)));
 lvar _top tuint tp;lvar _row tuint rp)
 SEP(row_heap sh a p tp rp(Zlength log)(model_m a)xs
 (journal_bitmap(root_mask(model_n a)seed)log)ys zs pk buf frames(Zrepeat 0(model_n a))s))%assert.
Definition zero_kernel_closed sh a p tp rp cap seed budget rules s path prefix g log buf xs ys zs pk frames:assert:=
 (!!zero_closed_top a cap seed path prefix g log&&
 zero_kernel_state sh a p tp rp cap seed budget rules s path log buf xs ys zs pk frames 1)%logic.
Section Proof.
Context{Espec:OracleKind}.
Lemma block_zero_kernel:forall sh a p tp rp cap seed budget rules s0 s path prefix g log buf xs ys zs pk frames,
 readable_share sh ->legal_model a ->legal_stats budget s ->stats_monotone s0 s ->
 ghost_phase g=0%nat ->loop_shape a cap seed path(prefix++[g])log buf xs ys zs pk frames ->
 (forall j,0<=j<model_m a ->Znth j ys=0) ->
 semax CCSearchContext.Delta
 (zero_kernel_state sh a p tp rp cap seed budget rules s path log buf xs ys zs pk frames 0)
 zero_kernel_then
 (overridePost(zero_kernel_closed sh a p tp rp cap seed budget rules s path prefix g log buf xs ys zs pk frames)
 (function_body_ret_assert tint(search_return sh a p tp rp cap budget s0))).
Proof.
 intros sh a p tp rp cap seed budget rules s0 s path prefix g log buf xs ys zs pk frames
 SH Legal Stats Mono Phase Whole Zero.
 pose proof(legal_model_ranges a Legal)as[NR[MR[LR[KR[HP[LP Rest]]]]]].
 assert(N:0<=model_n a<=Int.max_signed)by lia.
 assert(L:0<=model_l a<=Int.max_signed)by(split;[lia|nia]).
 assert(XL:Zlength xs=model_n a)by(unfold loop_shape in Whole;tauto).
 assert(ZL:Zlength zs=model_l a)by(unfold loop_shape in Whole;tauto).
 assert(XB:Forall(fun z:Z=>z=0\/z=1)xs)by(unfold loop_shape in Whole;tauto).
 assert(ZB:Forall(fun z:Z=>z=0\/z=1)zs)by(unfold loop_shape in Whole;tauto).
 assert(HC:cached(model_n a)(model_m a)xs ys(model_h a))by(unfold loop_shape in Whole;tauto).
 assert(LC:cached(model_n a)(model_l a)xs zs(model_lg a))by(unfold loop_shape in Whole;tauto).
 assert(OL:Zlength(Zrepeat 0(model_n a))=model_n a)by(rewrite Zlength_Zrepeat;lia).
 assert(Weight:output_weight a xs<=cap)by(unfold loop_shape,output_weight in Whole|-*;tauto).
 rewrite zero_kernel_then_layout,zero_logical_call_layout.
 unfold zero_kernel_state at 1.
 unfold CCSearchContext.Delta;abbreviate_semax.
 unfold row_heap,search_core_heap,problem_repr,workspace_fields.
 rewrite(read_share_split sh(tarray tuchar(model_l a))(tbytes zs)(ptr_logical_value p)).
 forward_call(ptr_problem p,ptr_workspace p,ptr_logical_value p,sh,zs).
 { rewrite ZL. change(lbytes zs)with(tbytes zs). cancel. }
 destruct(has_nonzero zs)eqn:NZ.
 - pose proof(cached_found_is_good(model_n a)(model_m a)(model_l a)(model_h a)(model_lg a)
 xs ys zs MR LR ZL HC LC Zero NZ)as Good.
   apply semax_if_seq. forward_if.
   2:{ pose proof(f_equal Int.unsigned H)as Bad;change(1=0)%Z in Bad;discriminate. }
   eapply returned_sequence with(R:=function_body_ret_assert tint(search_return sh a p tp rp cap budget s0));
   [reflexivity|].
   eapply semax_pre with(P':=
   (PROP()LOCAL(temp _p(ptr_problem p);temp _w(ptr_workspace p);temp _out(ptr_out p);
   lvar _top tuint tp;lvar _row tuint rp)
   SEP(row_heap sh a p tp rp(Zlength log)(model_m a)xs(journal_bitmap(root_mask(model_n a)seed)log)
   ys zs pk buf frames(Zrepeat 0(model_n a))s))%assert).
   { unfold row_heap,search_core_heap,problem_repr,workspace_fields.
     rewrite(read_share_split sh(tarray tuchar(model_l a))(tbytes zs)(ptr_logical_value p)).
     rewrite ZL. change(lbytes zs)with(tbytes zs).
     go_lowerx;normalize;cancel;try(apply andp_right;[apply prop_right;tauto|cancel]). }
   apply(block_found_heap sh a p tp rp(Zlength log)(model_m a)cap budget xs
   (journal_bitmap(root_mask(model_n a)seed)log)ys zs pk buf frames(Zrepeat 0(model_n a))s s0);
   assumption.
 - assert(Closed:zero_closed_top a cap seed path prefix g log).
   { intros e Min Within;apply(zero_kernel_trivial_no_critical_top a cap seed path prefix g log
     buf xs ys zs pk frames Legal Phase Whole Zero NZ e Min). }
   apply semax_if_seq. forward_if.
   { contradiction. }
   forward.
   unfold zero_kernel_closed,zero_kernel_state,row_heap,search_core_heap,problem_repr,workspace_fields.
   rewrite(read_share_split sh(tarray tuchar(model_l a))(tbytes zs)(ptr_logical_value p)).
   rewrite ZL. change(lbytes zs)with(tbytes zs).
   go_lowerx;normalize;cancel;try(apply andp_right;[apply prop_right;tauto|cancel]).
Qed.
End Proof.
Print Assumptions block_zero_kernel.
