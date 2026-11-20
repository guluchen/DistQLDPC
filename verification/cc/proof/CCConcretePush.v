(* Exact concrete C scan certificate discharges all pure child-push obligations.
   The actual complete C phase1 caller is composed separately. *)
Require Import VST.floyd.proofauto.
Require Import CCV.CCModel CCV.CCFunctional CCV.CCSearchSpecs CCV.CCStackInvariant
 CCV.CCLoopInvariant CCV.CCPushInvariant CCV.CCPushCoverage CCV.CCPushMemory
 CCV.CCPushScan CCV.CCScanBridge CCV.CCSearchPhases CCV.CCJournalArray
 CCV.CCJournalTrace CCV.CCRootArray CCV.CCRepresentation CCV.CCMatrixModel
 CCV.CCValidation CCV.CCAPIBridge CCV.VerifPhaseOne CCV.VerifPhaseOneTail
 CCV.CCFrameUpdates.
Import ListNotations. Open Scope Z_scope.
Theorem loop_shape_concrete_push a cap seed path prefix g log buf xs ys zs pk frames q:
 legal_model a ->1<=cap<=model_n a ->0<=seed<=model_n a ->ghost_phase g=1%nat ->
 loop_shape a cap seed path(prefix++[g])log buf xs ys zs pk frames ->
 phase1_certificate(model_n a)(Z.of_nat(ghost_row g))(Z.of_nat(ghost_next g))
 (model_h a)xs(journal_bitmap(root_mask(model_n a)seed)log)q ->q<model_n a ->
 loop_shape a cap seed(path++[Z.to_nat q])(pushed_records prefix g(Z.to_nat q)log)log buf
 (chosen_xs q xs)
 (chosen_ys(model_n a)(model_m a)q(model_h a)ys)
 (chosen_ys(model_n a)(model_l a)q(model_lg a)zs)pk
 (push_raw_frames path g(Z.to_nat q)log frames).
Proof.
 intros Legal Cap Seed Phase Whole[Bounds[Skip Hit]]Inside.
 pose proof(legal_model_ranges a Legal)as[NR[MR[LR[KR Rest]]]].
 assert(N:0<model_n a)by lia.
 assert(Q:0<=q<model_n a)by lia.
 pose proof Legal as Parts.
 destruct Parts as[DimN[DimM[DimL[DimK[HL[LL[GL[HB[LB[GB Meta]]]]]]]]]].
 pose proof Whole as Shape;unfold loop_shape in Shape.
 destruct Shape as[XL[YL[ZL[PKL[XB[YB[ZB[PKB[Trace[HC[LC[Phys[Geo[Tracks[Sep[Wgt[Before Live]]]]]]]]]]]]]]]]].
 pose proof Geo as Geometry;unfold stack_geometry in Geometry.
 destruct Geometry as[Len[ND[Range[Depth Per]]]].
 destruct(Per(length prefix)g(old_last prefix g))as[PB[Mark[RootMark[Anc Init]]]].
 destruct(Init(or_introl Phase))as[Row[Next[DepthCap Odd]]].
 assert(RowZ:0<=Z.of_nat(ghost_row g)<model_m a).
 { apply Nat2Z.inj_lt in Row;rewrite Z2Nat.id in Row by lia;lia. }
 assert(BaseLen:Zlength(root_mask(model_n a)seed)=model_n a)by(apply root_mask_length;assumption).
 assert(LogRange:Forall(fun i:Z=>0<=i<model_n a)log)by(unfold journal_trace in Trace;tauto).
 assert(FL:Zlength(journal_bitmap(root_mask(model_n a)seed)log)=model_n a)
 by(apply(journal_bitmap_length(model_n a));assumption).
 assert(FB:Forall(fun z:Z=>z=0\/z=1)(journal_bitmap(root_mask(model_n a)seed)log))
 by(apply journal_bitmap_bits;apply root_mask_bits;assumption).
 assert(Rev:rev(prefix++[g])=g::rev prefix)by(rewrite rev_app_distr;cbn[rev app];reflexivity).
 pose proof Tracks as OldTracks;unfold selected_tracks_stack in OldTracks;rewrite Rev,Phase in OldTracks.
 destruct OldTracks as[Nonempty[Root[NDX[RX[PL Selected]]]]].
 pose proof(concrete_scan_path_facts(model_n a)(model_m a)(Z.of_nat(ghost_row g))
 (Z.of_nat(ghost_next g))q(model_h a)xs(journal_bitmap(root_mask(model_n a)seed)log)
 path N MR RowZ ltac:(lia)Bounds HL XL FL HB XB FB Selected Skip Hit)as[Exact Frees].
 destruct(Frees Inside)as[Xq Fq].
 assert(RowEq:nth(ghost_row g)(model_h_rows a)zero_vector=
 row_vector(model_n a)(Z.of_nat(ghost_row g))(model_h a)).
 { unfold model_h_rows;apply matrix_vectors_nth;assumption. }
 assert(PrefixEq:prefix_selected path(length prefix)=CCSearchPhases.path_bits path).
 { apply parent_prefix_all;rewrite app_length in Len;cbn[length]in Len;lia. }
 assert(Scan:Z.to_nat q=CCCandidateScan.scan_candidates(Z.to_nat(model_n a))
 (ghost_next g)(nth(ghost_row g)(model_h_rows a)zero_vector)
 (prefix_selected path(length prefix))(decode(journal_bitmap(root_mask(model_n a)seed)log))).
 { rewrite RowEq,PrefixEq.
   rewrite Nat2Z.id in Exact. rewrite Exact,Nat2Z.id;reflexivity. }
 pose proof(loop_shape_push a cap seed path prefix g log buf xs ys zs pk frames(Z.to_nat q)
 Legal Cap Phase ltac:(apply Z2Nat.inj_lt;lia)Xq Fq Scan Whole)as New.
 rewrite Z2Nat.id in New by lia;exact New.
Qed.
Print Assumptions loop_shape_concrete_push.
