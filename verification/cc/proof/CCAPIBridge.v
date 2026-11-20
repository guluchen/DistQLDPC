(* Representation/range lemmas for the actual API call sites.
   These do not establish the three unproved search/API C bodies. *)
Require Import VST.floyd.proofauto.
Require Import CCV.CCModel CCV.CCValidation CCV.CCRepresentation CCV.VerifToggle CCV.CCFunctional CCV.VerifWeight CCV.CCSearchSpecs CCV.VerifShape CCV.VerifValidate CCV.VerifStats CCV.VerifClear CCV.CCWeightBridge.
Import ListNotations.
Open Scope Z_scope.
Definition zero_stats :stats_model :=
 {|stat_steps:=0;stat_nodes:=0;stat_pack:=0;stat_charge:=0;stat_overlap:=0|}.
Lemma zero_stats_legal budget :0<=budget<=Int.max_unsigned ->legal_stats budget zero_stats.
Proof. intros H;change
 (0<=0<=budget /\budget<=Int.max_unsigned /\0<=0<=0 /\
  0<=0<=0 /\0<=0<=0 /\0<=0<=0);lia. Qed.
Lemma legal_model_ranges a :legal_model a ->
 0<model_n a<=Int.max_signed /\0<=model_m a /\0<=model_l a /\0<=model_k a /\
 (model_m a*model_n a)%Z<=Int.max_signed /\
 (model_l a*model_n a)%Z<=Int.max_signed /\
 (model_k a*model_n a)%Z<=Int.max_signed.
Proof.
 intros[N[M[L[K Rest]]]];change Int.max_signed with 2147483647.
 pose proof(Z.div_mod 2147483647(model_n a)ltac:(lia))as D.
 pose proof(Z.mod_pos_bound 2147483647(model_n a)ltac:(lia))as Mod.
 repeat split;try lia;nia.
Qed.
Lemma legal_model_validation a :legal_model a ->
 VerifValidate.valid_stabilizers(model_n a)(model_m a)(model_l a)(model_k a)
 (model_h a)(model_lg a)(model_g a).
Proof.
 intros[N[M[L[K[Hlen[Llen[Glen[HB[LB[GB Meta]]]]]]]]]].
 unfold VerifValidate.valid_stabilizers,VerifValidate.validation_dot.
 apply GF2_metadata_implies_runtime_dots;try assumption;lia.
Qed.
Lemma zero_bytes_repr n :zero_bytes n=Zrepeat(Vint Int.zero)n.
Proof. unfold zero_bytes,tbytes,Zrepeat;rewrite map_repeat;reflexivity. Qed.
Lemma uchar_default_values n :default_val(tarray tuchar n)=Zrepeat Vundef n.
Proof. reflexivity. Qed.
Lemma output_weight_runtime a out :legal_model a ->Zlength out=model_n a ->
 Forall(fun z:Z=>z=0 \/z=1)out ->ccv_sum out=output_weight a out.
Proof.
 intros Legal Len Bits;rewrite ccv_weight_is_vector_weight by assumption.
 unfold output_weight;rewrite Len;reflexivity.
Qed.
Lemma model_good_positive a e :model_good a e ->0<Z.of_nat(CCModel.weight(Z.to_nat(model_n a))e).
Proof. intros[Pos Rest];lia. Qed.
Lemma model_good_weight_bound a e :0<=model_n a ->
 Z.of_nat(CCModel.weight(Z.to_nat(model_n a))e)<=model_n a.
Proof.
 intros N;pose proof(vector_weight_bound(Z.to_nat(model_n a))e).
 apply Nat2Z.inj_le in H;rewrite Z2Nat.id in H by assumption;assumption.
Qed.
Lemma empty_advances_distance_lower a cap :
 (forall e,model_good a e ->cap<Z.of_nat(CCModel.weight(Z.to_nat(model_n a))e)) ->
 forall e,model_good a e ->cap+1<=Z.of_nat(CCModel.weight(Z.to_nat(model_n a))e).
Proof. intros Empty e Good;pose proof(Empty e Good);lia. Qed.
Lemma found_at_first_cap_minimum a cap out :
 (forall e,model_good a e ->cap<=Z.of_nat(CCModel.weight(Z.to_nat(model_n a))e)) ->
 model_good a out ->Z.of_nat(CCModel.weight(Z.to_nat(model_n a))out)<=cap ->
 model_minimum a out.
Proof.
 intros Lower Good Upper;split;[assumption|].
 intros e GE;pose proof(Lower e GE);lia.
Qed.
Print Assumptions legal_model_ranges.
Print Assumptions legal_model_validation.
Print Assumptions found_at_first_cap_minimum.
