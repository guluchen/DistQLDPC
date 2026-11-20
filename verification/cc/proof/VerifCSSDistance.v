(* Refine the implemented generic API to the CSS interpretation. Full stabilizer
   rows are ghost reference data; completeness/commutation are preconditions.
   This does not verify their constructor, total termination or production C++. *)
Require Import VST.floyd.proofauto.
Require Import CCV.ccv_core CCV.CCSearchSpecs CCV.CCCSSSpecs CCV.CCCSSResultBridge CCV.VerifDistance.
Import ListNotations. Open Scope Z_scope.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
Lemma distance_css_sub:funspec_sub(snd CCSearchSpecs.distance_spec)(snd css_distance_spec).
Proof.
 do_funspec_sub.
 destruct w as [[[[[[a p]dp]sh]budget]rules]same]. cbn[fst snd];normalize.
 Exists(a,p,dp,sh,budget,rules)emp. apply andp_right.
 - entailer!;cancel.
 - apply prop_right. intros rho';normalize.
   lazymatch goal with
   | HM:minimum_result a ?ret ?out ?d,HS:legal_stats budget ?s |- _ =>
     pose proof(minimum_result_is_css a same ret out d ltac:(assumption)HM)as Css;
     Exists ret out d s
   end.
   entailer!;cancel.
Qed.
Theorem body_distance_css: @semax_body VerifDistance.Vprog VerifDistance.Gprog
 VerifDistance.CompSpecs ccv_core.f_ccv_distance css_distance_spec.
Proof.
 eapply semax_body_funspec_sub.
 - exact VerifDistance.body_distance_modular.
 - exact distance_css_sub.
 - vm_compute. repeat(apply list_norepet_cons;[simpl;intuition congruence|]);apply list_norepet_nil.
Qed.
Print Assumptions distance_css_sub.
Print Assumptions body_distance_css.
