(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.zlist.list_solver.
Require Import level_ast VerifDetected VerifSiblingRollback SiblingCounters VerifChildVisit
 VerifVisitRestoration OverlapColumnState OverlapChildState OverlapSharedBlocks
 EnabledCall EnabledLoopFacts VerifEnabledSiblings VerifEnabledUndo ClightSelect PreparedSeedDispatch
 PreparedRootStages PreparedDepthSpec PreparedSiblingScan.
Require flag_level_ast.
Import flag_level_ast.
Local Open Scope Z_scope.
#[local] Existing Instance VerifDetected.CompSpecs.

Definition undo_children:statement:=ltac:(native_fragment (counts_on _i__1) f_dfs).
Theorem enabled_undo {Espec:OracleKind} c heap report bits s cp children xs root st path w depth stop result (prefix:list int) :
 Zlength xs<=Int.max_signed -> 0<Zlength (blocked root)<=Int.max_signed ->
 in_array (Zlength (blocked root)) xs -> 0<=stop<=Zlength xs ->
 same_search st (sibling_state root xs stop) ->
 semax (func_tycontext f_dfs prepared_vars (depth_context c heap report bits) [])
  (PROPx nil (LOCALx (scan_loc c s children depth (Zlength xs) stop result bits)
    (SEPx [enabled_memory c s cp w path st;heap s prefix;child_array children xs])))
  undo_children
  (normal_ret_assert (PROPx nil (LOCALx (scan_loc c s children depth (Zlength xs) stop result bits)
    (SEPx [enabled_memory c s cp w path (restore_fields st (blocked root));heap s prefix;
           child_array children xs])))).
Proof.
 intros count cap range stop_range [saved_s saved_b].
 change (blocked st=added xs (blocked root) stop) in saved_b.
 unfold undo_children,scan_loc;abbreviate_semax.
 forward_for_simple_bound stop
  (EX i:Z,PROPx [0<=i<=stop] (LOCALx (scan_loc c s children depth (Zlength xs) stop result bits)
    (SEPx [enabled_memory c s cp w path (restore_fields st (replay (blocked root) xs stop i));
           heap s prefix;child_array children xs]))).
 - try forward;try (Exists 0);unfold scan_loc,replay;rewrite ?sublist_nil by lia;cbn [sweep fold_left].
   rewrite <-saved_b,reset_own_fields;entailer!;try apply derives_refl.
 - assert (width:Zlength (replay (blocked root) xs stop i)=Zlength (blocked root)) by (apply replay_size;exact range).
   assert (key:0<=Znth i xs<Zlength (blocked root)) by
    (apply Forall_forall with (x:=Znth i xs) in range;[exact range|apply Znth_In;lia]).
   assert (un:Int.unsigned (Int.repr (Znth i xs))=Znth i xs) by (apply Int.unsigned_repr;rep_lia).
   unfold scan_loc,child_array;rewrite child_owner_view by (cbn [restore_fields counters blocked];lia).
   unfold child_fields;cbn [restore_fields counters blocked];Intros;do 5 forward;forward.
   unfold scan_loc,child_array;rewrite child_owner_view by (cbn [restore_fields counters blocked];rewrite replay_size by exact range;lia).
   unfold child_fields,restore_fields,view_without_blocks,counters;cbn [slack blocked tight tight_extra forbidden].
   rewrite replay_next by lia;unfold adjust;rewrite upd_Znth_Zlength,upd_Znth_map by lia;rewrite decrement_word,?un;entailer!.
 - rewrite replay_stop by exact range;unfold scan_loc;entailer!.
Qed.

(* The loop returns the prefix index for all return codes. The undo phase
   consumes exactly that index, even when the last child timed out. *)
Theorem complete_recursive_sibling_scan {Espec:OracleKind} c heap report bits s cp children xs root path w depth:
 1<=depth<w-3 -> w<=Int.max_signed -> w<=Zlength path -> Zlength xs<=Int.max_signed ->
 0<Zlength (blocked root)<=Int.max_signed -> in_array (Zlength (blocked root)) xs ->
 is_pointer_or_null (callback_owner c) ->
 (forall i,0<=i<Zlength xs -> check_child (geometry c) (Znth i xs) (sibling_state root xs (i+1))) ->
 semax (func_tycontext f_dfs prepared_vars (depth_context c heap report bits) [])
 (PROPx [] (LOCALx (scan_loc c s children depth (Zlength xs) 0 0 bits)
 (SEPx [enabled_memory c s cp w path root;heap s (active_prefix depth path);child_array children xs])))
 (Ssequence PreparedChildCall.search_children undo_children)
 (normal_ret_assert (EX i:Z,EX r:Z,EX st:snapshot,EX tail:list int,
  PROPx [scan_outcome report (geometry c) root xs (active_prefix depth path) i r tail;
   keeps_witness c root xs i r tail;0<=r<=3;same_search st root;Zlength tail=Zlength path;
   active_prefix depth tail=active_prefix depth path]
  (LOCALx (scan_loc c s children depth (Zlength xs) i r bits)
    (SEPx [enabled_memory c s cp w tail st;heap s (active_prefix depth path);child_array children xs])))).
Proof.
 intros deep cap room bound total keys own safe;eapply semax_seq'.
 { apply recursive_siblings_overlap_enabled;assumption. }
 Intros i r st tail.
 assert (seen:0<=i<=Zlength xs) by (match goal with H:scan_outcome _ _ _ _ _ i r tail |- _=>
  destruct H as [_ [[e _]|[p _]]];pose proof (Zlength_nonneg xs);lia end).
 eapply semax_post'.
 2:{ apply (@enabled_undo Espec c heap report bits s cp children xs root st tail w depth i r (active_prefix depth path));assumption. }
 assert (restored:same_search (restore_fields st (blocked root)) root).
 { split;[match goal with H:same_search st _ |- _=>exact (proj1 H) end|reflexivity]. }
 Exists i r (restore_fields st (blocked root)) tail;unfold scan_loc;entailer!;apply derives_refl.
Qed.
