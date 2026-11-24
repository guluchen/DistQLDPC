(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.zlist.list_solver.
Require Import level_ast VerifDetected VerifSiblingRollback SiblingCounters VerifChildVisit.

(* Use the same allocated array and function specifications as the recursive
   visit. Only children strictly before the stopping index were excluded. *)
Definition replay base xs stop i :=
 sweep (-1) (sublist 0 i xs) (added xs base stop).
Lemma replay_next base xs stop i : 0<=i<Zlength xs ->
 replay base xs stop (i+1)=adjust (-1) (replay base xs stop i) (Znth i xs).
Proof.
 intro valid;unfold replay,sweep. rewrite (sublist_split 0 i (i+1)),(sublist_one i),fold_left_app by lia;reflexivity.
Qed.
Lemma replay_size base xs stop i : in_array (Zlength base) xs ->
 Zlength (replay base xs stop i)=Zlength base.
Proof.
 intro valid;unfold replay;rewrite sweep_size;[apply added_length|rewrite added_length;try apply Forall_sublist];assumption.
Qed.
Lemma replay_stop base xs stop : in_array (Zlength base) xs ->
 replay base xs stop stop=base.
Proof. intro valid;unfold replay,added;apply rollback_siblings;apply Forall_sublist;exact valid. Qed.
Lemma finished_bounds c xs base stop result : visit_finished c xs base stop result ->
 0<=stop<=Zlength xs.
Proof. intros [_ [[same _]|[less _]]];pose proof (Zlength_nonneg xs);lia. Qed.

Theorem semax_restore_visited {Espec:OracleKind} c s children cp bp xs base path w depth stop result :
 Zlength xs<=Int.max_signed -> Zlength base<=Int.max_signed ->
 in_array (Zlength base) xs -> 0<=stop<=Zlength xs ->
 semax (func_tycontext f_dfs Vprog (NestedGprog c) [])
  (PROPx nil (LOCALx (visit_loc c s children depth (Zlength xs) stop result)
    (SEPx [child_fields s cp bp w (added xs base stop) path;child_array children xs;active_support c s None])))
  native_undo
  (normal_ret_assert (PROPx nil (LOCALx (visit_loc c s children depth (Zlength xs) stop result)
    (SEPx [child_fields s cp bp w base path;child_array children xs;active_support c s None])))).
Proof.
 intros count cap range stop_range. unfold native_undo,visit_loc. abbreviate_semax.
 forward_for_simple_bound stop
  (EX i:Z, PROPx [0<=i<=stop] (LOCALx (visit_loc c s children depth (Zlength xs) stop result)
   (SEPx [child_fields s cp bp w (replay base xs stop i) path;child_array children xs;active_support c s None]))).
 - try forward;try (Exists 0);unfold visit_loc,replay;rewrite ?sublist_nil by lia;entailer!;try apply derives_refl.
 - unfold child_fields,child_array,visit_loc;Intros.
   assert (len:Zlength (replay base xs stop i)=Zlength base) by (apply replay_size;assumption).
   assert (valid:0<=Znth i xs<Zlength base) by
     (apply Forall_forall with (x:=Znth i xs) in range;[assumption|apply Znth_In;lia]).
   assert (u:Int.unsigned (Int.repr (Znth i xs))=Znth i xs) by (apply Int.unsigned_repr;rep_lia).
   do 5 forward. forward.
   unfold child_fields,child_array,visit_loc;rewrite replay_next by lia;unfold adjust.
   rewrite upd_Znth_Zlength,upd_Znth_map by lia;rewrite decrement_word,?u;entailer!.
 - rewrite replay_stop by assumption;unfold visit_loc;entailer!.
Qed.

(* Both statements are the compiler-output loops identified in f_dfs.
   A nonempty result retains the child's trace and stops the siblings. *)
Theorem semax_visit_then_restore {Espec:OracleKind} c s children cp bp xs base path w depth :
  1<=depth<w-2 -> w<=Int.max_signed -> Zlength xs<=Int.max_signed ->
  Zlength base<=Int.max_signed -> w<=Zlength path -> in_array (Zlength base) xs ->
  semax (func_tycontext f_dfs Vprog (NestedGprog c) [])
   (PROPx nil (LOCALx (visit_loc c s children depth (Zlength xs) 0 0)
     (SEPx [child_fields s cp bp w base path;child_array children xs;active_support c s None])))
   (Ssequence native_visit native_undo)
   (normal_ret_assert (EX i:Z, EX r:Z, EX tail:list int,
     PROPx [visit_finished c xs base i r; visit_trace c xs base i r tail; Zlength tail=Zlength path; sublist 0 depth tail=sublist 0 depth path]
     (LOCALx (visit_loc c s children depth (Zlength xs) i r)
       (SEPx [child_fields s cp bp w base tail;child_array children xs;active_support c s None])))).
Proof.
 intros deep weight count cap len range.
 eapply semax_seq'.
 - apply semax_recursive_siblings;assumption.
 - Intros i r tail. eapply semax_post'.
   2:{ apply semax_restore_visited;try eassumption;apply finished_bounds with (c:=c) (base:=base) (result:=r);assumption. }
   unfold visit_loc;Exists i r tail;entailer!;try apply derives_refl.
Qed.
