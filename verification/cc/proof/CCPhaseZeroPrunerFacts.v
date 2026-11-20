(* Concrete legal-model instantiations of all-target phase0 pruning contracts. *)
Require Import VST.floyd.proofauto.
Require Import CCV.CCModel CCV.CCFunctional CCV.CCValidation CCV.CCSearchSpecs CCV.CCRepresentation
 CCV.CCMatrixModel CCV.CCLoopInvariant CCV.CCStackInvariant CCV.CCPhaseZeroFacts
 CCV.CCSearchPolicies CCV.CCOverlapArray CCV.CCBoundsArray CCV.CCBoundsPolicy CCV.CCBoundsLoop
 CCV.CCJournalArray CCV.CCJournalTrace CCV.CCRootArray CCV.CCPushScan CCV.CCAPIBridge.
Import ListNotations. Open Scope Z_scope.
Lemma loop_bitmap_facts a cap seed path ghosts log buf xs ys zs pk frames:
 legal_model a ->0<=seed<=model_n a ->
 loop_shape a cap seed path ghosts log buf xs ys zs pk frames ->
 Zlength(root_mask(model_n a)seed)=model_n a /\
 Forall(fun z:Z=>z=0\/z=1)(root_mask(model_n a)seed)/\
 Zlength(journal_bitmap(root_mask(model_n a)seed)log)=model_n a /\
 Forall(fun z:Z=>z=0\/z=1)(journal_bitmap(root_mask(model_n a)seed)log).
Proof.
 intros Legal Seed Whole.
 assert(Trace:journal_trace(model_n a)(root_mask(model_n a)seed)log buf)by(unfold loop_shape in Whole;tauto).
 assert(Range:Forall(fun q:Z=>0<=q<model_n a)log)by(unfold journal_trace in Trace;tauto).
 assert(Len:Zlength(root_mask(model_n a)seed)=model_n a)by(apply root_mask_length;assumption).
 assert(Bits:Forall(fun z:Z=>z=0\/z=1)(root_mask(model_n a)seed))by(apply root_mask_bits;assumption).
 split;[assumption|split;[assumption|split]].
 - apply journal_bitmap_length;assumption.
 - apply journal_bitmap_bits;assumption.
Qed.
Theorem phase0_bounds_policy a cap seed path prefix g log buf xs ys zs pk frames:
 legal_model a ->0<=seed<=model_n a ->ghost_phase g=0%nat ->
 loop_shape a cap seed path(prefix++[g])log buf xs ys zs pk frames ->
 bounds_policy(model_n a)(model_m a)(model_h a)xs(journal_bitmap(root_mask(model_n a)seed)log)ys
 (cap-Z.of_nat(length path))
 (bounds_rejects_all(model_n a)(model_m a)(model_h a)(model_l_rows a)cap xs(journal_bitmap(root_mask(model_n a)seed)log)).
Proof.
 intros Legal Seed Phase Whole.
 pose proof(legal_model_ranges a Legal)as[NR[MR More]].
 destruct(loop_bitmap_facts a cap seed path(prefix++[g])log buf xs ys zs pk frames Legal Seed Whole)
 as[BL[BB[FL FB]]].
 pose proof(phase_zero_path_facts a cap seed path prefix g log buf xs ys zs pk frames Phase Whole)
 as[Nonempty[Weight MoreFacts]].
 apply universal_bounds_policy;try assumption;try lia;try(unfold loop_shape in Whole;tauto).
 unfold output_weight in Weight;lia.
Qed.
Theorem phase0_overlap_policy a cap seed path prefix g log buf xs ys zs pk frames:
 legal_model a ->loop_shape a cap seed path(prefix++[g])log buf xs ys zs pk frames ->
 overlap_policy(model_n a)(model_k a)xs(model_g a)
 (overlap_rejects_all(model_n a)(model_h_rows a)(model_l_rows a)cap xs)
 (overlap_allows_all(model_n a)(model_h_rows a)(model_l_rows a)cap xs).
Proof.
 intros Legal Whole.
 pose proof(legal_model_ranges a Legal)as[NR[MR[LR[KR Rest]]]].
 assert(XL:Zlength xs=model_n a)by(unfold loop_shape in Whole;tauto).
 assert(XB:Forall(fun z:Z=>z=0\/z=1)xs)by(unfold loop_shape in Whole;tauto).
 assert(GL:Zlength(model_g a)=model_k a*model_n a)by(unfold legal_model in Legal;tauto).
 assert(GB:Forall(fun z:Z=>z=0\/z=1)(model_g a))by(unfold legal_model in Legal;tauto).
 assert(Meta:kernel_metadata(model_n a)(model_m a)(model_l a)(model_k a)(model_h a)(model_lg a)(model_g a))
 by(unfold legal_model in Legal;tauto).
 apply universal_overlap_policy;try assumption;try lia.
 intros i I;destruct(Meta i I)as[H L].
 apply matrix_stabilizer_valid;assumption.
Qed.
Theorem phase0_cached_odd_row a cap seed path prefix g log buf xs ys zs pk frames row:
 legal_model a ->ghost_phase g=0%nat ->
 loop_shape a cap seed path(prefix++[g])log buf xs ys zs pk frames ->
 0<=row<model_m a ->Znth row ys<>0 ->
 parity(Z.to_nat(model_n a))(nth(Z.to_nat row)(model_h_rows a)zero_vector)
 (prefix_selected path(length prefix))=true.
Proof.
 intros Legal Phase Whole Row Odd.
 pose proof(legal_model_ranges a Legal)as[NR[MR More]].
 pose proof(phase_zero_path_facts a cap seed path prefix g log buf xs ys zs pk frames Phase Whole)
 as[Nonempty[Weight[Selected Rest]]].
 assert(HC:cached(model_n a)(model_m a)xs ys(model_h a))by(unfold loop_shape in Whole;tauto).
 assert(R:(Z.to_nat row<Z.to_nat(model_m a))%nat)by(apply Z2Nat.inj_lt;lia).
 unfold model_h_rows;rewrite matrix_vectors_nth by assumption;rewrite Z2Nat.id by lia.
 rewrite <-(CCFunctional.parity_ext(Z.to_nat(model_n a))(row_vector(model_n a)row(model_h a))
 (decode xs)(prefix_selected path(length prefix))Selected).
 pose proof(HC row Row)as Eq;unfold bitZ in Eq.
 destruct(parity(Z.to_nat(model_n a))(row_vector(model_n a)row(model_h a))(decode xs));congruence.
Qed.
Print Assumptions phase0_bounds_policy.
Print Assumptions phase0_overlap_policy.
Print Assumptions phase0_cached_odd_row.
