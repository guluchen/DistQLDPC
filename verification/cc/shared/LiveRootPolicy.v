(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto.
Require Import level_ast VerifDetected EnabledCall VerifOverlapDispatch OverlapView OverlapColumnState
 SeedSharedView RootOwnerMemory UniversalRootSearch DynamicOverlapCallback VerifChildVisit.
#[local] Existing Instance VerifDetected.CompSpecs.
Local Open Scope Z_scope.

Definition installed_rows g ex:=Build_layout (column_offsets g) (column_rows g)
 (row_offsets g) (row_qubits g) (Some ex) (first_extra g).
Definition at_seed c ex:=with_rows c (installed_rows (geometry c) ex).
Definition reusable_pointer c:=func_ptr' (dynamic_overlap (callback_owner c) (conn c)) (callback_addr c).
Definition fixed_overlap c:=
 (field_at Tsh (Tstruct _cc_level_policy noattr) [StructField _overlap] (callback_addr c) (nested_policy (nested c)) *
  reusable_pointer c * weak_valid_pointer (callback_addr c))%logic.

(* The address and its general contract survive every call.  A specialized
   function-pointer assertion is duplicable; the arrays it describes are not. *)
Lemma lend_callback_spec (universal specific:funspec) fp :
 funspec_sub universal specific ->
 func_ptr' universal fp=(func_ptr' specific fp * func_ptr' universal fp)%logic.
Proof.
 intro sub;apply pred_ext.
 - rewrite (split_func_ptr' universal fp) at 1;apply sepcon_derives;[apply func_ptr'_mono;exact sub|apply derives_refl].
 - rewrite <- (emp_sepcon (func_ptr' universal fp)) at 2;apply sepcon_derives;[apply func_ptr'_emp|apply derives_refl].
Qed.
Theorem overlap_at_each_seed c ex:
 fixed_overlap c=(overlap_only (at_seed c ex) * reusable_pointer c)%logic.
Proof.
 unfold fixed_overlap,overlap_only,reusable_pointer,cols,at_seed,with_rows.
 cbn [callback_owner callback_addr nested geometry conn].
 rewrite (lend_callback_spec _ _ (callback_addr c)
   (specialize_dynamic_geometry (callback_owner c) (conn c) (installed_rows (geometry c) ex))) at 1.
 apply pred_ext;cancel;apply derives_refl.
Qed.
Lemma installed_private c ex st:
 overlap_private (callback_owner c) (conn c) (installed_rows (geometry c) ex) st=
 overlap_private (callback_owner c) (conn c) (geometry c) st.
Proof. reflexivity. Qed.
