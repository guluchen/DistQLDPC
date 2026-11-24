(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto.
Require Import level_ast VerifDetected VerifChildVisit EnabledCall SeedLoopModel VerifRootCall VerifRootAdmission
 SeedColumnModel SeedBlockModel SeedBlockView SeedPolicyView OverlapColumnState OverlapView RootOwnerMemory
 ActualOrbitCommit LiveRootPolicy UniversalRootSearch OrbitHeapLoan SeedOrbitStorage VerifOrbitBlock
 SeedResume SeedColumnRestore SiblingCounters.
#[local] Existing Instance VerifDetected.CompSpecs.
Local Open Scope Z_scope.

Record seed_level := {
 state_address:val; path_address:val; weight:Z; policy:policy_state;
 visit_address:val; done_address:val; limit_address:val; base_address:val; fallback_address:val;
 database:seed_column; orbits:orbit_blocks; limits:list int; order:list int
}.
Record root_state := {
 remaining_rows:exhausted_state; running:snapshot; witness_path:list int; seed_calls:int64
}.
Definition seed_memory e x:=
 let c:=policy e in let st:=remaining_rows x in
 (((seed_heap c (visit_address e) (limit_address e) (base_address e) (fallback_address e)
     (dynamic_rows (database e) st) (limits e) (live_rows st) *
    shared_root c (state_address e) (path_address e) (weight e) (witness_path x) (running x)) *
   pending_block c (orbits e) (done_address e)) *
  active_support (nested c) (state_address e) None * seed_counter (state_address e) (seed_calls x))%logic.
Definition next_block e i x:=Build_root_state
 (after_exhaustion (database e) (orbits e) (limits e) i (remaining_rows x))
 (running x) (witness_path x) (seed_calls x).
Definition orbit_storage e x:=
 search_arrays (state_address e) (nested_policy (nested (policy e))) (callback_owner (policy e))
   (live_arrays (policy e) (limit_address e)) (live_csr (policy e) (base_address e) (fallback_address e))
   (database e) (orbits e) (limits e) (remaining_rows x).
Definition orbit_callback e:=block_functions (nested_policy (nested (policy e))) (callback_owner (policy e)) (done_address e).
Definition orbit_frame_data e x:=
 (outside_block (policy e) (state_address e) (path_address e) (weight e) (witness_path x) (visit_address e) (running x) *
 active_support (nested (policy e)) (state_address e) None * seed_counter (state_address e) (seed_calls x))%logic.
Lemma enter_orbit_view e x:
 seed_memory e x = (orbit_storage e x * orbit_callback e * orbit_frame_data e x)%logic.
Proof.
 unfold seed_memory,orbit_storage,orbit_callback,orbit_frame_data;rewrite lend_exhausted_orbit;apply pred_ext;cancel.
Qed.
Definition orbit_driver_loc e i:=finish_loc (state_address e) (nested_policy (nested (policy e))) i (Zlength (order e)).
Definition valid_orbit e i x :=
 block_safe (database e) (orbits e) (limits e) i (after_counts (orbits e) i (remaining_rows x)) /\
 Zlength (reference_counts (live_rows (remaining_rows x)))<=Int.max_unsigned /\
 in_array (Zlength (reference_counts (live_rows (remaining_rows x)))) (raw_members (orbits e)).

Theorem physical_block_advances {Espec:OracleKind} e x i frame:
 isptr (nested_policy (nested (policy e))) -> isptr (done_address e) ->
 is_pointer_or_null (callback_owner (policy e)) -> 0<Zlength (block_members (orbits e)) ->
 valid_orbit e i x ->
 semax (func_tycontext f_cc_run_level Vprog (all_roots (policy e)) [])
 (PROPx [] (LOCALx (orbit_driver_loc e i) (SEPx [(seed_memory e x * frame)%logic])))
 finish_orbit
 (normal_ret_assert (PROPx [] (LOCALx (orbit_driver_loc e i) (SEPx [(seed_memory e (next_block e i x) * frame)%logic])))).
Proof.
 intros pp live owner cells [safe [cap indices]];rewrite !enter_orbit_view.
 unfold orbit_driver_loc,orbit_storage,orbit_callback.
 eapply semax_Delta_subsumption;[apply (all_roots_subsumes_seed (policy e) (geometry (policy e)))|].
 eapply semax_post'.
 2:{ eapply semax_pre;[|apply (@complete_empty_policy_orbit Espec (with_rows (policy e) (geometry (policy e)))
   (state_address e) (nested_policy (nested (policy e))) (callback_owner (policy e)) (done_address e)
   (live_arrays (policy e) (limit_address e)) (live_csr (policy e) (base_address e) (fallback_address e))
   (database e) (orbits e) (limits e) (remaining_rows x) i (Zlength (order e)) (orbit_frame_data e x * frame)%logic)];
   try assumption;unfold SEPx,fold_right_sepcon;rewrite !sepcon_emp,!sepcon_assoc;apply andp_left2;apply derives_refl. }
 cbn [next_block remaining_rows];change (orbit_frame_data e (next_block e i x)) with (orbit_frame_data e x).
 unfold SEPx,fold_right_sepcon;rewrite !sepcon_emp,!sepcon_assoc;apply andp_left2;apply derives_refl.
Qed.
