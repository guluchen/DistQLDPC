(* Lift the unchanged function proofs independently. The external library
   declarations and CompCert layouts depend only on function signatures. *)
Require Import VST.floyd.proofauto.
Require Import CCV.CCLibraryFunctions CCV.CCSearchSpecs CCV.CCSearchContext
 CCV.CCLinkedProgram CCV.CCExpandedBody CCV.ccv_core CCV.VerifDistance.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
Local Ltac lifted L := lazymatch type of L with
 | @semax_body _ _ _ ?f ?spec=>exact(@semax_body CCSearchContext.Vprog linked_Gprog CCSearchSpecs.CompSpecs f spec) end.
Local Ltac prove_lift L :=
 lazymatch type of L with | @semax_body ?V ?G _ _ _ =>
 assert (Sub:tycontext_subVG V G CCSearchContext.Vprog linked_Gprog) by
 (split;
 [apply sub_option_get;
  let a:=fresh in let b:=fresh in set(a:=make_tycontext_g V G);set(b:=make_tycontext_g CCSearchContext.Vprog linked_Gprog);
  compute in a;compute in b;subst a b;repeat(apply Forall_cons;[reflexivity|]);apply Forall_nil
 |apply subsume_spec_get;
  let a:=fresh in let b:=fresh in set(a:=make_tycontext_s G);set(b:=make_tycontext_s linked_Gprog);
  let x:=make_ground_PTree a in change a with x;clear a;
  let x:=make_ground_PTree b in change b with x;clear b;
  repeat(apply Forall_cons;[apply subsumespec_refl|]);apply Forall_nil]);
 apply_semax_body L end.
Lemma lift_body_shape_legal : ltac:(lifted VerifShape.body_shape_legal).
Proof. prove_lift VerifShape.body_shape_legal. Qed.
Lemma lift_body_validate_legal : ltac:(lifted VerifValidate.body_validate_legal).
Proof. prove_lift VerifValidate.body_validate_legal. Qed.
Lemma lift_body_clear : ltac:(lifted VerifClear.body_clear).
Proof. prove_lift VerifClear.body_clear. Qed.
Lemma lift_body_core_toggle : ltac:(lifted VerifCoreToggle.body_core_toggle).
Proof. prove_lift VerifCoreToggle.body_core_toggle. Qed.
Lemma lift_body_nontrivial : ltac:(lifted VerifNontrivial.body_nontrivial).
Proof. prove_lift VerifNontrivial.body_nontrivial. Qed.
Lemma lift_body_restore : ltac:(lifted VerifRestore.body_restore).
Proof. prove_lift VerifRestore.body_restore. Qed.
Lemma lift_body_forbid : ltac:(lifted VerifForbid.body_forbid).
Proof. prove_lift VerifForbid.body_forbid. Qed.
Lemma lift_body_overlap : ltac:(lifted VerifOverlap.body_overlap).
Proof. prove_lift VerifOverlap.body_overlap. Qed.
Lemma lift_body_bounds : ltac:(lifted VerifBounds.body_bounds).
Proof. prove_lift VerifBounds.body_bounds. Qed.
Lemma lift_body_leaf : ltac:(lifted VerifLeaf.body_leaf).
Proof. prove_lift VerifLeaf.body_leaf. Qed.
Lemma lift_body_decide_modular : ltac:(lifted VerifDecide.body_decide_modular).
Proof. prove_lift VerifDecide.body_decide_modular. Qed.
Lemma lift_body_bit_xor : ltac:(lifted VerifPrimitives.body_bit_xor).
Proof. prove_lift VerifPrimitives.body_bit_xor. Qed.
Lemma lift_body_ceil_div : ltac:(lifted VerifPrimitives.body_ceil_div).
Proof. prove_lift VerifPrimitives.body_ceil_div. Qed.
Lemma lift_body_dot : ltac:(lifted VerifDot.body_dot).
Proof. prove_lift VerifDot.body_dot. Qed.
Lemma lift_body_weight : ltac:(lifted VerifWeight.body_weight).
Proof. prove_lift VerifWeight.body_weight. Qed.
Lemma lift_body_toggle : ltac:(lifted VerifToggle.body_toggle).
Proof. prove_lift VerifToggle.body_toggle. Qed.
Lemma lift_search c (body:@semax_body CCSearchContext.Vprog CCSearchContext.Gprog CCSearchSpecs.CompSpecs (with_body f_search c) search_spec):ltac:(lifted body).
Proof. prove_lift body. Qed.
Lemma lift_distance c (body:@semax_body VerifDistance.Vprog VerifDistance.Gprog VerifDistance.CompSpecs (with_body f_ccv_distance c) distance_spec):ltac:(lifted body).
Proof. prove_lift body. Qed.
