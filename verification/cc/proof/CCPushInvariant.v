(* Complete PURE loop-shape transition for a fresh child push. Exact C scan
   facts/caller composition and all other loop branches remain separate. *)
Require Import VST.floyd.proofauto.
Require Import CCV.CCModel CCV.CCFunctional CCV.CCCache CCV.CCMatrix
 CCV.CCSearchSpecs CCV.CCStackInvariant CCV.CCLoopInvariant CCV.CCPushCoverage
 CCV.CCPushMemory CCV.CCPushGeometry CCV.CCResumeInvariant CCV.CCResumeMemory
 CCV.CCJournalArray CCV.CCRootArray CCV.CCSearchSeparation CCV.CCRepresentation CCV.CCSearchPhases CCV.CCResumeCoverage
 CCV.CCFrameUpdates CCV.CCAPIBridge CCV.VerifPhaseOneTail CCV.VerifToggle.
Import ListNotations. Open Scope Z_scope.
Theorem loop_shape_push a cap seed path prefix g log buf xs ys zs pk frames q:
 legal_model a ->1<=cap<=model_n a ->ghost_phase g=1%nat ->
 (q<Z.to_nat(model_n a))%nat ->decode xs q=false ->
 decode(journal_bitmap(root_mask(model_n a)seed)log)q=false ->
 q=CCCandidateScan.scan_candidates(Z.to_nat(model_n a))(ghost_next g)
   (nth(ghost_row g)(model_h_rows a)zero_vector)
   (prefix_selected path(length prefix))
   (decode(journal_bitmap(root_mask(model_n a)seed)log)) ->
 loop_shape a cap seed path(prefix++[g])log buf xs ys zs pk frames ->
 loop_shape a cap seed(path++[q])(pushed_records prefix g q log)log buf
 (chosen_xs(Z.of_nat q)xs)
 (chosen_ys(model_n a)(model_m a)(Z.of_nat q)(model_h a)ys)
 (chosen_ys(model_n a)(model_l a)(Z.of_nat q)(model_lg a)zs)pk
 (push_raw_frames path g q log frames).
Proof.
 intros Legal Cap Phase Q Free Fq Scan Whole.
 pose proof(legal_model_ranges a Legal)as[NR[MR[LR[KR Rest]]]].
 assert(N:0<model_n a)by lia.
 destruct Legal as[DimN[DimM[DimL[DimK[HL[LL[GL[HB[LB[GB Meta]]]]]]]]]].
 pose proof Whole as Shape;unfold loop_shape in Shape.
 destruct Shape as[XL[YL[ZL[PKL[XB[YB[ZB[PKB[Trace[HC[LC[Phys[Geo[Tracks[Sep[Wgt[Before Live]]]]]]]]]]]]]]]]].
 assert(QZ:0<=Z.of_nat q<model_n a).
 { apply Nat2Z.inj_lt in Q;rewrite Z2Nat.id in Q by lia;lia. }
 assert(Rev:rev(prefix++[g])=g::rev prefix)by(rewrite rev_app_distr;cbn[rev app];reflexivity).
 pose proof Tracks as OldTracks;unfold selected_tracks_stack in OldTracks;rewrite Rev,Phase in OldTracks.
 destruct OldTracks as[Nonempty[Root State]].
 destruct State as[ND[PathRange[PathLen Sel]]].
 assert(Fresh:~In q path).
 { apply path_bits_false;rewrite <-Sel by assumption;assumption. }
 pose proof Geo as Geometry;unfold stack_geometry in Geometry.
 destruct Geometry as[Len[NDG[RG[Depth Per]]]].
 destruct(Per(length prefix)g(old_last prefix g))as[PB[Mark[RootMark[Anc Init]]]].
 destruct(Init(or_introl Phase))as[Row[Next[DepthCap Odd]]].
 assert(LenPath:length path=S(length prefix))by(rewrite app_length in Len;cbn[length]in Len;lia).
 assert(Capacity:(length path<Z.to_nat(model_n a))%nat).
 { apply Nat2Z.inj_lt;rewrite Z2Nat.id by lia.
   apply Nat2Z.inj_lt in DepthCap;rewrite Z2Nat.id in DepthCap by lia;lia. }
 pose proof(pushed_selected_tracks(Z.to_nat(model_n a))(Z.to_nat seed)path prefix g q log xs
 ltac:(rewrite Z2Nat.id by lia;assumption)XB Q Free Phase Tracks)as TracksNew.
 pose proof TracksNew as NewTracks;unfold selected_tracks_stack in NewTracks.
 unfold pushed_records in NewTracks;rewrite rev_app_distr in NewTracks;
 cbn[rev app child_record ghost_phase ghost_chosen]in NewTracks.
 destruct NewTracks as[NewNonempty[NewRoot NewState]].
 pose proof(proj1(phase_path_weight _ _ _ _ _ _ NewState)(or_introl eq_refl))as NewWeight.
 assert(SelectedDecode:forall i,(i<Z.to_nat(model_n a))%nat ->
 decode(chosen_xs(Z.of_nat q)xs)i=flip(decode xs)q i).
 { intros i I;unfold chosen_xs.
   rewrite(decode_toggle xs(Z.of_nat q)ltac:(lia)XB i ltac:(rewrite XL;exact I)).
   rewrite Nat2Z.id;reflexivity. }
 unfold loop_shape.
 split;[unfold chosen_xs;rewrite upd_Znth_Zlength by lia;assumption|].
 split;[apply chosen_ys_length;assumption|].
 split;[apply chosen_ys_length;assumption|].
 split;[assumption|split;[apply(chosen_xs_binary(model_n a)(Z.of_nat q)xs);assumption|]].
 split;[apply chosen_ys_binary;assumption|].
 split;[apply chosen_ys_binary;assumption|].
 split;[assumption|split;[assumption|]].
 split;[unfold chosen_xs,chosen_ys;apply cached_toggle;assumption|].
 split;[unfold chosen_xs,chosen_ys;apply cached_toggle;assumption|].
 split;[apply push_physical_stack;assumption|].
 split;[apply geometry_push;assumption|].
 split;[exact TracksNew|].
 split.
 - pose proof(separated_flip _ _ _ q Sep Fq)as NewSep.
   intros i I Hit;rewrite SelectedDecode in Hit by assumption;apply NewSep;assumption.
 - split.
   + rewrite NewWeight,app_length,Nat2Z.inj_add;cbn.
     apply Nat2Z.inj_lt in DepthCap;rewrite Z2Nat.id in DepthCap by lia;lia.
   + split;[assumption|apply push_preserves_live_targets;assumption].
Qed.
Print Assumptions loop_shape_push.
