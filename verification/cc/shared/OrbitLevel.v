(* SPDX-License-Identifier: GPL-3.0-or-later *)
From mathcomp Require Import all_ssreflect all_algebra perm.
Require Import LeafMatrix MinimumPrefix LevelSearch.
Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.
Local Open Scope ring_scope.

Section Levels.
Variables m n k : nat.
Variables (H : 'M['F_2]_(m,n)) (L : 'M['F_2]_(k,n)).
Variable rank : 'I_n -> nat.
Variable rep : nat -> 'I_n.
Variable order : seq nat.
Hypothesis scheduled : forall q, rank q \in order.
Hypothesis maps : forall q : 'I_n, exists p : {perm 'I_n},
  [ /\ p q=rep (rank q),
       forall a, rank (p a)=rank a &
       forall S, logical H L (indicator S) -> logical H L (indicator (p @: S)) ].

(* The C++ producer permanently excludes every member of an exhausted
   orbit. Among earlier orbits is exactly what the rank threshold removes. *)
Definition orbit_free i := [set a : 'I_n | (i <= rank a)%N] :\ rep i.
Definition orbit_level w :=
  if w is rest.+1 then has (fun i => descend H L rest w [set rep i] (orbit_free i)) order
  else false.

Lemma orbit_level_sound w : orbit_level w ->
  exists T : {set 'I_n}, (#|T| == w)%N && logical H L (indicator T).
Proof. case: w=> [|w] //= /hasP[i _ hit]; exact: descend_sound hit. Qed.

Theorem orbit_minimum_level (x:'cV['F_2]_n) :
  minimum H L x -> orbit_level #|support x|.
Proof.
move=> minx; have nonempty := logical_nonempty (proj1 minx).
case W: #|support x| => [|w].
- by move: W;move/eqP;rewrite cards_eq0 (negbTE nonempty).
- have /set0Pn[q0 some] := nonempty.
  case: (@arg_minnP _ q0 (mem (support x)) rank some)=> q present first.
  have [p [at_rep keep valid]] := maps q.
  pose T := p @: support x.
  have same : #|T| = #|support x| by rewrite /T card_imset //;exact: perm_inj.
  have xp : indicator (support x)=x by apply: binary_support_inj;rewrite support_indicator.
  have found : logical H L (indicator T) by apply: valid;rewrite xp;exact: (proj1 minx).
  have least : minimum H L (indicator T).
    split=> // y ly; rewrite support_indicator same; exact: (proj2 minx y ly).
  have chosen : rep (rank q) \in T by rewrite -at_rep;exact: imset_f.
  apply/hasP; exists (rank q);first exact: scheduled.
  apply: (descend_complete (x:=indicator T) least).
  + by rewrite support_indicator same W.
  + apply/set0Pn;exists (rep (rank q));exact: set11.
  + by rewrite sub1set support_indicator.
  + rewrite support_indicator;apply/subsetP=> a;rewrite !inE => /andP[avoid belongs].
    rewrite avoid /=;move/imsetP: belongs=> [b mem ->];by rewrite keep first.
  + by rewrite cards1 add1n.
Qed.

Theorem orbit_smaller_empty (x:'cV['F_2]_n) w :
  minimum H L x -> (w < #|support x|)%N -> ~~ orbit_level w.
Proof.
move=> [_ least] small;apply/negP=> /orbit_level_sound[T /andP[/eqP wt ok]].
by move: (least _ ok);rewrite support_indicator wt leqNgt small.
Qed.
End Levels.
