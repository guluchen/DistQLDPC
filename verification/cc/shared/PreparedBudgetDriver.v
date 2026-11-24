(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VerifDetected VerifChildVisit EnabledCall OverlapColumnState RootDriver
 SeedBlockView SeedLoopModel SeedExecution RootOwnerMemory UniversalRootSearch SeedTableSafety RootTableInvariant
 ConcreteSeedSafety PreparedRootStages PreparedSeedDispatch PreparedSourceDriver PreparedDepthSpec PreparedTablesDriver
 PreparedArenaContext PreparedCandidateArena PreparedRecursiveCall PreparedArenaRoot PreparedBudgetContract PreparedBudgetArena.
Require flag_level_ast.
Import flag_level_ast.
#[local] Existing Instance VerifDetected.CompSpecs.
Local Open Scope Z_scope.

Theorem one_weight_through_recursive_driver e n initial array bits packed report base stride levels:
 let c:=policy e in let r:=root_projection (report (weight e)) in let scratch:=pool base stride levels in
 (forall s,active_support (nested c) s None=(packed s [] * scratch s 1)%logic) ->
 (forall s q,active_support (nested c) s (Some q)=(packed s [Int.repr q] * scratch s 1)%logic) ->
 Int.and bits Int.one<>Int.zero -> Int.and bits (Int.repr 16)<>Int.zero ->
 Int.and bits (Int.repr 32)<>Int.zero -> Int.and bits (Int.repr 64)<>Int.zero ->
 checked_tables e n -> tables_at_rest n (database e) (remaining_rows initial) ->
 admission_contract e r initial -> 0<Zlength (block_members (orbits e)) ->
 semax_body prepared_vars (recursive_policy c packed scratch report bits) f_cc_run_prepared_level
  (prepared_spec (schedule e r initial) (state_address e) (p_address e) array bits).
Proof.
 intros c r scratch empty one options overlap exempt notify tables init admission members.
 eapply semax_body_subsumption.
 - apply (table_driver_at_weight e (fun actual=>root_projection (report actual)) n initial array bits);assumption.
 - apply tycontext_sub_i99;split;[variable_map_sub|].
   compare_function_maps (root_calls_at_weight c (fun w=>root_projection (report w)) bits)
     (recursive_policy c packed scratch report bits).
   repeat (apply Forall_cons;[first [apply subsumespec_refl|eexists;split;[reflexivity|apply funspec_sub_sub_si;
    first [apply pure_flip_at_root with (scratch:=scratch);assumption|apply budget_contract_for_root;intros;apply one]]]|]);
    apply Forall_nil.
Qed.
