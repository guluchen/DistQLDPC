(* Actual phase2 caller, with trace-implied fresh capacity.
   No complete search/termination claim. Normal coqc receipt required. *)
Require Import VST.floyd.proofauto.
Require Import CCV.ccv_core CCV.CCSearchSpecs CCV.CCSearchContext CCV.CCSearchFragments
 CCV.CCSearchMemory CCV.CCFrameJoin CCV.CCFrameFields CCV.VerifCandidateScan
 CCV.VerifPhaseOneTail CCV.VerifCoreToggle CCV.VerifForbid CCV.VerifToggle.
Import ListNotations. Open Scope Z_scope.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
#[export] Instance ForbidPreserve:change_composite_env VerifForbid.CompSpecs CCSearchSpecs.CompSpecs.
 make_cs_preserve VerifForbid.CompSpecs CCSearchSpecs.CompSpecs.
Defined.
Definition excl_enabled rules:=negb(Int.eq(Int.and(Int.repr rules)(Int.repr 1))Int.zero).
Definition phase2_memory sh p tp n m l top hs ls xs fs ys zs frames buf:mpred:=
 (phase1_memory sh p tp n m l top hs ls xs fs ys zs frames*
  @field_at CCSearchSpecs.CompSpecs sh CCSearchMemory.workspace_type[StructField _undo](ptr_undo p)(ptr_workspace p)*
  @data_at CCSearchSpecs.CompSpecs Tsh(tarray tuint n)buf(ptr_undo p))%logic.
Definition phase2_result sh p tp n m l depth top row next q mark rules hs ls xs fs ys zs frames buf:assert:=
 (PROP()LOCAL(temp _p(ptr_problem p);temp _w(ptr_workspace p);
   temp _f(active_frame_address p n depth);temp _q(Vint(Int.repr q));
   temp _rules(Vint(Int.repr rules));temp _depth(Vint(Int.repr depth));lvar _top tuint tp)
 SEP(phase2_memory sh p tp n m l(if excl_enabled rules then top+1 else top)hs ls
   (chosen_xs q xs)(if excl_enabled rules then upd_Znth q fs 1 else fs)
   (chosen_ys n m q hs ys)(chosen_ys n l q ls zs)
   (upd_Znth(depth-1)frames(frame_words row next(Vint(Int.repr q))mark 1))
   (if excl_enabled rules then upd_Znth top buf(Vint(Int.repr q))else buf)))%assert.
Section Proof.
Context{Espec:OracleKind}.
Lemma block_phase_two:
 forall sh p tp n m l depth top row next q mark rules hs ls xs fs ys zs frames buf,
 readable_share sh ->0<n ->20*n<=Int.max_signed ->0<=m ->0<=l ->
 m*n<=Int.max_signed ->l*n<=Int.max_signed ->
 1<=depth<=n ->0<=top<n ->0<=q<n ->0<=rules<=63 ->Znth q fs=0 ->
 Zlength frames=n ->Znth(depth-1)frames=frame_words row next(Vint(Int.repr q))mark 2 ->
 Zlength hs=m*n ->Zlength ls=l*n ->Zlength xs=n ->Zlength fs=n ->
 Zlength ys=m ->Zlength zs=l ->Zlength buf=n ->
 Forall(fun z:Z=>z=0\/z=1)hs ->Forall(fun z:Z=>z=0\/z=1)ls ->
 Forall(fun z:Z=>z=0\/z=1)xs ->Forall(fun z:Z=>z=0\/z=1)fs ->
 Forall(fun z:Z=>z=0\/z=1)ys ->Forall(fun z:Z=>z=0\/z=1)zs ->
 semax CCSearchContext.Delta
 (PROP()LOCAL(temp _p(ptr_problem p);temp _w(ptr_workspace p);
   temp _f(active_frame_address p n depth);temp _rules(Vint(Int.repr rules));
   temp _depth(Vint(Int.repr depth));lvar _top tuint tp)
 SEP(phase2_memory sh p tp n m l top hs ls xs fs ys zs frames buf))%assert
 CCSearchFragments.search_phase_two
 (normal_ret_assert(phase2_result sh p tp n m l depth top row next q mark rules hs ls xs fs ys zs frames buf)).
