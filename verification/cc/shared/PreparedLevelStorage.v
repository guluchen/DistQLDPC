(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto.
Require Import level_ast VerifDetected VerifChildVisit EnabledCall SeedLoopModel VerifRootCall VerifRootAdmission
 SeedColumnModel SeedBlockModel SeedBlockView SeedPolicyView OverlapColumnState OverlapView RootOwnerMemory
 ActualOrbitCommit LiveRootPolicy UniversalRootSearch OrbitHeapLoan SeedOrbitStorage VerifOrbitBlock
 SeedResume SeedColumnRestore SiblingCounters SeedExecution PreparedOrbitLoan PreparedOwnerLoan PreparedRootOrbit
 PreparedRootStages PreparedOverlapCalls.
Require flag_level_ast.
Import flag_level_ast.
#[local] Existing Instance VerifDetected.CompSpecs.
Local Open Scope Z_scope.

Definition seed_memory e x:=
 let c:=policy e in let st:=remaining_rows x in
 (((seed_owner c (visit_address e) (limit_address e) (base_address e) (fallback_address e)
     (dynamic_rows (database e) st) (limits e) (live_rows st) *
    shared_root c (state_address e) (path_address e) (weight e) (witness_path x) (running x)) *
   pending_block c (orbits e) (done_address e)) *
  active_support (nested c) (state_address e) None * seed_counter (state_address e) (seed_calls x))%logic.
Definition orbit_callback e:=done_fields (nested_policy (nested (policy e))) (callback_owner (policy e)) (done_address e).
Definition orbit_frame_data e x:=
 (outside_block (policy e) (state_address e) (path_address e) (weight e) (witness_path x) (visit_address e) (running x) *
 active_support (nested (policy e)) (state_address e) None * seed_counter (state_address e) (seed_calls x))%logic.
Lemma enter_orbit_view e x:
 seed_memory e x = (orbit_storage e x * orbit_callback e * orbit_frame_data e x)%logic.
Proof.
 unfold seed_memory,orbit_storage,orbit_callback,orbit_frame_data;rewrite lend_exhausted_orbit;apply pred_ext;cancel.
Qed.
Definition orbit_driver_loc e i bits:=orbit_with_flags (state_address e) (nested_policy (nested (policy e))) i (Zlength (order e)) bits.
Theorem physical_block_advances {Espec:OracleKind} flip dfs e x i bits frame:
 Int.and bits Int.one<>Int.zero -> Int.and bits (Int.repr 64)<>Int.zero ->
 is_pointer_or_null (callback_owner (policy e)) -> 0<Zlength (block_members (orbits e)) ->
 valid_orbit e i x ->
 semax (func_tycontext f_cc_run_prepared_level PreparedSeedDispatch.prepared_vars (prepared_calls flip dfs) [])
 (PROPx [] (LOCALx (orbit_driver_loc e i bits) (SEPx [(seed_memory e x * frame)%logic])))
 close_block
 (normal_ret_assert (PROPx [] (LOCALx (orbit_driver_loc e i bits) (SEPx [(seed_memory e (next_block e i x) * frame)%logic])))).
Proof.
 intros pp live owner cells [safe [cap indices]];rewrite !enter_orbit_view.
 unfold orbit_driver_loc,orbit_storage,orbit_callback.
 eapply semax_post'.
 2:{ eapply semax_pre;[|apply (@prepared_complete_orbit Espec flip dfs
   (state_address e) (nested_policy (nested (policy e))) (callback_owner (policy e)) (done_address e)
   (live_arrays (policy e) (limit_address e)) (live_csr (policy e) (base_address e) (fallback_address e))
   (database e) (orbits e) (limits e) (remaining_rows x) i (Zlength (order e)) bits (orbit_frame_data e x * frame)%logic)];
   try assumption;unfold SEPx,fold_right_sepcon;rewrite !sepcon_emp,!sepcon_assoc;apply andp_left2;apply derives_refl. }
 cbn [next_block remaining_rows];change (orbit_frame_data e (next_block e i x)) with (orbit_frame_data e x).
 unfold SEPx,fold_right_sepcon;rewrite !sepcon_emp,!sepcon_assoc;apply andp_left2;apply derives_refl.
Qed.
