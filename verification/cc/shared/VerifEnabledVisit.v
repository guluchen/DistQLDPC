(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.floyd.reassoc_seq.
Require Import level_ast VerifDetected VerifChildVisit VerifOverlapDispatch EnabledCall
 OverlapColumnState OverlapView OverlapChildState OverlapSharedBlocks ChildColumn.
Local Open Scope Z_scope.
#[local] Existing Instance VerifDetected.CompSpecs.

(* Flatten only ordinary Ssequence nodes in the actual loop. All branches,
   calls, and early exits remain present in the compiler's statements. *)
Fixpoint sequence_items (s:statement):list statement :=
 match s with Ssequence l r=>sequence_items l++sequence_items r|_=>[s] end.
Fixpoint push_index (xs:list statement):nat :=
 match xs with []=>O | h::t=>if stmt_for _t'40 h then O else S (push_index t) end.
Definition iteration_items:= match native_visit with
 | Ssequence _ (Sloop body _) => sequence_items body | _=>[] end.
Definition bracketed_child:statement := ltac:(
 let i:=eval vm_compute in (push_index iteration_items) in
 let ys:=eval cbv beta iota zeta delta [List.firstn List.skipn iteration_items sequence_items native_visit app] in
       (List.firstn 6 (List.skipn i iteration_items)) in
 lazymatch ys with ?a::?b::?c::?d::?e::?f::nil =>
 exact (Ssequence a (Ssequence b (Ssequence c (Ssequence d (Ssequence e f))))) end).

Definition move_loc c s depth q children count index:=
 [temp _s s;temp _policy (nested_policy (nested c));temp _size (Vint (Int.repr depth));
  temp _a (Vint (Int.repr q));temp _update_overlap (Vint Int.one);
  temp _children children;temp _count (Vint (Int.repr count));
  temp _i (Vint (Int.repr index));temp _excluded (Vint (Int.repr index))].
Definition last_trace c st q depth before tail :=
 Zlength tail=Zlength before /\ sublist 0 depth tail=sublist 0 depth before /\
 Znth depth tail=Int.repr q /\
 (child_outcome (nested c) (blocked st) q<>0 -> returned_trace (nested c) (blocked st) q tail).

Lemma chosen_trace depth path (q:Z) (tail:list int):
 0<=depth<Zlength path -> Zlength tail=Zlength path ->
 sublist 0 (depth+1) tail=sublist 0 (depth+1) (upd_Znth depth path (Int.repr q)) ->
 sublist 0 depth tail=sublist 0 depth path /\ Znth depth tail=Int.repr q.
Proof.
 intros pos len kept;split.
 - apply (f_equal (sublist 0 depth)) in kept.
   rewrite !sublist_sublist00 in kept by lia;rewrite sublist_upd_Znth_l in kept by lia;exact kept.
 - apply (f_equal (Znth depth)) in kept.
   rewrite !Znth_sublist in kept by (rewrite ?upd_Znth_Zlength;lia).
   replace (depth+0) with depth in kept by lia;rewrite upd_Znth_same in kept by lia;exact kept.
Qed.

Theorem semax_enabled_visit {Espec:OracleKind} c s cp w depth q parent path children xs index :
 1<=depth<w-2 -> w<=Int.max_signed -> w<=Zlength path -> 0<=q<Zlength (blocked parent) ->
 is_pointer_or_null (callback_owner c) ->
 let g:=geometry c in let entered:=after_column g q true parent in
 column_bounds g q parent -> admissible g q true parent -> admissible g q false entered ->
 semax (func_tycontext f_dfs Vprog (EGprog c) [])
   (PROPx nil (LOCALx (move_loc c s depth q children (Zlength xs) index) (SEPx
     [enabled_memory c s cp w path parent;active_support (nested c) s (Some q);child_array children xs])))
   bracketed_child
   (normal_ret_assert (EX final:snapshot, EX tail:list int,
    PROPx [same_search final parent;last_trace c entered q depth path tail;
      0<=child_outcome (nested c) (blocked entered) q<=3]
     (LOCALx (temp _result (Vint (Int.repr (child_outcome (nested c) (blocked entered) q)))::move_loc c s depth q children (Zlength xs) index)
      (SEPx [enabled_memory c s cp w tail final;active_support (nested c) s (Some q);child_array children xs])))).
Proof.
 intros deep cap room key owner g entered legal add_ok remove_ok.
 pose proof (nested_policy_valid (nested c)) as validp.
 pose proof (@entered_block_count g q parent legal) as size_block;fold entered in size_block.
 unfold move_loc,bracketed_child,enabled_memory,pointers,callback_fields.
 abbreviate_semax;Intros.
 apply semax_if_seq;forward_if;try solve [discriminate|congruence].
 do 2 forward;forward_call (parent,q,true);try solve [entailer!].
 unfold level_links;Intros;do 2 forward;rewrite upd_Znth_map.
 set (chosen:=upd_Znth depth path (Int.repr q)).
 assert (len:Zlength chosen=Zlength path) by (unfold chosen;rewrite upd_Znth_Zlength by lia;reflexivity).
 assert (prefix:sublist 0 depth chosen=sublist 0 depth path) by (unfold chosen;rewrite sublist_upd_Znth_l by lia;reflexivity).
 assert (mark:Znth depth chosen=Int.repr q) by (unfold chosen;rewrite upd_Znth_same by lia;reflexivity).
 forward;apply semax_if_seq;forward_if.
 { exfalso;match goal with K:Int.repr depth=Int.sub _ _ |- _ =>
   unfold Int.sub in K;rewrite !Int.unsigned_repr in K by rep_lia;
   apply (f_equal Int.signed) in K;rewrite !Int.signed_repr in K by rep_lia;lia end. }
 forward_call (s,cp,w,depth,q,entered,chosen);
 try solve [entailer!;rep_lia | entailer!;f_equal;unfold Int.add;rewrite Int.unsigned_repr by rep_lia;reflexivity].
 { unfold enabled_memory,pointers,callback_fields,level_links,chosen;rewrite ?upd_Znth_Zlength by lia;unfold entered,g,Frame;cancel.
   instantiate (Frame := [child_array children xs]);cbn [fold_right_sepcon];cancel. }
 Intros vret;destruct vret as [child tail];cbn [fst snd] in *.
 assert (exit_ok:admissible g q false child) by
   (eapply same_admissible;[|exact remove_ok];match goal with K:same_search child entered |- _ => destruct K;split;congruence end).
 assert (stable:same_search (after_column g q false child) parent) by (apply after_child_column;assumption).
 assert (kept_path:sublist 0 depth tail=sublist 0 depth path /\ Znth depth tail=Int.repr q).
 { apply chosen_trace;try lia;assumption. }
 destruct kept_path as [kept_head kept_at].
 unfold enabled_memory,pointers,callback_fields;Intros.
 forward_if;try solve [discriminate|congruence].
 do 2 forward;forward_call (child,q,false);try solve [entailer!].
 Exists (after_column g q false child) tail;unfold last_trace,move_loc,enabled_memory,pointers,callback_fields.
 entailer!;try apply derives_refl.
Qed.
