(* Single entry point for the verified CC kernel. The VST library and CSS
   contract refer to the same frozen function as the termination theorem. *)
Require Import VST.floyd.proofauto compcert.cfrontend.Clight compcert.common.Smallstep.
Require Import CCV.ccv_core CCV.CCLinkedProgram CCV.CCSearchContext CCV.CCSearchSpecs
 CCV.CCCertifiedLibrary CCV.VerifCertificateDistance CCV.CCUniqueExecution
 CCV.CCFramedInternal CCV.CCOwnedSolver CCV.CCPublicTermination.
Import ListNotations.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
Theorem certified_kernel_contract_and_termination {E:OracleKind} (z:OK_ty):
 semax_prog.postcondition_allows_exit E tint ->
 semax_func CCSearchContext.Vprog linked_Gprog (Genv.globalenv linked_prog)
 (prog_funct linked_prog) linked_Gprog /\
 semax_func CCSearchContext.Vprog linked_Gprog (Genv.globalenv linked_prog)
 [(ccv_core._ccv_distance,Internal ccv_core.f_ccv_distance)] [certified_css_distance_spec] /\
 forall entry args m,owns_entry z entry args m ->
 let ge:=Clight.globalenv linked_prog in
 let start:=Callstate (Internal(entry_function entry)) args Kstop m in
 exists v m',(exists t,star step2 ge start t (Returnstate v Kstop m')) /\
 (forall t fin,star step2 ge start t fin ->terminal_state ge fin ->fin=Returnstate v Kstop m') /\
 (forall T,~forever step2 ge start T).
Proof.
 intro Exit;destruct (@linked_library_with_certified_CSS_entry E) as [Library CSS].
 split;[exact Library|split;[exact CSS|]];intros entry args m Owned;
 exact (all_original_executions_return z entry args m Exit Owned).
Qed.
Print Assumptions certified_kernel_contract_and_termination.
