(* Actual leaf candidate hit discharges the complete FOUND caller's mathematical
   and byte-representation obligations at one unit of remaining weight. *)
Require Import VST.floyd.proofauto.
Require Import CCV.CCModel CCV.CCFunctional CCV.CCSearchSpecs CCV.CCRepresentation
 CCV.CCLoopInvariant CCV.CCStackInvariant CCV.CCPhaseZeroFacts CCV.CCLeaf CCV.CCLeafSound
 CCV.CCResumeInvariant CCV.CCJournalArray CCV.CCRootArray CCV.CCAPIBridge CCV.VerifPhaseOneTail.
Import ListNotations. Open Scope Z_scope.
Theorem phase0_leaf_hit a cap seed path prefix g log buf xs ys zs pk frames chosen:
 legal_model a ->ghost_phase g=0%nat ->
 loop_shape a cap seed path(prefix++[g])log buf xs ys zs pk frames ->
 cap-Z.of_nat(length path)=1 ->0<=chosen<model_n a ->
 leaf_candidate(model_n a)(model_m a)(model_l a)xs(journal_bitmap(root_mask(model_n a)seed)log)
 ys zs(model_h a)(model_lg a)chosen=true ->
 model_good a(decode(chosen_xs chosen xs)) /\output_weight a(chosen_xs chosen xs)<=cap /\
 Zlength(chosen_xs chosen xs)=model_n a /\Forall(fun z:Z=>z=0\/z=1)(chosen_xs chosen xs).
Proof.
 intros Legal Phase Whole One Q Hit.
 pose proof(legal_model_ranges a Legal)as[NR[MR[LR[KR Rest]]]].
 pose proof(phase_zero_path_facts a cap seed path prefix g log buf xs ys zs pk frames Phase Whole)
 as[Nonempty[OldWeight More]].
 assert(XL:Zlength xs=model_n a)by(unfold loop_shape in Whole;tauto).
 assert(XB:Forall(fun z:Z=>z=0\/z=1)xs)by(unfold loop_shape in Whole;tauto).
 assert(HC:cached(model_n a)(model_m a)xs ys(model_h a))by(unfold loop_shape in Whole;tauto).
 assert(LC:cached(model_n a)(model_l a)xs zs(model_lg a))by(unfold loop_shape in Whole;tauto).
 destruct Legal as[DimN[DimM[DimL[DimK[HL[LL[GL[HB[LB[GB Meta]]]]]]]]]].
 destruct(numeric_leaf_sound(model_n a)(model_m a)(model_l a)chosen xs
 (journal_bitmap(root_mask(model_n a)seed)log)ys zs(model_h a)(model_lg a)
 (proj1 NR)MR LR Q XL HL LL XB HB LB HC LC Hit)as[Good NewWeight].
 split;[exact Good|split].
 - assert(W:output_weight a(chosen_xs chosen xs)=output_weight a xs+1).
   { unfold output_weight,chosen_xs;rewrite NewWeight,Nat2Z.inj_add;reflexivity. }
   lia.
 - split.
   + unfold chosen_xs;rewrite upd_Znth_Zlength by lia;assumption.
   + apply(chosen_xs_binary(model_n a)chosen xs);assumption.
Qed.
Print Assumptions phase0_leaf_hit.
