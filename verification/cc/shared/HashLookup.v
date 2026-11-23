(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto Coq.Logic.Classical_Prop.
Require Import VerifDetected VerifClosesBody.

Record lookup_data := {
  slots : list Z; links : list Z; blocked : list int; keys : list int64;
  mask : int64; query : int64
}.

Definition slot b i := Znth (Int64.unsigned i) (slots b).
Definition advance b i := Int64.and (Int64.add i Int64.one) (mask b).
Definition origin b := Int64.and (query b) (mask b).
Definition usable b v odd q := Znth q (blocked b) = Int.zero /\ close_result v q odd = Vint Int.one.

Lemma closes_boolean v q odd :
  close_result v q odd = Vint Int.zero \/ close_result v q odd = Vint Int.one.
Proof.
  unfold close_result, detected_value.
  destruct (Z.eq_dec _ _); [|auto].
  destruct (ClassicalDescription.excluded_middle_informative _); [|auto].
  destruct (Int64.eq _ _); auto.
Qed.

Section Path.
Variables (b : lookup_data) (v : close_view) (odd : Z).

(* A finite trace uses exactly the indices and successor operations of the
   C hash table, including failed probes and rejected members of a bucket. *)
Inductive chain_run : Z -> Z -> Prop :=
| chain_end : forall q, q < 0 -> chain_run q (-1)
| chain_take : forall q, 0 <= q -> usable b v odd q -> chain_run q q
| chain_skip : forall q a, 0 <= q -> ~usable b v odd q ->
    chain_run (Znth q (links b)) a -> chain_run q a.

Inductive probe_run : int64 -> Z -> Prop :=
| probe_empty : forall i, slot b i < 0 -> probe_run i (-1)
| probe_found : forall i a, 0 <= slot b i -> Znth (slot b i) (keys b) = query b ->
    chain_run (slot b i) a -> probe_run i a
| probe_next : forall i a, 0 <= slot b i -> Znth (slot b i) (keys b) <> query b ->
    probe_run (advance b i) a -> probe_run i a.

Lemma chain_result q a : chain_run q a -> a = -1 \/ (0 <= a /\ usable b v odd a).
Proof. induction 1; auto. Qed.
Lemma probe_result i a : probe_run i a -> a = -1 \/ (0 <= a /\ usable b v odd a).
Proof. induction 1; eauto using chain_result. Qed.

Lemma chain_deterministic q a c : chain_run q a -> chain_run q c -> a = c.
Proof.
  intros R; revert c; induction R; intros c Other; inversion Other; subst;
    try reflexivity; try lia; try contradiction; auto.
Qed.
Lemma probe_deterministic i a c : probe_run i a -> probe_run i c -> a = c.
Proof.
  intros R; revert c; induction R; intros c Other; inversion Other; subst;
    try reflexivity; try lia; try congruence; eauto using chain_deterministic.
Qed.

(* The rows in a chain need not have distinct physical syndromes. The
   native call to closes distinguishes candidates with colliding keys. *)
Inductive chain_lists : Z -> list Z -> Prop :=
| list_end : forall q, q < 0 -> chain_lists q nil
| list_next : forall q qs, 0 <= q -> chain_lists (Znth q (links b)) qs -> chain_lists q (q :: qs).

Lemma chain_complete q qs : chain_lists q qs ->
  exists a, chain_run q a /\
    (a = -1 <-> forall x, In x qs -> ~usable b v odd x) /\
    (a <> -1 -> In a qs).
Proof.
  induction 1 as [q neg|q qs pos more [a [trace [miss member]]]].
  - exists (-1); split; [constructor; assumption|]. simpl; intuition.
  - destruct (classic (usable b v odd q)) as [yes|no].
    + exists q; split; [constructor; assumption|]. simpl; split; [|auto].
      split; [lia|intro none; exfalso; apply (none q); auto].
    + exists a; split; [apply chain_skip; assumption|]. simpl; split; [|auto].
      split.
      * intros E x [<-|later]; [assumption|exact (proj1 miss E _ later)].
      * intro none; apply (proj2 miss); intros x later; apply none; auto.
Qed.
Lemma probe_at_match i a : probe_run i a -> 0<=slot b i ->
  Znth (slot b i) (keys b)=query b -> chain_run (slot b i) a.
Proof. intros trace pos same; inversion trace;subst;try lia;try congruence;assumption. Qed.
Lemma probe_at_miss i a : probe_run i a -> 0<=slot b i ->
  Znth (slot b i) (keys b)<>query b -> probe_run (advance b i) a.
Proof. intros trace pos diff; inversion trace;subst;try lia;try congruence;assumption. Qed.
Lemma chain_at_hit q a : chain_run q a -> 0<=q -> usable b v odd q -> a=q.
Proof. intros trace pos yes; inversion trace;subst;try lia;contradiction. Qed.
Lemma chain_at_miss q a : chain_run q a -> 0<=q -> ~usable b v odd q ->
  chain_run (Znth q (links b)) a.
Proof. intros trace pos no; inversion trace;subst;try lia;try contradiction;assumption. Qed.
End Path.
