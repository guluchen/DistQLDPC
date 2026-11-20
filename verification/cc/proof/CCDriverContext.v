(* Retain the original library proof when adding the verification entry. *)
Require Import VST.floyd.proofauto.
Require Import CCV.CCVerificationDriver CCV.CCSearchSpecs CCV.CCSearchContext CCV.CCLinkedProgram
 CCV.CCLibraryFunctions.
Import ListNotations.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
Section Driver.
Context {Espec:OracleKind} (ora:OK_ty).
Definition driver_spec : ident*funspec := (driver_id,main_spec_ext driver_prog ora).
Definition driver_specs : funspecs := linked_Gprog ++ [driver_spec].
Lemma driver_no_duplicate_specs : list_norepet (map fst CCSearchContext.Vprog ++ map fst driver_specs).
Proof. apply compute_list_norepet_e;vm_compute;reflexivity. Qed.
Lemma old_no_duplicate_specs : list_norepet (map fst linked_Gprog).
Proof. apply compute_list_norepet_e;vm_compute;reflexivity. Qed.
Lemma driver_context_extends : tycontext_subVG CCSearchContext.Vprog linked_Gprog CCSearchContext.Vprog driver_specs.
Proof.
 split;intro i.
 - apply make_tycontext_g_app1;[apply old_no_duplicate_specs|apply driver_no_duplicate_specs].
 - apply subsumespec_app1.
Qed.
Lemma existing_driver_functions :
 semax_func CCSearchContext.Vprog driver_specs (Genv.globalenv driver_prog) (prog_funct linked_prog) linked_Gprog.
Proof.
 eapply semax_func_subsumption with (V:=CCSearchContext.Vprog) (F:=linked_Gprog).
 - exact (tycontext_sub_i99 (Clight.mkfunction Tvoid cc_default [] [] [] Sskip) _ _ _ _ [] driver_context_extends).
 - apply (proj1 driver_context_extends).
 - eapply semax_func_mono;[apply cspecs_sub_refl|apply driver_keeps_symbols|apply driver_keeps_functions|].
   apply linked_library_functions.
Qed.
End Driver.
