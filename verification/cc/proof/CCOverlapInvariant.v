(* Complete PURE loop-shape transition for the phase0 overlap journal update.
   The actual C caller/return branches are still composed separately. *)
Require Import VST.floyd.proofauto.
Require Import CCV.CCModel CCV.CCFunctional CCV.CCSearchSpecs CCV.CCStackInvariant
 CCV.CCLoopInvariant CCV.CCSearchSeparation CCV.CCJournalArray CCV.CCJournalTrace
 CCV.CCRootArray CCV.CCRepresentation CCV.CCSearchPolicies CCV.CCOverlapCoverage
 CCV.CCResumeCoverage CCV.CCSearchPhases CCV.CCPushCoverage CCV.CCAPIBridge.
Import ListNotations. Open Scope Z_scope.
Lemma separated_iff_avoids n s f:separated n s f <->avoids n s f.
Proof.
 split;intros Safe i I Hit.
 - destruct(s i)eqn:S;[pose proof(Safe i I S);congruence|reflexivity].
 - destruct(f i)eqn:F;[pose proof(Safe i I F);congruence|reflexivity].
Qed.
Lemma journal_extension_separated n base old new xs Allowed:
 Zlength base=n ->Zlength xs=n ->
 Forall(fun q:Z=>0<=q<n)old ->Forall(fun q:Z=>0<=q<n)new ->
 allowed_extension old new Allowed ->(forall q,Allowed q ->Znth q xs=0) ->
 separated(Z.to_nat n)(decode xs)(decode(journal_bitmap base old)) ->
 separated(Z.to_nat n)(decode xs)(decode(journal_bitmap base new)).
Proof.
 intros Len XL Rold Rnew[added[Eq All]]Zero Sep;subst new.
 apply separated_iff_avoids in Sep;apply separated_iff_avoids.
 apply Forall_app in Rnew;destruct Rnew as[Old Added].
 apply(bitmap_extension_avoids n base old added(decode xs));try assumption.
 intros q Hin;pose proof(proj1(Forall_forall _ _)Added q Hin)as Q.
 pose proof(proj1(Forall_forall _ _)All q Hin)as A.
 cbn in Q.
 rewrite decode_at_nat,Z2Nat.id by lia;rewrite Zero by assumption;reflexivity.
Qed.
Lemma allowed_extension_growth old new Allowed:
 allowed_extension old new Allowed ->Zlength old<=Zlength new.
Proof.
 intros[added[-> All]];rewrite Zlength_app;pose proof(Zlength_nonneg added);lia.
Qed.
Theorem loop_shape_overlap a cap seed path prefix g old new oldbuf newbuf xs ys zs pk frames:
 legal_model a ->0<=seed<=model_n a ->ghost_phase g=0%nat ->
 loop_shape a cap seed path(prefix++[g])old oldbuf xs ys zs pk frames ->
 journal_trace(model_n a)(root_mask(model_n a)seed)new newbuf ->
 allowed_extension old new(overlap_allows_all(model_n a)(model_h_rows a)(model_l_rows a)cap xs) ->
 loop_shape a cap seed path(prefix++[g])new newbuf xs ys zs pk frames.
Proof.
 intros Legal Seed Phase Whole NewTrace Ext.
 pose proof(legal_model_ranges a Legal)as[NR[MR[LR[KR Rest]]]].
 pose proof Whole as Shape;unfold loop_shape in Shape.
 destruct Shape as[XL[YL[ZL[PKL[XB[YB[ZB[PKB[Trace[HC[LC[Phys[Geo[Tracks[Sep[Wgt[Before Live]]]]]]]]]]]]]]]]].
 assert(Cap:0<=cap)by lia.
 assert(BaseLen:Zlength(root_mask(model_n a)seed)=model_n a)by(apply root_mask_length;assumption).
 assert(Rold:Forall(fun q:Z=>0<=q<model_n a)old)by(unfold journal_trace in Trace;tauto).
 assert(Rnew:Forall(fun q:Z=>0<=q<model_n a)new)by(unfold journal_trace in NewTrace;tauto).
 assert(Growth:Zlength old<=Zlength new)by(apply(allowed_extension_growth old new _ Ext)).
 pose proof Geo as Geometry;unfold stack_geometry in Geometry.
 destruct Geometry as[Len[ND[Range[Depth Per]]]].
 assert(PathLen:length path=S(length prefix))by(rewrite app_length in Len;cbn[length]in Len;lia).
 assert(Rev:rev(prefix++[g])=g::rev prefix)by(rewrite rev_app_distr;cbn[rev app];reflexivity).
 pose proof Tracks as TrackParts;unfold selected_tracks_stack in TrackParts;rewrite Rev,Phase in TrackParts.
 destruct TrackParts as[Nonempty[Root[NDX[RX[PL Selected]]]]].
 assert(SelectedPrefix:forall i,(i<Z.to_nat(model_n a))%nat ->
 decode xs i=prefix_selected path(length prefix)i).
 { intros i I;rewrite(parent_prefix_all path prefix PathLen);apply Selected;assumption. }
 unfold loop_shape.
 split;[assumption|split;[assumption|split;[assumption|split;[assumption|]]]].
 split;[assumption|split;[assumption|split;[assumption|split;[assumption|]]]].
 split;[assumption|split;[assumption|split;[assumption|split;[assumption|]]]].
 split;[apply(geometry_log_growth _ _ _ _ _ _ old new);assumption|].
 split;[assumption|].
 split.
 - apply(journal_extension_separated(model_n a)(root_mask(model_n a)seed)old new xs
   (overlap_allows_all(model_n a)(model_h_rows a)(model_l_rows a)cap xs));try assumption.
   intros q[Free Safe];assumption.
 - split;[assumption|split;[assumption|]].
   apply(overlap_preserves_live_targets(model_n a)(model_h_rows a)(model_l_rows a)cap
   (Z.to_nat seed)(root_mask(model_n a)seed)old new path prefix g xs);try assumption;try lia.
   apply(geometry_marks(Z.to_nat(model_n a))(Z.to_nat(model_m a))(Z.to_nat cap)
   (model_h_rows a)path(prefix++[g])old Geo).
Qed.
Print Assumptions loop_shape_overlap.
