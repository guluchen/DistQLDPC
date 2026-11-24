(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VerifDetected VerifPackedDetector VerifClosesBody
 VerifLookup VerifToggleBody VerifLowestBit VerifTableBuild VerifEpoch PreparedSeedDispatch.
Require flag_level_ast level_ast.
#[local] Existing Instance VerifDetected.CompSpecs.

(* Definition equality checks the compiler's entire function record, including
   temporaries, signatures and bodies. This also detects changes introduced by
   a different order of temporary normalization on the new entry path. *)
Theorem same_prepared_primitives :
 flag_level_ast.f_cc_clear_tags=level_ast.f_cc_clear_tags /\
 flag_level_ast.f_cc_next_tag=level_ast.f_cc_next_tag /\
 flag_level_ast.f_cc_next_tag_pair=level_ast.f_cc_next_tag_pair /\
 flag_level_ast.f_cc_lowest_bit=level_ast.f_cc_lowest_bit /\
 flag_level_ast.f_toggle=level_ast.f_toggle /\ flag_level_ast.f_detected=level_ast.f_detected /\
 flag_level_ast.f_closes=level_ast.f_closes /\ flag_level_ast.f_closing_qubit=level_ast.f_closing_qubit /\
 flag_level_ast.f_cc_build_leaf_index=level_ast.f_cc_build_leaf_index /\
 flag_level_ast.f_index_children=level_ast.f_index_children.
Proof. repeat split;reflexivity. Qed.

Theorem prepared_primitive_contracts :
 semax_body prepared_vars EpochGprog flag_level_ast.f_cc_clear_tags clear_tag_spec /\
 semax_body prepared_vars EpochGprog flag_level_ast.f_cc_next_tag next_tag_spec /\
 semax_body prepared_vars EpochGprog flag_level_ast.f_cc_next_tag_pair pair_tag_spec /\
 semax_body prepared_vars LowGprog flag_level_ast.f_cc_lowest_bit lowest_spec /\
 semax_body prepared_vars ToggleGprog flag_level_ast.f_toggle toggle_spec /\
 semax_body prepared_vars Gprog flag_level_ast.f_detected detected_bits_spec /\
 semax_body prepared_vars ClosesGprog flag_level_ast.f_closes closes_spec /\
 semax_body prepared_vars LookupGprog flag_level_ast.f_closing_qubit lookup_spec /\
 semax_body prepared_vars BuildGprog flag_level_ast.f_cc_build_leaf_index build_spec.
Proof.
 change prepared_vars with VerifDetected.Vprog.
 split;[exact body_clear_tags|];split;[exact body_next_tag|];split;[exact body_next_pair|].
 split;[exact body_cc_lowest_bit|];split;[exact body_toggle|];split;[exact body_detected_bits|].
 split;[exact body_closes|];split;[exact body_closing_qubit|exact body_table_builder].
Qed.
