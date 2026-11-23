(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto.
Require Import TableFlow.

(* Remaining positions in a chain increase. Updating the as-yet-uninserted
   position cannot change any link in a previously built chain. *)
Inductive member_chain (n:Z) (links:list Z) : Z -> Z -> Prop :=
| first_member : forall j, 0<=j<n -> member_chain n links j j
| later_member : forall j z, 0<=j<n -> j<Znth j links<n ->
    member_chain n links (Znth j links) z -> member_chain n links j z.
Lemma insert_before_chain n links h z q value : Zlength links=n -> 0<=q<n ->
  member_chain n links h z -> q<h -> member_chain n (upd_Znth q links value) h z.
Proof.
  intros len fresh old;induction old as [j bound|j z bound increase later IH];intro earlier.
  - constructor;assumption.
  - apply later_member;[assumption|rewrite upd_Znth_diff by lia;assumption|].
    rewrite upd_Znth_diff by lia;apply IH;lia.
Qed.

Section Contents.
Variables (ks:list int64) (mask:int64) (cap:Z).
Let n:=Zlength ks.
Hypothesis valid_mask : Int64.unsigned mask<cap.
Definition tracked q tab links := forall z, q<z<n ->
  exists i, reached ks mask z tab i /\ 0<=TableFlow.head tab i /\
   Znth (TableFlow.head tab i) ks=Znth z ks /\ member_chain n links (TableFlow.head tab i) z.

Lemma route_stable z tab newtab i :
  (forall j, 0<=slot_index j<cap -> 0<=TableFlow.head tab j ->
    0<=TableFlow.head newtab j /\ Znth (TableFlow.head newtab j) ks=Znth (TableFlow.head tab j) ks) ->
  reached ks mask z tab i -> reached ks mask z newtab i.
Proof.
  intros stable path;induction path as [|j old IH occupied different];[constructor|].
  destruct (stable j (@reached_inside ks mask cap valid_mask _ _ _ old) occupied) as [pop same].
  apply after_collision;try assumption;congruence.
Qed.

Lemma tracked_insert q tab links i newlinks : history ks mask cap q tab links -> tracked q tab links ->
  0<=q -> reached ks mask q tab i ->
  ((TableFlow.head tab i<0 /\ newlinks=links) \/
    (0<=TableFlow.head tab i /\ Znth (TableFlow.head tab i) ks=Znth q ks /\
     newlinks=upd_Znth q links (TableFlow.head tab i))) ->
  tracked (q-1) (upd_Znth (slot_index i) tab q) newlinks.
Proof.
  intros built previous positive insertion action.
  destruct (@history_shape ks mask cap valid_mask _ _ _ built) as [qrange length_tab length_links before increasing].
  pose proof (@reached_inside ks mask cap valid_mask _ _ _ insertion) as place.
  set (tab':=upd_Znth (slot_index i) tab q).
  assert (written:TableFlow.head tab' i=q) by (unfold TableFlow.head,tab';rewrite upd_Znth_same by lia;reflexivity).
  assert (stable:forall j,0<=slot_index j<cap -> 0<=TableFlow.head tab j ->
     0<=TableFlow.head tab' j /\ Znth (TableFlow.head tab' j) ks=Znth (TableFlow.head tab j) ks).
  { intros j loc occupied;unfold TableFlow.head,tab' in *.
    destruct (Z.eq_dec (slot_index j) (slot_index i)) as [eq|diff].
    - rewrite eq,upd_Znth_same by lia. rewrite eq in occupied. destruct action as [[empty _]|[ok [same _]]].
      + lia.
      + auto.
    - rewrite upd_Znth_diff by lia;auto. }
  intros z range. destruct (Z.eq_dec z q) as [->|notnew].
  - exists i;rewrite written. split;[eapply route_stable;eassumption|].
    split;[assumption|split;[reflexivity|constructor;unfold n;lia]].
  - destruct (previous z ltac:(lia)) as [j [walk [inhabited [same older]]]].
    pose proof (@reached_inside ks mask cap valid_mask _ _ _ walk) as loc.
    pose proof (stable j loc inhabited) as [occupied keep].
    exists j;split;[eapply route_stable;eassumption|]. split;[assumption|split;[congruence|]].
    assert (higher:q<TableFlow.head tab j<n).
    { destruct (before (slot_index j) loc);unfold TableFlow.head in *;lia. }
    destruct (Z.eq_dec (slot_index j) (slot_index i)) as [equal|diff].
    + assert (samehead:TableFlow.head tab j=TableFlow.head tab i) by (unfold TableFlow.head;rewrite equal;reflexivity).
      assert (newhead:TableFlow.head tab' j=q) by (unfold TableFlow.head;rewrite equal;exact written).
      rewrite newhead. destruct action as [[neg _]|[nonneg [equal_key ->]]];[lia|].
      apply later_member;[unfold n;lia|rewrite upd_Znth_same by lia;lia|].
      rewrite upd_Znth_same by lia. rewrite <-samehead.
      apply insert_before_chain;try assumption;unfold n in *;lia.
    + assert (unchanged:TableFlow.head tab' j=TableFlow.head tab j)
        by (unfold TableFlow.head,tab';rewrite upd_Znth_diff by lia;reflexivity).
      rewrite unchanged. destruct action as [[_ ->]|[_ [_ ->]]];[exact older|].
      apply insert_before_chain;try assumption;unfold n in *;lia.
Qed.

Theorem history_tracks q tab links : history ks mask cap q tab links -> tracked q tab links.
Proof.
  induction 1.
  - intros z range;unfold n in range;lia.
  - eapply tracked_insert;try eassumption;left;auto.
  - eapply tracked_insert;try eassumption;right;auto.
Qed.
End Contents.
