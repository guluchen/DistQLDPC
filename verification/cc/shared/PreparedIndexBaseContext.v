(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto PreparedSeedDispatch VerifDetected PreparedIndexLink
 PreparedNativeCallees PreparedArenaContext PreparedDFSClosed PreparedDFSOneLeft PreparedIndexBaseCases.
From mathcomp Require Import all_ssreflect all_algebra.
Require Import flag_level_ast.
#[local] Existing Instance VerifDetected.CompSpecs.
Local Open Scope ring_scope.

(* All three nonrecursive exits use the physical helper bodies in the deep
   traversal's environment. None consumes a hypothesis about the result of
   the recursive call. *)
Theorem native_base_cases_in_recursive_context m n (H:'M['F_2]_(m,n))
 (rows:'I_m->seq 'I_n) (flip dfs:funspec):
 let calls:=index_callees H rows flip dfs in
 semax_body prepared_vars calls f_dfs budget_leaf_spec /\
 semax_body prepared_vars calls f_dfs PreparedDFSClosed.dfs_closed_spec /\
 semax_body prepared_vars calls f_dfs PreparedDFSOneLeft.dfs_one_spec.
Proof.
 intro calls;split;[|split];eapply semax_body_subsumption.
 - exact terminal_on_native_budget_array.
 - add_checked_calls base_calls calls.
 - exact PreparedDFSClosed.body_dfs_closed.
 - add_checked_calls PreparedDFSClosed.ClosedGprog calls.
 - exact PreparedDFSOneLeft.body_dfs_one_left.
 - add_checked_calls PreparedDFSOneLeft.OneGprog calls.
Qed.
