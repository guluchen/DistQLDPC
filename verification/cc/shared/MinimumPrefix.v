(* SPDX-License-Identifier: GPL-3.0-or-later *)
From mathcomp Require Import all_ssreflect all_algebra.
Require Import LeafMatrix.

Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.
Import GRing.Theory.
Local Open Scope ring_scope.

Section Prefix.
Variables m n k : nat.
Variables (H : 'M['F_2]_(m,n)) (L : 'M['F_2]_(k,n)).

Definition logical (x : 'cV['F_2]_n) := (H *m x == 0) && (L *m x != 0).
Definition minimum (x : 'cV['F_2]_n) :=
  logical x /\ forall y, logical y -> (#|support x| <= #|support y|)%N.

Lemma sum_support_subset (prefix target : 'cV['F_2]_n) :
  support prefix \subset support target ->
  support (target + prefix) = support target :\: support prefix.
Proof.
move=> sub; apply/setP=> i.
have bin (a : 'F_2) : a = 0 \/ a = 1.
  case: a=> a ha; case: a ha=> [|[|a]] ha; [left|right|]; try by apply: val_inj.
  by [].
have implies := (subsetP sub i).
rewrite /support !inE mxE in implies *.
by case: (bin (target i 0))=> Et; case: (bin (prefix i 0))=> Ep;
   rewrite Et Ep in implies * => //=; move: (implies isT).
Qed.

(* Every nonempty proper prefix of a minimum logical support has an odd
   physical check. Otherwise the prefix or its complement is a smaller
   logical operator. This is the reason DFS may stop at a closed prefix. *)
Theorem minimum_prefix_odd (prefix target : 'cV['F_2]_n) :
  minimum target -> support prefix != set0 ->
  support prefix \proper support target -> H *m prefix != 0.
Proof.
move=> [/andP[/eqP ht lt0] least] nonempty proper.
apply/eqP=> hp.
have small : (#|support prefix| < #|support target|)%N := proper_card proper.
have lp0 : L *m prefix = 0.
  apply/eqP; case eqp: (L *m prefix == 0) => //.
  have lv : logical prefix by rewrite /logical hp eqxx eqp.
  by move: (least prefix lv); rewrite leqNgt small.
have other : logical (target + prefix).
  by rewrite /logical !mulmxDr ht hp lp0 !addr0 eqxx.
have sub := proper_sub proper.
have residual := sum_support_subset sub.
have proper_rest : support target :\: support prefix \proper support target.
  rewrite properE subsetDl; apply/negP=> included.
  have /set0Pn [i hi] := nonempty.
  have inside := subsetP sub i hi.
  by move: (subsetP included i inside); rewrite inE hi.
have less := proper_card proper_rest.
by move: (least _ other); rewrite residual leqNgt less.
Qed.
End Prefix.

Section OddRow.
Variables m n : nat.
Variable H : 'M['F_2]_(m,n).

(* At any odd check, a target extending the prefix must add an incident
   qubit. The quantification includes arbitrary row and qubit order. *)
Theorem odd_row_hits_residual (prefix target : 'cV['F_2]_n) (r : 'I_m) :
  support prefix \subset support target -> H *m target = 0 ->
  (H *m prefix) r 0 != 0 ->
  exists q : 'I_n, q \in support target :\: support prefix /\ H r q != 0.
Proof.
move=> sub closed odd.
have residual : H *m (target + prefix) = H *m prefix.
  by rewrite mulmxDr closed add0r.
have hits : [exists q : 'I_n,
  (q \in support (target + prefix)) && (H r q != 0)].
  case E: [exists q : 'I_n, (q \in support (target + prefix)) && (H r q != 0)] => //.
  exfalso; have /existsPn miss : ~~ [exists q : 'I_n, (q \in support (target + prefix)) && (H r q != 0)] by rewrite E.
  have zero : (H *m (target + prefix)) r 0 = 0.
    rewrite mxE; apply: big1 => q _.
    move: (miss q); rewrite /support inE negb_and !negbK.
    by move/orP=> [/eqP -> | /eqP ->]; rewrite (mulr0, mul0r).
  by move: odd; rewrite -residual zero eqxx.
move/existsP: hits=> [q /andP[hq inc]]; exists q; split=> //.
by move: hq; rewrite (sum_support_subset sub).
Qed.
End OddRow.
