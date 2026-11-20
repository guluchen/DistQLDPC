(* A zero-argument entry for the VST soundness interface, appended after
   every original definition. It has no calls and cannot affect a solver call. *)
Require Import VST.floyd.proofauto.
Require Import compcert.lib.Maps compcert.common.Globalenvs.
Require Import CCV.ccv_core CCV.CCLinkedProgram CCV.CCSearchSpecs CCV.CCSearchContext.
Import ListNotations.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
Definition driver_id := ccv_core._main.
Definition driver_fn := Clight.mkfunction tint cc_default [] [] [] (Sreturn (Some (Econst_int Int.zero tint))).
Definition driver_def : ident * globdef Clight.fundef type := (driver_id,Gfun (Internal driver_fn)).
Definition driver_prog : Clight.program :=
 {| Ctypes.prog_defs := Ctypes.prog_defs linked_prog ++ [driver_def];
    Ctypes.prog_public := Ctypes.prog_public linked_prog;
    Ctypes.prog_main := driver_id;
    Ctypes.prog_types := Ctypes.prog_types linked_prog;
    Ctypes.prog_comp_env := Ctypes.prog_comp_env linked_prog;
    Ctypes.prog_comp_env_eq := Ctypes.prog_comp_env_eq linked_prog |}.
Lemma driver_symbol_fresh : Genv.find_symbol (Genv.globalenv linked_prog) driver_id=None.
Proof. vm_compute;reflexivity. Qed.
Local Opaque linked_prog.
Lemma driver_global_extension : Genv.globalenv driver_prog =
 Genv.add_global (Genv.globalenv linked_prog) driver_def.
Proof.
 unfold Genv.globalenv at 1.
 change (Genv.add_globals (Genv.empty_genv Clight.fundef type (prog_public linked_prog)) (prog_defs linked_prog++[driver_def])=Genv.add_global (Genv.globalenv linked_prog) driver_def).
 exact (Genv.add_globals_app [driver_def] (prog_defs linked_prog)
   (Genv.empty_genv Clight.fundef type (prog_public linked_prog))).
Qed.
Lemma driver_keeps_symbols i : sub_option (Genv.find_symbol (Genv.globalenv linked_prog) i)
                                          (Genv.find_symbol (Genv.globalenv driver_prog) i).
Proof.
 rewrite driver_global_extension. destruct (peq i driver_id) as [->|Different].
 - rewrite driver_symbol_fresh; exact I.
 - unfold Genv.find_symbol;cbn [Genv.add_global Genv.genv_symb fst driver_def].
   rewrite PTree.gso by assumption;apply sub_option_refl.
Qed.
Lemma driver_keeps_functions b : sub_option (Genv.find_funct_ptr (Genv.globalenv linked_prog) b)
                                            (Genv.find_funct_ptr (Genv.globalenv driver_prog) b).
Proof.
 rewrite driver_global_extension. destruct (Genv.find_funct_ptr (Genv.globalenv linked_prog) b) as [fd|] eqn:Old;[|exact I].
 apply Genv.find_funct_ptr_iff in Old.
 pose proof (Genv.genv_defs_range _ _ Old) as Earlier.
 assert (New: Genv.find_funct_ptr (Genv.add_global (Genv.globalenv linked_prog) driver_def) b=Some fd).
 { apply Genv.find_funct_ptr_iff. unfold Genv.find_def in *;cbn [Genv.add_global Genv.genv_defs fst snd driver_def].
   rewrite PTree.gso;[exact Old|intro Eq;subst;apply (Pos.lt_irrefl _ Earlier)]. }
 rewrite New;apply sub_option_refl.
Qed.
Lemma driver_functions : prog_funct driver_prog = (prog_funct linked_prog++[(driver_id,Internal driver_fn)])%list.
Proof. reflexivity. Qed.
