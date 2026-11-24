(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VerifDetected VerifPackedDetector VerifToggleBody VerifClosesBody VerifLookup
 VerifChildVisit EnabledCall OverlapColumnState PreparedSeedDispatch PreparedRootStages PreparedDepthSpec
 PreparedPairDispatch PreparedArenaContext PreparedBudgetContract.
Require flag_level_ast.
Import flag_level_ast.
#[local] Existing Instance VerifDetected.CompSpecs.

(* All direct calls on the installed-policy route have one consistent
   specification map, including the helper called from closing_qubit. *)
Definition policy_callees c packed dfs_heap report bits:funspecs:=
 ltac:(let fs:=constr:([detected_spec;closes_spec;lookup_spec;toggle_spec;
    depth_flip c packed bits;budget_dfs c dfs_heap report bits]) in with_library prog fs).

Ltac add_checked_calls old new:=
 apply tycontext_sub_i99;split;[variable_map_sub|];
 compare_function_maps old new;repeat (apply Forall_cons;[apply subsumespec_refl|]);apply Forall_nil.

Theorem installed_recursive_context c packed dfs_heap report bits:
 let full:=policy_callees c packed dfs_heap report bits in
 let recursive:=prepared_calls (snd (depth_flip c packed bits)) (snd (budget_dfs c dfs_heap report bits)) in
 tycontext_sub (func_tycontext f_dfs prepared_vars recursive []) (func_tycontext f_dfs prepared_vars full []) /\
 tycontext_sub pair_delta (func_tycontext f_dfs prepared_vars full []).
Proof.
 intros full recursive;split.
 - add_checked_calls recursive full.
 - unfold pair_delta;add_checked_calls PairG full.
Qed.

Theorem installed_leaf_functions c packed dfs_heap report bits:
 let full:=policy_callees c packed dfs_heap report bits in
 semax_body prepared_vars full f_detected detected_spec /\
 semax_body prepared_vars full f_closes closes_spec /\
 semax_body prepared_vars full f_closing_qubit lookup_spec /\
 semax_body prepared_vars full f_toggle toggle_spec.
Proof.
 intro full;split;[|split;[|split]];eapply semax_body_subsumption.
 - exact VerifDetected.body_detected.
 - add_checked_calls VerifDetected.Gprog full.
 - exact VerifClosesBody.body_closes.
 - add_checked_calls ClosesGprog full.
 - exact VerifLookup.body_closing_qubit.
 - add_checked_calls LookupGprog full.
 - exact VerifToggleBody.body_toggle.
 - add_checked_calls ToggleGprog full.
Qed.
