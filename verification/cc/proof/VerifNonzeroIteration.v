(* Actual nonzero-phase dispatch, including its real frame-phase read and shared
   finish continuation. Phase0, entry/fuel and outer loops remain separate. *)
Require Import VST.floyd.proofauto.
Require Import CCV.ccv_core CCV.CCSearchSpecs CCV.CCSearchContext CCV.CCSearchFragments
 CCV.CCSearchMemory CCV.CCSearchHeap CCV.CCLoopInvariant CCV.CCStackInvariant
 CCV.CCFrameFields CCV.CCFrameShape CCV.CCFrameJoin CCV.CCSearchPhases
 CCV.CCJournalArray CCV.CCRootArray CCV.CCResumeMemory CCV.CCAPIBridge
 CCV.VerifPhaseOneIteration CCV.VerifPhaseTwoIteration.
Import ListNotations. Open Scope Z_scope.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
Lemma represented_nonzero_phase g raw:
 frame_represents g raw ->(ghost_phase g=1%nat\/ghost_phase g=2%nat) ->
 exists r nx ch mk,raw=(r,(nx,(ch,(mk,Vint(Int.repr(Z.of_nat(ghost_phase g))))))).
Proof.
 intros Rep[Phase|Phase];unfold frame_represents in Rep;rewrite Phase in Rep |- *.
 - destruct Rep as[ch Eq];exists(Vint(Int.repr(Z.of_nat(ghost_row g)))),
 (Vint(Int.repr(Z.of_nat(ghost_next g)))),ch,(Vint(Int.repr(ghost_mark g)));exact Eq.
 - exists(Vint(Int.repr(Z.of_nat(ghost_row g)))),(Vint(Int.repr(Z.of_nat(ghost_next g)))),
 (Vint(Int.repr(Z.of_nat(ghost_chosen g)))),(Vint(Int.repr(ghost_mark g)));exact Rep.
Qed.
Section Proof.
Context{Espec:OracleKind}.
Lemma block_nonzero_iteration:forall sh a p tp rp cap seed budget rules s0 s
 path prefix g log buf xs ys zs pk frames,
 readable_share sh ->legal_model a ->1<=cap<=model_n a ->0<=seed<=model_n a ->0<=rules<=63 ->
 legal_stats budget s ->stats_monotone s0 s ->(ghost_phase g=1%nat\/ghost_phase g=2%nat) ->
 loop_shape a cap seed path(prefix++[g])log buf xs ys zs pk frames ->
 semax CCSearchContext.Delta
 (PROP()LOCAL(temp _p(ptr_problem p);temp _w(ptr_workspace p);
 temp _f(active_frame_address p(model_n a)(Z.of_nat(length path)));
 temp _depth(Vint(Int.repr(Z.of_nat(length path))));temp _finish(Vint Int.zero);
 temp _cap(Vint(Int.repr cap));temp _seed(Vint(Int.repr seed));temp _budget(Vint(Int.repr budget));
 temp _rules(Vint(Int.repr rules));temp _out(ptr_out p);temp _stats(ptr_stats p);
 lvar _top tuint tp;lvar _row tuint rp)
 SEP(search_heap sh a p tp rp(Zlength log)xs(journal_bitmap(root_mask(model_n a)seed)log)
 ys zs pk buf frames(Zrepeat 0(model_n a))s))%assert
 (Ssequence search_phase_nonzero search_finish)
 (normal_ret_assert(search_while_invariant sh a p tp rp cap seed budget rules s0)).
