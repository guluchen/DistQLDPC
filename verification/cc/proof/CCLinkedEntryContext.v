(* Recover the semantic (shallow) library proof through the public soundness
   rule of VST. The appended entry retains every frozen solver definition. *)
Require Import VST.floyd.proofauto VST.floyd.SeparationLogicAsLogicSoundness.
Require Import CCV.CCLibraryEntry CCV.CCSearchSpecs CCV.CCSearchContext
 CCV.CCVerificationDriver CCV.CCDriverContext CCV.CCDriverProgram.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
Lemma actual_library_context {Espec:OracleKind} (ora:OK_ty) :
 library_context Espec CCSearchSpecs.CompSpecs CCSearchContext.Vprog (driver_specs ora) driver_prog.
Proof.
 pose proof (@MainTheorem.CSHL_Sound.semax_prog_sound _ _ _ _ _ _
    (driver_program_verified ora)) as Sound.
 destruct Sound as [NoDup [Align [Env [Funcs [Vars Main]]]]];constructor;assumption.
Qed.
Print Assumptions actual_library_context.
