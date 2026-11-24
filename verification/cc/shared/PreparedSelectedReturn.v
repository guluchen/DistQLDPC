(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.floyd.reassoc_seq VerifDetected VerifChildVisit EnabledCall
 OverlapColumnState OverlapView OverlapSharedBlocks PreparedSeedDispatch PreparedOverlapDepth
 PreparedSiblingScan PreparedVerdictExit PreparedSampling PreparedInitializeScan.
Require flag_level_ast.
Import flag_level_ast.
#[local] Existing Instance VerifDetected.CompSpecs.
Local Open Scope Z_scope.

Definition rest_of_level c s cp path st:=
 (field_at Tsh level_type [StructField _blk] (blockp (conn c)) s *
  field_at Tsh level_type [StructField _cur] cp s *
  data_at Tsh (tarray tint (Zlength path)) (map Vint path) cp * cols c st * pointers c)%logic.

Lemma share_weight_during_setup c s cp w path st:
 enabled_memory c s cp w path st =
 (field_at Tsh level_type [StructField _w] (Vint (Int.repr w)) s * rest_of_level c s cp path st)%logic.
Proof. unfold enabled_memory,level_links,rest_of_level;apply pred_ext;cancel. Qed.

(* Selected_subtree contains every instruction from the cache decision
   to return. The same level weight is lent temporarily to initialize
   the loop and is present again when the loop or fast path starts. *)
Theorem from_selected_candidates {Espec:OracleKind} D c s children cp w path st depth count bits sample
 (others:list mpred) (finish:ret_assert):
 tycontext_sub (func_tycontext f_dfs prepared_vars [] []) D -> 0<=depth<=w -> w<=Int.max_signed ->
 let owned:=enabled_memory c s cp w path st::others in
 semax D (PROPx [] (LOCALx
  (scan_loc_mode (enabled_at bits w depth) c s children depth count 0 0 bits++[lvar _sample sample_type sample])
  (SEPx owned))) search_finish finish ->
 semax D (PROPx [] (LOCALx (chosen_loc c s children depth count bits sample) (SEPx owned)))
 selected_subtree finish.
Proof.
 intros larger range fit owned tail.
 apply (semax_unfold_seq (Ssequence ready_scan search_finish) selected_subtree eq_refl).
 eapply semax_seq';[|exact tail].
 eapply semax_Delta_subsumption;[exact larger|].
 pose proof (@initialize_sibling_scan Espec c s children w depth count bits sample
     (rest_of_level c s cp path st * fold_right_sepcon others)%logic range fit) as init.
 unfold owned,SEPx in *;cbn [fold_right_sepcon] in *.
 rewrite !sepcon_emp in init;rewrite share_weight_during_setup,sepcon_assoc;exact init.
Qed.
