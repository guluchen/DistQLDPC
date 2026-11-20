(* The caller supplies only the original contracts and original symbol
   environment. The proof-only search does not impose extra heap resources. *)
Require Import VST.floyd.proofauto VST.veric.tycontext.
Require Import CCV.CCOwnedCall CCV.CCBodyProgram CCV.CCBodyLibrary CCV.CCVerificationDriver
 CCV.CCDriverContext CCV.CCReplayEnvironment.
Import ListNotations.
Lemma same_driver_variables s d:prog_vars (proof_driver s d)=prog_vars driver_prog.
Proof. transitivity (@nil (ident*globvar type));vm_compute;reflexivity. Qed.
Lemma driver_world_symbols s d:filter_genv (Clight.globalenv(proof_driver s d))=filter_genv (Clight.globalenv driver_prog).
Proof. extensionality i;apply body_addresses. Qed.
Lemma same_driver_specs {E:OracleKind} s d (z:OK_ty):
 body_specs s d z=driver_specs z.
Proof.
 unfold body_specs,driver_specs,body_main_spec,driver_spec.
 assert (Pre:main_pre (proof_driver s d) z=main_pre driver_prog z).
 { unfold main_pre;rewrite same_driver_variables;reflexivity. }
 unfold main_spec_ext;rewrite Pre;reflexivity.
Qed.
