(* DRAFT: actual selected phase1 branch followed by the actual shared finish
   continuation. These are extracted frozen C statements, not replacement code.
   No complete search body claim. Must pass normal coqc before use. *)
Require Import VST.floyd.proofauto.
Require Import CCV.ccv_core CCV.CCSearchSpecs CCV.CCSearchContext CCV.CCSearchFragments
 CCV.CCSearchHeap CCV.CCSearchMemory CCV.CCLoopInvariant CCV.CCStackInvariant
 CCV.CCConcretePush CCV.CCPushCoverage CCV.CCPushMemory CCV.CCPushScan CCV.CCScanFinish
 CCV.CCJournalArray CCV.CCJournalTrace CCV.CCRootArray CCV.CCSearchPhases
 CCV.CCResumeMemory CCV.CCResumeCoverage CCV.CCFrameUpdates CCV.CCRepresentation
 CCV.CCValidation CCV.CCMatrixModel CCV.CCAPIBridge CCV.VerifPhaseOne
 CCV.VerifPhaseOneTail CCV.VerifPhaseOneHeap CCV.VerifFinishLoop.
Import ListNotations. Open Scope Z_scope.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
Section Proof.
Context{Espec:OracleKind}.
Lemma block_phase_one_iteration:forall sh a p tp rp cap seed budget rules s0 s
 path prefix g log buf xs ys zs pk frames,
 readable_share sh ->legal_model a ->1<=cap<=model_n a ->0<=seed<=model_n a ->
 legal_stats budget s ->stats_monotone s0 s ->ghost_phase g=1%nat ->
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
 (Ssequence search_phase_one search_finish)
 (normal_ret_assert(search_while_invariant sh a p tp rp cap seed budget rules s0)).
