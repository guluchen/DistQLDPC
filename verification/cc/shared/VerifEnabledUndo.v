(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.zlist.list_solver.
Require Import level_ast VerifDetected VerifSiblingRollback SiblingCounters VerifChildVisit
 VerifVisitRestoration OverlapColumnState OverlapChildState OverlapSharedBlocks
 EnabledCall EnabledLoopFacts VerifEnabledSiblings.
Local Open Scope Z_scope.
#[local] Existing Instance VerifDetected.CompSpecs.

Definition restore_fields before base := counters before (slack before) base.
Lemma reset_own_fields before:restore_fields before (blocked before)=before.
Proof. destruct before;reflexivity. Qed.
Lemma undo_stop_range c root xs stop r:done_children c root xs stop r -> 0<=stop<=Zlength xs.
Proof. intros [_ [[same _]|[inrange _]]];pose proof (Zlength_nonneg xs);lia. Qed.
Theorem enabled_undo {Espec:OracleKind} c s cp children xs root st path w depth stop result :
 Zlength xs<=Int.max_signed -> 0<Zlength (blocked root)<=Int.max_signed ->
 in_array (Zlength (blocked root)) xs -> 0<=stop<=Zlength xs ->
 same_search st (sibling_state root xs stop) ->
 semax (func_tycontext f_dfs Vprog (EGprog c) [])
  (PROPx nil (LOCALx (end_loc c s children depth (Zlength xs) stop result)
    (SEPx [enabled_memory c s cp w path st;active_support (nested c) s None;child_array children xs])))
  native_undo
  (normal_ret_assert (PROPx nil (LOCALx (end_loc c s children depth (Zlength xs) stop result)
    (SEPx [enabled_memory c s cp w path (restore_fields st (blocked root));active_support (nested c) s None;
           child_array children xs])))).
Proof.
 intros count cap range stop_range [saved_s saved_b].
 change (blocked st=added xs (blocked root) stop) in saved_b.
 unfold native_undo,end_loc;abbreviate_semax.
 forward_for_simple_bound stop
  (EX i:Z,PROPx [0<=i<=stop] (LOCALx (end_loc c s children depth (Zlength xs) stop result)
    (SEPx [enabled_memory c s cp w path (restore_fields st (replay (blocked root) xs stop i));
           active_support (nested c) s None;child_array children xs]))).
 - try forward;try (Exists 0);unfold end_loc,replay;rewrite ?sublist_nil by lia;cbn [sweep fold_left].
   rewrite <-saved_b,reset_own_fields;entailer!;try apply derives_refl.
 - assert (width:Zlength (replay (blocked root) xs stop i)=Zlength (blocked root)) by (apply replay_size;exact range).
   assert (key:0<=Znth i xs<Zlength (blocked root)) by
    (apply Forall_forall with (x:=Znth i xs) in range;[exact range|apply Znth_In;lia]).
   assert (un:Int.unsigned (Int.repr (Znth i xs))=Znth i xs) by (apply Int.unsigned_repr;rep_lia).
   unfold end_loc,child_array;rewrite child_owner_view by (cbn [restore_fields counters blocked];lia).
   unfold child_fields;cbn [restore_fields counters blocked];Intros;do 5 forward;forward.
   unfold end_loc,child_array;rewrite child_owner_view by (cbn [restore_fields counters blocked];rewrite replay_size by exact range;lia).
   unfold child_fields,restore_fields,view_without_blocks,counters;cbn [slack blocked tight tight_extra forbidden].
   rewrite replay_next by lia;unfold adjust;rewrite upd_Znth_Zlength,upd_Znth_map by lia;rewrite decrement_word,?un;entailer!.
 - rewrite replay_stop by exact range;unfold end_loc;entailer!.
Qed.

Theorem enabled_level_visits_restore {Espec:OracleKind} c s cp children xs root path w depth :
 1<=depth<w-3 -> w<=Int.max_signed -> w<=Zlength path -> Zlength xs<=Int.max_signed ->
 0<Zlength (blocked root)<=Int.max_signed -> in_array (Zlength (blocked root)) xs ->
 is_pointer_or_null (callback_owner c) ->
 (forall i,0<=i<Zlength xs -> check_child (geometry c) (Znth i xs) (sibling_state root xs (i+1))) ->
 semax (func_tycontext f_dfs Vprog (EGprog c) [])
  (PROPx nil (LOCALx (end_loc c s children depth (Zlength xs) 0 0)
    (SEPx [enabled_memory c s cp w path root;active_support (nested c) s None;child_array children xs])))
  (Ssequence native_visit native_undo)
  (normal_ret_assert (EX i:Z,EX r:Z,EX final:snapshot,EX tail:list int,
    PROPx [done_children c root xs i r;retained_trace c root xs i r tail;
      same_search final root;Zlength tail=Zlength path;sublist 0 depth tail=sublist 0 depth path]
    (LOCALx (end_loc c s children depth (Zlength xs) i r)
      (SEPx [enabled_memory c s cp w tail final;active_support (nested c) s None;child_array children xs])))).
Proof.
 intros deep cap room count width range owner safe;eapply semax_seq'.
 - apply recursive_siblings_overlap_enabled;assumption.
 - Intros i r st tail;eapply semax_post'.
   2:{ apply enabled_undo;try eassumption;apply undo_stop_range with (c:=c) (root:=root) (r:=r);assumption. }
   Exists i r (restore_fields st (blocked root)) tail;unfold end_loc;entailer!;try apply derives_refl.
   match goal with H:same_search st (sibling_state root xs i) |- _ =>
    split;[exact (proj1 H)|reflexivity] end.
Qed.
