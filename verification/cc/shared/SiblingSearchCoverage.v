(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.zlist.list_solver.
Require Import SiblingCounters ActiveChildren VerifChildVisit.
From Coq Require Import List Lia.
Import ListNotations.
(* Target membership in the first matching child is enough. The native
   siblings before that child have been excluded but none lies in the
   target. Every target qubit therefore still has a machine zero counter. *)
Theorem first_kept_child (target:Z->bool) xs base :
 in_array (Zlength base) xs -> NoDup xs ->
 Forall (fun q=>Znth q base=Int.zero) xs ->
 (forall q,target q=true->0<=q<Zlength base /\ Znth q base=Int.zero) ->
 (exists q,In q xs /\ target q=true) ->
 exists i, 0<=i<Zlength xs /\ target (Znth i xs)=true /\
     (forall q,target q=true -> Znth q (added xs base i)=Int.zero).
Proof.
 intros valid distinct free target_free [q [member hit]].
 destruct (in_split q xs member) as [pre [aft layout]].
 assert (found:exists pre q aft,xs=pre++q::aft /\ Forall (fun a=>target a=false) pre /\ target q=true).
 { clear layout pre aft valid distinct free target_free base.
   induction xs as [|a xs IH];[contradiction|].
   destruct (target a) eqn:A.
   - exists [],a,xs;auto.
   - assert (later:In q xs) by (destruct member;[subst;congruence|assumption]).
     destruct (IH later) as [pre [b [aft [same [earlier match_b]]]]].
     exists (a::pre),b,aft;subst xs;split;[reflexivity|split;auto]. }
 clear layout pre aft;destruct found as [past [first [rest [same [none first_hit]]]]];subst xs.
 exists (Zlength past).
 pose proof (Zlength_nonneg past) as positive.
 split;[rewrite Zlength_app,Zlength_cons;pose proof (Zlength_nonneg rest);lia|].
 split.
 - rewrite app_Znth2,Z.sub_diag by lia;exact first_hit.
 - intros a chosen;specialize (target_free a chosen) as [range unused].
   unfold added;rewrite sublist0_app1 by lia;rewrite sublist_same by lia.
   assert (bounds:in_array (Zlength base) past) by (unfold in_array in *;apply Forall_app in valid;tauto).
   assert (uniq:NoDup past) by (apply NoDup_app_iff in distinct;tauto).
   apply Forall_app in free;destruct free as [unchanged _].
   apply (proj2 (@machine_free_after_excluding base past a bounds uniq unchanged range)).
   split;[exact unused|intro member_past;apply Forall_forall with (x:=a) in none;congruence].
Qed.

Lemma complete_visit c xs base i result :
 visit_finished c xs base i result ->
 (exists j,0<=j<Zlength xs /\ outcome_at c xs base j<>0) -> result<>0.
Proof.
 intros [clear [[end_idx answer]|[_ [_ hits]]]] [j [earlier live]];[|assumption].
 subst i result;specialize (clear j earlier);contradiction.
Qed.

Theorem exhaustion_iff_all_empty c xs base stop result :
 visit_finished c xs base stop result ->
 (result=0 <-> forall j,0<=j<Zlength xs -> outcome_at c xs base j=0).
Proof.
 intros [past [[last answer]|[within [answer hit]]]].
 - subst stop result;unfold clear_prefix in past;tauto.
 - split;[contradiction|intros all_empty;rewrite answer;apply all_empty;assumption].
Qed.

Corollary first_child_trace c xs base stop result path :
 visit_finished c xs base stop result -> visit_trace c xs base stop result path -> result<>0 ->
 exists q, In q xs /\ result=child_outcome c (added xs base (stop+1)) q /\
     returned_trace c (added xs base (stop+1)) q path /\ clear_prefix c xs base stop.
Proof.
 intros [previous [[last zero]|[within [value nonempty]]]] trace positive;[contradiction|].
 exists (Znth stop xs);split;[apply Znth_In;assumption|].
 repeat split;try assumption;exact (trace positive).
Qed.

(* The selected qubit is now active. Its own counter is one while all
   other qubits of the retained target remain selectable in the child. *)
Corollary first_entered_child target xs base :
 in_array (Zlength base) xs -> NoDup xs ->
 Forall (fun q=>Znth q base=Int.zero) xs ->
 (forall q,target q=true->0<=q<Zlength base /\ Znth q base=Int.zero) ->
 (exists q,In q xs /\ target q=true) ->
 exists i,0<=i<Zlength xs /\ target (Znth i xs)=true /\
    Znth (Znth i xs) (added xs base (i+1))=Int.one /\
    (forall q,target q=true -> q<>Znth i xs -> Znth q (added xs base (i+1))=Int.zero).
Proof.
 intros bounds distinct free valid touches.
 destruct (@first_kept_child target xs base bounds distinct free valid touches)
   as [i [live [hit allowed]]].
 destruct (valid _ hit) as [range _].
 pose proof (@added_length xs base i bounds) as len.
 exists i;split;[exact live|split;[exact hit|]].
 rewrite added_next by exact live;unfold adjust;split.
 - rewrite upd_Znth_same by lia;rewrite (allowed _ hit);reflexivity.
 - intros q wanted different;destruct (valid _ wanted) as [inside _].
   rewrite upd_Znth_diff by lia;apply allowed;exact wanted.
Qed.

Theorem trace_of_retained_target c xs base stop result path (target:Z->bool) :
 in_array (Zlength base) xs -> NoDup xs -> Forall (fun q=>Znth q base=Int.zero) xs ->
 (forall q,target q=true->0<=q<Zlength base /\ Znth q base=Int.zero) ->
 (exists q,In q xs /\ target q=true) ->
 (forall i,0<=i<Zlength xs -> target (Znth i xs)=true ->
    Znth (Znth i xs) (added xs base (i+1))=Int.one ->
    (forall q,target q=true -> q<>Znth i xs -> Znth q (added xs base (i+1))=Int.zero) ->
    outcome_at c xs base i<>0) ->
 visit_finished c xs base stop result -> visit_trace c xs base stop result path ->
 result<>0 /\ exists q,In q xs /\ returned_trace c (added xs base (stop+1)) q path.
Proof.
 intros bounds distinct free valid touches child done trace.
 destruct (@first_entered_child target xs base bounds distinct free valid touches)
   as [i [live [hit [one available]]]].
 assert (nonempty:result<>0).
 { apply (@complete_visit c xs base stop result done);exists i;split;[exact live|apply child;assumption]. }
 destruct (@first_child_trace c xs base stop result path done trace nonempty)
   as [q [member [returned [reported earlier]]]].
 split;[exact nonempty|exists q;auto].
Qed.
