(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.zlist.list_solver VerifDetected VerifChildVisit EnabledCall
 OverlapColumnState UniversalRootSearch PreparedSeedDispatch PreparedRootStages PreparedRecursiveCall PreparedDepthSpec.
Require flag_level_ast.
Import flag_level_ast.
#[local] Existing Instance VerifDetected.CompSpecs.
Local Open Scope Z_scope.

(* A flip changes the physical prefix. It never allocates a candidate
   row. The recursive call alone borrows the remaining rows at its depth. *)
Definition depth_workspace:=val->Z->mpred.
Definition node_heap (packed:node_storage) (scratch:depth_workspace):node_storage:=
 fun s path=>(packed s path * scratch s (Zlength path))%logic.
Definition full_calls c packed scratch report bits:=
 prepared_calls (snd (depth_flip c packed bits)) (snd (depth_dfs c (node_heap packed scratch) report bits)).
Definition only_child (c:policy_state) (heap:node_storage) (report:node_report) (bits:int):funspecs:=
 ltac:(let fs:=constr:([depth_dfs c heap report bits]) in with_library prog fs).

Lemma pure_flip_at_root c packed scratch bits:
 (forall s,active_support (nested c) s None=(packed s [] * scratch s 1)%logic) ->
 (forall s q,active_support (nested c) s (Some q)=(packed s [Int.repr q] * scratch s 1)%logic) ->
 funspec_sub (snd (depth_flip c packed bits)) (snd (root_flip c bits)).
Proof.
 intros empty one;do_funspec_sub;destruct w as [[s q] enter];cbn [fst snd];normalize.
 Exists (s,(@nil int),q,enter) (scratch s 1);apply andp_right.
 - destruct enter;cbn [app];rewrite ?empty,?one;entailer!;cancel.
 - apply prop_right;intro rho;normalize;destruct enter;cbn [app];rewrite ?empty,?one;entailer!;cancel.
Qed.

Ltac variable_map_sub := apply sub_option_get;repeat (apply Forall_cons;[reflexivity|]);apply Forall_nil.
Ltac compare_function_maps old new :=
 apply subsume_spec_get;let A:=fresh in let B:=fresh in
 set (A:=make_tycontext_s old);set (B:=make_tycontext_s new);
 let a:=make_ground_PTree A in change A with a;clear A;
 let b:=make_ground_PTree B in change B with b;clear B.

Theorem root_with_recursive_workspace c packed scratch report bits:
 (forall s,active_support (nested c) s None=(packed s [] * scratch s 1)%logic) ->
 (forall s q,active_support (nested c) s (Some q)=(packed s [Int.repr q] * scratch s 1)%logic) ->
 tycontext_sub (func_tycontext f_cc_run_prepared_level prepared_vars (RecG c (root_projection report) bits) [])
  (func_tycontext f_cc_run_prepared_level prepared_vars (full_calls c packed scratch report bits) []).
Proof.
 intros empty one;apply tycontext_sub_i99;split;[variable_map_sub|].
 compare_function_maps (RecG c (root_projection report) bits) (full_calls c packed scratch report bits).
 repeat (apply Forall_cons;[first [apply subsumespec_refl|eexists;split;[reflexivity|apply funspec_sub_sub_si;
  first [apply pure_flip_at_root with (scratch:=scratch);assumption|apply depth_spec_serves_seed;intros;unfold node_heap;apply one]]]|]);apply Forall_nil.
Qed.

Theorem child_context_uses_real_workspace c packed scratch report bits:
 tycontext_sub (func_tycontext f_dfs prepared_vars (only_child c (node_heap packed scratch) report bits) [])
               (func_tycontext f_dfs prepared_vars (full_calls c packed scratch report bits) []).
Proof.
 apply tycontext_sub_i99;split;[variable_map_sub|].
 compare_function_maps (only_child c (node_heap packed scratch) report bits) (full_calls c packed scratch report bits).
 repeat (apply Forall_cons;[apply subsumespec_refl|]);apply Forall_nil.
Qed.
