(* WORK IN PROGRESS. Actual phase2 block to the complete candidate while
   invariant. No full search/linking/termination claim. *)
Require Import VST.floyd.proofauto.
Require Import CCV.ccv_core CCV.CCSearchSpecs CCV.CCSearchContext CCV.CCSearchFragments
 CCV.CCSearchMemory CCV.CCSearchHeap CCV.CCStackInvariant CCV.CCLoopInvariant
 CCV.CCResumeInvariant CCV.CCResumeMemory CCV.CCResumeCoverage CCV.CCFrameUpdates
 CCV.CCJournalArray CCV.CCJournalTrace CCV.CCRootArray CCV.CCSearchPhases
 CCV.CCSearchSeparation CCV.CCCache CCV.CCBlockFrame CCV.CCAPIBridge CCV.VerifPhaseTwo CCV.VerifPhaseOneTail.
Import ListNotations. Open Scope Z_scope.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
Definition phase2_loop_frame sh a p rp cap seed budget pk s:assert:=
 (PROP()LOCAL(temp _cap(Vint(Int.repr cap));temp _seed(Vint(Int.repr seed));
 temp _budget(Vint(Int.repr budget));temp _out(ptr_out p);temp _stats(ptr_stats p);
 lvar _row tuint rp)
 SEP(search_phase2_extra sh a p rp pk(Zrepeat 0(model_n a))s))%assert.
Section Proof.
Context{Espec:OracleKind}.
Lemma block_phase_two_loop:forall sh a p tp rp cap seed budget rules s0 s
 path prefix g log buf xs ys zs pk frames,
 readable_share sh ->legal_model a ->0<=seed<=model_n a ->0<=rules<=63 ->
 legal_stats budget s ->stats_monotone s0 s ->ghost_phase g=2%nat ->
 loop_shape a cap seed path(prefix++[g])log buf xs ys zs pk frames ->
 semax CCSearchContext.Delta
 (PROP()LOCAL(temp _p(ptr_problem p);temp _w(ptr_workspace p);
 temp _f(active_frame_address p(model_n a)(Z.of_nat(length path)));
 temp _depth(Vint(Int.repr(Z.of_nat(length path))));
 temp _cap(Vint(Int.repr cap));temp _seed(Vint(Int.repr seed));
 temp _budget(Vint(Int.repr budget));temp _rules(Vint(Int.repr rules));
 temp _out(ptr_out p);temp _stats(ptr_stats p);lvar _top tuint tp;lvar _row tuint rp)
 SEP(search_heap sh a p tp rp(Zlength log)xs
 (journal_bitmap(root_mask(model_n a)seed)log)ys zs pk buf frames
 (Zrepeat 0(model_n a))s))%assert
 search_phase_two
 (normal_ret_assert(search_while_invariant sh a p tp rp cap seed budget rules s0)).
