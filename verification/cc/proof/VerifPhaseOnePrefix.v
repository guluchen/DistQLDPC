(* Composition of the actual phase1 setup and scan statements.
   IN PROGRESS until normal coqc PASS; this is not the complete search body. *)
Require Import VST.floyd.proofauto.
Require Import CCV.ccv_core CCV.CCSearchSpecs CCV.CCSearchContext CCV.CCSearchScan
 CCV.CCSearchMemory CCV.CCBlockFrame CCV.VerifCandidateScan.
Import ListNotations. Open Scope Z_scope.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
Definition phase1_prefix:=Ssequence CCSearchScan.scan_setup CCSearchScan.scan_loop.
Definition prefix_result sh p tp n m l depth top row next (chosen:val)(mark:Z) hs ls xs fs ys zs frames:assert:=
 (EX q:Z,PROP(next<=q<=n;scan_skipped n row hs xs fs next q;
   q<n ->scan_available n row hs xs fs q=true)
 LOCAL(temp _p(ptr_problem p);temp _w(ptr_workspace p);
   temp _f(active_frame_address p n depth);temp _depth(Vint(Int.repr depth));
   temp _finish(Vint Int.zero);temp _q(Vint(Int.repr q));lvar _top tuint tp)
 SEP(phase1_memory sh p tp n m l top hs ls xs fs ys zs frames))%assert.
Section Proof.
Context{Espec:OracleKind}.
Lemma block_phase1_scan_prefix:
 forall sh p tp n m l depth top row next chosen mark hs ls xs fs ys zs frames,
 readable_share sh ->0<n<=Int.max_signed ->0<=m ->m*n<=Int.max_signed ->
 0<=row<m ->0<=next<=n ->1<=depth<=n ->
 Zlength frames=n ->Znth(depth-1)frames=frame_words row next chosen mark 1 ->
 Zlength hs=m*n ->Zlength xs=n ->Zlength fs=n ->
 Forall(fun z:Z=>z=0\/z=1)hs ->Forall(fun z:Z=>z=0\/z=1)xs ->
 Forall(fun z:Z=>z=0\/z=1)fs ->
 semax CCSearchContext.Delta
 (PROP()LOCAL(temp _p(ptr_problem p);temp _w(ptr_workspace p);
   temp _f(active_frame_address p n depth);temp _depth(Vint(Int.repr depth));
   temp _finish(Vint Int.zero);lvar _top tuint tp)
 SEP(phase1_memory sh p tp n m l top hs ls xs fs ys zs frames))%assert
 phase1_prefix
 (normal_ret_assert(prefix_result sh p tp n m l depth top row next chosen mark hs ls xs fs ys zs frames)).
Proof.
 intros sh p tp n m l depth top row next chosen mark hs ls xs fs ys zs frames
   SH N M Product Row Next Depth Flen Frame Hlen Xlen Blen HB XB FB.
 unfold CCSearchContext.Delta;abbreviate_semax.
 let C:=eval cbv -[Int.repr]in phase1_prefix in
 lazymatch goal with|-semax ?D ?P _ ?R=>change(semax D P C R)end.
 rewrite(phase1_scan_memory_split sh p tp n m l depth top row next chosen mark 1 hs ls xs fs ys zs frames Flen Depth Frame).
 unfold VerifCandidateScan.scan_memory,scan_extra. Intros.
 forward.
 pose(ScanF:=LOCALx
   [temp _depth(Vint(Int.repr depth));temp _finish(Vint Int.zero);lvar _top tuint tp]
   (SEPx[scan_extra sh p tp n m l depth top row next chosen mark 1 ls ys zs frames])).
 pose(ScanP:=
  (PROP()LOCAL(temp _p(ptr_problem p);temp _w(ptr_workspace p);
    temp _f(active_frame_address p n depth);temp _q(Vint(Int.repr next)))
   SEP(VerifCandidateScan.scan_memory sh(CCSearchMemory.scan_addresses p n depth)n m row hs xs fs))%assert).
 pose(ScanQ:=fun(q:Z)=>
  (PROP(next<=q<=n;scan_skipped n row hs xs fs next q;
    q<n ->scan_available n row hs xs fs q=true)
   LOCAL(temp _p(ptr_problem p);temp _w(ptr_workspace p);
     temp _f(active_frame_address p n depth);temp _q(Vint(Int.repr q)))
   SEP(VerifCandidateScan.scan_memory sh(CCSearchMemory.scan_addresses p n depth)n m row hs xs fs))%assert).
 eapply semax_pre_post' with(P':=(ScanP*ScanF)%logic)
   (R':=(EX q:Z,(ScanQ q*ScanF)%logic)%assert).
 - unfold ScanP,ScanF,scan_extra,VerifCandidateScan.scan_memory,CCSearchMemory.scan_addresses.
   cbn[sa_problem sa_workspace sa_h sa_selected sa_forbidden sa_frame].
   apply andp_left2;go_lowerx;normalize;cancel.
   apply andp_right;[apply prop_right;tauto|cancel].
 - unfold ScanQ,ScanF. Intros q. unfold prefix_result. Exists q.
   rewrite(phase1_scan_memory_split sh p tp n m l depth top row next chosen mark 1 hs ls xs fs ys zs frames Flen Depth Frame).
   apply andp_left2;go_lowerx;normalize;cancel.
   apply andp_right;[apply prop_right;tauto|cancel].
 - apply semax_exists_block_frame.
   + unfold ScanF;auto 50 with closed.
   + unfold ScanP,ScanQ.
     apply(block_candidate_scan CCSearchContext.Gprog sh(CCSearchMemory.scan_addresses p n depth)n m row next hs xs fs);
       assumption.
Qed.
End Proof.
Print Assumptions block_phase1_scan_prefix.
