(* Actual phase-1 child-frame initialization, including array bounds.
   Not a proof of complete search coverage. *)
Require Import VST.floyd.proofauto.
Require Import CCV.ccv_core CCV.CCSearchContext CCV.CCSearchFragments.
Import ListNotations. Open Scope Z_scope.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
Definition frame_type:=Tstruct _ccv_frame noattr.
Definition workspace_type:=Tstruct _ccv_workspace noattr.
Definition push_path:=phase_one_path++
 [SeqNext;SeqNext;SeqNext;ElseBranch;SeqNext;SeqNext;SeqNext;SeqNext].
Definition push_body:=search_fragment push_path.
Lemma push_body_is_actual:statement_at push_path(fn_body ccv_core.f_search)=Some push_body.
Proof. reflexivity. Qed.
Lemma push_body_shape:exists a b c,push_body=Ssequence a(Ssequence b c).
Proof. eexists;eexists;eexists;reflexivity. Qed.
Definition initialized_child(old:reptype frame_type)(mark:Z):reptype frame_type:=
 (fst old,(fst(snd old),(fst(snd(snd old)),(Vint(Int.repr mark),Vint Int.zero)))).
Section Proof.
Context{Espec:OracleKind}.
Lemma block_search_push:forall sh wp base tp n depth top (frames:list(reptype frame_type)),
 readable_share sh ->0<n ->20*n<=Int.max_signed ->0<=depth<n ->
 0<=top<=n ->Zlength frames=n ->
 semax CCSearchContext.Delta
 (PROP()LOCAL(temp _w wp;temp _depth(Vint(Int.repr depth));lvar _top tuint tp)
  SEP(field_at sh workspace_type[StructField _frames]base wp;
      data_at Tsh tuint(Vint(Int.repr top))tp;
      data_at Tsh(tarray frame_type n)frames base))%assert
 push_body
 (normal_ret_assert
 (PROP()LOCAL(temp _w wp;temp _depth(Vint(Int.repr(depth+1)));lvar _top tuint tp)
  SEP(field_at sh workspace_type[StructField _frames]base wp;
      data_at Tsh tuint(Vint(Int.repr top))tp;
      data_at Tsh(tarray frame_type n)
       (upd_Znth depth frames(initialized_child(Znth depth frames)top))base))%assert).
Proof.
 intros sh wp base tp n depth top frames SH N Extent Depth Top Len.
 unfold CCSearchContext.Delta;abbreviate_semax.
 let C:=eval cbv -[Int.repr]in push_body in
 lazymatch goal with|-semax ?D ?P _ ?R=>change(semax D P C R)end.
 forward. forward. forward. forward. forward. forward.
 assert(I:0<=depth<Zlength frames)by lia.
 rewrite !upd_Znth_same by exact I.
 cbn[fst snd].
 rewrite upd_Znth_twice by exact I.
 unfold initialized_child.
 entailer!.
Qed.
End Proof.
Print Assumptions block_search_push.
