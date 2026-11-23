(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto.

Definition slot_index (i:int64) := Int64.unsigned i.
Definition insert_home ks mask q := Int64.and (Znth q ks) mask.
Definition insert_next mask i := Int64.and (Int64.add i Int64.one) mask.

Section Builder.
Variables (ks:list int64) (mask:int64) (size:Z).
Let n := Zlength ks.
Definition head (tab:list Z) i := Znth (slot_index i) tab.
Inductive reached q tab : int64 -> Prop :=
| at_home : reached q tab (insert_home ks mask q)
| after_collision : forall i, reached q tab i -> 0<=head tab i ->
    Znth (head tab i) ks<>Znth q ks -> reached q tab (insert_next mask i).

(* q is the next column to insert. The constructor traverses columns in
   descending order and uses the first empty or equal-key slot. *)
Inductive history : Z -> list Z -> list Z -> Prop :=
| initially : history (n-1) (Zrepeat (-1) size) (Zrepeat (-1) n)
| placed_empty : forall q tab links i, history q tab links -> 0<=q ->
    reached q tab i -> head tab i<0 ->
    history (q-1) (upd_Znth (slot_index i) tab q) links
| placed_chain : forall q tab links i, history q tab links -> 0<=q ->
    reached q tab i -> 0<=head tab i -> Znth (head tab i) ks=Znth q ks ->
    history (q-1) (upd_Znth (slot_index i) tab q) (upd_Znth q links (head tab i)).

Hypothesis mask_ok : Int64.unsigned mask<size.
Lemma masked_inside word : 0<=slot_index (Int64.and word mask)<size.
Proof.
  split;[apply Int64.unsigned_range|]. unfold slot_index;rewrite Int64.and_commut.
  pose proof (Int64.and_le mask word);lia.
Qed.
Lemma reached_inside q tab i : reached q tab i -> 0<=slot_index i<size.
Proof. destruct 1;apply masked_inside. Qed.

Record shape q (tab links:list Z) := {
  remaining : -1<=q<n;
  slot_count : Zlength tab=size;
  link_count : Zlength links=n;
  heads_inserted : forall j, 0<=j<size -> Znth j tab = -1 \/ q<Znth j tab<n;
  links_increase : forall j, 0<=j<n -> Znth j links= -1 \/
     (j<Znth j links<n /\ Znth (Znth j links) ks=Znth j ks)
}.
Lemma next_shape q tab links i : shape q tab links -> 0<=q -> reached q tab i ->
  forall later, (later=links \/
    (0<=head tab i /\ Znth (head tab i) ks=Znth q ks /\ later=upd_Znth q links (head tab i))) ->
  shape (q-1) (upd_Znth (slot_index i) tab q) later.
Proof.
  intros [bounds length links_len old_heads old_links] pos traced later set_link.
  pose proof (reached_inside _ _ _ traced) as inside.
  assert (valid_slot:0<=slot_index i<Zlength tab) by lia.
  assert (valid_q:0<=q<Zlength links) by lia.
  constructor.
  - lia.
  - rewrite upd_Znth_Zlength by lia;assumption.
  - destruct set_link as [->|[_ [_ ->]]];[exact links_len|rewrite upd_Znth_Zlength by lia;assumption].
  - intros j loc. destruct (Z.eq_dec j (slot_index i)) as [->|other].
    + rewrite upd_Znth_same by lia;right;lia.
    + rewrite upd_Znth_diff by lia;destruct (old_heads j loc);[left|right];lia.
  - intros j loc. destruct set_link as [->|[nonnegative [same ->]]];[apply old_links;assumption|].
    destruct (Z.eq_dec j q) as [->|other].
    + rewrite upd_Znth_same by lia;right;split;[|exact same].
      destruct (old_heads (slot_index i) inside);unfold head in *;lia.
    + rewrite upd_Znth_diff by lia;apply old_links;assumption.
Qed.
Theorem history_shape q tab links : history q tab links -> shape q tab links.
Proof.
  induction 1.
  - pose proof (Int64.unsigned_range mask) as M. pose proof (Zlength_nonneg ks) as N.
    assert (nonneg:0<=size) by lia. constructor;unfold n in *.
    + lia.
    + rewrite Zlength_Zrepeat by lia;reflexivity.
    + rewrite Zlength_Zrepeat by lia;reflexivity.
    + intros;left;apply Znth_Zrepeat;assumption.
    + intros;left;apply Znth_Zrepeat;assumption.
  - eapply next_shape;eauto.
  - eapply next_shape;eauto.
Qed.
End Builder.
