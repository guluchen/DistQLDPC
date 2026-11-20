(* WORKING DRAFT, not a checked theorem. Actual phase1 tail caller proof. *)
Require Import VST.floyd.proofauto.
Require Import CCV.CCArray CCV.CCMatrix CCV.VerifCandidateScan.
Require Import CCV.ccv_core CCV.CCSearchSpecs CCV.CCSearchContext CCV.CCSearchScan
 CCV.CCSearchMemory CCV.CCFrameJoin CCV.CCFrameFields CCV.CCFrameShape
 CCV.VerifCoreToggle CCV.VerifToggle CCV.VerifSearchPush.
Import ListNotations. Open Scope Z_scope.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
#[export] Instance CoreTogglePreserve:change_composite_env VerifCoreToggle.CompSpecs CCSearchSpecs.CompSpecs.
 make_cs_preserve VerifCoreToggle.CompSpecs CCSearchSpecs.CompSpecs.
Defined.
Definition choice_frames depth row q mark frames:=
 upd_Znth(depth-1)frames(frame_words row(q+1)(Vint(Int.repr q))mark 2).
Definition child_frames depth row q mark top frames:=
 let parents:=choice_frames depth row q mark frames in
 upd_Znth depth parents(initialized_child(Znth depth parents)top).
Definition chosen_xs q xs:=upd_Znth q xs(Z.lxor(Znth q xs)1).
Definition chosen_ys n m q hs ys:=VerifToggle.xor_vector ys(CCMatrix.column n m q hs).
Definition tail_result sh p tp n m l depth top row mark hs ls xs fs ys zs frames q:assert:=
 (PROP()LOCAL(temp _p(ptr_problem p);temp _w(ptr_workspace p);
   temp _f(active_frame_address p n depth);temp _q(Vint(Int.repr q));
   temp _depth(Vint(Int.repr(if q<?n then depth+1 else depth)));
   temp _finish(Vint(Int.repr(if q<?n then 0 else 1)));lvar _top tuint tp)
 SEP(phase1_memory sh p tp n m l top hs ls
   (if q<?n then chosen_xs q xs else xs)fs
   (if q<?n then chosen_ys n m q hs ys else ys)
   (if q<?n then chosen_ys n l q ls zs else zs)
   (if q<?n then child_frames depth row q mark top frames else frames)))%assert.
Section Proof.
Context{Espec:OracleKind}.
Lemma block_phase1_tail:
 forall sh p tp n m l depth top row next chosen mark hs ls xs fs ys zs frames q,
 readable_share sh ->0<n ->20*n<=Int.max_signed ->0<=m ->0<=l ->
 m*n<=Int.max_signed ->l*n<=Int.max_signed ->
 1<=depth<n ->0<=top<=n ->0<=q<=n ->
 Zlength frames=n ->Znth(depth-1)frames=frame_words row next chosen mark 1 ->
 Zlength hs=m*n ->Zlength ls=l*n ->Zlength xs=n ->Zlength fs=n ->
 Zlength ys=m ->Zlength zs=l ->
 Forall(fun z:Z=>z=0\/z=1)hs ->Forall(fun z:Z=>z=0\/z=1)ls ->
 Forall(fun z:Z=>z=0\/z=1)xs ->Forall(fun z:Z=>z=0\/z=1)ys ->
 Forall(fun z:Z=>z=0\/z=1)zs ->
 semax CCSearchContext.Delta
 (PROP()LOCAL(temp _p(ptr_problem p);temp _w(ptr_workspace p);
   temp _f(active_frame_address p n depth);temp _q(Vint(Int.repr q));
   temp _depth(Vint(Int.repr depth));temp _finish(Vint Int.zero);lvar _top tuint tp)
 SEP(phase1_memory sh p tp n m l top hs ls xs fs ys zs frames))%assert
 CCSearchScan.scan_tail
 (normal_ret_assert(tail_result sh p tp n m l depth top row mark hs ls xs fs ys zs frames q)).
