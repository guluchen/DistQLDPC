(* Complete PURE loop-shape transition for phase2. The actual C block/caller
   composition and other iteration phases are separate obligations. *)
Require Import VST.floyd.proofauto.
Require Import CCV.CCModel CCV.CCFunctional CCV.CCCache CCV.CCMatrix CCV.CCRepresentation
 CCV.CCSearchSpecs CCV.CCSearchPhases CCV.CCSearchSeparation CCV.CCStackInvariant
 CCV.CCLoopInvariant CCV.CCResumeCoverage CCV.CCResumeGeometry CCV.CCResumeMemory
 CCV.CCFrameUpdates CCV.CCJournalArray CCV.CCJournalTrace CCV.CCRootArray
 CCV.VerifPhaseOneTail CCV.VerifToggle CCV.CCAPIBridge.
Import ListNotations. Open Scope Z_scope.
Lemma chosen_xs_binary n q xs:Zlength xs=n ->0<=q<n ->
 Forall(fun z:Z=>z=0\/z=1)xs ->Forall(fun z:Z=>z=0\/z=1)(chosen_xs q xs).
Proof.
 intros Len Q Bits;unfold chosen_xs;apply Forall_upd_Znth;[assumption|].
 assert(Bit:Znth q xs=0\/Znth q xs=1)by(apply Forall_Znth;auto;lia).
 destruct Bit as[B|B];rewrite B;cbn;auto.
Qed.
Lemma chosen_ys_length n m q h ys:0<=m ->Zlength ys=m ->
 Zlength(chosen_ys n m q h ys)=m.
Proof.
 intros M Len;unfold chosen_ys.
 rewrite xor_vector_length by(rewrite column_length;lia);assumption.
Qed.
Lemma chosen_ys_binary n m q h ys:0<n ->0<=m ->0<=q<n ->Zlength ys=m ->
 Zlength h=m*n ->Forall(fun z:Z=>z=0\/z=1)ys ->Forall(fun z:Z=>z=0\/z=1)h ->
 Forall(fun z:Z=>z=0\/z=1)(chosen_ys n m q h ys).
Proof.
 intros N M Q Len Hlen YB HB;unfold chosen_ys;apply xor_vector_bits.
 - rewrite column_length;lia.
 - assumption.
 - apply(column_bits n m q h);assumption.
Qed.
Lemma resume_log_growth exclude log g:Zlength log<=Zlength(resume_log exclude log g).
Proof. unfold resume_log;destruct exclude;[rewrite Zlength_app;cbn;lia|lia]. Qed.
Lemma resume_separated n base log g xs exclude:
 0<=n ->Zlength base=n ->Forall(fun q:Z=>0<=q<n)log ->
 Zlength xs=n ->Forall(fun z:Z=>z=0\/z=1)xs ->
 (ghost_chosen g<Z.to_nat n)%nat ->decode xs(ghost_chosen g)=true ->
 separated(Z.to_nat n)(decode xs)(decode(journal_bitmap base log)) ->
 separated(Z.to_nat n)(decode(chosen_xs(Z.of_nat(ghost_chosen g))xs))
 (decode(journal_bitmap base(resume_log exclude log g))).
Proof.
 intros N Len Range Xlen XB Q Hit Sep.
 assert(QZ:0<=Z.of_nat(ghost_chosen g)<n).
 { apply Nat2Z.inj_lt in Q;rewrite Z2Nat.id in Q by assumption;lia. }
 pose proof(separated_resume(Z.to_nat n)(decode xs)(decode(journal_bitmap base log))
   (ghost_chosen g)exclude Sep Hit)as Safe.
 intros i I Selected.
 rewrite(resumed_selected_decode n g xs Xlen XB QZ i I)in Selected.
 unfold resume_log;destruct exclude.
 - rewrite(resume_bitmap_decode n base log g N Len Range Q);apply Safe;assumption.
 - apply Safe;assumption.
Qed.
Theorem loop_shape_resume a cap seed path prefix g log buf xs ys zs pk frames exclude:
 legal_model a ->0<=seed<=model_n a ->ghost_phase g=2%nat ->
 loop_shape a cap seed path(prefix++[g])log buf xs ys zs pk frames ->
 loop_shape a cap seed path(prefix++[resumed_record g])(resume_log exclude log g)
 (resume_buffer exclude log buf g)(chosen_xs(Z.of_nat(ghost_chosen g))xs)
 (chosen_ys(model_n a)(model_m a)(Z.of_nat(ghost_chosen g))(model_h a)ys)
 (chosen_ys(model_n a)(model_l a)(Z.of_nat(ghost_chosen g))(model_lg a)zs)
 pk(resume_raw_frames prefix frames).
