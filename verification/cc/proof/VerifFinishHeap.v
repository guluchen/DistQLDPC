(* Actual restore-and-pop C block under full search ownership. Undo prefix
   borrowing preserves the complementary share and suffix. The old inactive
   frame bytes are retained here; global-pop composition may forget them. *)
Require Import VST.floyd.proofauto.
Require Import CCV.ccv_core CCV.CCSearchSpecs CCV.CCSearchContext CCV.CCSearchHeap
 CCV.CCSearchMemory CCV.CCUndoArray CCV.CCJournalArray CCV.CCJournalTrace
 CCV.CCJournalSnapshots CCV.CCRootArray CCV.CCFrameFields CCV.CCFrameShape
 CCV.CCFrameJoin CCV.CCAPIBridge CCV.VerifToggle CCV.VerifSearchFinish CCV.VerifRestore.
Import ListNotations. Open Scope Z_scope.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
Section Proof.
Context{Espec:OracleKind}.
Lemma block_finish_heap:forall sh a p tp rp cap seed budget rules depth mark log buf
 xs ys zs pk frames out s r nx ch ph,
 readable_share sh ->legal_model a ->0<=seed<=model_n a ->1<=depth<=model_n a ->
 0<=mark<=Zlength log ->Zlength frames=model_n a ->
 Znth(depth-1)frames=(r,(nx,(ch,(Vint(Int.repr mark),ph)))) ->
 journal_trace(model_n a)(root_mask(model_n a)seed)log buf ->
 semax CCSearchContext.Delta
 (PROP()LOCAL(temp _p(ptr_problem p);temp _w(ptr_workspace p);
 temp _f(active_frame_address p(model_n a)depth);temp _depth(Vint(Int.repr depth));
 temp _cap(Vint(Int.repr cap));temp _seed(Vint(Int.repr seed));temp _budget(Vint(Int.repr budget));
 temp _rules(Vint(Int.repr rules));temp _out(ptr_out p);temp _stats(ptr_stats p);
 lvar _top tuint tp;lvar _row tuint rp)
 SEP(search_heap sh a p tp rp(Zlength log)xs(journal_bitmap(root_mask(model_n a)seed)log)
 ys zs pk buf frames out s))%assert
 finish_body
 (normal_ret_assert
 (PROP()LOCAL(temp _p(ptr_problem p);temp _w(ptr_workspace p);
 temp _f(active_frame_address p(model_n a)depth);temp _depth(Vint(Int.repr(depth-1)));
 temp _cap(Vint(Int.repr cap));temp _seed(Vint(Int.repr seed));temp _budget(Vint(Int.repr budget));
 temp _rules(Vint(Int.repr rules));temp _out(ptr_out p);temp _stats(ptr_stats p);
 lvar _top tuint tp;lvar _row tuint rp)
 SEP(search_heap sh a p tp rp mark xs
 (journal_bitmap(root_mask(model_n a)seed)(sublist 0 mark log))ys zs pk buf frames out s))%assert).
Proof.
 intros sh a p tp rp cap seed budget rules depth mark log buf xs ys zs pk frames out s r nx ch ph
 SH Legal Seed Depth Mark Len Cell Trace.
 pose proof(legal_model_ranges a Legal)as[NR[MR[LR[KR Rest]]]].
 assert(BaseLen:Zlength(root_mask(model_n a)seed)=model_n a)by(apply root_mask_length;assumption).
 assert(BaseBits:Forall(fun z:Z=>z=0\/z=1)(root_mask(model_n a)seed))by(apply root_mask_bits;assumption).
 pose proof Trace as Parts.
 destruct Parts as[Top[Range[ND[Clear[BufLen Prefix]]]]].
 assert(FLen:Zlength(journal_bitmap(root_mask(model_n a)seed)log)=model_n a)
 by(apply(journal_bitmap_length(model_n a));assumption).
 assert(FBits:Forall(fun z:Z=>z=0\/z=1)(journal_bitmap(root_mask(model_n a)seed)log))
 by(apply journal_bitmap_bits;assumption).
 assert(ExactF:restored(journal_bitmap(root_mask(model_n a)seed)log)log mark(Zlength log)=
 journal_bitmap(root_mask(model_n a)seed)(sublist 0 mark log))
 by(apply(journal_restore_bitmap_exact(model_n a)(root_mask(model_n a)seed)log buf mark);assumption).
 assert(Index:0<=depth-1<model_n a)by lia.
 assert(Sub:Int.sub(Int.repr depth)(Int.repr 1)=Int.repr(depth-1)).
 { unfold Int.sub;rewrite !Int.unsigned_repr by rep_lia;reflexivity. }
 unfold CCSearchContext.Delta;abbreviate_semax.
 let C:=eval cbv -[Int.repr]in finish_body in
 lazymatch goal with|-semax ?D ?P _ ?R=>change(semax D P C R)end.
 unfold search_heap,workspace_fields.
 rewrite(undo_array_split sh(model_n a)log buf(ptr_undo p)Top BufLen Prefix).
 pose proof(frame_array_focus Tsh(model_n a)(depth-1)frames(ptr_frames p)Len Index)as Focus.
 unfold CCFrameFields.frame_type in Focus;unfold CCSearchSpecs.frame_type;rewrite Focus.
 pose proof(frame_data_at_fields Tsh r nx ch(Vint(Int.repr mark))ph
 (active_frame_address p(model_n a)depth))as Shape.
 unfold CCFrameShape.frame_type,active_frame_address,CCSearchMemory.frame_type in Shape.
 lazymatch goal with|-context[@data_at ?cs Tsh(Tstruct _ccv_frame noattr)?v ?adr]=>
 let Slot:=constr:(@data_at cs Tsh(Tstruct _ccv_frame noattr)v adr)in
 lazymatch type of Shape with ?Canonical = ?Fields =>
 assert(SlotEq:Slot=Canonical)by(f_equal;exact Cell)end end.
 rewrite SlotEq,Shape. unfold frame_fields. Intros.
 forward.
 forward_call(ptr_workspace p,tp,ptr_forbidden p,ptr_undo p,sh,model_n a,
 Zlength log,mark,journal_bitmap(root_mask(model_n a)seed)log,log).
 forward.
 sep_apply(undo_array_join sh(model_n a)log buf(ptr_undo p)Top BufLen Prefix).
 sep_apply(frame_fields_join Tsh r nx ch(Vint(Int.repr mark))ph
 (active_frame_address p(model_n a)depth)).
 sep_apply(frame_cell_join Tsh(model_n a)(depth-1)frames(ptr_frames p)
 (r,(nx,(ch,(Vint(Int.repr mark),ph))))Len Index).
 assert(Same:upd_Znth(depth-1)frames(r,(nx,(ch,(Vint(Int.repr mark),ph))))=frames)
 by(apply upd_Znth_triv;[lia|assumption]).
 go_lowerx;normalize.
 lazymatch goal with |-context[@upd_Znth ?ty ?i frames ?v]=>
 assert(SameActual:@upd_Znth ty i frames v=frames)by exact Same;rewrite SameActual end.
 rewrite ExactF.
 unfold search_heap,workspace_fields;normalize;cancel.
 rewrite Sub in *. apply andp_right;[apply prop_right;tauto|cancel].
Qed.
End Proof.
Print Assumptions block_finish_heap.