Proof.
 intros sh p tp n m l depth top row next chosen mark hs ls xs fs ys zs frames q
 SH N Extent M L Hprod Lprod Depth Top Q Flen Frame Hlen Llen Xlen Blen Ylen Zlen HB LB XB YB ZB.
 assert(NS:0<n<=Int.max_signed)by lia.
 unfold CCSearchContext.Delta;abbreviate_semax.
 let C:=eval cbv -[Int.repr]in CCSearchScan.scan_tail in
 lazymatch goal with|-semax ?D ?P _ ?R=>change(semax D P C R)end.
 rewrite(phase1_scan_memory_split sh p tp n m l depth top row next chosen mark 1 hs ls xs fs ys zs frames Flen ltac:(lia) Frame).
 unfold VerifCandidateScan.scan_memory,scan_extra. Intros.
 forward. forward_if.
 { subst q. forward. unfold tail_result.
   rewrite Z.ltb_irrefl.
   rewrite(phase1_scan_memory_split sh p tp n m l depth top row next chosen mark 1 hs ls xs fs ys zs frames Flen ltac:(lia) Frame).
   entailer!;cancel.
   unfold VerifCandidateScan.scan_memory,scan_extra,CCSearchMemory.scan_addresses.
   cbn[sa_problem sa_workspace sa_h sa_selected sa_forbidden sa_frame];cancel. }
 { assert(Qin:0<=q<n)by lia.
   forward. forward. forward.
   assert(Add:Int.add(Int.repr q)(Int.repr 1)=Int.repr(q+1)).
   { unfold Int.add;rewrite !Int.unsigned_repr by rep_lia;reflexivity. }
   rewrite Add.
   cbn[CCSearchMemory.scan_addresses sa_problem sa_workspace sa_h sa_selected sa_forbidden sa_frame].
   sep_apply(frame_fields_join Tsh(Vint(Int.repr row))(Vint(Int.repr(q+1)))
     (Vint(Int.repr q))(Vint(Int.repr mark))(Vint(Int.repr 2))
     (active_frame_address p n depth)).
   sep_apply(frame_cell_join Tsh n(depth-1)frames(ptr_frames p)
     (frame_words row(q+1)(Vint(Int.repr q))mark 2)Flen ltac:(lia)).
   forward_call(ptr_problem p,ptr_workspace p,ptr_h p,ptr_lg p,
     ptr_selected p,ptr_syndrome p,ptr_logical_value p,sh,n,m,l,q,xs,ys,zs,hs,ls).
   (* Continue with the verified child-frame initialization block, framed by
      all unchanged pointers, H/L matrices, updated caches and forbidden set. *)
   unfold POSTCONDITION,abbreviate.
   unfold tail_result.
   rewrite(proj2(Z.ltb_lt q n)(proj2 Qin)).
   unfold child_frames,choice_frames,chosen_xs,chosen_ys,phase1_memory.
   semax_frame
    [temp _p(ptr_problem p);temp _f(active_frame_address p n depth);
     temp _q(Vint(Int.repr q));temp _finish(Vint Int.zero)]
    [field_at sh CCSearchMemory.problem_type[StructField _n](Vint(Int.repr n))(ptr_problem p);
     field_at sh CCSearchMemory.problem_type[StructField _checks](Vint(Int.repr m))(ptr_problem p);
     field_at sh CCSearchMemory.problem_type[StructField _logical_rows](Vint(Int.repr l))(ptr_problem p);
     field_at sh CCSearchMemory.problem_type[StructField _h](ptr_h p)(ptr_problem p);
     field_at sh CCSearchMemory.problem_type[StructField _logical](ptr_lg p)(ptr_problem p);
     field_at sh CCSearchMemory.workspace_type[StructField _selected](ptr_selected p)(ptr_workspace p);
     field_at sh CCSearchMemory.workspace_type[StructField _forbidden](ptr_forbidden p)(ptr_workspace p);
     field_at sh CCSearchMemory.workspace_type[StructField _syndrome](ptr_syndrome p)(ptr_workspace p);
     field_at sh CCSearchMemory.workspace_type[StructField _logical_value](ptr_logical_value p)(ptr_workspace p);
     data_at sh(tarray tuchar(m*n))(tbytes hs)(ptr_h p);
     data_at sh(tarray tuchar(l*n))(tbytes ls)(ptr_lg p);
     data_at Tsh(tarray tuchar n)(tbytes(upd_Znth q xs(Z.lxor(Znth q xs)1)))(ptr_selected p);
     data_at Tsh(tarray tuchar n)(tbytes fs)(ptr_forbidden p);
     data_at Tsh(tarray tuchar m)(tbytes(VerifToggle.xor_vector ys(CCMatrix.column n m q hs)))(ptr_syndrome p);
     data_at Tsh(tarray tuchar l)(tbytes(VerifToggle.xor_vector zs(CCMatrix.column n l q ls)))(ptr_logical_value p)].
   eapply semax_pre with(P':=
    (PROP()LOCAL(temp _w(ptr_workspace p);temp _depth(Vint(Int.repr depth));lvar _top tuint tp)
     SEP(@field_at CCSearchSpecs.CompSpecs sh VerifSearchPush.workspace_type[StructField _frames](ptr_frames p)(ptr_workspace p);
       @data_at CCSearchSpecs.CompSpecs Tsh tuint(Vint(Int.repr top))tp;
       @data_at CCSearchSpecs.CompSpecs Tsh(tarray VerifSearchPush.frame_type n)
         (upd_Znth(depth-1)frames(frame_words row(q+1)(Vint(Int.repr q))mark 2))(ptr_frames p)))%assert).
   { entailer!;cancel. }
   apply(block_search_push sh(ptr_workspace p)(ptr_frames p)tp n depth top
     (upd_Znth(depth-1)frames(frame_words row(q+1)(Vint(Int.repr q))mark 2))).
   { exact SH. } { exact N. } { exact Extent. } { lia. } { exact Top. }
   { assert(I:0<=depth-1<Zlength frames)by lia.
     rewrite upd_Znth_Zlength by exact I;exact Flen. }
   cbn[app]. entailer!;cancel.
 }
Qed.
End Proof.
Print Assumptions block_phase1_tail.