Proof.
 intros Legal Seed Phase Whole.
 pose proof(legal_model_ranges a Legal)as[NR[MR[LR[KR Rest]]]].
 assert(N:0<model_n a)by lia.
 destruct Legal as[DimN[DimM[DimL[DimK[HL[LL[GL[HB[LB[GB Meta]]]]]]]]]].
 pose proof Whole as Shape;unfold loop_shape in Shape.
 destruct Shape as[XL[YL[ZL[PKL[XB[YB[ZB[PKB[Trace[HC[LC[Phys[Geo[Tracks[Sep[Wgt[Before Live]]]]]]]]]]]]]]]]].
 assert(Rev:rev(prefix++[g])=g::rev prefix)by(rewrite rev_app_distr;cbn[rev app];reflexivity).
 pose proof Tracks as TrackOld;unfold selected_tracks_stack in TrackOld;rewrite Rev in TrackOld.
 destruct TrackOld as[Nonempty[Root State]];rewrite Phase in State.
 pose proof(pending_phase_selected _ _ _ _ _ State)as[QN Hit].
 assert(QZ:0<=Z.of_nat(ghost_chosen g)<model_n a).
 { apply Nat2Z.inj_lt in QN;rewrite Z2Nat.id in QN by lia;lia. }
 pose proof(loop_pending_frame_room a cap seed path(prefix++[g])log buf xs ys zs pk frames
   g(rev prefix)Seed Whole Rev Phase)as[Free Room].
 assert(BaseLen:Zlength(root_mask(model_n a)seed)=model_n a)by(apply root_mask_length;assumption).
 assert(Range:Forall(fun q:Z=>0<=q<model_n a)log)by(unfold journal_trace in Trace;tauto).
 pose proof Geo as GeoParts;unfold stack_geometry in GeoParts.
 destruct GeoParts as[PathLen[ND[PathRange[Depth Per]]]].
 assert(Capacity:(length(prefix++[g])<=Z.to_nat(model_n a))%nat).
 { pose proof(path_length_bound(Z.to_nat(model_n a))path ND PathRange);lia. }
 pose proof(resumed_selected_tracks(model_n a)(Z.to_nat seed)path prefix g xs XL XB QZ Phase Tracks)as TracksNew.
 pose proof TracksNew as NewState;unfold selected_tracks_stack in NewState.
 rewrite rev_app_distr in NewState;cbn[rev app resumed_record ghost_phase ghost_chosen]in NewState.
 destruct NewState as[NonemptyNew[RootNew StateNew]].
 pose proof(proj2(phase_path_weight _ _ _ _ _ _ State)eq_refl)as OldWeight.
 pose proof(proj1(phase_path_weight _ _ _ _ _ _ StateNew)(or_intror eq_refl))as NewWeight.
 assert(PosLength:(0<length path)%nat)by(rewrite app_length in PathLen;cbn[length]in PathLen;lia).
 unfold loop_shape.
 split;[unfold chosen_xs;rewrite upd_Znth_Zlength by lia;assumption|].
 split;[apply chosen_ys_length;assumption|].
 split;[apply chosen_ys_length;assumption|].
 split;[assumption|split;[apply(chosen_xs_binary(model_n a)(Z.of_nat(ghost_chosen g))xs);assumption|]].
 split;[apply chosen_ys_binary;assumption|].
 split;[apply chosen_ys_binary;assumption|].
 split;[assumption|].
 split;[apply resume_journal_trace;try assumption;lia|].
 split;[unfold chosen_xs,chosen_ys;apply cached_toggle;assumption|].
 split;[unfold chosen_xs,chosen_ys;apply cached_toggle;assumption|].
 split;[apply resume_physical_stack;assumption|].
 split;[apply geometry_resume with(log);[assumption|apply resume_log_growth|assumption]|].
 split;[exact TracksNew|].
 split;[apply resume_separated;try assumption;lia|].
 split.
 - rewrite NewWeight. rewrite OldWeight,Nat2Z.inj_add in Wgt;cbn in Wgt;lia.
 - split;[assumption|].
   apply resume_preserves_live_targets;try assumption;try lia.
   apply(geometry_marks(Z.to_nat(model_n a))(Z.to_nat(model_m a))(Z.to_nat cap)
     (model_h_rows a)path(prefix++[g])log Geo).
Qed.
Print Assumptions resume_separated.
Print Assumptions loop_shape_resume.