Proof.
 intros sh a p tp rp cap seed budget rules s0 s path prefix g log buf xs ys zs pk frames
 SH Legal Cap Seed Rules Stats Mono Kind Whole.
 pose proof(legal_model_ranges a Legal)as[NR[MR[LR[KR Rest]]]].
 assert(Geo:stack_geometry(Z.to_nat(model_n a))(Z.to_nat(model_m a))(Z.to_nat cap)
 (model_h_rows a)path(prefix++[g])log)by(unfold loop_shape in Whole;tauto).
 assert(Phys:physical_stack(Z.to_nat(model_n a))(prefix++[g])frames)
 by(unfold loop_shape in Whole;tauto).
 destruct Geo as[Len[ND[Range[Depth Per]]]].
 pose proof(path_length_bound(Z.to_nat(model_n a))path ND Range)as Capacity.
 assert(PathLen:length path=S(length prefix))by(rewrite app_length in Len;cbn[length]in Len;lia).
 assert(DRange:1<=Z.of_nat(length path)<=model_n a).
 { apply Nat2Z.inj_le in Capacity;rewrite Z2Nat.id in Capacity by lia;lia. }
 assert(Idx:0<=Z.of_nat(length path)-1<model_n a)by lia.
 assert(IdxEq:Z.of_nat(length path)-1=Z.of_nat(length prefix))by lia.
 assert(PhRange:0<=Z.of_nat(ghost_phase g)<=2)by(destruct Kind as[P|P];rewrite P;cbn;lia).
 destruct Phys as[FrameLen Cells];rewrite Z2Nat.id in FrameLen by lia.
 assert(TopIndex:(length prefix<Z.to_nat(model_n a))%nat)by lia.
 pose proof(Cells(length prefix)TopIndex)as Rep.
 destruct(lt_dec(length prefix)(length(prefix++[g])))as[Inside|Outside].
 2:{ rewrite app_length in Outside;cbn[length]in Outside;lia. }
 rewrite nth_snoc_last in Rep.
 destruct(represented_nonzero_phase g(Znth(Z.of_nat(length prefix))frames)Rep Kind)
 as[r[nx[ch[mk Cell]]]].
 assert(Frame:Znth(Z.of_nat(length path)-1)frames=
 (r,(nx,(ch,(mk,Vint(Int.repr(Z.of_nat(ghost_phase g))))))))by(rewrite IdxEq;exact Cell).
 unfold CCSearchContext.Delta;abbreviate_semax.
 let C:=eval cbv -[Int.repr]in(Ssequence search_phase_nonzero search_finish)in
 lazymatch goal with|-semax ?D ?P _ ?R=>change(semax D P C R)end.
 unfold search_heap at 1.
 pose proof(frame_array_focus Tsh(model_n a)(Z.of_nat(length path)-1)frames(ptr_frames p)FrameLen Idx)as Focus.
 unfold CCFrameFields.frame_type in Focus;unfold CCSearchSpecs.frame_type;rewrite Focus.
 pose proof(frame_data_at_fields Tsh r nx ch mk(Vint(Int.repr(Z.of_nat(ghost_phase g))))
 (active_frame_address p(model_n a)(Z.of_nat(length path))))as Shape.
 unfold CCFrameShape.frame_type,active_frame_address,CCSearchMemory.frame_type in Shape.
 lazymatch goal with|-context[@data_at ?cs Tsh(Tstruct _ccv_frame noattr)?v ?adr]=>
 let Slot:=constr:(@data_at cs Tsh(Tstruct _ccv_frame noattr)v adr)in
 lazymatch type of Shape with ?Canonical = ?Fields =>
 assert(SlotEq:Slot=Canonical)by(f_equal;exact Frame)end end.
 rewrite SlotEq,Shape. unfold frame_fields. Intros. forward.
 sep_apply(frame_fields_join Tsh r nx ch mk(Vint(Int.repr(Z.of_nat(ghost_phase g))))
 (active_frame_address p(model_n a)(Z.of_nat(length path)))).
 sep_apply(frame_cell_join Tsh(model_n a)(Z.of_nat(length path)-1)frames(ptr_frames p)
 (r,(nx,(ch,(mk,Vint(Int.repr(Z.of_nat(ghost_phase g)))))))FrameLen Idx).
 assert(Same:upd_Znth(Z.of_nat(length path)-1)frames
 (r,(nx,(ch,(mk,Vint(Int.repr(Z.of_nat(ghost_phase g)))))))=frames)
 by(apply upd_Znth_triv;[lia|exact Frame]).
 lazymatch goal with|-context[@upd_Znth ?ty ?i frames ?v]=>
 assert(SameActual:@upd_Znth ty i frames v=frames)by exact Same;rewrite SameActual end.
 apply semax_if_seq. forward_if.
 - assert(Phase:ghost_phase g=1%nat).
   { apply Nat2Z.inj;cbn;lia. }
   eapply semax_pre.
   2:{ apply(block_phase_one_iteration sh a p tp rp cap seed budget rules s0 s
   path prefix g log buf xs ys zs pk frames);assumption. }
   unfold search_heap;entailer!;cancel.
 - assert(Phase:ghost_phase g=2%nat).
   { destruct Kind as[P|P];[exfalso;apply H;rewrite P;reflexivity|assumption]. }
   eapply semax_pre.
   2:{ apply(block_phase_two_iteration sh a p tp rp cap seed budget rules s0 s
   path prefix g log buf xs ys zs pk frames);assumption. }
   unfold search_heap;entailer!;cancel.
Qed.
End Proof.
Print Assumptions block_nonzero_iteration.
