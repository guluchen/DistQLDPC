(* Actual root depth/top/frame initialization prefix, without replacing C. *)
Require Import VST.floyd.proofauto.
Require Import CCV.ccv_core CCV.CCSearchSpecs CCV.CCSearchContext CCV.CCSearchFragments CCV.VerifSearchPush CCV.CCFrameFields CCV.CCFrameShape CCV.CCFrameJoin.
Import ListNotations. Open Scope Z_scope.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
Definition root_after_toggle_path:=seed_loop_path++[LoopBody;SeqNext;SeqNext;SeqNext;SeqNext].
Definition root_after_toggle:=search_fragment root_after_toggle_path.
Definition root_piece path:=match statement_at path root_after_toggle with Some s=>s|None=>Sskip end.
Definition root_depth_set:=root_piece[SeqFirst].
Definition root_top_set:=root_piece[SeqNext;SeqFirst].
Definition root_reload:=root_piece[SeqNext;SeqNext;SeqFirst].
Definition root_phase_set:=root_piece[SeqNext;SeqNext;SeqNext;SeqFirst].
Definition root_mark_set:=root_piece[SeqNext;SeqNext;SeqNext;SeqNext;SeqFirst].
Definition root_rest:=root_piece[SeqNext;SeqNext;SeqNext;SeqNext;SeqNext].
Definition root_frame_init:=Ssequence root_depth_set(Ssequence root_top_set
 (Ssequence root_reload(Ssequence root_phase_set root_mark_set))).
Lemma root_frame_layout:root_after_toggle=Ssequence root_depth_set(Ssequence root_top_set
 (Ssequence root_reload(Ssequence root_phase_set(Ssequence root_mark_set root_rest)))).
Proof. reflexivity. Qed.
Section Proof.
Context{Espec:OracleKind}.
Lemma block_root_frame:forall sh wp fp tp n(frames:list(reptype VerifSearchPush.frame_type)),
 readable_share sh ->0<n ->20*n<=Int.max_signed ->Zlength frames=n ->
 semax CCSearchContext.Delta
 (PROP()LOCAL(temp _w wp;lvar _top tuint tp)
 SEP(field_at sh VerifSearchPush.workspace_type[StructField _frames]fp wp;
   data_at_ Tsh tuint tp;data_at Tsh(tarray VerifSearchPush.frame_type n)frames fp))%assert
 root_frame_init
 (normal_ret_assert
 (PROP()LOCAL(temp _w wp;lvar _top tuint tp;temp _depth(Vint(Int.repr 1));temp _f fp)
 SEP(field_at sh VerifSearchPush.workspace_type[StructField _frames]fp wp;
   data_at Tsh tuint(Vint Int.zero)tp;
   data_at Tsh(tarray VerifSearchPush.frame_type n)
     (upd_Znth 0 frames(initialized_child(Znth 0 frames)0))fp))%assert).
Proof.
 intros sh wp fp tp n frames SH N Extent Len.
 unfold CCSearchContext.Delta;abbreviate_semax.
 let C:=eval cbv -[Int.repr]in root_frame_init in
 lazymatch goal with|-semax ?D ?P _ ?R=>change(semax D P C R)end.
 forward. forward. forward. forward.
 assert_PROP(isptr fp)as Ptr by entailer!.
 cbn[sem_binary_operation'].
 unfold sem_add,Cop.classify_add,typeconv,remove_attributes,change_attributes,sem_add_ptr_int.
 rewrite sem_add_pi_ptr by(auto;rep_lia). autorewrite with norm.
 lazymatch goal with|-context[complete_type ?ce ?ty]=>
   let T:=constr:(complete_type ce ty=true)in
   assert(CT_actual:T)by reflexivity;rewrite CT_actual end.
 cbn[force_val].
 assert(I:0<=0<n)by lia.
 assert_PROP(field_compatible(tarray VerifSearchPush.frame_type n)[]fp)as FC by entailer!.
 pose proof(frame_array_focus Tsh n 0 frames fp Len I)as Focus.
 unfold CCFrameFields.frame_type in Focus.
 unfold VerifSearchPush.frame_type. rewrite Focus.
 assert(Address:field_address0(tarray(Tstruct _ccv_frame noattr)n)[ArraySubsc 0]fp=fp).
 { rewrite field_address0_offset by auto with field_compatible.
   cbn. autorewrite with norm. reflexivity. }
 destruct(Znth 0 frames)as[r[nx[ch[mk ph]]]]eqn:Old.
 pose proof(frame_data_at_fields Tsh r nx ch mk ph
   (field_address0(tarray(Tstruct _ccv_frame noattr)n)[ArraySubsc 0]fp))as Shape.
 unfold CCFrameShape.frame_type in Shape.
 lazymatch goal with|-context[@data_at ?cs Tsh(Tstruct _ccv_frame noattr)?v ?a]=>
   let Cell:=constr:(@data_at cs Tsh(Tstruct _ccv_frame noattr)v a)in
   lazymatch type of Shape with ?Canonical = ?Fields =>
     assert(CellEq:Cell=Canonical)by(f_equal;exact Old)end end.
 rewrite CellEq,Shape,Address. unfold frame_fields. Intros. forward. forward.
 sep_apply(frame_fields_join Tsh r nx ch(Vint(Int.repr 0))(Vint(Int.repr 0))fp).
 pose proof(frame_cell_join Tsh n 0 frames fp
   (r,(nx,(ch,(Vint(Int.repr 0),Vint(Int.repr 0)))))Len I)as Join.
 unfold CCFrameFields.frame_type in Join. rewrite Address in Join. sep_apply Join.
 unfold initialized_child;cbn[fst snd];entailer!.
Qed.
End Proof.
Print Assumptions block_root_frame.
