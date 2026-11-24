(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.zlist.list_solver.
Require Import SeedSharedView SeedColumnModel SeedPolicyView SeedBlockView VerifSeedMove
 OverlapColumnState OverlapView VerifOrbitBlock VerifDetected.
Require seed_ast level_ast.
Local Open Scope Z_scope.
#[local] Existing Instance SeedC.

(* The same cells carry the new exemption and reference counts into DFS.
   Both sides reserve the additional fields used by the other operation. *)
Theorem switch_to_overlap owner a g seed_geom st run limitp basep fbp limits :
 isptr owner -> field_compatible seed_type [] owner ->
 column_offsets g=col_starts seed_geom -> column_rows g=col_rows seed_geom ->
 exempt_qubits g=Some (exempts st) -> blocked run=reference_counts st -> forbidden run=forbidden_events st ->
 0<Zlength (exempts st) -> 0<Zlength (reference_counts st) ->
 ((scans_at owner (Build_seed_column_ptrs (colp a) (rowp a) basep fbp) seed_geom *
   moving_at owner (Build_seed_arrays (exemp a) limitp (blockp a) (forbidp a)) limits st) *
   overlap_private owner a g run)%logic =
 (view_mem owner a g run * seed_private owner a seed_geom limitp basep fbp limits)%logic.
Proof.
 intros addr compat starts rows ex count events epos bpos.
 rewrite seed_owns_common_part,overlap_address_at_start by assumption.
 rewrite (overlap_owns_common_part owner a g run (exempts st)) by (try assumption;rewrite count;assumption).
 rewrite starts,rows,count,events;apply pred_ext;cancel.
Qed.

#[local] Instance LevelLayout : change_composite_env SeedC VerifDetected.CompSpecs.
 make_cs_preserve SeedC VerifDetected.CompSpecs.
Defined.
Definition seed_block_slots owner b:=
 (field_at Tsh seed_type [StructField seed_ast._block_start] (offset_addr b) owner *
  field_at Tsh seed_type [StructField seed_ast._block_qubit] (member_addr b) owner)%logic.
Definition search_block_slots s p b bp base:=
 (@field_at VerifDetected.CompSpecs Tsh (Tstruct level_ast._cc_level_policy noattr) [StructField level_ast._block_start]
   (offset_addr b) p *
  @field_at VerifDetected.CompSpecs Tsh (Tstruct level_ast._cc_level_policy noattr) [StructField level_ast._block]
   (member_addr b) p *
  @field_at VerifDetected.CompSpecs Tsh level_type [StructField level_ast._blk] bp s *
  @data_at VerifDetected.CompSpecs Tsh (tarray tuint (Zlength base)) (map Vint base) bp)%logic.
Lemma encoded_unsigned (xs:list int):map (fun q=>Vint (Int.repr q)) (map Int.unsigned xs)=map Vint xs.
Proof. rewrite map_map;apply map_ext;intro x;rewrite Int.repr_unsigned;reflexivity. Qed.
Lemma transfer_unsigned xs p:0<Zlength xs -> unsigned_rows xs p=
 @data_at VerifDetected.CompSpecs Tsh (tarray tuint (Zlength xs)) (map Vint xs) p.
Proof.
 intro pos;rewrite pos_unsigned by assumption.
 erewrite (@data_at_change_composite SeedC VerifDetected.CompSpecs _ Tsh (tarray tuint (Zlength xs))
  (map Vint xs) (map Vint xs));[reflexivity|apply JMeq_refl|reflexivity].
Qed.
Theorem switch_to_orbit_block s p owner b bp base :
 0<Zlength (block_offsets b) -> 0<Zlength (block_members b) ->
 (blocks_at owner b * search_block_slots s p b bp base)%logic=
 (seed_block_slots owner b * orbit_mem s p (offset_addr b) (member_addr b) bp
  (map Int.unsigned (block_offsets b)) (map Int.unsigned (block_members b)) base)%logic.
Proof.
 intros;unfold blocks_at,search_block_slots,seed_block_slots,orbit_mem.
 rewrite !Zlength_map,!encoded_unsigned,!transfer_unsigned by assumption;apply pred_ext;cancel.
Qed.
