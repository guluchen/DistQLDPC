(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VerifDetected VerifChildVisit EnabledCall RootDriver
 SeedLoopModel SeedExecution RootOwnerMemory UniversalRootSearch SeedTableSafety RootTableInvariant
 BlockTableSafety VerifOrbitBlock PreparedRootStages PreparedSeedDispatch PreparedRootLoop
 SeedBlockView ConcreteSeedSafety PreparedSourceDriver PreparedDepthSpec PreparedTablesDriver.
Require flag_level_ast.
Import flag_level_ast.
#[local] Existing Instance VerifDetected.CompSpecs.
Local Open Scope Z_scope.

(* The root loop and its descendants can now use one function specification
   for the same recursive C symbol. The empty path owns the initial heap. *)
Theorem prepared_driver_depth e n initial array bits heap report:
 let c:=policy e in let first:=root_projection report in
 (forall s,active_support (nested c) s None=heap s []) ->
 (forall s q,active_support (nested c) s (Some q)=heap s [Int.repr q]) ->
 Int.and bits Int.one<>Int.zero -> Int.and bits (Int.repr 16)<>Int.zero ->
 Int.and bits (Int.repr 32)<>Int.zero -> Int.and bits (Int.repr 64)<>Int.zero ->
 checked_tables e n -> tables_at_rest n (database e) (remaining_rows initial) ->
 admission_contract e first initial -> 0<Zlength (block_members (orbits e)) ->
 semax_body prepared_vars (depth_context c heap report bits) f_cc_run_prepared_level
  (prepared_spec (schedule e first initial) (state_address e) (p_address e) array bits).
Proof.
 intros c first empty one opts overlap exempt notify tables init admission members.
 eapply semax_body_subsumption.
 - apply (native_root_driver_from_tables e first n initial array bits);assumption.
 - apply same_search_functions;assumption.
Qed.
