(* Actual child-completion block. IN PROGRESS until normal coqc PASS.
   The restore callee body is already proved; full search remains separate. *)
Require Import VST.floyd.proofauto.
Require Import CCV.ccv_core CCV.CCSearchContext CCV.CCSearchFragments CCV.VerifRestore.
Import ListNotations. Open Scope Z_scope.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
#[export] Instance RestorePreserve:change_composite_env VerifRestore.CompSpecs CCSearchSpecs.CompSpecs.
 make_cs_preserve VerifRestore.CompSpecs CCSearchSpecs.CompSpecs.
Defined.
Definition frame_type:=Tstruct _ccv_frame noattr.
Definition finish_body:=CCSearchFragments.search_fragment(finish_path++[ThenBranch]).
Lemma finish_body_is_actual:
 statement_at(finish_path++[ThenBranch])(fn_body ccv_core.f_search)=Some finish_body.
Proof. reflexivity. Qed.
Definition finish_memory sh wp fp up tp fr n top mark xs entries :mpred :=
 (field_at sh VerifRestore.workspace_type[StructField _forbidden]fp wp*
  field_at sh VerifRestore.workspace_type[StructField _undo]up wp*
  data_at Tsh tuint(Vint(Int.repr top))tp*
  data_at Tsh(tarray tuchar n)(rbytes xs)fp*
  data_at sh(tarray tuint(Zlength entries))(rbytes entries)up*
  field_at Tsh frame_type[StructField _mark](Vint(Int.repr mark))fr)%logic.
Section Proof.
Context{Espec:OracleKind}.
Lemma block_search_finish :forall sh wp fp up tp fr n top mark depth xs entries,
 readable_share sh ->0<n<=Int.max_signed ->0<=mark<=top ->top<=n ->
 0<depth<=n ->Zlength xs=n ->Zlength entries=top ->
 Forall(fun z:Z=>z=0\/z=1)xs ->Forall(fun q=>0<=q<n)entries ->
 semax CCSearchContext.Delta
 (PROP()LOCAL(temp _w wp;temp _f fr;temp _depth(Vint(Int.repr depth));lvar _top tuint tp)
  SEP(finish_memory sh wp fp up tp fr n top mark xs entries))%assert
 finish_body
 (normal_ret_assert
  (PROP()LOCAL(temp _w wp;temp _f fr;temp _depth(Vint(Int.repr(depth-1)));lvar _top tuint tp)
   SEP(finish_memory sh wp fp up tp fr n mark mark(restored xs entries mark top)entries))%assert).
Proof.
 intros sh wp fp up tp fr n top mark depth xs entries SH N Mark Top Depth Xlen Elen XB EB.
 unfold CCSearchContext.Delta. abbreviate_semax.
 let C:=eval cbv -[Int.repr]in finish_body in
 lazymatch goal with|-semax ?D ?P _ ?R=>change(semax D P C R)end.
 unfold finish_memory. Intros.
 forward.
 forward_call(wp,tp,fp,up,sh,n,top,mark,xs,entries).
 { rewrite Elen;cancel. }
 forward.
 entailer!;unfold finish_memory;cancel.
Qed.
End Proof.
Print Assumptions block_search_finish.
