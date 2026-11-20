(* DRAFT: actual finish-body to the complete loop invariant. Requires the
   separately checked full-heap finish helper. No completion claim. *)
Require Import VST.floyd.proofauto.
Require Import CCV.ccv_core CCV.CCSearchSpecs CCV.CCSearchContext CCV.CCSearchHeap
 CCV.CCSearchMemory CCV.CCLoopInvariant CCV.CCStackInvariant CCV.CCPopInvariant
 CCV.CCPopMemory CCV.CCPopCoverage CCV.CCFrameForget CCV.CCFrameFields
 CCV.CCResumeMemory CCV.CCJournalArray CCV.CCJournalTrace CCV.CCRootArray
 CCV.CCSearchPhases CCV.CCResumeCoverage CCV.CCFrameUpdates CCV.CCAPIBridge
 CCV.VerifFinishHeap CCV.VerifSearchFinish.
Import ListNotations. Open Scope Z_scope.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
Lemma frame_mark_initialized g raw:
 frame_represents g raw ->(ghost_phase g=0%nat\/ghost_phase g=1%nat) ->
 exists r nx ch ph,raw=(r,(nx,(ch,(Vint(Int.repr(ghost_mark g)),ph)))).
Proof.
 intros Rep[Phase|Phase];unfold frame_represents in Rep;rewrite Phase in Rep.
 - destruct Rep as[r[nx[ch Eq]]];exists r,nx,ch,(Vint Int.zero);exact Eq.
 - destruct Rep as[ch Eq];exists(Vint(Int.repr(Z.of_nat(ghost_row g)))),
   (Vint(Int.repr(Z.of_nat(ghost_next g)))),ch,(Vint(Int.repr 1));exact Eq.
Qed.
Section Proof.
Context{Espec:OracleKind}.
Lemma block_finish_loop:forall sh a p tp rp cap seed budget rules s0 s
 parent_path prefix g log buf xs ys zs pk frames q,
 readable_share sh ->legal_model a ->0<=seed<=model_n a ->
 legal_stats budget s ->stats_monotone s0 s ->
 (ghost_phase g=0%nat\/ghost_phase g=1%nat) ->
 loop_shape a cap seed(parent_path++[q])(prefix++[g])log buf xs ys zs pk frames ->
 (forall e,CCModel.minimum(Z.to_nat(model_n a))(model_h_rows a)(model_l_rows a)e ->
 (CCModel.weight(Z.to_nat(model_n a))e<=Z.to_nat cap)%nat ->e(Z.to_nat seed)=true ->
 ~critical_at(Z.to_nat(model_n a))(model_h_rows a)(root_mask(model_n a)seed)log
 (parent_path++[q])(prefix++[g])e(length prefix)) ->
 semax CCSearchContext.Delta
 (PROP()LOCAL(temp _p(ptr_problem p);temp _w(ptr_workspace p);
 temp _f(active_frame_address p(model_n a)(Z.of_nat(length(parent_path++[q]))));
 temp _depth(Vint(Int.repr(Z.of_nat(length(parent_path++[q])))));
 temp _cap(Vint(Int.repr cap));temp _seed(Vint(Int.repr seed));temp _budget(Vint(Int.repr budget));
 temp _rules(Vint(Int.repr rules));temp _out(ptr_out p);temp _stats(ptr_stats p);
 lvar _top tuint tp;lvar _row tuint rp)
 SEP(search_heap sh a p tp rp(Zlength log)xs(journal_bitmap(root_mask(model_n a)seed)log)
 ys zs pk buf frames(Zrepeat 0(model_n a))s))%assert
 finish_body(normal_ret_assert(search_while_invariant sh a p tp rp cap seed budget rules s0)).
