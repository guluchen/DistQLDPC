(* Actual canonical-root exclusion initialization loop. Not the full root or search. *)
Require Import VST.floyd.proofauto.
Require Import CCV.ccv_core CCV.CCSearchContext CCV.CCSearchFragments CCV.CCRootArray CCV.VerifToggle.
Import ListNotations. Open Scope Z_scope.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
Definition workspace_type:=Tstruct _ccv_workspace noattr.
Definition root_mask_path:=seed_loop_path++[LoopBody;SeqNext;SeqNext;SeqFirst].
Definition root_mask_block:=search_fragment root_mask_path.
Lemma root_mask_is_actual:statement_at root_mask_path(fn_body ccv_core.f_search)=Some root_mask_block.
Proof. reflexivity. Qed.
Lemma root_mask_shape:exists a b c,root_mask_block=Ssequence a(Sloop b c).
Proof. eexists;eexists;eexists;reflexivity. Qed.
Definition mask_memory sh wp fp n i:mpred:=
 (field_at sh workspace_type[StructField _forbidden]fp wp*
  data_at Tsh(tarray tuchar n)(tbytes(root_mask n i))fp)%logic.
Definition mask_result sh wp fp n seed:assert:=
 (PROP()LOCAL(temp _w wp;temp _seed(Vint(Int.repr seed)))
 SEP(mask_memory sh wp fp n seed))%assert.
Section Proof.
Context{Espec:OracleKind}.
Lemma block_root_mask:forall sh wp fp n seed,
 readable_share sh ->0<=n<=Int.max_signed ->0<=seed<=n ->
 semax CCSearchContext.Delta
 (PROP()LOCAL(temp _w wp;temp _seed(Vint(Int.repr seed)))
 SEP(mask_memory sh wp fp n 0))%assert
 root_mask_block(normal_ret_assert(mask_result sh wp fp n seed)).
Proof.
 intros sh wp fp n seed SH N Seed.
 unfold CCSearchContext.Delta;abbreviate_semax.
 let C:=eval cbv -[Int.repr]in root_mask_block in
 lazymatch goal with|-semax ?D ?P _ ?R=>change(semax D P C R)end.
 unfold mask_memory. Intros. forward.
 forward_loop
 (EX i:Z,PROP(0<=i<=seed)
 LOCAL(temp _w wp;temp _seed(Vint(Int.repr seed));temp _i(Vint(Int.repr i)))
 SEP(mask_memory sh wp fp n i))%assert
 break:(mask_result sh wp fp n seed).
 { Exists 0. unfold mask_memory;entailer!. }
 { Intros i. unfold mask_memory. Intros. forward_if.
   { forward. unfold tbytes. forward.
     forward. Exists(i+1). unfold mask_memory,tbytes;entailer!.
     rewrite <-root_mask_step by lia.
     change(Vint(Int.zero_ext 8(Int.repr 1)))with(Vint(Int.repr 1)).
     rewrite <-upd_Znth_map by(rewrite root_mask_length;lia);cancel.
   }
   { assert(E:i=seed)by lia;subst i. forward.
     unfold mask_result,mask_memory. entailer!. }
 }
Qed.
End Proof.
Print Assumptions block_root_mask.
