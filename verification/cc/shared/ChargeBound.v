(* SPDX-License-Identifier: GPL-3.0-or-later *)
From mathcomp Require Import all_ssreflect.
Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.

Section Cover.
Variables R Q : finType.
Variables (odd : {set R}) (target : {set Q}) (incident : R -> {set Q}).
Variable charge : R -> nat.
Variable cap : nat.
Hypothesis covered : forall r, r \in odd -> exists2 q, q \in target & q \in incident r.
Definition load r q := if q \in incident r then charge r else 0.
Hypothesis capacity : forall q, q \in target -> \sum_(r in odd) load r q <= cap.

(* Every odd row must be hit. Summing row charges by qubit yields the
   certified lower bound; charge selection and the row order are unrestricted. *)
Theorem charge_bound : \sum_(r in odd) charge r <= #|target| * cap.
Proof.
have row r : r \in odd -> charge r <= \sum_(q in target) load r q.
  move=> /covered [q present hits].
  by rewrite (bigD1 q present) //= /load hits leq_addr.
apply: (@leq_trans (\sum_(r in odd) \sum_(q in target) load r q)); first exact: leq_sum.
rewrite exchange_big -sum_nat_const; exact: leq_sum.
Qed.
End Cover.

Section Packing.
Variables R Q : finType.
Variables (rows : {set R}) (target : {set Q}) (incident : R -> {set Q}).
Hypothesis covered : forall r, r \in rows -> exists2 q, q \in target & q \in incident r.
Hypothesis disjoint : forall q r s, q \in target -> r \in rows -> s \in rows ->
  q \in incident r -> q \in incident s -> r = s.

Theorem packing_bound : #|rows| <= #|target|.
Proof.
have cap q : q \in target -> \sum_(r in rows) load incident (fun _ => 1) r q <= 1.
  move=> present.
  case E: [exists r : R, (r \in rows) && (q \in incident r)].
  - move/existsP: E=> [r /andP[found hits]].
    rewrite (bigD1 r found) //= /load hits.
    have -> : \sum_(i in rows | i != r) (if q \in incident i then 1 else 0) = 0.
      apply: big1=> i /andP[inside diff]; case I: (q \in incident i) => //.
      by move: diff; rewrite (disjoint present inside found I hits) eqxx.
    by [].
  - have /existsPn missing : ~~ [exists r : R, (r \in rows) && (q \in incident r)] by rewrite E.
    rewrite big1 // => r inside; move: (missing r); rewrite inside /= /load.
    by case: (q \in incident r).
have := @charge_bound R Q rows target incident (fun _ => 1) 1 covered cap.
by rewrite sum_nat_const !muln1.
Qed.
End Packing.