Proof.
 intros sh a p tp rp cap seed budget rules s0 s path prefix g log buf xs ys zs pk frames
 SH Legal Seed Rules Stats Mono Phase Whole.
 pose proof(legal_model_ranges a Legal)as[NR[MR[LR[KR[HP[LP GP]]]]]].
 assert(N:0<model_n a)by lia.
 pose proof Legal as LegalParts.
 destruct LegalParts as[DimN[DimM[DimL[DimK[HL[LL[GL[HB[LB[GB Meta]]]]]]]]]].
 pose proof Whole as Shape;unfold loop_shape in Shape.
 destruct Shape as[XL[YL[ZL[PKL[XB[YB[ZB[PKB[Trace[HC[LC[Phys[Geo[Tracks[Sep[Wgt[Before Live]]]]]]]]]]]]]]]]].
 assert(Rev:rev(prefix++[g])=g::rev prefix)by(rewrite rev_app_distr;cbn[rev app];reflexivity).
 pose proof(loop_pending_frame_room a cap seed path(prefix++[g])log buf xs ys zs pk frames
   g(rev prefix)Seed Whole Rev Phase)as[Free Room].
 pose proof Tracks as TrackOld;unfold selected_tracks_stack in TrackOld;rewrite Rev in TrackOld.
 destruct TrackOld as[Nonempty[Root State]];rewrite Phase in State.
 pose proof(pending_phase_selected _ _ _ _ _ State)as[QN Hit].
 assert(QZ:0<=Z.of_nat(ghost_chosen g)<model_n a).
 { apply Nat2Z.inj_lt in QN;rewrite Z2Nat.id in QN by lia;lia. }
 pose proof Geo as GeoParts;unfold stack_geometry in GeoParts.
 destruct GeoParts as[PathLen[ND[PathRange[Depth Per]]]].
 pose proof(path_length_bound(Z.to_nat(model_n a))path ND PathRange)as PathBound.
 assert(DRange:1<=Z.of_nat(length path)<=model_n a).
 { rewrite app_length in PathLen;cbn[length]in PathLen.
   apply Nat2Z.inj_le in PathBound;rewrite Z2Nat.id in PathBound by lia;lia. }
 assert(IdxEq:Z.of_nat(length path)-1=Z.of_nat(length prefix)).
 { rewrite PathLen,app_length,Nat2Z.inj_add;cbn;lia. }
 assert(Extent:20*model_n a<=Int.max_signed).
 { change Int.max_signed with 2147483647;lia. }
 assert(BaseLen:Zlength(root_mask(model_n a)seed)=model_n a)by(apply root_mask_length;assumption).
 assert(BaseBits:Forall(fun z:Z=>z=0\/z=1)(root_mask(model_n a)seed))by(apply root_mask_bits;assumption).
 assert(Range:Forall(fun q:Z=>0<=q<model_n a)log)by(unfold journal_trace in Trace;tauto).
 assert(FLen:Zlength(journal_bitmap(root_mask(model_n a)seed)log)=model_n a)
   by(apply(journal_bitmap_length(model_n a));assumption).
 assert(FB:Forall(fun z:Z=>z=0\/z=1)(journal_bitmap(root_mask(model_n a)seed)log))
   by(apply journal_bitmap_bits;assumption).
 assert(BufLen:Zlength buf=model_n a)by(unfold journal_trace in Trace;tauto).
 destruct Phys as[FrameLen Cells];rewrite Z2Nat.id in FrameLen by lia.
 assert(TopIndex:(length prefix<Z.to_nat(model_n a))%nat).
 { rewrite app_length in PathLen;cbn[length]in PathLen;lia. }
 pose proof(Cells(length prefix)TopIndex)as Cell.
 destruct(lt_dec(length prefix)(length(prefix++[g])))as[Inside|Outside].
 2:{ rewrite app_length in Outside;cbn[length]in Outside;lia. }
 rewrite nth_snoc_last in Cell;unfold frame_represents in Cell;rewrite Phase in Cell.
 assert(Frame:Znth(Z.of_nat(length path)-1)frames=
   frame_words(Z.of_nat(ghost_row g))(Z.of_nat(ghost_next g))
    (Vint(Int.repr(Z.of_nat(ghost_chosen g))))(ghost_mark g)2).
 { rewrite IdxEq;exact Cell. }
 pose proof(loop_shape_resume a cap seed path prefix g log buf xs ys zs pk frames
   (excl_enabled rules)Legal Seed Phase Whole)as NewShape.
 assert(FrameNew:
 upd_Znth(Z.of_nat(length path)-1)frames
   (frame_words(Z.of_nat(ghost_row g))(Z.of_nat(ghost_next g))
    (Vint(Int.repr(Z.of_nat(ghost_chosen g))))(ghost_mark g)1)=
 resume_raw_frames prefix frames).
 { unfold resume_raw_frames;rewrite <- IdxEq,Frame.
   unfold set_raw_phase,frame_words;reflexivity. }
 assert(TopAfter:(if excl_enabled rules then Zlength log+1 else Zlength log)=
 Zlength(resume_log(excl_enabled rules)log g)).
 { unfold resume_log;destruct(excl_enabled rules);[rewrite Zlength_app;cbn;lia|reflexivity]. }
 set(F:=phase2_loop_frame sh a p rp cap seed budget pk s).
 eapply semax_post' with(R':=(phase2_result sh p tp(model_n a)(model_m a)(model_l a)
 (Z.of_nat(length path))(Zlength log)(Z.of_nat(ghost_row g))(Z.of_nat(ghost_next g))
 (Z.of_nat(ghost_chosen g))(ghost_mark g)rules(model_h a)(model_lg a)xs
 (journal_bitmap(root_mask(model_n a)seed)log)ys zs frames buf*F)%logic).
 2:{ eapply semax_pre with(P':=((PROP()LOCAL(temp _p(ptr_problem p);temp _w(ptr_workspace p);
 temp _f(active_frame_address p(model_n a)(Z.of_nat(length path)));
 temp _rules(Vint(Int.repr rules));temp _depth(Vint(Int.repr(Z.of_nat(length path))));
 lvar _top tuint tp)
 SEP(phase2_memory sh p tp(model_n a)(model_m a)(model_l a)(Zlength log)
 (model_h a)(model_lg a)xs(journal_bitmap(root_mask(model_n a)seed)log)
 ys zs frames buf))*F)%logic).
 { unfold F,phase2_loop_frame;rewrite search_heap_phase2;go_lowerx;normalize;cancel.
   apply andp_right;[apply prop_right;tauto|cancel]. }
 apply semax_normal_block_frame.
 { unfold F,phase2_loop_frame,search_phase_two;auto 50 with closed. }
 apply(block_phase_two sh p tp(model_n a)(model_m a)(model_l a)(Z.of_nat(length path))
 (Zlength log)(Z.of_nat(ghost_row g))(Z.of_nat(ghost_next g))(Z.of_nat(ghost_chosen g))
 (ghost_mark g)rules(model_h a)(model_lg a)xs(journal_bitmap(root_mask(model_n a)seed)log)
 ys zs frames buf);try assumption;try apply Zlength_nonneg;try lia.
 split;[apply Zlength_nonneg|exact Room].
 }
 apply andp_left2. unfold phase2_result,F,phase2_loop_frame,search_while_invariant.
 go_lowerx;normalize.
 lazymatch goal with |-context[@upd_Znth ?ty ?i frames ?v]=>
 assert(FrameActual:@upd_Znth ty i frames v=resume_raw_frames prefix frames)
 by exact FrameNew;rewrite FrameActual end.
 rewrite TopAfter,<-resume_bitmap.
 fold(resume_buffer(excl_enabled rules)log buf g).
 Exists path(prefix++[resumed_record g])(resume_log(excl_enabled rules)log g)
 (resume_buffer(excl_enabled rules)log buf g)(chosen_xs(Z.of_nat(ghost_chosen g))xs)
 (chosen_ys(model_n a)(model_m a)(Z.of_nat(ghost_chosen g))(model_h a)ys)
 (chosen_ys(model_n a)(model_l a)(Z.of_nat(ghost_chosen g))(model_lg a)zs)
 pk(resume_raw_frames prefix frames)s.
 rewrite search_heap_phase2. normalize;cancel.
 apply andp_right;[apply prop_right;tauto|cancel].
 unfold resume_buffer;apply derives_refl.
Qed.
End Proof.
Print Assumptions block_phase_two_loop.
