(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.floyd.reassoc_seq VST.zlist.list_solver.
Require Import level_ast VerifDetected VerifChildVisit VerifVisitRestoration VerifSiblingRollback
 EnabledCall VerifEnabledVisit OverlapView OverlapChildState OverlapColumnState OverlapSharedBlocks
 ChildColumn EnabledLoopFacts SiblingCounters.
Local Open Scope Z_scope.
#[local] Existing Instance VerifDetected.CompSpecs.

Definition previous_empty c st xs i:=forall j,0<=j<i -> outcome (nested c) (geometry c) st xs j=0.
Definition done_children c st xs i r:=
 previous_empty c st xs i /\ ((i=Zlength xs /\ r=0) \/
 (0<=i<Zlength xs /\ r=outcome (nested c) (geometry c) st xs i /\ r<>0)).
Definition retained_trace c root xs i r tail :=
 r<>0 -> returned_trace (nested c) (blocked (child_entry (geometry c) root xs i)) (Znth i xs) tail.
Definition end_loc c s children depth n i r:=
 [temp _s s;temp _children children;temp _policy (nested_policy (nested c));temp _update_overlap (Vint Int.one);
  temp _size (Vint (Int.repr depth));temp _count (Vint (Int.repr n));temp _excluded (Vint (Int.repr i));
  temp _result (Vint (Int.repr r))].
Lemma child_owner_view c s cp w st path:0<Zlength (blocked st) ->
 enabled_memory c s cp w path st =
 (child_fields s cp (blockp (conn c)) w (blocked st) path *
  view_without_blocks (callback_owner c) (conn c) (geometry c) st * pointers c)%logic.
Proof. intro live;unfold enabled_memory,cols;rewrite callbacks_share_block_buffer by assumption;reflexivity. Qed.
Lemma same_view_when_marked p a g st dir q:
 view_without_blocks p a g (counters st (slack st) (adjust dir (blocked st) q))=view_without_blocks p a g st.
Proof. reflexivity. Qed.

Theorem recursive_siblings_overlap_enabled {Espec:OracleKind} c s cp children xs root path w depth :
 1<=depth<w-3 -> w<=Int.max_signed -> w<=Zlength path ->
 Zlength xs<=Int.max_signed -> 0<Zlength (blocked root)<=Int.max_signed ->
 in_array (Zlength (blocked root)) xs -> is_pointer_or_null (callback_owner c) ->
 (forall i,0<=i<Zlength xs ->
   check_child (geometry c) (Znth i xs) (sibling_state root xs (i+1))) ->
 semax (func_tycontext f_dfs Vprog (EGprog c) [])
   (PROPx nil (LOCALx (end_loc c s children depth (Zlength xs) 0 0)
     (SEPx [enabled_memory c s cp w path root;active_support (nested c) s None;child_array children xs])))
   native_visit
   (normal_ret_assert (EX i:Z,EX r:Z,EX st:snapshot,EX tail:list int,
    PROPx [done_children c root xs i r;retained_trace c root xs i r tail;
     same_search st (sibling_state root xs i);Zlength tail=Zlength path;sublist 0 depth tail=sublist 0 depth path]
    (LOCALx (end_loc c s children depth (Zlength xs) i r)
      (SEPx [enabled_memory c s cp w tail st;active_support (nested c) s None;child_array children xs])))).
Proof.
 intros deep cap plen count total range owner safe.
 pose proof (nested_policy_valid (nested c)) as validp.
 unfold end_loc,native_visit;abbreviate_semax;forward.
 forward_loop (EX i:Z,EX st:snapshot,EX cur:list int,
   PROPx [0<=i<=Zlength xs;previous_empty c root xs i;same_search st (sibling_state root xs i);
          Zlength cur=Zlength path;sublist 0 depth cur=sublist 0 depth path]
   (LOCALx (temp _i (Vint (Int.repr i))::end_loc c s children depth (Zlength xs) i 0)
    (SEPx [enabled_memory c s cp w cur st;active_support (nested c) s None;child_array children xs])))%assert
 break: (EX i:Z,EX r:Z,EX st:snapshot,EX tail:list int,
    PROPx [done_children c root xs i r;retained_trace c root xs i r tail;
     same_search st (sibling_state root xs i);Zlength tail=Zlength path;sublist 0 depth tail=sublist 0 depth path]
    (LOCALx (end_loc c s children depth (Zlength xs) i r)
      (SEPx [enabled_memory c s cp w tail st;active_support (nested c) s None;child_array children xs])))%assert.
 - Exists 0 root path;unfold end_loc;entailer!;try apply derives_refl.
   split;[unfold previous_empty;intros;lia|apply initial_siblings].
 - Intros i st cur;unfold end_loc;forward_if.
   2:{ forward;Exists i 0 st cur;unfold end_loc,done_children,retained_trace;entailer!;tauto || lia. }
   assert (pos:0<=i<Zlength xs) by rep_lia.
   set (q:=Znth i xs).
   assert (valid:0<=q<Zlength (blocked root)) by
     (apply Forall_forall with (x:=q) in range;[exact range|apply Znth_In;lia]).
   assert (same:same_search st (sibling_state root xs i)) by assumption.
   assert (width:Zlength (blocked st)=Zlength (blocked root)).
   { rewrite (proj2 same);unfold sibling_state;cbn [counters blocked];apply added_length;assumption. }
   assert (safe_child:check_child (geometry c) q (selected st q))
    by (apply checked_from_iterator with (root:=root) (xs:=xs) (i:=i);auto).
   destruct safe_child as [bounds [plus minus]].
   rewrite child_owner_view by lia;unfold child_fields,child_array;Intros.
   do 6 forward;rewrite upd_Znth_map;change (Int.repr 1) with Int.one.
   forward_call (s,q,true).
   reassoc_seq;unfold_abbrev'.
   match goal with |- semax _ _ ?body _ =>
     let suffix:=lazymatch body with
         Ssequence _ (Ssequence _ (Ssequence _ (Ssequence _ (Ssequence _ (Ssequence _ ?rest))))) => rest
       end in
     apply (semax_unfold_seq (Ssequence bracketed_child suffix) body eq_refl) end.
   eapply semax_seq'.
   { assert (sel_len: Zlength (blocked (selected st q))=Zlength (blocked st)) by
       (unfold selected,counters;cbn [blocked];unfold adjust;rewrite upd_Znth_Zlength by lia;reflexivity).
     eapply semax_pre;[|apply (@semax_enabled_visit Espec c s cp w depth q (selected st q) cur children xs i)];
       try eassumption;try lia.
     unfold move_loc;rewrite child_owner_view by lia;unfold child_fields,child_array.
     rewrite sel_len;unfold selected,counters,view_without_blocks;cbn [slack blocked tight tight_extra forbidden].
     unfold adjust,q;entailer!;try apply derives_refl. }
   Intros final tail;unfold move_loc.
   set (entry:=after_column (geometry c) q true (selected st q)) in *.
   assert (out:child_outcome (nested c) (blocked entry) q=outcome (nested c) (geometry c) root xs i)
     by (unfold entry,q;apply actual_outcome;assumption).
   assert (back:same_search final (selected st q)) by assumption.
   assert (after:(blocked final)=adjust 1 (blocked st) q) by exact (proj2 back).
   assert (len_final:Zlength (blocked final)=Zlength (blocked root)) by (rewrite after;unfold adjust;rewrite upd_Znth_Zlength;lia).
   assert (undo:adjust (-1) (blocked final) q=blocked st) by (rewrite after;apply cancel_child;lia).
   forward_call (s,q,false).
   rewrite child_owner_view by lia;unfold child_fields;Intros;do 4 forward;rewrite upd_Znth_map,decrement_word.
   set (resume:=released final q).
   assert (restored:same_search resume st).
   { split;[exact (proj1 back)|exact undo]. }
   assert (history:same_search resume (sibling_state root xs i)).
   { destruct restored,same;split;congruence. }
   apply semax_if_seq;forward_if.
   + assert (hit:child_outcome (nested c) (blocked entry) q<>0) by (intro E;rewrite E in *;congruence).
     forward;Exists i (child_outcome (nested c) (blocked entry) q) resume tail.
     unfold done_children,retained_trace,end_loc;rewrite child_owner_view by (unfold resume,released,counters;cbn [blocked];rewrite undo;lia).
     unfold child_fields,resume,released,counters,view_without_blocks;cbn [blocked slack tight tight_extra forbidden].
     unfold adjust,q in *;rewrite ?upd_Znth_Zlength by lia;entailer!;try cancel.
     destruct H6 as [len_tail [pre_tail [marked witness]]].
     assert (eb:blocked entry=blocked (child_entry (geometry c) root xs i)).
     { exact (proj2 (@physical_child_congruence (geometry c) (Znth i xs) true _ _
          (@selected_sibling root xs i st pos same))). }
     split;[rewrite <-eb;exact witness|split;congruence].
     apply derives_refl.
   + assert (empty:outcome (nested c) (geometry c) root xs i=0) by (rewrite <-out;assumption).
     assert (passed:previous_empty c root xs (i+1)).
     { intros j J;destruct (Z.eq_dec j i) as [->|different];auto;unfold previous_empty in *;auto with zarith. }
     assert (next:same_search (selected resume q) (sibling_state root xs (i+1))) by (apply selected_sibling;assumption).
     assert (signed_inc:Int.min_signed<=i+1<=Int.max_signed) by rep_lia.
     assert (inc:Int.add (Int.repr i) Int.one=Int.repr (i+1)) by apply add_encoded.
     do 5 forward;try solve [entailer!;exact signed_inc].
     forward;try solve [entailer!;exact signed_inc].
     rewrite ?inc;Exists (i+1) (selected resume q) tail;unfold end_loc.
     assert (resume_width:Zlength (blocked resume)=Zlength (blocked root)) by
       (unfold resume,released,counters;cbn [blocked];rewrite undo;lia).
     assert (chosen_width:Zlength (blocked (selected resume q))=Zlength (blocked final)).
     { unfold selected,counters;cbn [blocked];unfold adjust;rewrite upd_Znth_Zlength by lia;lia. }
     rewrite child_owner_view by lia;unfold child_fields;rewrite chosen_width.
     unfold selected,resume,released,counters,view_without_blocks;cbn [blocked slack tight tight_extra forbidden].
     unfold adjust;rewrite upd_Znth_map;entailer!;try apply derives_refl.
     destruct H6 as [len_tail [pre_tail [marked witness]]];split;congruence.
 - Intros i r st tail;Exists i r st tail;unfold end_loc;entailer!;try apply derives_refl.
Qed.
