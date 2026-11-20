(* The CSS certificate API in the actual linked library specification context.
   Partial correctness only; no constructor or total-termination theorem. *)
Require Import VST.floyd.proofauto.
Require Import CCV.ccv_core CCV.CCSearchSpecs CCV.CCSearchContext CCV.CCLinkedProgram
 CCV.CCLibraryFunctions CCV.VerifDistance CCV.VerifCertificateDistance.
Import ListNotations.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
(* The ground-PTree environment proof follows VST2.14 floyd/forward.v
   try_prove_tycontext_subVG, instantiated outside a semax_func goal. *)
Lemma distance_linked_environment:
 tycontext_subVG VerifDistance.Vprog VerifDistance.Gprog CCSearchContext.Vprog linked_Gprog.
Proof.
 split.
 - apply sub_option_get.
   let A1:=fresh in let A2:=fresh in
   set(A1:=make_tycontext_g VerifDistance.Vprog VerifDistance.Gprog);
   set(A2:=make_tycontext_g CCSearchContext.Vprog linked_Gprog);
   compute in A1;compute in A2;subst A1 A2;
   repeat(apply Forall_cons;[reflexivity|]);apply Forall_nil.
 - apply subsume_spec_get.
   let A1:=fresh in let A2:=fresh in
   set(A1:=make_tycontext_s VerifDistance.Gprog);
   set(A2:=make_tycontext_s linked_Gprog);
   let a:=make_ground_PTree A1 in change A1 with a;clear A1;
   let a:=make_ground_PTree A2 in change A2 with a;clear A2;
   repeat(apply Forall_cons;[apply subsumespec_refl|]);apply Forall_nil.
Qed.
Lemma body_distance_linked:semax_body CCSearchContext.Vprog linked_Gprog
 ccv_core.f_ccv_distance CCSearchSpecs.distance_spec.
Proof.
 pose proof distance_linked_environment as Sub.
 apply_semax_body VerifDistance.body_distance_modular.
Qed.
Theorem body_distance_certified_linked:semax_body CCSearchContext.Vprog linked_Gprog
 ccv_core.f_ccv_distance certified_css_distance_spec.
Proof.
 eapply semax_body_funspec_sub.
 - exact body_distance_linked.
 - exact distance_certificate_sub.
 - vm_compute. repeat(apply list_norepet_cons;[simpl;intuition congruence|]);apply list_norepet_nil.
Qed.
Print Assumptions body_distance_linked.
Print Assumptions body_distance_certified_linked.
