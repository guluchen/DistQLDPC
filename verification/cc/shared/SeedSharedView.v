(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.floyd.nested_loadstore.
Require Import VerifSeedMove SeedColumnModel SeedPolicyView OverlapColumnState OverlapRowSpecs OverlapView.
Require seed_ast overlap_ast.
Local Open Scope Z_scope.
#[local] Existing Instance SeedC.
#[local] Instance SeedLayout : change_composite_env SeedC OverlapSpecs.
 make_cs_preserve SeedC OverlapSpecs.
Defined.

Definition at_overlap owner := field_address seed_type [StructField seed_ast._overlap] owner.
Lemma overlap_address_at_start owner : isptr owner -> field_compatible seed_type [] owner ->
 at_overlap owner=owner.
Proof.
 intros ptr compat;unfold at_overlap;rewrite field_address_offset by auto with field_compatible.
 change (offset_val 0 owner=owner);destruct owner;try contradiction;apply offset_val_zero_Vptr.
Qed.

Definition common_arrays a (cur blocks:list int) count :=
 (@data_at OverlapSpecs Tsh (tarray tint (Zlength cur)) (map Vint cur) (exemp a) *
  @data_at OverlapSpecs Tsh (tarray tuint (Zlength blocks)) (map Vint blocks) (blockp a) *
  @data_at OverlapSpecs Tsh tulong (Vlong count) (forbidp a))%logic.
Definition common_owner p a starts rows cur blocks count :=
 (@field_at OverlapSpecs Tsh view_type [StructField overlap_ast._column_start] (colp a) p *
  @field_at OverlapSpecs Tsh view_type [StructField overlap_ast._column_row] (rowp a) p *
  @field_at OverlapSpecs Tsh view_type [StructField overlap_ast._blocked] (blockp a) p *
  @field_at OverlapSpecs Tsh view_type [StructField overlap_ast._forbidden] (forbidp a) p *
  array32 starts (colp a) * array32 rows (rowp a) * common_arrays a cur blocks count)%logic.

Definition seed_private owner a geom limitp basep fbp limits :=
 (field_at Tsh seed_type [StructField seed_ast._current] (exemp a) owner *
  field_at Tsh seed_type [StructField seed_ast._limit] limitp owner *
  field_at Tsh seed_type [StructField seed_ast._base] basep owner *
  field_at Tsh seed_type [StructField seed_ast._fallback] fbp owner *
  data_at Tsh (tarray tint (Zlength limits)) (map Vint limits) limitp *
  signed_rows (base_order geom) basep * signed_rows (first_block geom) fbp)%logic.

Lemma unsigned_in_overlap xs p:unsigned_rows xs p=array32 xs p.
Proof.
 unfold unsigned_rows,array32;destruct Z.eq_dec;[reflexivity|].
 erewrite (@data_at_change_composite SeedC OverlapSpecs _ Tsh (tarray tuint (Zlength xs))
  (map Vint xs) (map Vint xs));[reflexivity|apply JMeq_refl|reflexivity].
Qed.

Ltac share_owner_field owner id value :=
 let eqfield:=fresh "same_field" in
 assert (eqfield:
   @field_at SeedC Tsh seed_type [StructField id;StructField seed_ast._overlap] value owner =
   @field_at OverlapSpecs Tsh view_type [StructField id] value (at_overlap owner)) by
 (transitivity (@field_at SeedC Tsh view_type [StructField id] value (at_overlap owner));
  [ apply (@field_at_app SeedC Tsh seed_type [StructField id] [StructField seed_ast._overlap]
           value value owner);apply JMeq_refl
  | erewrite (@field_at_change_composite SeedC OverlapSpecs _ Tsh view_type [StructField id] value value);
    [reflexivity|apply JMeq_refl|reflexivity] ]);
 rewrite eqfield;clear eqfield.

Theorem seed_owns_common_part owner a geom limitp basep fbp limits st :
 (scans_at owner (Build_seed_column_ptrs (colp a) (rowp a) basep fbp) geom *
  moving_at owner (Build_seed_arrays (exemp a) limitp (blockp a) (forbidp a)) limits st)%logic =
 (common_owner (at_overlap owner) a (col_starts geom) (col_rows geom)
    (exempts st) (reference_counts st) (forbidden_events st) *
  seed_private owner a geom limitp basep fbp limits)%logic.
Proof.
 unfold scans_at,moving_at,seed_move_mem,common_owner,common_arrays,seed_private,at_overlap.
 cbn [starts_addr rows_addr base_addr first_addr current_ptr limit_ptr blocked_ptr events_ptr].
 rewrite !unsigned_in_overlap.
 share_owner_field owner seed_ast._column_start (colp a).
 share_owner_field owner seed_ast._column_row (rowp a).
 share_owner_field owner seed_ast._blocked (blockp a).
 share_owner_field owner seed_ast._forbidden (forbidp a).
 erewrite (@data_at_change_composite SeedC OverlapSpecs _ Tsh (tarray tint (Zlength (exempts st)))
  (map Vint (exempts st)) (map Vint (exempts st)));[|apply JMeq_refl|reflexivity].
 erewrite (@data_at_change_composite SeedC OverlapSpecs _ Tsh (tarray tuint (Zlength (reference_counts st)))
  (map Vint (reference_counts st)) (map Vint (reference_counts st)));[|apply JMeq_refl|reflexivity].
 erewrite (@data_at_change_composite SeedC OverlapSpecs _ Tsh tulong (Vlong (forbidden_events st))
  (Vlong (forbidden_events st)));[|apply JMeq_refl|reflexivity].
 apply pred_ext;cancel.
Qed.

Definition overlap_private p a g st :=
 (@field_at OverlapSpecs Tsh view_type [StructField overlap_ast._row_start] (rowoffp a) p *
  @field_at OverlapSpecs Tsh view_type [StructField overlap_ast._row_qubit] (qubitp a) p *
  @field_at OverlapSpecs Tsh view_type [StructField overlap_ast._exempt] (exemp a) p *
  @field_at OverlapSpecs Tsh view_type [StructField overlap_ast._slack] (slackp a) p *
  @field_at OverlapSpecs Tsh view_type [StructField overlap_ast._first_extra_row] (Vint (first_extra g)) p *
  @field_at OverlapSpecs Tsh view_type [StructField overlap_ast._tight] (tightp a) p *
  @field_at OverlapSpecs Tsh view_type [StructField overlap_ast._tight_extra] (extrap a) p *
  array32 (row_offsets g) (rowoffp a) * array32 (row_qubits g) (qubitp a) *
  signed_array (slack st) (slackp a) *
  @data_at OverlapSpecs Tsh tulong (Vlong (tight st)) (tightp a) *
  @data_at OverlapSpecs Tsh tulong (Vlong (tight_extra st)) (extrap a))%logic.
Theorem overlap_owns_common_part p a g st cur :
 exempt_qubits g=Some cur -> 0<Zlength cur -> 0<Zlength (blocked st) ->
 view_mem p a g st =
 (common_owner p a (column_offsets g) (column_rows g) cur (blocked st) (forbidden st) *
  overlap_private p a g st)%logic.
Proof.
 intros ex cur_ok counts_ok;unfold view_mem,exemptp,exempt_store,common_owner,common_arrays,overlap_private.
 rewrite ex,(signed_live cur),(stored_array (blocked st)) by assumption;apply pred_ext;cancel.
Qed.
