(* SPDX-License-Identifier: GPL-3.0-or-later *)
From mathcomp Require Import all_ssreflect.

Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.

Section Branches.
Variable Q : finType.
Variable default_qubit : Q.
Variable children : seq Q.

(* Child i includes children[i] and excludes every earlier sibling. *)
Definition owns (target : {set Q}) (i : nat) : Prop :=
  [ /\ i < size children, nth default_qubit children i \in target &
       forall j, j < i -> nth default_qubit children j \notin target ].

Theorem dfs_siblings_partition (target : {set Q}) :
  has (mem target) children -> exists! i, owns target i.
Proof.
move=> hit; set i := find (mem target) children.
have inside : i < size children by rewrite -has_find.
have present : nth default_qubit children i \in target := nth_find _ hit.
have earlier j : j < i -> nth default_qubit children j \notin target.
  move=> before; apply/negbT. exact: (before_find default_qubit before).
exists i; split; first by split.
move=> k [_ selected excluded].
case: (ltngtP i k)=> [lt|lt|eq].
- exfalso; exact: (negP (excluded i lt) present).
- exfalso; exact: (negP (earlier k lt) selected).
- exact eq.
Qed.
End Branches.
