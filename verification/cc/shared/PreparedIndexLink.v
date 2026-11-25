(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VerifDetected VerifClosesBody VerifToggleBody VerifLookup
 VerifLowestBit VerifEpoch PreparedFlip PreparedSeedDispatch PreparedRootStages PreparedDepthSpec PreparedBudgetContract
 PreparedArenaContext PreparedPairDispatch PreparedNativeCallees PreparedPlainDescent PreparedIndexCall
 PreparedIndexEpoch PreparedIndexWhile PreparedUniformIndex.
From mathcomp Require Import all_ssreflect all_algebra.
Require flag_level_ast.
Import flag_level_ast.
#[local] Existing Instance VerifDetected.CompSpecs.
Set Implicit Arguments.
Unset Strict Implicit.
Local Open Scope ring_scope.

Section Link.
Variables m n:nat.
Variables (H:'M['F_2]_(m,n)) (rows:'I_m->seq 'I_n).
Variables (flip dfs:funspec).
Definition index_callees:funspecs:=ltac:(let fs:=constr:(
 [::detected_spec;closes_spec;lookup_spec;toggle_spec;clear_tag_spec;next_tag_spec;pair_tag_spec;
    lowest_spec;(_flip,flip);pcm_index_spec H rows;(_dfs,dfs)]) in with_library prog fs).

(* All nodes of the recursive tree invoke the very same C function.
   The current node is supplied by instantiating the uniform specification. *)
Theorem one_context_for_all_nodes a:
 legal_choice H rows a ->
 let local_call:=call_spec (globals_at a) (level_p a) (output_p a) (call_depth a)
       (before_at a) (after_at a) (length_at a) (provenance_at H rows a) in
 tycontext_sub (func_tycontext f_dfs Vprog (caller_functions local_call) nil)
               (func_tycontext f_dfs prepared_vars index_callees nil).
Proof.
 move=>legal local_call;apply tycontext_sub_i99;split;first variable_map_sub.
 compare_function_maps (caller_functions local_call) index_callees.
 repeat (apply Forall_cons;[first [apply subsumespec_refl|eexists;split;
   [reflexivity|apply funspec_sub_sub_si;exact: (same_chooser_at_each_call legal)]]|]);apply Forall_nil.
Qed.

Theorem child_contexts_link:
 tycontext_sub (func_tycontext f_dfs prepared_vars (prepared_calls flip dfs) nil)
               (func_tycontext f_dfs prepared_vars index_callees nil) /\
 tycontext_sub pair_delta (func_tycontext f_dfs prepared_vars index_callees nil).
Proof.
 split;first by add_checked_calls (prepared_calls flip dfs) index_callees.
 unfold pair_delta;add_checked_calls PairG index_callees.
Qed.

Theorem checked_helpers_in_dfs:
 semax_body prepared_vars index_callees f_index_children (pcm_index_spec H rows) /\
 semax_body prepared_vars index_callees f_cc_clear_tags clear_tag_spec /\
 semax_body prepared_vars index_callees f_cc_next_tag next_tag_spec /\
 semax_body prepared_vars index_callees f_cc_lowest_bit lowest_spec /\
 semax_body prepared_vars index_callees f_toggle toggle_spec /\
 semax_body prepared_vars index_callees f_detected detected_spec /\
 semax_body prepared_vars index_callees f_closes closes_spec /\
 semax_body prepared_vars index_callees f_closing_qubit lookup_spec.
Proof.
 split;[|split;[|split;[|split;[|split;[|split;[|split]]]]]].
 all:eapply semax_body_subsumption.
 - exact:pcm_index_body.
 - add_checked_calls index_calls index_callees.
 - exact body_clear_tags.
 - add_checked_calls EpochGprog index_callees.
 - exact body_next_tag.
 - add_checked_calls EpochGprog index_callees.
 - exact body_cc_lowest_bit.
 - add_checked_calls LowGprog index_callees.
 - exact VerifToggleBody.body_toggle.
 - add_checked_calls ToggleGprog index_callees.
 - exact VerifDetected.body_detected.
 - add_checked_calls VerifDetected.Gprog index_callees.
 - exact VerifClosesBody.body_closes.
 - add_checked_calls ClosesGprog index_callees.
 - exact VerifLookup.body_closing_qubit.
 - add_checked_calls LookupGprog index_callees.
Qed.
End Link.
