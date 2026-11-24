(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.floyd.reassoc_seq VerifDetected
 PreparedSeedDispatch PreparedChildCall PreparedSiblingRestore PreparedSampling.
Require flag_level_ast.
Import flag_level_ast.
#[local] Existing Instance VerifDetected.CompSpecs.
Local Open Scope Z_scope.

Definition no_work_loc ptr:=
 [temp _count (Vint Int.zero);temp _excluded (Vint Int.zero);temp _result (Vint Int.zero);
  lvar _sample sample_type ptr].
Ltac discard_zero_loop:=
 lazymatch goal with |- semax _ (PROPx ?P (LOCALx ?L (SEPx ?S))) _ _ =>
  forward_for_simple_bound 0 (EX i:Z,PROPx P (LOCALx L (SEPx S)));
    try solve [rep_lia|entailer!|Intros;exfalso;lia] end.
Theorem skip_empty_scan {Espec:OracleKind} D ptr (frame:mpred):
 tycontext_sub (func_tycontext f_dfs prepared_vars [] []) D ->
 semax D (PROPx [] (LOCALx (no_work_loc ptr) (SEPx [frame])))
 (Ssequence search_children undo_children)
 (normal_ret_assert (PROPx [] (LOCALx (no_work_loc ptr) (SEPx [frame])))).
Proof.
 intro larger;eapply semax_Delta_subsumption;[exact larger|].
 unfold search_children,undo_children,no_work_loc;abbreviate_semax;reassoc_seq.
 discard_zero_loop;discard_zero_loop;entailer!.
Qed.
