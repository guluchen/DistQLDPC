(* Full loop-shape caller fact: a unit-budget numeric leaf miss has no live
   critical top frame. This justifies pop; it is not the complete C caller. *)
Require Import VST.floyd.proofauto.
Require Import CCV.CCModel CCV.CCFunctional CCV.CCSearchSpecs CCV.CCStackInvariant
 CCV.CCLoopInvariant CCV.CCPhaseZeroFacts CCV.CCLeafExhaustion CCV.CCLeaf
 CCV.CCRepresentation CCV.CCJournalArray CCV.CCJournalTrace CCV.CCRootArray
 CCV.CCResumeCoverage CCV.CCFrameUpdates CCV.CCAPIBridge.
Import ListNotations. Open Scope Z_scope.
Theorem leaf_miss_no_critical_top a cap seed path prefix g log buf xs ys zs pk frames:
 legal_model a ->0<=seed<=model_n a ->ghost_phase g=0%nat ->
 loop_shape a cap seed path(prefix++[g])log buf xs ys zs pk frames ->
 ~model_good a(decode xs) ->output_weight a xs+1=cap ->
 (forall q,0<=q<model_n a ->
 leaf_candidate(model_n a)(model_m a)(model_l a)xs
 (journal_bitmap(root_mask(model_n a)seed)log)ys zs(model_h a)(model_lg a)q=false) ->
 forall e,model_minimum a e ->(weight(Z.to_nat(model_n a))e<=Z.to_nat cap)%nat ->
 ~critical_at(Z.to_nat(model_n a))(model_h_rows a)(root_mask(model_n a)seed)log
 path(prefix++[g])e(length prefix).
Proof.
 intros Legal Seed Phase Whole Unfinished One Miss e Min Within[gk[At Critical]].
 pose proof(legal_model_ranges a Legal)as[NR[MR[LR[KR Rest]]]].
 pose proof(phase_zero_path_facts a cap seed path prefix g log buf xs ys zs pk frames Phase Whole)
 as[Nonempty[Weight[Selected Wgt]]].
 rewrite old_last in At;inversion At;subst gk.
 cbv zeta in Critical;rewrite Phase,snapshot_top in Critical.
 destruct Critical as[Sub Avoid].
 assert(Compat:compatible(Z.to_nat(model_n a))e(decode xs)
 (decode(journal_bitmap(root_mask(model_n a)seed)log))).
 { split;[|assumption]. intros i I Hit;apply Sub;[assumption|rewrite <-Selected by assumption;assumption]. }
 assert(XL:Zlength xs=model_n a)by(unfold loop_shape in Whole;tauto).
 assert(XB:Forall(fun z:Z=>z=0\/z=1)xs)by(unfold loop_shape in Whole;tauto).
 assert(HC:cached(model_n a)(model_m a)xs ys(model_h a))by(unfold loop_shape in Whole;tauto).
 assert(LC:cached(model_n a)(model_l a)xs zs(model_lg a))by(unfold loop_shape in Whole;tauto).
 assert(Trace:journal_trace(model_n a)(root_mask(model_n a)seed)log buf)by(unfold loop_shape in Whole;tauto).
 assert(LogRange:Forall(fun q:Z=>0<=q<model_n a)log)by(unfold journal_trace in Trace;tauto).
 assert(BaseLen:Zlength(root_mask(model_n a)seed)=model_n a)by(apply root_mask_length;assumption).
 assert(FL:Zlength(journal_bitmap(root_mask(model_n a)seed)log)=model_n a)
 by(apply journal_bitmap_length;assumption).
 assert(FB:Forall(fun z:Z=>z=0\/z=1)(journal_bitmap(root_mask(model_n a)seed)log))
 by(apply journal_bitmap_bits;apply root_mask_bits;assumption).
 destruct Legal as[DimN[DimM[DimL[DimK[HL[LL[GL[HB[LB[GB Meta]]]]]]]]]].
 apply(numeric_leaf_exhaustion(model_n a)(model_m a)(model_l a)(model_h a)(model_lg a)
 xs(journal_bitmap(root_mask(model_n a)seed)log)ys zs cap e);try assumption;lia.
Qed.
Print Assumptions leaf_miss_no_critical_top.
