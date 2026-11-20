(* Pure facts linking the phase0 path, cached tests and safe finish conditions.
   Actual complete phase0 C caller composition remains separate. *)
Require Import VST.floyd.proofauto.
Require Import CCV.CCModel CCV.CCFunctional CCV.CCCache CCV.CCSearchSpecs
 CCV.CCStackInvariant CCV.CCLoopInvariant CCV.CCSearchPhases CCV.CCPushCoverage
 CCV.CCResumeCoverage CCV.CCFrameUpdates CCV.CCRepresentation CCV.CCMatrixModel
 CCV.CCRootArray CCV.CCSearchResults CCV.CCPhaseZero CCV.CCAPIBridge CCV.VerifNontrivial.
Import ListNotations. Open Scope Z_scope.
Theorem phase_zero_path_facts a cap seed path prefix g log buf xs ys zs pk frames:
 ghost_phase g=0%nat ->loop_shape a cap seed path(prefix++[g])log buf xs ys zs pk frames ->
 path<>[] /\output_weight a xs=Z.of_nat(length path) /\
 (forall i,(i<Z.to_nat(model_n a))%nat ->decode xs i=prefix_selected path(length prefix)i) /\
 0<Z.of_nat(length path)<=cap.
Proof.
 intros Phase Whole.
 assert(Tracks:selected_tracks_stack(Z.to_nat(model_n a))(Z.to_nat seed)path(prefix++[g])xs)
 by(unfold loop_shape in Whole;tauto).
 assert(Len:length path=length(prefix++[g]))by(unfold loop_shape,stack_geometry in Whole;tauto).
 assert(Wgt:0<output_weight a xs<=cap)by(unfold loop_shape,output_weight in Whole |- *;tauto).
 unfold selected_tracks_stack in Tracks;rewrite rev_app_distr in Tracks;cbn[rev app]in Tracks.
 destruct Tracks as[Nonempty[Root State]];rewrite Phase in State.
 pose proof(proj1(phase_path_weight _ _ _ _ _ _ State)(or_introl eq_refl))as Weight.
 assert(Eq:output_weight a xs=Z.of_nat(length path))by(unfold output_weight;rewrite Weight;reflexivity).
 split;[assumption|split;[assumption|split]].
 - destruct State as[ND[Range[PL Selected]]].
   intros i I;rewrite(parent_prefix_all path prefix ltac:(rewrite app_length in Len;cbn[length]in Len;lia));apply Selected;assumption.
 - rewrite <-Eq;assumption.
Qed.
Lemma logical_cache_has_nonzero n l lg xs zs:
 0<=l ->Zlength zs=l ->cached n l xs zs lg ->
 CCModel.logical(Z.to_nat n)(matrix_vectors n l lg)(decode xs) ->has_nonzero zs=true.
Proof.
 intros L Len Cache Logical;apply(matrix_logical_indexed n l lg(decode xs)L)in Logical.
 destruct Logical as[i[I Hit]].
 apply(indexed_nonzero_exists zs i ltac:(lia)).
 pose proof(Cache i I)as Eq;rewrite Hit in Eq;cbn in Eq;lia.
Qed.
Lemma cached_odd_row_not_good a xs ys row:
 0<=model_m a ->cached(model_n a)(model_m a)xs ys(model_h a) ->
 0<=row<model_m a ->Znth row ys=1 ->~model_good a(decode xs).
Proof.
 intros M Cache Row One[Pos[Ker Log]].
 unfold model_h_rows in Ker.
 pose proof(proj1(matrix_kernel_indexed(model_n a)(model_m a)(model_h a)(decode xs)M)Ker)as KerRows.
 pose proof(KerRows row Row)as Even;pose proof(Cache row Row)as Eq.
 rewrite Even,One in Eq;cbn in Eq;discriminate.
