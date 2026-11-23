(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto.
Require Import HashLookup HashProbe VerifClosesBody TableFlow TableCoverage TableMembers BuiltLookup.

Section Contents.
Variables (ks:list int64) (mask key:int64) (cap:Z) (tab links:list Z) (blocked:list int).
Let b:=table_book ks mask key tab links blocked.
Let n:=Zlength ks.
Hypothesis built : history ks mask cap (-1) tab links.
Hypothesis mask_fits : Int64.unsigned mask<cap.
Hypothesis nonzero : 0<n.
Lemma foreign_head i : slot b i<n.
Proof.
  pose proof (@history_shape ks mask cap mask_fits _ _ _ built) as [bounds len _ heads _].
  change (Znth (Int64.unsigned i) tab<n);destruct (Z_lt_dec (Int64.unsigned i) cap) as [inside|out].
  - pose proof (Int64.unsigned_range i) as I;destruct (heads (Int64.unsigned i) ltac:(lia));lia.
  - rewrite Znth_overflow by lia;assumption.
Qed.
Lemma link_range q : 0<=q<n -> Znth q links<0 \/ q<Znth q links<n.
Proof.
  intro range. destruct (@history_shape ks mask cap mask_fits _ _ _ built) as [_ _ _ _ inc].
  destruct (inc q range) as [last|[up _]];[left;lia|right;exact up].
Qed.
Lemma terminal_bucket (v:close_view) odd i a : probe_run b v odd i a ->
  exists qs, bucket_path b i qs.
Proof.
  induction 1.
  - exists [];constructor;assumption.
  - destruct (@finite_chain b n link_range (slot b i) (foreign_head i)) as [qs path].
    exists qs;eapply path_chain;eassumption.
  - destruct IHprobe_run as [qs last];exists qs;eapply path_next;eassumption.
Qed.
Lemma at_built_slot z i qs : Znth z ks=key -> reached ks mask z tab i ->
  bucket_path b (origin b) qs -> bucket_path b i qs.
Proof.
  intros same reach root;induction reach as [|i prior IH occupied different].
  - unfold insert_home;rewrite same;exact root.
  - assert (pop:0<=slot b i) by exact occupied.
    assert (bad:Znth (slot b i) (keys b)<>query b) by
      (change (Znth (TableFlow.head tab i) ks<>key);congruence).
    inversion IH;subst;try lia;try congruence;assumption.
Qed.
Lemma chain_contains start z : member_chain n links start z ->
  forall qs, chain_lists b start qs -> In z qs.
Proof.
  induction 1 as [j range|j z range up later IH];intros qs listpath;inversion listpath;subst;try lia.
  - left;reflexivity.
  - right;apply IH;assumption.
Qed.
Lemma chain_entries start qs : chain_lists b start qs -> start<n ->
  (0<=start -> Znth start ks=key) ->
  forall z, In z qs -> 0<=z<n /\ Znth z ks=key.
Proof.
  intro path;induction path as [j neg|j qs pos tail IH];intros bound same z member.
  - contradiction.
  - destruct member as [->|later];[split;[lia|apply same;assumption]|].
    destruct (@history_shape ks mask cap mask_fits _ _ _ built) as [_ _ _ _ inc].
    destruct (inc j ltac:(lia)) as [end_here|[higher group]].
    + eapply IH;[change (Znth j links<n);lia|intro valid;change (0<=Znth j links) in valid;lia|assumption].
    + eapply IH;[change (Znth j links<n);lia|intro valid;change (Znth (Znth j links) ks=key);rewrite group;auto|assumption].
Qed.
Lemma bucket_entries i qs : bucket_path b i qs -> forall z, In z qs -> 0<=z<n /\ Znth z ks=key.
Proof.
  intro path;induction path as [i empty|i qs yes same chain|i qs yes other more IH].
  - intros;contradiction.
  - eapply chain_entries;[exact chain|apply foreign_head|intros;exact same].
  - exact IH.
Qed.

Theorem exact_bucket qs : bucket_path b (origin b) qs -> forall z,
  In z qs <-> 0<=z<n /\ Znth z ks=key.
Proof.
  intros route z;split;[apply (bucket_entries _ _ route)|].
  intros [range same].
  destruct (@history_tracks ks mask cap mask_fits _ _ _ built z ltac:(unfold n in *;lia))
    as [i [walk [occupied [headkey member]]]].
  pose proof (at_built_slot _ _ _ same walk route) as here.
  assert (pop:0<=slot b i) by exact occupied.
  assert (match_key:Znth (slot b i) (keys b)=query b) by (change (Znth (TableFlow.head tab i) ks=key);congruence).
  assert (chosen:chain_lists b (slot b i) qs).
  { inversion here;subst;try lia;try congruence;assumption. }
  eapply chain_contains;[exact member|exact chosen].
Qed.
End Contents.