Proof.
 intros sh a p tp rp cap seed budget rules s0 s parent_path prefix g log buf xs ys zs pk frames q
 SH Legal Seed Stats Mono Kind Whole NoLast.
 pose proof(loop_shape_pop a cap seed parent_path prefix g log buf xs ys zs pk frames q
 Legal Seed Kind Whole NoLast)as NewShape.
 pose proof(legal_model_ranges a Legal)as[NR[MR[LR[KR Rest]]]].
 pose proof Whole as Shape;unfold loop_shape in Shape.
 destruct Shape as[XL[YL[ZL[PKL[XB[YB[ZB[PKB[Trace[HC[LC[Phys[Geo More]]]]]]]]]]]]].
 pose proof Geo as Geometry;unfold stack_geometry in Geometry.
 destruct Geometry as[Len[ND[Range[Depth Per]]]].
 assert(ParentLen:length parent_path=length prefix)by(rewrite !app_length in Len;cbn[length]in Len;lia).
 pose proof(path_length_bound(Z.to_nat(model_n a))(parent_path++[q])ND Range)as Capacity.
 assert(DRange:1<=Z.of_nat(length(parent_path++[q]))<=model_n a).
 { rewrite app_length;cbn[length]. apply Nat2Z.inj_le in Capacity;
 rewrite Z2Nat.id in Capacity by lia;rewrite app_length in Capacity;cbn[length]in Capacity;lia. }
 assert(IdxEq:Z.of_nat(length(parent_path++[q]))-1=Z.of_nat(length prefix)).
 { rewrite app_length,Nat2Z.inj_add;cbn;lia. }
 assert(DepthNew:Z.of_nat(length(parent_path++[q]))-1=Z.of_nat(length parent_path)).
 { rewrite IdxEq,ParentLen;reflexivity. }
 pose proof(Per(length prefix)g(old_last prefix g))as[PB[Mark Other]].
 assert(PopLen:Zlength(popped_log g log)=ghost_mark g)
 by(unfold popped_log;autorewrite with sublist;lia).
 destruct Phys as[FrameLen Cells];rewrite Z2Nat.id in FrameLen by lia.
 assert(TopIndex:(length prefix<Z.to_nat(model_n a))%nat).
 { rewrite app_length in Capacity;cbn[length]in Capacity;lia. }
 pose proof(Cells(length prefix)TopIndex)as Rep.
 destruct(lt_dec(length prefix)(length(prefix++[g])))as[Inside|Outside].
 2:{ rewrite app_length in Outside;cbn[length]in Outside;lia. }
 rewrite nth_snoc_last in Rep.
 destruct(frame_mark_initialized g(Znth(Z.of_nat(length prefix))frames)Rep Kind)
 as[r[nx[ch[ph Cell]]]].
 assert(Frame:Znth(Z.of_nat(length(parent_path++[q]))-1)frames=
 (r,(nx,(ch,(Vint(Int.repr(ghost_mark g)),ph)))))by(rewrite IdxEq;exact Cell).
 assert(SlotIndex:0<=Z.of_nat(length prefix)<model_n a)by lia.
 eapply semax_post'.
 2:{ apply(block_finish_heap sh a p tp rp cap seed budget rules
 (Z.of_nat(length(parent_path++[q])))(ghost_mark g)log buf xs ys zs pk frames
 (Zrepeat 0(model_n a))s r nx ch ph);assumption. }
 apply andp_left2. unfold search_while_invariant. go_lowerx;normalize.
 rewrite DepthNew in *.
 Exists parent_path prefix(popped_log g log)buf xs ys zs pk(popped_raw_frames prefix frames)s.
 rewrite PopLen.
 unfold search_heap at 1.
 sep_apply(forget_frame_slot Tsh(model_n a)(Z.of_nat(length prefix))frames(ptr_frames p)
 FrameLen SlotIndex).
 unfold search_heap,popped_raw_frames,default_frame.
 normalize;cancel.
 apply andp_right;[apply prop_right;tauto|cancel].
Qed.
End Proof.
Print Assumptions block_finish_loop.