Qed.
Theorem zero_kernel_trivial_no_critical_top a cap seed path prefix g log buf xs ys zs pk frames:
 legal_model a ->ghost_phase g=0%nat ->
 loop_shape a cap seed path(prefix++[g])log buf xs ys zs pk frames ->
 (forall i,0<=i<model_m a ->Znth i ys=0) ->has_nonzero zs=false ->
 forall e,model_minimum a e ->
 ~critical_at(Z.to_nat(model_n a))(model_h_rows a)(root_mask(model_n a)seed)log
 path(prefix++[g])e(length prefix).
Proof.
 intros Legal Phase Whole Zero Trivial e Min[gk[At Critical]].
 pose proof(phase_zero_path_facts a cap seed path prefix g log buf xs ys zs pk frames Phase Whole)
 as[Nonempty[Weight[Selected Wgt]]].
 pose proof(legal_model_ranges a Legal)as[NR[MR[LR[KR Rest]]]].
 assert(HC:cached(model_n a)(model_m a)xs ys(model_h a))by(unfold loop_shape in Whole;tauto).
 assert(LC:cached(model_n a)(model_l a)xs zs(model_lg a))by(unfold loop_shape in Whole;tauto).
 assert(ZL:Zlength zs=model_l a)by(unfold loop_shape in Whole;tauto).
 rewrite old_last in At;inversion At;subst gk.
 cbv zeta in Critical;rewrite Phase in Critical;destruct Critical as[Sub Avoid].
 assert(SubXS:subset(Z.to_nat(model_n a))(decode xs)e).
 { intros i I Hit;apply Sub;[assumption|rewrite <-Selected by assumption;assumption]. }
 pose proof(cache_zero_is_kernel(model_n a)(model_m a)(model_h a)xs ys MR HC Zero)as Ker.
 destruct(minimum_prefix_kernel_closes(Z.to_nat(model_n a))(model_h_rows a)(model_l_rows a)
 e(decode xs)Min SubXS ltac:(unfold output_weight in Weight;lia)Ker)as[Good Same].
 destruct Good as[Pos[Kernel Logical]].
 unfold model_l_rows in Logical.
 pose proof(logical_cache_has_nonzero(model_n a)(model_l a)(model_lg a)xs zs LR ZL LC Logical);
 congruence.
Qed.
Theorem no_room_unfinished_no_critical_top a cap seed path prefix g log buf xs ys zs pk frames:
 ghost_phase g=0%nat ->loop_shape a cap seed path(prefix++[g])log buf xs ys zs pk frames ->
 ~model_good a(decode xs) ->cap<=output_weight a xs ->
 forall e,model_minimum a e ->(weight(Z.to_nat(model_n a))e<=Z.to_nat cap)%nat ->
 ~critical_at(Z.to_nat(model_n a))(model_h_rows a)(root_mask(model_n a)seed)log
 path(prefix++[g])e(length prefix).
Proof.
 intros Phase Whole Unfinished Full e Min Within[gk[At Critical]].
 pose proof(phase_zero_path_facts a cap seed path prefix g log buf xs ys zs pk frames Phase Whole)
 as[Nonempty[Weight[Selected Wgt]]].
 assert(Cap:0<=cap)by lia.
 rewrite old_last in At;inversion At;subst gk.
 cbv zeta in Critical;rewrite Phase in Critical;destruct Critical as[Sub Avoid].
 assert(SubXS:subset(Z.to_nat(model_n a))(decode xs)e).
 { intros i I Hit;apply Sub;[assumption|rewrite <-Selected by assumption;assumption]. }
 pose proof(unfinished_prefix_is_proper(Z.to_nat(model_n a))(model_h_rows a)(model_l_rows a)
 e(decode xs)Min SubXS Unfinished)as Proper.
 apply Nat2Z.inj_lt in Proper;apply Nat2Z.inj_le in Within;rewrite Z2Nat.id in Within by assumption.
 unfold output_weight in Full;lia.
Qed.
Print Assumptions phase_zero_path_facts.
Print Assumptions zero_kernel_trivial_no_critical_top.
Print Assumptions no_room_unfinished_no_critical_top.
