(* Actual full phase1 branch under complete search ownership. Its exact scan
   certificate is retained; conversion to the global loop invariant is separate. *)
Require Import VST.floyd.proofauto.
Require Import CCV.ccv_core CCV.CCSearchSpecs CCV.CCSearchContext CCV.CCSearchFragments
 CCV.CCSearchMemory CCV.CCSearchHeap CCV.VerifPhaseOne CCV.VerifPhaseOneTail
 CCV.VerifPhaseTwo CCV.CCBlockFrame CCV.CCAPIBridge CCV.VerifToggle.
Import ListNotations. Open Scope Z_scope.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
Definition phase1_heap_frame sh a p(tp:val)rp cap seed budget rules pk buf out s:assert:=
 (PROP()LOCAL(temp _cap(Vint(Int.repr cap));temp _seed(Vint(Int.repr seed));
 temp _budget(Vint(Int.repr budget));temp _rules(Vint(Int.repr rules));
 temp _out(ptr_out p);temp _stats(ptr_stats p);lvar _row tuint rp)
 SEP(field_at sh CCSearchMemory.workspace_type[StructField _undo](ptr_undo p)(ptr_workspace p);
 data_at Tsh(tarray tuint(model_n a))buf(ptr_undo p);
 search_phase2_extra sh a p rp pk out s))%assert.
Definition phase1_heap_result sh a p tp rp cap seed budget rules depth top row next mark
 xs fs ys zs pk buf frames out s:assert:=
 (EX q:Z,
 PROP(phase1_certificate(model_n a)row next(model_h a)xs fs q)
 LOCAL(temp _p(ptr_problem p);temp _w(ptr_workspace p);
 temp _f(active_frame_address p(model_n a)depth);temp _q(Vint(Int.repr q));
 temp _depth(Vint(Int.repr(if q<?model_n a then depth+1 else depth)));
 temp _finish(Vint(Int.repr(if q<?model_n a then 0 else 1)));
 temp _cap(Vint(Int.repr cap));temp _seed(Vint(Int.repr seed));
 temp _budget(Vint(Int.repr budget));temp _rules(Vint(Int.repr rules));
 temp _out(ptr_out p);temp _stats(ptr_stats p);lvar _top tuint tp;lvar _row tuint rp)
 SEP(search_heap sh a p tp rp top
 (if q<?model_n a then chosen_xs q xs else xs)fs
 (if q<?model_n a then chosen_ys(model_n a)(model_m a)q(model_h a)ys else ys)
 (if q<?model_n a then chosen_ys(model_n a)(model_l a)q(model_lg a)zs else zs)
 pk buf(if q<?model_n a then child_frames depth row q mark top frames else frames)out s))%assert.
Section Proof.
Context{Espec:OracleKind}.
Lemma block_phase_one_heap:forall sh a p tp rp cap seed budget rules depth top row next chosen mark
 xs fs ys zs pk buf frames out s,
 readable_share sh ->legal_model a ->0<=row<model_m a ->0<=next<=model_n a ->
 1<=depth<model_n a ->0<=top<=model_n a ->
 Zlength frames=model_n a ->Znth(depth-1)frames=frame_words row next chosen mark 1 ->
 Zlength xs=model_n a ->Zlength fs=model_n a ->Zlength ys=model_m a ->Zlength zs=model_l a ->
 Forall(fun z:Z=>z=0\/z=1)xs ->Forall(fun z:Z=>z=0\/z=1)fs ->
 Forall(fun z:Z=>z=0\/z=1)ys ->Forall(fun z:Z=>z=0\/z=1)zs ->
 semax CCSearchContext.Delta
 (PROP()LOCAL(temp _p(ptr_problem p);temp _w(ptr_workspace p);
 temp _f(active_frame_address p(model_n a)depth);temp _depth(Vint(Int.repr depth));
 temp _finish(Vint Int.zero);temp _cap(Vint(Int.repr cap));temp _seed(Vint(Int.repr seed));
 temp _budget(Vint(Int.repr budget));temp _rules(Vint(Int.repr rules));
 temp _out(ptr_out p);temp _stats(ptr_stats p);lvar _top tuint tp;lvar _row tuint rp)
 SEP(search_heap sh a p tp rp top xs fs ys zs pk buf frames out s))%assert
 search_phase_one
 (normal_ret_assert(phase1_heap_result sh a p tp rp cap seed budget rules depth top row next mark
 xs fs ys zs pk buf frames out s)).
Proof.
 intros sh a p tp rp cap seed budget rules depth top row next chosen mark xs fs ys zs pk buf frames out s
 SH Legal Row Next Depth Top Flen Frame XL FL YL ZL XB FB YB ZB.
 pose proof(legal_model_ranges a Legal)as[NR[MR[LR[KR[HP[LP GP]]]]]].
 assert(N:0<model_n a)by lia.
 assert(Extent:20*model_n a<=Int.max_signed).
 { unfold legal_model in Legal;change Int.max_signed with 2147483647;lia. }
 destruct Legal as[DimN[DimM[DimL[DimK[HL[LL[GL[HB[LB[GB Meta]]]]]]]]]].
 set(F:=phase1_heap_frame sh a p tp rp cap seed budget rules pk buf out s).
 eapply semax_post' with(R':=(phase1_result sh p tp(model_n a)(model_m a)(model_l a)
 depth top row next mark(model_h a)(model_lg a)xs fs ys zs frames*F)%logic).
 2:{ eapply semax_pre with(P':=((PROP()LOCAL(temp _p(ptr_problem p);temp _w(ptr_workspace p);
 temp _f(active_frame_address p(model_n a)depth);temp _depth(Vint(Int.repr depth));
 temp _finish(Vint Int.zero);lvar _top tuint tp)
 SEP(phase1_memory sh p tp(model_n a)(model_m a)(model_l a)top(model_h a)(model_lg a)
 xs fs ys zs frames))*F)%logic).
 { unfold F,phase1_heap_frame;rewrite search_heap_phase2;unfold phase2_memory;
 go_lowerx;normalize;cancel.
 apply andp_right;[apply prop_right;tauto|cancel]. }
 apply semax_normal_block_frame.
 { unfold F,phase1_heap_frame,search_phase_one;auto 50 with closed. }
 apply(block_phase_one sh p tp(model_n a)(model_m a)(model_l a)depth top row next chosen mark
 (model_h a)(model_lg a)xs fs ys zs frames);assumption.
 }
 apply andp_left2.
 unfold phase1_result,tail_result,F,phase1_heap_frame,phase1_heap_result.
 go_lowerx;normalize. Exists x.
 rewrite search_heap_phase2. unfold phase2_memory. normalize;cancel.
 apply andp_right;[apply prop_right;tauto|cancel].
Qed.
End Proof.
Print Assumptions block_phase_one_heap.
