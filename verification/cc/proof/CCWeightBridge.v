(* Relate the verified C weight primitive to the mathematical vector weight. *)
Require Import VST.floyd.proofauto.
Require Import CCV.CCModel CCV.CCRepresentation CCV.CCBoundsArray CCV.VerifWeight.
Open Scope Z_scope.
Lemma sum_prefix_decode xs : Forall(fun z:Z=>z=0 \/z=1)xs ->forall k,
 Z.of_nat k<=Zlength xs ->
 ccv_sum(sublist 0(Z.of_nat k)xs)=bitcount(Z.of_nat k)(decode xs).
Proof.
 intros Bits k;induction k as[|k IH];intros Range.
 - change(Z.of_nat 0)with 0;autorewrite with sublist;reflexivity.
 - replace(Z.of_nat(S k))with(Z.of_nat k+1)by lia.
   rewrite(sublist_split 0(Z.of_nat k)(Z.of_nat k+1))by lia.
   assert(K:0<=Z.of_nat k<Zlength xs)by lia.
   rewrite ccv_sum_app,(sublist_one(Z.of_nat k))by lia;rewrite IH by lia.
   rewrite bitcount_step by lia;rewrite Nat2Z.id,decode_at_nat.
   assert(Bit:Znth(Z.of_nat k)xs=0 \/Znth(Z.of_nat k)xs=1)by(apply Forall_Znth;auto;lia).
   rewrite(encode_bit _ Bit);cbn[ccv_sum fold_right];lia.
Qed.
Theorem ccv_weight_is_vector_weight xs : Forall(fun z:Z=>z=0 \/z=1)xs ->
 ccv_sum xs=Z.of_nat(CCModel.weight(Z.to_nat(Zlength xs))(decode xs)).
Proof.
 intros Bits;pose proof(sum_prefix_decode xs Bits (Z.to_nat(Zlength xs))ltac:(rewrite Z2Nat.id by(apply Zlength_nonneg);lia))as Eq.
 rewrite Z2Nat.id in Eq by(apply Zlength_nonneg).
 autorewrite with sublist in Eq;exact Eq.
Qed.
Print Assumptions ccv_weight_is_vector_weight.
