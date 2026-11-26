(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.floyd.SeparationLogicAsLogicSoundness
 VerifDetected VerifClosesBody VerifLookup VerifToggleBody VerifEpoch VerifLowestBit
 PreparedPCMChooser PreparedUniformIndex PreparedIndexLink PreparedSeedDispatch
 PreparedArenaContext PreparedNativeCallees flag_level_ast.
From mathcomp Require Import all_ssreflect all_algebra.
#[local] Existing Instance VerifDetected.CompSpecs.
Set Implicit Arguments.
Unset Strict Implicit.
Local Open Scope ring_scope.

(* These identifiers and bodies are looked up in the generated C program's
   global environment, including the back edge from dfs to itself. *)
Definition index_functions:seq (ident*Clight.fundef):=
 [::(_dfs,Internal f_dfs);(_flip,Internal f_flip);
    (_index_children,Internal f_index_children);(_cc_clear_tags,Internal f_cc_clear_tags);
    (_cc_next_tag,Internal f_cc_next_tag);(_cc_next_tag_pair,Internal f_cc_next_tag_pair);
    (_cc_lowest_bit,Internal f_cc_lowest_bit);(_toggle,Internal f_toggle);
    (_detected,Internal f_detected);(_closes,Internal f_closes);
    (_closing_qubit,Internal f_closing_qubit)].

Section Functions.
Variables m n:nat.
Variables (H:'M['F_2]_(m,n)) (rows:'I_m->seq 'I_n) (flip dfs:funspec).
Let calls:=index_callees H rows flip dfs.
Definition index_specs:funspecs:=
 [::(_dfs,dfs);(_flip,flip);pcm_index_spec H rows;clear_tag_spec;next_tag_spec;pair_tag_spec;
    lowest_spec;toggle_spec;detected_spec;closes_spec;lookup_spec].

Local Ltac bind_body body:=
 eapply semax_func_cons;
 [ reflexivity
 | repeat apply Forall_cons;try apply Forall_nil;try computable;reflexivity
 | unfold var_sizes_ok;repeat constructor;try (simpl;rep_lia)
 | first [reflexivity|assumption] | LookupID | LookupB | exact body | ].

Theorem link_recursive_index {Espec:OracleKind}:
 fn_callconv f_dfs=callingconvention_of_funspec dfs ->
 fn_callconv f_flip=callingconvention_of_funspec flip ->
 semax_body prepared_vars calls f_dfs (_dfs,dfs) ->
 semax_body prepared_vars calls f_flip (_flip,flip) ->
 semax_func prepared_vars calls (Genv.globalenv flag_level_ast.prog) index_functions index_specs.
Proof.
 move=>dfs_cc flip_cc visit change_column.
 have [choose [clear [next [lowest [toggle [detect [close lookup]]]]]]]:=
   @checked_helpers_in_dfs m n H rows flip dfs.
 have next_pair:semax_body prepared_vars calls f_cc_next_tag_pair pair_tag_spec.
 { eapply semax_body_subsumption;first exact VerifEpoch.body_next_pair.
   unfold calls;add_checked_calls EpochGprog (index_callees H rows flip dfs). }
 unfold index_functions,index_specs,calls in *;destruct dfs;destruct flip.
 cbn [callingconvention_of_funspec] in dfs_cc,flip_cc.
 prove_semax_prog_setup_globalenv.
 bind_body visit. bind_body change_column. bind_body choose. bind_body clear.
 bind_body next. bind_body next_pair. bind_body lowest. bind_body toggle.
 bind_body detect. bind_body close. bind_body lookup. apply semax_func_nil.
Qed.
End Functions.

Require Import PreparedFlip PreparedDepthSpec.
(* The public flip contract also serves a caller which carries a more
   precise packed-path invariant. DFS still calls its own published ABI. *)
Theorem publish_index_functions {Espec:OracleKind} m n
 (H:'M['F_2]_(m,n)) (rows:'I_m->seq 'I_n) c heap (dfs:funspec):
 let local_flip:=snd (depth_flip c heap Int.zero) in
 fn_callconv f_dfs=callingconvention_of_funspec dfs ->
 funspec_sub (snd PreparedFlip.flip_spec) local_flip ->
 semax_body prepared_vars (index_callees H rows local_flip dfs) f_dfs (_dfs,dfs) ->
 semax_func prepared_vars (index_callees H rows (snd PreparedFlip.flip_spec) dfs)
   (Genv.globalenv flag_level_ast.prog) index_functions (index_specs H rows (snd PreparedFlip.flip_spec) dfs).
Proof.
 move=>local_flip cc sub body;apply link_recursive_index;[exact cc|reflexivity| |].
 - eapply semax_body_subsumption;first exact body.
   apply (@tycontext_sub_i99 f_dfs prepared_vars prepared_vars
     (index_callees H rows local_flip dfs) (index_callees H rows (snd PreparedFlip.flip_spec) dfs) nil).
   split.
   { intro id;apply sub_option_refl. }
   compare_function_maps (index_callees H rows local_flip dfs) (index_callees H rows (snd PreparedFlip.flip_spec) dfs).
   repeat (apply Forall_cons;[first [apply subsumespec_refl|eexists;split;
     [reflexivity|apply funspec_sub_sub_si;exact sub]]|]);apply Forall_nil.
 - eapply semax_body_subsumption;first exact PreparedFlip.body_flip.
   add_checked_calls PreparedFlip.FlipGprog (index_callees H rows (snd PreparedFlip.flip_spec) dfs).
Qed.
