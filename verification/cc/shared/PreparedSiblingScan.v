(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.floyd.reassoc_seq VST.zlist.list_solver.
Require Import level_ast VerifDetected VerifChildVisit VerifVisitRestoration VerifSiblingRollback
 EnabledCall VerifEnabledVisit OverlapView OverlapChildState OverlapColumnState OverlapSharedBlocks
 ChildColumn EnabledLoopFacts SiblingCounters VerifEnabledSiblings UniversalRootSearch PreparedRecursiveCall
 PreparedRootStages PreparedSeedDispatch PreparedDepthSpec PreparedChildCall.
Require Import PreparedBudgetContract PreparedChildMode.
Require flag_level_ast.
Import flag_level_ast.
Local Open Scope Z_scope.
#[local] Existing Instance VerifDetected.CompSpecs.

Definition child_evidence_mode (update:bool) (rep:node_report) g root xs prefix i r tail:=
 exists seen,same_search seen (entered_mode update g (Znth i xs) (sibling_state root xs (i+1))) /\ rep g seen (prefix++[Int.repr (Znth i xs)]) r tail.
Definition prior_empty_mode (update:bool) rep g root xs prefix i:=forall j,0<=j<i -> exists path,child_evidence_mode update rep g root xs prefix j 0 path.
Definition scan_outcome_mode (update:bool) rep g root xs prefix i r tail:=
 prior_empty_mode update rep g root xs prefix i /\ ((i=Zlength xs /\ r=0) \/
  (0<=i<Zlength xs /\ r<>0 /\ child_evidence_mode update rep g root xs prefix i r tail)).
Definition keeps_witness_mode (update:bool) c root xs i r tail:=witness_status r ->
 returned_trace (nested c) (blocked (entered_mode update (geometry c) (Znth i xs) (sibling_state root xs (i+1)))) (Znth i xs) tail.
Definition scan_loc_mode (update:bool) c s children depth n i r bits:=
 [temp _s s;temp _children children;temp _policy (nested_policy (nested c));temp _options (Vint bits);
  temp _update_overlap (Vint (if update then Int.one else Int.zero));temp _size (Vint (Int.repr depth));temp _count (Vint (Int.repr n));
  temp _excluded (Vint (Int.repr i));temp _result (Vint (Int.repr r))].
Definition child_evidence (rep:node_report) g root xs prefix i r tail:=
 exists seen,same_search seen (child_entry g root xs i) /\ rep g seen (prefix++[Int.repr (Znth i xs)]) r tail.
Definition prior_empty rep g root xs prefix i:=forall j,0<=j<i -> exists path,child_evidence rep g root xs prefix j 0 path.
Definition scan_outcome rep g root xs prefix i r tail:=
 prior_empty rep g root xs prefix i /\ ((i=Zlength xs /\ r=0) \/
  (0<=i<Zlength xs /\ r<>0 /\ child_evidence rep g root xs prefix i r tail)).
Definition keeps_witness c root xs i r tail:=witness_status r ->
 returned_trace (nested c) (blocked (child_entry (geometry c) root xs i)) (Znth i xs) tail.
Definition scan_loc c s children depth n i r bits:=
 [temp _s s;temp _children children;temp _policy (nested_policy (nested c));temp _options (Vint bits);
  temp _update_overlap (Vint Int.one);temp _size (Vint (Int.repr depth));temp _count (Vint (Int.repr n));
  temp _excluded (Vint (Int.repr i));temp _result (Vint (Int.repr r))].
Lemma kept_parent depth before q after:
 0<=depth<Zlength before -> Zlength after=Zlength before ->
 active_prefix (depth+1) after=append_qubit before depth q ->
 active_prefix depth after=active_prefix depth before.
Proof.
 intros slot len save;rewrite <-stored_prefix in save by assumption.
 unfold active_prefix in *;apply (proj1 (@chosen_trace depth before q after slot len save)).
Qed.
Theorem siblings_at_weight_and_mode {Espec:OracleKind} c heap (dfs_heap:budget_heap) (loan:mpred) (report:budget_report) bits s cp children xs root path w depth (update:bool) :
 1<=depth<w-2 -> w<=Int.max_signed -> w<=Zlength path ->
 Zlength xs<=Int.max_signed -> 0<Zlength (blocked root)<=Int.max_signed ->
 in_array (Zlength (blocked root)) xs -> is_pointer_or_null (callback_owner c) ->
 (forall i,0<=i<Zlength xs ->
   mode_ready update (geometry c) (Znth i xs) (sibling_state root xs (i+1))) ->
 (forall node,Zlength node=depth+1 -> dfs_heap w s node=(heap s node * loan)%logic) ->
 semax (func_tycontext f_dfs prepared_vars (prepared_calls (snd (depth_flip c heap bits)) (snd (budget_dfs c dfs_heap report bits))) [])
   (PROPx nil (LOCALx (scan_loc_mode update c s children depth (Zlength xs) 0 0 bits)
     (SEPx [enabled_memory c s cp w path root;heap s (active_prefix depth path);loan;child_array children xs])))
   search_children
   (normal_ret_assert (EX i:Z,EX r:Z,EX st:snapshot,EX tail:list int,
    PROPx [scan_outcome_mode update (report w) (geometry c) root xs (active_prefix depth path) i r tail;keeps_witness_mode update c root xs i r tail;0<=r<=3;
     same_search st (sibling_state root xs i);Zlength tail=Zlength path;active_prefix depth tail=active_prefix depth path]
    (LOCALx (scan_loc_mode update c s children depth (Zlength xs) i r bits)
      (SEPx [enabled_memory c s cp w tail st;heap s (active_prefix depth path);loan;child_array children xs])))).
Proof.
 intros deep cap plen count total range owner safe join.
 pose proof (nested_policy_valid (nested c)) as validp.
 unfold scan_loc_mode,search_children;abbreviate_semax;forward.
 forward_loop (EX i:Z,EX st:snapshot,EX cur:list int,
   PROPx [0<=i<=Zlength xs;prior_empty_mode update (report w) (geometry c) root xs (active_prefix depth path) i;same_search st (sibling_state root xs i);
          Zlength cur=Zlength path;active_prefix depth cur=active_prefix depth path]
   (LOCALx (temp _i (Vint (Int.repr i))::scan_loc_mode update c s children depth (Zlength xs) i 0 bits)
    (SEPx [enabled_memory c s cp w cur st;heap s (active_prefix depth path);loan;child_array children xs])))%assert
 break: (EX i:Z,EX r:Z,EX st:snapshot,EX tail:list int,
    PROPx [scan_outcome_mode update (report w) (geometry c) root xs (active_prefix depth path) i r tail;keeps_witness_mode update c root xs i r tail;0<=r<=3;
     same_search st (sibling_state root xs i);Zlength tail=Zlength path;active_prefix depth tail=active_prefix depth path]
    (LOCALx (scan_loc_mode update c s children depth (Zlength xs) i r bits)
      (SEPx [enabled_memory c s cp w tail st;heap s (active_prefix depth path);loan;child_array children xs])))%assert.
 - Exists 0 root path;unfold scan_loc_mode;entailer!;try apply derives_refl.
   split;[unfold prior_empty_mode;intros;lia|apply initial_siblings].
 - Intros i st cur;unfold scan_loc_mode;forward_if.
   2:{ forward;Exists i 0 st cur;unfold scan_loc_mode,scan_outcome_mode,keeps_witness_mode,witness_status;entailer!;intuition lia. }
   assert (pos:0<=i<Zlength xs) by rep_lia.
   set (q:=Znth i xs).
   assert (valid:0<=q<Zlength (blocked root)) by
     (apply Forall_forall with (x:=q) in range;[exact range|apply Znth_In;lia]).
   assert (same:same_search st (sibling_state root xs i)) by assumption.
   assert (width:Zlength (blocked st)=Zlength (blocked root)).
   { rewrite (proj2 same);unfold sibling_state;cbn [counters blocked];apply added_length;assumption. }
   assert (safe_child:mode_ready update (geometry c) q (selected st q))
    by (apply ready_for_selected with (root:=root) (xs:=xs) (i:=i);auto).
   assert (qint:0<=q<Int.max_signed) by lia.
   pose proof (ready_for_flip _ _ _ _ safe_child) as csr.
   rewrite child_owner_view by lia;unfold child_fields,child_array;Intros.
   do 6 forward;rewrite upd_Znth_map;change (Int.repr 1) with Int.one.
   forward_call (s,active_prefix depth path,q,true);try solve [entailer!].
   reassoc_seq;unfold_abbrev'.
   match goal with |- semax _ _ ?body _ =>
     let suffix:=lazymatch body with
         Ssequence _ (Ssequence _ (Ssequence _ (Ssequence _ (Ssequence _ (Ssequence _ ?rest))))) => rest
       end in
     apply (semax_unfold_seq (Ssequence child_bracket suffix) body eq_refl) end.
   assert (node_len:Zlength (append_qubit cur depth q)=depth+1).
   { unfold append_qubit,active_prefix;rewrite Zlength_app,Zlength_sublist by lia;cbn;lia. }
   eapply semax_seq'.
   { assert (sel_len: Zlength (blocked (selected st q))=Zlength (blocked st)) by
       (unfold selected,counters;cbn [blocked];unfold adjust;rewrite upd_Znth_Zlength by lia;reflexivity).
     eapply semax_pre;[|apply (@recursive_bracket_at_weight Espec (snd (depth_flip c heap bits)) c dfs_heap report bits s cp w depth q (selected st q) cur children (Zlength xs) i (child_array children xs) update)];
       try eassumption;try lia.
     rewrite (join _ node_len);unfold descent_loc,append_qubit;rewrite child_owner_view by lia;unfold child_fields,child_array.
     rewrite sel_len;unfold selected,counters,view_without_blocks;cbn [slack blocked tight tight_extra forbidden].
     match goal with K:active_prefix depth cur=active_prefix depth path |- _=>rewrite K end.
     unfold adjust,q;entailer!;try apply derives_refl. }
   Intros final tail r;unfold descent_loc;rewrite (join _ node_len);Intros.
   set (entry:=entered_mode update (geometry c) q (selected st q)) in *.
   assert (agree:same_search entry (entered_mode update (geometry c) (Znth i xs) (sibling_state root xs (i+1)))).
   { apply entered_mode_congruence;apply selected_sibling;assumption. }
   assert (prefix:active_prefix depth cur=active_prefix depth path) by assumption.
   assert (record:child_evidence_mode update (report w) (geometry c) root xs (active_prefix depth path) i r tail).
   { exists entry;split;[exact agree|];unfold append_qubit in *;rewrite <-prefix;assumption. }
   assert (parent_path:active_prefix depth tail=active_prefix depth path).
   { rewrite <-prefix;eapply kept_parent;try eassumption;lia. }
   assert (words:keeps_witness_mode update c root xs i r tail).
   { unfold keeps_witness_mode;rewrite <-(proj2 agree);assumption. }
   assert (back:same_search final (selected st q)) by assumption.
   assert (after:(blocked final)=adjust 1 (blocked st) q) by exact (proj2 back).
   assert (len_final:Zlength (blocked final)=Zlength (blocked root)) by (rewrite after;unfold adjust;rewrite upd_Znth_Zlength;lia).
   assert (undo:adjust (-1) (blocked final) q=blocked st) by (rewrite after;apply cancel_child;lia).
   unfold append_qubit;rewrite prefix;forward_call (s,active_prefix depth path,q,false);try solve [entailer!].
   rewrite child_owner_view by lia;unfold child_fields;Intros;do 4 forward;rewrite upd_Znth_map,decrement_word.
   set (resume:=released final q).
   assert (restored:same_search resume st).
   { split;[exact (proj1 back)|exact undo]. }
   assert (history:same_search resume (sibling_state root xs i)).
   { destruct restored,same;split;congruence. }
   apply semax_if_seq;forward_if.
   + assert (hit:r<>0) by (intro E;subst r;congruence).
     forward;Exists i r resume tail.
     assert (summary:scan_outcome_mode update (report w) (geometry c) root xs (active_prefix depth path) i r tail) by
        (split;[assumption|right;auto]).
     unfold scan_loc_mode;rewrite child_owner_view by (unfold resume,released,counters;cbn [blocked];rewrite undo;lia).
     unfold child_fields,resume,released,counters,view_without_blocks;cbn [blocked slack tight tight_extra forbidden].
     unfold adjust,q in *;rewrite ?upd_Znth_Zlength by lia;entailer!;try apply derives_refl.
   + assert (empty:r=0) by rep_lia;subst r.
     assert (passed:prior_empty_mode update (report w) (geometry c) root xs (active_prefix depth path) (i+1)).
     { intros j J;destruct (Z.eq_dec j i) as [->|diff];[exists tail;exact record|].
       match goal with H:prior_empty_mode _ _ _ _ _ _ i |- _=>apply H;lia end. }
     assert (next:same_search (selected resume q) (sibling_state root xs (i+1))) by (apply selected_sibling;assumption).
     assert (signed_inc:Int.min_signed<=i+1<=Int.max_signed) by rep_lia.
     assert (inc:Int.add (Int.repr i) Int.one=Int.repr (i+1)) by apply add_encoded.
     do 5 forward;try solve [entailer!;exact signed_inc].
     forward;try solve [entailer!;exact signed_inc].
     rewrite ?inc;Exists (i+1) (selected resume q) tail;unfold scan_loc_mode.
     assert (resume_width:Zlength (blocked resume)=Zlength (blocked root)) by
       (unfold resume,released,counters;cbn [blocked];rewrite undo;lia).
     assert (chosen_width:Zlength (blocked (selected resume q))=Zlength (blocked final)).
     { unfold selected,counters;cbn [blocked];unfold adjust;rewrite upd_Znth_Zlength by lia;lia. }
     rewrite child_owner_view by lia;unfold child_fields;rewrite chosen_width.
     unfold selected,resume,released,counters,view_without_blocks;cbn [blocked slack tight tight_extra forbidden].
     unfold adjust;rewrite upd_Znth_map;entailer!;try apply derives_refl.

 - Intros i r st tail;Exists i r st tail;unfold scan_loc_mode;entailer!;try apply derives_refl.
Qed.

Theorem recursive_siblings_using_loan {Espec:OracleKind} c heap (dfs_heap:node_storage) (loan:mpred) report bits s cp children xs root path w depth :
 1<=depth<w-3 -> w<=Int.max_signed -> w<=Zlength path ->
 Zlength xs<=Int.max_signed -> 0<Zlength (blocked root)<=Int.max_signed ->
 in_array (Zlength (blocked root)) xs -> is_pointer_or_null (callback_owner c) ->
 (forall i,0<=i<Zlength xs ->
   check_child (geometry c) (Znth i xs) (sibling_state root xs (i+1))) ->
 (forall node,Zlength node=depth+1 -> dfs_heap s node=(heap s node * loan)%logic) ->
 semax (func_tycontext f_dfs prepared_vars (prepared_calls (snd (depth_flip c heap bits)) (snd (depth_dfs c dfs_heap report bits))) [])
   (PROPx nil (LOCALx (scan_loc c s children depth (Zlength xs) 0 0 bits)
     (SEPx [enabled_memory c s cp w path root;heap s (active_prefix depth path);loan;child_array children xs])))
   search_children
   (normal_ret_assert (EX i:Z,EX r:Z,EX st:snapshot,EX tail:list int,
    PROPx [scan_outcome report (geometry c) root xs (active_prefix depth path) i r tail;keeps_witness c root xs i r tail;0<=r<=3;
     same_search st (sibling_state root xs i);Zlength tail=Zlength path;active_prefix depth tail=active_prefix depth path]
    (LOCALx (scan_loc c s children depth (Zlength xs) i r bits)
      (SEPx [enabled_memory c s cp w tail st;heap s (active_prefix depth path);loan;child_array children xs])))).
Proof.
 intros deep cap len count width valid owner safe lend.
 apply (@siblings_at_weight_and_mode Espec c heap (fun _=>dfs_heap) loan (fun _=>report)
    bits s cp children xs root path w depth true);try assumption;lia.
Qed.

Theorem recursive_siblings_overlap_enabled {Espec:OracleKind} c heap report bits s cp children xs root path w depth :
 1<=depth<w-3 -> w<=Int.max_signed -> w<=Zlength path ->
 Zlength xs<=Int.max_signed -> 0<Zlength (blocked root)<=Int.max_signed ->
 in_array (Zlength (blocked root)) xs -> is_pointer_or_null (callback_owner c) ->
 (forall i,0<=i<Zlength xs ->
   check_child (geometry c) (Znth i xs) (sibling_state root xs (i+1))) ->
 semax (func_tycontext f_dfs prepared_vars (depth_context c heap report bits) [])
   (PROPx nil (LOCALx (scan_loc c s children depth (Zlength xs) 0 0 bits)
     (SEPx [enabled_memory c s cp w path root;heap s (active_prefix depth path);child_array children xs])))
   search_children
   (normal_ret_assert (EX i:Z,EX r:Z,EX st:snapshot,EX tail:list int,
    PROPx [scan_outcome report (geometry c) root xs (active_prefix depth path) i r tail;keeps_witness c root xs i r tail;0<=r<=3;
     same_search st (sibling_state root xs i);Zlength tail=Zlength path;active_prefix depth tail=active_prefix depth path]
    (LOCALx (scan_loc c s children depth (Zlength xs) i r bits)
      (SEPx [enabled_memory c s cp w tail st;heap s (active_prefix depth path);child_array children xs])))).
Proof.
 intros deep cap plen count total range owner safe;eapply semax_post'.
 2:{ eapply semax_pre;[|apply (@recursive_siblings_using_loan Espec c heap heap emp report bits s cp children xs root path w depth)];
      try eassumption;try solve [intros;rewrite sepcon_emp;reflexivity].
     unfold scan_loc;entailer!;cancel. }
 Intros i r st tail;Exists i r st tail;unfold scan_loc;entailer!;cancel.
Qed.
