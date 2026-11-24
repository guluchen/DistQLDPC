(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.zlist.list_solver.
Require Import VerifDetected VerifOrbitBlock VerifSeedMove SeedPolicyView SeedBlockView
 SeedBlockModel SeedColumnModel SeedStorageTransition.
Require seed_ast level_ast.
Local Open Scope Z_scope.
#[local] Existing Instance SeedC.
#[local] Existing Instance LevelLayout.

Definition traversal_slots s p b bp :=
 (@field_at VerifDetected.CompSpecs Tsh (Tstruct level_ast._cc_level_policy noattr) [StructField level_ast._block_start]
   (offset_addr b) p *
  @field_at VerifDetected.CompSpecs Tsh (Tstruct level_ast._cc_level_policy noattr) [StructField level_ast._block]
   (member_addr b) p *
  @field_at VerifDetected.CompSpecs Tsh level_type [StructField level_ast._blk] bp s)%logic.
Definition move_fields owner a limits st :=
 (field_at Tsh seed_type [StructField seed_ast._current] (current_ptr a) owner *
  field_at Tsh seed_type [StructField seed_ast._limit] (limit_ptr a) owner *
  field_at Tsh seed_type [StructField seed_ast._blocked;StructField seed_ast._overlap] (blocked_ptr a) owner *
  field_at Tsh seed_type [StructField seed_ast._forbidden;StructField seed_ast._overlap] (events_ptr a) owner *
  data_at Tsh (tarray tint (Zlength (exempts st))) (map Vint (exempts st)) (current_ptr a) *
  data_at Tsh (tarray tint (Zlength limits)) (map Vint limits) (limit_ptr a) *
  data_at Tsh tulong (Vlong (forbidden_events st)) (events_ptr a))%logic.
Definition orbit_frame owner a pa g b limits st :=
 (seed_block_slots owner b * scans_at owner pa (dynamic_rows g st) * move_fields owner a limits (live_rows st))%logic.
Definition search_arrays s p owner a pa g b limits st :=
 (exhausted_at owner a pa g b limits st * traversal_slots s p b (blocked_ptr a))%logic.
Definition replace_counts st bs:=Build_exhausted_state (exhausted_fallback st)
 (Build_moving_state (exempts (live_rows st)) bs (forbidden_events (live_rows st))).
Lemma orbit_fields_ignore_counts owner a pa g b limits st counts:
 orbit_frame owner a pa g b limits (replace_counts st counts)=orbit_frame owner a pa g b limits st.
Proof. reflexivity. Qed.
Theorem search_owns_reference_counts s p owner a pa g b limits st:
 0<Zlength (block_offsets b) -> 0<Zlength (block_members b) ->
 search_arrays s p owner a pa g b limits st =
 (orbit_frame owner a pa g b limits st *
  orbit_mem s p (offset_addr b) (member_addr b) (blocked_ptr a)
    (map Int.unsigned (block_offsets b)) (map Int.unsigned (block_members b)) (reference_counts (live_rows st)))%logic.
Proof.
 intros starts members;unfold search_arrays,exhausted_at,orbit_frame,moving_at,seed_move_mem,move_fields.
 erewrite (@data_at_change_composite SeedC VerifDetected.CompSpecs _ Tsh (tarray tuint (Zlength (reference_counts (live_rows st))))
    (map Vint (reference_counts (live_rows st))) (map Vint (reference_counts (live_rows st))));[|apply JMeq_refl|reflexivity].
 unfold blocks_at,seed_block_slots,traversal_slots,orbit_mem.
 rewrite !Zlength_map,!encoded_unsigned,!transfer_unsigned by assumption;apply pred_ext;cancel.
Qed.
