(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto.
Require Import VerifDetected VerifChildVisit VerifOverlapDispatch EnabledCall
 OverlapView OverlapSharedBlocks OverlapColumnState SeedStorageTransition SeedPolicyView SeedColumnModel
 SeedSharedView VerifSeedMove SeedCallFrame UniversalRootSearch DynamicOverlapCallback LiveRootPolicy PreparedSeedDispatch.
Require flag_level_ast.
Import flag_level_ast.
#[local] Existing Instance VerifDetected.CompSpecs.
Local Open Scope Z_scope.

Definition seed_field p fp:=
 (field_at Tsh (Tstruct _cc_level_policy noattr) [StructField _seed_exemption] fp p *
  func_ptr' (snd seed_visit_spec) fp)%logic.
Definition overlap_field c:=
 (field_at Tsh (Tstruct _cc_level_policy noattr) [StructField _overlap] (callback_addr c) (nested_policy (nested c)) *
  func_ptr' (callback_contract (callback_owner c) (geometry c) (cols c)) (callback_addr c))%logic.
Definition dynamic_field c:=
 (field_at Tsh (Tstruct _cc_level_policy noattr) [StructField _overlap] (callback_addr c) (nested_policy (nested c)) *
  reusable_pointer c)%logic.
Definition root_storage c s cp w path run:=
 (overlap_field c * level_links s cp (blockp (conn c)) w path *
  overlap_private (callback_owner c) (conn c) (geometry c) run)%logic.
Definition seed_storage c fp geom limitp basep fbp limits:=
 (seed_field (nested_policy (nested c)) fp *
  seed_private (callback_owner c) (conn c) geom limitp basep fbp limits)%logic.
Definition seed_owner c fp limitp basep fbp geom limits st:=
 let a:=conn c in optional_seed (nested_policy (nested c)) (callback_owner c) fp
  (Build_seed_arrays (exemp a) limitp (blockp a) (forbidp a))
  (Build_seed_column_ptrs (colp a) (rowp a) basep fbp) geom limits st.

Lemma specialize_owned_field c ex:
 dynamic_field c=(overlap_field (at_seed c ex) * reusable_pointer c)%logic.
Proof.
 unfold dynamic_field,overlap_field,reusable_pointer,cols,at_seed,with_rows.
 cbn [callback_owner callback_addr nested geometry conn].
 rewrite (lend_callback_spec _ _ (callback_addr c)
  (specialize_dynamic_geometry (callback_owner c) (conn c) (installed_rows (geometry c) ex))) at 1.
 apply pred_ext;cancel;apply derives_refl.
Qed.

(* The policy owns a single copy of the owner field, including when the
   seed and overlap callbacks alternate on the same reference-count array. *)
Theorem borrow_prepared_root c s cp w path fp g limitp basep fbp limits st run:
 isptr (callback_owner c) -> @field_compatible SeedC seed_type [] (callback_owner c) ->
 column_offsets (geometry c)=col_starts g -> column_rows (geometry c)=col_rows g ->
 exempt_qubits (geometry c)=Some (exempts st) -> blocked run=reference_counts st ->
 forbidden run=forbidden_events st -> 0<Zlength (exempts st) -> 0<Zlength (reference_counts st) ->
 (seed_owner c fp limitp basep fbp g limits st * root_storage c s cp w path run)%logic =
 (enabled_memory c s cp w path run * seed_storage c fp g limitp basep fbp limits)%logic.
Proof.
 intros;pose proof (switch_to_overlap (callback_owner c) (conn c) (geometry c) g st run
   limitp basep fbp limits ltac:(assumption) ltac:(assumption) ltac:(assumption) ltac:(assumption)
   ltac:(assumption) ltac:(assumption) ltac:(assumption) ltac:(assumption) ltac:(assumption)) as shared.
 unfold seed_owner,optional_seed,root_storage,enabled_memory,cols,seed_storage,
  pointers,callback_fields,overlap_field,seed_field.
 pose proof (equivalent_storage _ _ shared) as give.
 pose proof (equivalent_storage _ _ (eq_sym shared)) as take.
 apply pred_ext;[sep_apply give|sep_apply take];cancel.
Qed.