Proof.
 intros sh p tp n m l depth top row next q mark rules hs ls xs fs ys zs frames buf
 SH N Extent M L Hprod Lprod Depth Room Q Rules Fq Flen Frame Hlen Llen Xlen Blen Ylen Zlen Buflen HB LB XB FB YB ZB.
 assert(NS:0<n<=Int.max_signed)by lia.
 assert(I:0<=depth-1<Zlength frames)by lia.
 assert(Idx:0<=depth-1<n)by lia.
 assert(Fresh:fresh_push fs q top n=true).
 { unfold fresh_push;repeat if_tac;try congruence;try lia;reflexivity. }
 assert(Ret:forbid_result fs q top n=1).
 { unfold forbid_result;repeat if_tac;try congruence;try lia;reflexivity. }
 unfold CCSearchContext.Delta;abbreviate_semax.
 let C:=eval cbv -[Int.repr]in CCSearchFragments.search_phase_two in
 lazymatch goal with|-semax ?D ?P _ ?R=>change(semax D P C R)end.
 unfold phase2_memory.
 rewrite(phase1_scan_memory_split sh p tp n m l depth top row next(Vint(Int.repr q))mark 2 hs ls xs fs ys zs frames Flen Depth Frame).
 unfold VerifCandidateScan.scan_memory,scan_extra. Intros.
 forward.
 cbn[CCSearchMemory.scan_addresses sa_problem sa_workspace sa_h sa_selected sa_forbidden sa_frame].
 sep_apply(frame_fields_join Tsh(Vint(Int.repr row))(Vint(Int.repr next))
   (Vint(Int.repr q))(Vint(Int.repr mark))(Vint(Int.repr 2))(active_frame_address p n depth)).
 sep_apply(frame_cell_join Tsh n(depth-1)frames(ptr_frames p)
   (frame_words row next(Vint(Int.repr q))mark 2)Flen Idx).
 assert(Same:upd_Znth(depth-1)frames(frame_words row next(Vint(Int.repr q))mark 2)=frames).
 { exact(upd_Znth_triv(depth-1)frames(frame_words row next(Vint(Int.repr q))mark 2)I Frame). }
 forward_call(ptr_problem p,ptr_workspace p,ptr_h p,ptr_lg p,
   ptr_selected p,ptr_syndrome p,ptr_logical_value p,sh,n,m,l,q,xs,ys,zs,hs,ls).
 forward_if
 (PROP()LOCAL(temp _p(ptr_problem p);temp _w(ptr_workspace p);
   temp _f(active_frame_address p n depth);temp _q(Vint(Int.repr q));
   temp _rules(Vint(Int.repr rules));temp _depth(Vint(Int.repr depth));
   lvar _top tuint tp;temp _t'11(Vint Int.zero))
 SEP(phase2_memory sh p tp n m l(if excl_enabled rules then top+1 else top)hs ls
   (chosen_xs q xs)(if excl_enabled rules then upd_Znth q fs 1 else fs)
   (chosen_ys n m q hs ys)(chosen_ys n l q ls zs)
   (upd_Znth(depth-1)frames(frame_words row next(Vint(Int.repr q))mark 2))
   (if excl_enabled rules then upd_Znth top buf(Vint(Int.repr q))else buf)))%assert.
 - assert(En:excl_enabled rules=true).
   { unfold excl_enabled;rewrite Int.eq_false by exact H;reflexivity. }
   forward.
   forward_call(ptr_workspace p,tp,ptr_forbidden p,ptr_undo p,sh,n,top,q,fs,buf).
   rewrite Fresh,Ret. forward.
   rewrite En. unfold phase2_memory,phase1_memory,chosen_xs,chosen_ys.
   entailer!;cancel.
 - assert(En:excl_enabled rules=false).
   { unfold excl_enabled;rewrite H,Int.eq_true;reflexivity. }
   forward. rewrite En.
   unfold phase2_memory,phase1_memory,chosen_xs,chosen_ys. entailer!;cancel.
 - forward_if. { contradiction. }
   rewrite Same. unfold phase2_memory.
   rewrite(phase1_scan_memory_split sh p tp n m l depth
     (if excl_enabled rules then top+1 else top)row next(Vint(Int.repr q))mark 2
     hs ls(chosen_xs q xs)(if excl_enabled rules then upd_Znth q fs 1 else fs)
     (chosen_ys n m q hs ys)(chosen_ys n l q ls zs)frames Flen Depth Frame).
   unfold VerifCandidateScan.scan_memory,scan_extra. Intros. forward.
   cbn[CCSearchMemory.scan_addresses sa_problem sa_workspace sa_h sa_selected sa_forbidden sa_frame].
   sep_apply(frame_fields_join Tsh(Vint(Int.repr row))(Vint(Int.repr next))
     (Vint(Int.repr q))(Vint(Int.repr mark))(Vint(Int.repr 1))(active_frame_address p n depth)).
   sep_apply(frame_cell_join Tsh n(depth-1)frames(ptr_frames p)
     (frame_words row next(Vint(Int.repr q))mark 1)Flen Idx).
   unfold phase2_result,phase2_memory,phase1_memory. entailer!;cancel.
Qed.
End Proof.
Print Assumptions block_phase_two.
