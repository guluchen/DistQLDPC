(* Actual complete C phase1 branch, composed from checked prefix and tail.
   Draft until normal coqc PASS; main loop and global coverage remain separate. *)
Require Import VST.floyd.proofauto.
Require Import CCV.ccv_core CCV.CCSearchSpecs CCV.CCSearchContext CCV.CCSearchScan
 CCV.CCSearchFragments CCV.CCSearchMemory CCV.VerifCandidateScan
 CCV.VerifPhaseOnePrefix CCV.VerifPhaseOneTail.
Import ListNotations. Open Scope Z_scope.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
Definition phase1_certificate n row next hs xs fs q:=
 next<=q<=n /\scan_skipped n row hs xs fs next q /\
 (q<n ->scan_available n row hs xs fs q=true).
Definition phase1_result sh p tp n m l depth top row next mark hs ls xs fs ys zs frames:assert:=
 (EX q:Z,!!(phase1_certificate n row next hs xs fs q)&&
 tail_result sh p tp n m l depth top row mark hs ls xs fs ys zs frames q)%logic.
Section Proof.
Context{Espec:OracleKind}.
Lemma block_phase_one:
 forall sh p tp n m l depth top row next chosen mark hs ls xs fs ys zs frames,
 readable_share sh ->0<n ->20*n<=Int.max_signed ->0<=m ->0<=l ->
 m*n<=Int.max_signed ->l*n<=Int.max_signed ->
 0<=row<m ->0<=next<=n ->1<=depth<n ->0<=top<=n ->
 Zlength frames=n ->Znth(depth-1)frames=frame_words row next chosen mark 1 ->
 Zlength hs=m*n ->Zlength ls=l*n ->Zlength xs=n ->Zlength fs=n ->
 Zlength ys=m ->Zlength zs=l ->
 Forall(fun z:Z=>z=0\/z=1)hs ->Forall(fun z:Z=>z=0\/z=1)ls ->
 Forall(fun z:Z=>z=0\/z=1)xs ->Forall(fun z:Z=>z=0\/z=1)fs ->
 Forall(fun z:Z=>z=0\/z=1)ys ->Forall(fun z:Z=>z=0\/z=1)zs ->
 semax CCSearchContext.Delta
 (PROP()LOCAL(temp _p(ptr_problem p);temp _w(ptr_workspace p);
   temp _f(active_frame_address p n depth);temp _depth(Vint(Int.repr depth));
   temp _finish(Vint Int.zero);lvar _top tuint tp)
 SEP(phase1_memory sh p tp n m l top hs ls xs fs ys zs frames))%assert
 CCSearchFragments.search_phase_one
 (normal_ret_assert(phase1_result sh p tp n m l depth top row next mark hs ls xs fs ys zs frames)).
Proof.
 intros sh p tp n m l depth top row next chosen mark hs ls xs fs ys zs frames
 SH N Extent M L Hprod Lprod Row Next Depth Top Flen Frame Hlen Llen Xlen Blen Ylen Zlen HB LB XB FB YB ZB.
 assert(NS:0<n<=Int.max_signed)by lia.
 rewrite CCSearchScan.phase_one_layout.
 rewrite seq_assoc. fold VerifPhaseOnePrefix.phase1_prefix.
 eapply semax_seq' with(P':=prefix_result sh p tp n m l depth top row next chosen mark hs ls xs fs ys zs frames).
 - apply(block_phase1_scan_prefix sh p tp n m l depth top row next chosen mark hs ls xs fs ys zs frames);
     try assumption;lia.
 - unfold prefix_result. Intros q.
   eapply semax_post' with(R':=tail_result sh p tp n m l depth top row mark hs ls xs fs ys zs frames q).
   + unfold phase1_result. Exists q.
     apply andp_right.
     * apply prop_right;unfold phase1_certificate;tauto.
     * apply andp_left2;apply derives_refl.
   + eapply semax_pre with(P':=
      (PROP()LOCAL(temp _p(ptr_problem p);temp _w(ptr_workspace p);
       temp _f(active_frame_address p n depth);temp _q(Vint(Int.repr q));
       temp _depth(Vint(Int.repr depth));temp _finish(Vint Int.zero);lvar _top tuint tp)
       SEP(phase1_memory sh p tp n m l top hs ls xs fs ys zs frames))%assert).
     { entailer!;cancel. }
     apply(block_phase1_tail sh p tp n m l depth top row next chosen mark hs ls xs fs ys zs frames q);
       try assumption;lia.
Qed.
End Proof.
Print Assumptions block_phase_one.