Proof.
 intros sh a p tp rp cap seed budget rules s0 s path prefix g log buf xs ys zs pk frames
 SH Legal Cap Seed Stats Mono Phase Whole.
 pose proof(legal_model_ranges a Legal)as[NR[MR[LR[KR Rest]]]].
 pose proof Legal as ModelParts.
 destruct ModelParts as[DimN[DimM[DimL[DimK[HL[LL[GL[HB[LB[GB Meta]]]]]]]]]].
 pose proof Whole as Shape;unfold loop_shape in Shape.
 destruct Shape as[XL[YL[ZL[PKL[XB[YB[ZB[PKB[Trace[HC[LC[Phys[Geo[Tracks More]]]]]]]]]]]]]].
 pose proof Geo as Geometry;unfold stack_geometry in Geometry.
 destruct Geometry as[Len[ND[PathRange[Depth Per]]]].
 assert(PathLen:length path=S(length prefix))by(rewrite app_length in Len;cbn[length]in Len;lia).
 destruct(Per(length prefix)g(old_last prefix g))as[PB[Mark[RootMark[Anc Init]]]].
 destruct(Init(or_introl Phase))as[Row[Next[DepthCap Odd]]].
 assert(RowZ:0<=Z.of_nat(ghost_row g)<model_m a).
 { apply Nat2Z.inj_lt in Row;rewrite Z2Nat.id in Row by lia;lia. }
 assert(NextZ:0<=Z.of_nat(ghost_next g)<=model_n a).
 { apply Nat2Z.inj_le in Next;rewrite Z2Nat.id in Next by lia;lia. }
 assert(DRange:1<=Z.of_nat(length path)<model_n a).
 { apply Nat2Z.inj_lt in DepthCap;rewrite Z2Nat.id in DepthCap by lia;lia. }
 assert(BaseLen:Zlength(root_mask(model_n a)seed)=model_n a)by(apply root_mask_length;assumption).
 assert(LogRange:Forall(fun i:Z=>0<=i<model_n a)log)by(unfold journal_trace in Trace;tauto).
 assert(FL:Zlength(journal_bitmap(root_mask(model_n a)seed)log)=model_n a)
 by(apply(journal_bitmap_length(model_n a));assumption).
 assert(FB:Forall(fun z:Z=>z=0\/z=1)(journal_bitmap(root_mask(model_n a)seed)log))
 by(apply journal_bitmap_bits;apply root_mask_bits;assumption).
 assert(TopRange:0<=Zlength log<=model_n a)by(unfold journal_trace in Trace;tauto).
 destruct Phys as[FrameLen Cells];rewrite Z2Nat.id in FrameLen by lia.
 assert(IdxEq:Z.of_nat(length path)-1=Z.of_nat(length prefix))by lia.
 assert(TopIndex:(length prefix<Z.to_nat(model_n a))%nat).
 { apply Nat2Z.inj_lt;rewrite Z2Nat.id by lia;lia. }
 pose proof(Cells(length prefix)TopIndex)as Rep.
 destruct(lt_dec(length prefix)(length(prefix++[g])))as[Inside|Outside].
 2:{ rewrite app_length in Outside;cbn[length]in Outside;lia. }
 rewrite nth_snoc_last in Rep;unfold frame_represents in Rep;rewrite Phase in Rep.
 destruct Rep as[ch Cell].
 assert(Frame:Znth(Z.of_nat(length path)-1)frames=
 frame_words(Z.of_nat(ghost_row g))(Z.of_nat(ghost_next g))ch(ghost_mark g)1)
 by(rewrite IdxEq;exact Cell).
 assert(Rev:rev(prefix++[g])=g::rev prefix)by(rewrite rev_app_distr;cbn[rev app];reflexivity).
 pose proof Tracks as TrackParts;unfold selected_tracks_stack in TrackParts;rewrite Rev,Phase in TrackParts.
 destruct TrackParts as[Nonempty[Root[NDX[RX[PL Selected]]]]].
 assert(RowEq:nth(ghost_row g)(model_h_rows a)CCFunctional.zero_vector=
 row_vector(model_n a)(Z.of_nat(ghost_row g))(model_h a)).
 { unfold model_h_rows;apply matrix_vectors_nth;assumption. }
 assert(SelectedPrefix:forall i,(i<Z.to_nat(model_n a))%nat ->
 decode xs i=prefix_selected path(length prefix)i).
 { intros i I;rewrite(parent_prefix_all path prefix PathLen);apply Selected;assumption. }
 eapply semax_seq' with(P':=phase1_heap_result sh a p tp rp cap seed budget rules
 (Z.of_nat(length path))(Zlength log)(Z.of_nat(ghost_row g))(Z.of_nat(ghost_next g))
 (ghost_mark g)xs(journal_bitmap(root_mask(model_n a)seed)log)ys zs pk buf frames
 (Zrepeat 0(model_n a))s).
 - apply(block_phase_one_heap sh a p tp rp cap seed budget rules(Z.of_nat(length path))(Zlength log)
 (Z.of_nat(ghost_row g))(Z.of_nat(ghost_next g))ch(ghost_mark g)xs
 (journal_bitmap(root_mask(model_n a)seed)log)ys zs pk buf frames(Zrepeat 0(model_n a))s);
 assumption.
 - unfold phase1_heap_result. Intros c.
   match goal with H:phase1_certificate _ _ _ _ _ _ c |- _=>rename H into Certificate end.
   destruct(c<?model_n a)eqn:Choose.
   + assert(CInside:c<model_n a)by(apply Z.ltb_lt;assumption).
     assert(CPos:0<=c)by(destruct Certificate as[B RestC];lia).
     pose proof(loop_shape_concrete_push a cap seed path prefix g log buf xs ys zs pk frames c
     Legal Cap Seed Phase Whole Certificate CInside)as NewShape.
     assert(FramesEq:push_raw_frames path g(Z.to_nat c)log frames=
     child_frames(Z.of_nat(length path))(Z.of_nat(ghost_row g))c(ghost_mark g)(Zlength log)frames).
     { unfold push_raw_frames;rewrite Z2Nat.id by lia;reflexivity. }
     rewrite FramesEq in NewShape.
     unfold CCSearchContext.Delta;abbreviate_semax.
     let C:=eval cbv -[Int.repr]in search_finish in
     lazymatch goal with|-semax ?D ?P _ ?R=>change(semax D P C R)end.
     forward_if.
     { contradiction. }
     forward.
     unfold search_while_invariant.
     Exists(path++[Z.to_nat c])(pushed_records prefix g(Z.to_nat c)log)log buf
     (chosen_xs c xs)(chosen_ys(model_n a)(model_m a)c(model_h a)ys)
     (chosen_ys(model_n a)(model_l a)c(model_lg a)zs)pk
     (child_frames(Z.of_nat(length path))(Z.of_nat(ghost_row g))c(ghost_mark g)(Zlength log)frames)s.
     assert(DepthPush:Z.of_nat(length(path++[Z.to_nat c]))=Z.of_nat(length path)+1)
     by(rewrite app_length,Nat2Z.inj_add;cbn;lia).
     rewrite DepthPush. entailer!;cancel.
   + assert(Ceq:c=model_n a).
     { apply Z.ltb_ge in Choose;destruct Certificate as[B RestC];lia. }
     subst c.
     assert(NoLast:forall e,~critical_at(Z.to_nat(model_n a))(model_h_rows a)
     (root_mask(model_n a)seed)log path(prefix++[g])e(length prefix)).
     { apply(concrete_exhausted_top_not_critical(model_n a)(model_m a)(model_h_rows a)
     (root_mask(model_n a)seed)log path prefix g(model_h a)xs);try assumption;lia. }
     assert(PathSplit:path=removelast path++[last path 0%nat]).
     { apply app_removelast_last;assumption. }
     unfold CCSearchContext.Delta;abbreviate_semax.
     let C:=eval cbv -[Int.repr]in search_finish in
     lazymatch goal with|-semax ?D ?P _ ?R=>change(semax D P C R)end.
     forward_if.
     2:{ pose proof(f_equal Int.unsigned H)as Bad;change(1=0)%Z in Bad;discriminate. }
     rewrite PathSplit in Whole,NoLast|-*.
     eapply semax_pre.
     2:{ apply(block_finish_loop sh a p tp rp cap seed budget rules s0 s
     (removelast path)prefix g log buf xs ys zs pk frames(last path 0%nat));try assumption.
     - right;assumption.
     - intros e Min Within Hit;apply NoLast.
     }
     entailer!;cancel.
Qed.
End Proof.
Print Assumptions block_phase_one_iteration.
