(* Verify a proof-only entry so that VST's exported program soundness rule
   supplies the semantic function library for the original calls. *)
Require Import VST.floyd.proofauto.
Require Import CCV.CCVerificationDriver CCV.CCDriverContext CCV.CCSearchSpecs
 CCV.CCSearchContext CCV.CCLinkedProgram CCV.CCLibraryFunctions.
Import ListNotations.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
Local Transparent tint eval_expr tc_expr force_val.
Section Driver.
Context {Espec:OracleKind} (ora:OK_ty).
Lemma driver_body:semax_body CCSearchContext.Vprog (driver_specs ora) driver_fn (driver_spec ora).
Proof.
 split;[reflexivity|];split;[reflexivity|];intros E ts x.
 eapply semax_pre;[|apply semax_return].
 intro rho.
 match goal with |- ?P |-- _ => change (P |-- TT && ((!! True && TT) * emp)) end.
 rewrite sepcon_emp;repeat apply andp_right;try apply TT_right;apply prop_right;exact I.
Qed.
Lemma driver_app_functions: semax_func CCSearchContext.Vprog (driver_specs ora)
 (Genv.globalenv driver_prog) (prog_funct driver_prog) (driver_specs ora).
Proof.
 rewrite driver_functions. unfold driver_specs at 2. apply semax_func_app.
 - apply existing_driver_functions.
 - prove_semax_prog_setup_globalenv.
   eapply semax_func_cons;[vm_compute;reflexivity|constructor|constructor|reflexivity|LookupID|LookupB|exact driver_body|apply semax_func_nil].
 - reflexivity.
Qed.
Theorem driver_program_verified : semax_prog driver_prog ora CCSearchContext.Vprog (driver_specs ora).
Proof.
 split3;[ | |split3;[ | |split]].
 - vm_compute;reflexivity.
 - vm_compute;reflexivity.
 - change (Maps.PTree.elements (@cenv_cs CCSearchSpecs.CompSpecs)=Maps.PTree.elements (prog_comp_env linked_prog)).
   rewrite linked_composite_env;reflexivity.
 - exact driver_app_functions.
 - reflexivity.
 - change (exists post,main_spec_ext driver_prog ora = main_spec_ext' driver_prog ora post).
   eexists;reflexivity.
Qed.
End Driver.
