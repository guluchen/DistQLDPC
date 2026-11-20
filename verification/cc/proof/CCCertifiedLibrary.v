(* Actual linked implementation and its certificate-qualified CSS entry.
   All claims are partial correctness/safety; no whole execution termination,
   native PCM constructor, CLI, production C++ or WASM32 claim is made. *)
Require Import VST.floyd.proofauto.
Require Import CCV.ccv_core CCV.CCSearchSpecs CCV.CCSearchContext CCV.CCLinkedProgram
 CCV.CCLibraryFunctions CCV.VerifCertificateDistance CCV.VerifLinkedCertificateAPI.
Import ListNotations.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
Section EntryFunction.
Context{Espec:OracleKind}.
Theorem linked_certified_distance_function:
 semax_func CCSearchContext.Vprog linked_Gprog(Genv.globalenv linked_prog)
 [(ccv_core._ccv_distance,Internal ccv_core.f_ccv_distance)]
 [certified_css_distance_spec].
Proof.
 prove_semax_prog_setup_globalenv.
 assert(SameContext:tycontext_subVG CCSearchContext.Vprog linked_Gprog CCSearchContext.Vprog linked_Gprog).
 { split;intro i;[apply sub_option_refl|apply subsumespec_refl]. }
 linked_func_cons body_distance_certified_linked.
Qed.
Theorem linked_library_with_certified_CSS_entry:
 semax_func CCSearchContext.Vprog linked_Gprog(Genv.globalenv linked_prog)
 (prog_funct linked_prog)linked_Gprog /\
 semax_func CCSearchContext.Vprog linked_Gprog(Genv.globalenv linked_prog)
 [(ccv_core._ccv_distance,Internal ccv_core.f_ccv_distance)]
 [certified_css_distance_spec].
Proof. split;[apply linked_library_functions|apply linked_certified_distance_function]. Qed.
End EntryFunction.
Print Assumptions linked_library_with_certified_CSS_entry.
