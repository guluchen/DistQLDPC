(* SPDX-License-Identifier: GPL-3.0-or-later *)
From mathcomp Require Import all_ssreflect.
Require Import ChargeBound.
Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.

Section IndexScan.
Variables Q R : finType.
Variable incidence : R -> {set Q}.
Variables free target : {set Q}.
Variable odd : {set R}.
Variable budget : nat.
Definition choices r := incidence r :&: free.

(* index_children remembers the first odd row. Its greedy packing can see
   stale marks after stamp wrap. Extra marks can only prevent a row from
   entering the packing. *)
Fixpoint scan (rs : seq R) (marked : {set Q}) (packed : nat) :=
  if rs is r :: tail then
    if choices r == set0 then false
    else if [disjoint choices r & marked] then
      (packed.+1 <= budget) && scan tail (marked :|: incidence r) packed.+1
    else scan tail marked packed
  else true.

Hypothesis allowed : target \subset free.
Hypothesis weight : #|target| <= budget.
Hypothesis covers : forall r, r \in odd -> exists2 q, q \in target & q \in incidence r.

Theorem scan_keeps_target rs marked packed :
  {subset rs <= odd} -> packed <= #|target :&: marked| ->
  scan rs marked packed.
Proof.
elim: rs marked packed=> [|r rs ih] marked packed //= rows count.
have od : r \in odd by apply: rows; rewrite inE eqxx.
have [q member touches] := covers od.
have qfree := subsetP allowed q member.
have candidate : q \in choices r by rewrite /choices inE touches qfree.
have nonempty : choices r != set0 by apply/set0Pn; exists q.
rewrite (negbTE nonempty); case D: [disjoint choices r & marked].
- have outside : q \notin marked.
    by rewrite (disjointFr D candidate).
  have inside : target :&: marked \proper target :&: (marked :|: incidence r).
    rewrite properE; apply/andP; split.
    + apply/subsetP=> x; rewrite !inE => /andP[t m]; by rewrite t m.
    + apply/negP=> /subsetP back.
      have bigger : q \in target :&: (marked :|: incidence r) by rewrite !inE member touches orbT.
      by move: (back q bigger); rewrite inE (negbTE outside) andbF.
  have strict := proper_card inside.
  have extended : packed.+1 <= #|target :&: (marked :|: incidence r)| := leq_ltn_trans count strict.
  apply/andP; split.
  + apply: leq_trans extended _. apply: leq_trans _ weight.
    exact: subset_leq_card (subsetIl _ _).
  + apply: ih => // x later. apply: rows; by rewrite inE later orbT.
- apply: ih => // x later. apply: rows; by rewrite inE later orbT.
Qed.

Theorem first_branch_covers r rs marked :
  {subset r :: rs <= odd} ->
  scan (r :: rs) marked 0 /\ exists2 q, q \in target & q \in choices r.
Proof.
move=> rows; split; first exact: scan_keeps_target rows (leq0n _).
have od : r \in odd by apply: rows; rewrite inE eqxx.
have [q mem incidence_q] := covers od.
exists q=> //; by rewrite /choices inE incidence_q (subsetP allowed q mem).
Qed.
End IndexScan.
