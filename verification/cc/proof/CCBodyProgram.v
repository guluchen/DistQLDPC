(* A verification-only library. Only two internal function bodies can vary.
   All exported names, argument layouts and data definitions are retained. *)
Require Import VST.floyd.proofauto compcert.lib.Maps.
Require Import CCV.ccv_core CCV.CCLinkedProgram CCV.CCVerificationDriver CCV.CCExpandedBody.
Import ListNotations.
Section Replacement.
Variables search distance:statement.
Definition replace_def (d:ident * globdef Clight.fundef type) :=
 let '(i,g):=d in
 (i,if Pos.eqb i _search then Gfun (Internal (with_body f_search search))
    else if Pos.eqb i _ccv_distance then Gfun (Internal (with_body f_ccv_distance distance))
    else g).
Definition body_program (p:Clight.program) : Clight.program :=
 {| Ctypes.prog_defs := map replace_def (Ctypes.prog_defs p);
    Ctypes.prog_public := Ctypes.prog_public p; Ctypes.prog_main := Ctypes.prog_main p;
    Ctypes.prog_types := Ctypes.prog_types p; Ctypes.prog_comp_env := Ctypes.prog_comp_env p;
    Ctypes.prog_comp_env_eq := Ctypes.prog_comp_env_eq p |}.
Definition proof_library := body_program linked_prog.
Definition proof_driver := body_program driver_prog.
Lemma proof_driver_functions:prog_funct proof_driver =
 (prog_funct proof_library ++ [(driver_id,Internal driver_fn)])%list.
Proof. reflexivity. Qed.
Lemma replace_def_id d:fst (replace_def d)=fst d.
Proof. destruct d;reflexivity. Qed.
Lemma body_names p:map fst (prog_defs (body_program p))=map fst (prog_defs p).
Proof. change (map fst (map replace_def (prog_defs p))=map fst (prog_defs p)).
 rewrite map_map;apply map_ext;apply replace_def_id. Qed.
End Replacement.
