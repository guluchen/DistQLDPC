(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto.
Require Import level_ast VerifDetected VerifChildVisit VerifOverlapDispatch VerifSeedBranch EnabledCall
 OverlapView OverlapSharedBlocks OverlapColumnState SeedStorageTransition SeedPolicyView SeedColumnModel
 SeedSharedView VerifSeedMove VerifRootCall SeedCallFrame.
#[local] Existing Instance VerifDetected.CompSpecs.
Local Open Scope Z_scope.

Definition make_run template moving:=Build_snapshot (slack template) (reference_counts moving)
 (tight template) (tight_extra template) (forbidden_events moving).
Definition borrow_moving ex run:=Build_moving_state ex (blocked run) (forbidden run).
Definition seed_only p fp:=
 (field_at Tsh (Tstruct _cc_level_policy noattr) [StructField _seed_exemption] fp p * seed_function fp)%logic.
Definition overlap_only c:=
 (field_at Tsh (Tstruct _cc_level_policy noattr) [StructField _overlap] (callback_addr c) (nested_policy (nested c)) *
  func_ptr' (callback_contract (callback_owner c) (geometry c) (cols c)) (callback_addr c) *
  weak_valid_pointer (callback_addr c))%logic.
Definition seed_heap c fp limitp basep fbp geom limits st:=
 let a:=conn c in seed_step (nested_policy (nested c)) (callback_owner c) fp
   (Build_seed_arrays (exemp a) limitp (blockp a) (forbidp a))
   (Build_seed_column_ptrs (colp a) (rowp a) basep fbp) geom limits st.
Definition root_reserve c s cp w path run:=
 (overlap_only c * level_links s cp (blockp (conn c)) w path *
  overlap_private (callback_owner c) (conn c) (geometry c) run)%logic.
Definition seed_reserve c fp geom limitp basep fbp limits:=
 (seed_only (nested_policy (nested c)) fp *
  seed_private (callback_owner c) (conn c) geom limitp basep fbp limits)%logic.

(* Both C callbacks read policy->owner. They also share the actual counts,
   current exemptions, incidence arrays, and forbidden-event storage. *)
Theorem start_root_borrow c s cp w path fp g limitp basep fbp limits st run :
 isptr (callback_owner c) -> @field_compatible SeedC seed_type [] (callback_owner c) ->
 column_offsets (geometry c)=col_starts g -> column_rows (geometry c)=col_rows g ->
 exempt_qubits (geometry c)=Some (exempts st) -> blocked run=reference_counts st ->
 forbidden run=forbidden_events st -> 0<Zlength (exempts st) -> 0<Zlength (reference_counts st) ->
 (seed_heap c fp limitp basep fbp g limits st * root_reserve c s cp w path run)%logic =
 (enabled_memory c s cp w path run * live_links c * seed_reserve c fp g limitp basep fbp limits)%logic.
Proof.
 intros;pose proof (switch_to_overlap (callback_owner c) (conn c) (geometry c) g st run
   limitp basep fbp limits ltac:(assumption) ltac:(assumption) ltac:(assumption) ltac:(assumption)
   ltac:(assumption) ltac:(assumption) ltac:(assumption) ltac:(assumption) ltac:(assumption)) as shared.
 unfold seed_heap,seed_step,root_reserve,enabled_memory,cols,live_links,seed_reserve,seed_slot,
  pointers,callback_fields,overlap_only,seed_only.
 pose proof (equivalent_storage _ _ shared) as give.
 pose proof (equivalent_storage _ _ (eq_sym shared)) as take.
 apply pred_ext.
 - sep_apply give;cancel.
 - sep_apply take;cancel.
Qed.
