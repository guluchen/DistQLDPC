(* SPDX-License-Identifier: GPL-3.0-or-later *)
From mathcomp Require Import all_ssreflect all_algebra.
Require Import LeafMatrix MinimumOverlap.
Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.
Import GRing.Theory.
Local Open Scope ring_scope.

Lemma parity_of_sum m (v c : 'cV['F_2]_m) :
  odd #|support (v+c)| = odd #|support v| (+) odd #|support c|.
Proof.
rewrite support_sum; set A := support v; set B := support c.
have disj : (A :\: B) :&: (B :\: A) = set0.
  by apply/setP=> i; rewrite !inE; case: (c i 0 != 0); case: (v i 0 != 0).
have U := cardsUI (A :\: B) (B :\: A); rewrite disj cards0 addn0 in U.
have XA := cardsID B A; have XB := cardsID A B; rewrite (setIC B A) in XB.
rewrite U -XA -XB !oddD.
by case: (odd #|A :&: B|); case: (odd #|A :\: B|); case: (odd #|B :\: A|).
Qed.

Section Parity.
Variables m n : nat.
Variable H : 'M['F_2]_(m,n).
Hypothesis every_column_odd : forall q : 'I_n, odd #|support (col q H)|.

Fixpoint add_columns (qs : seq 'I_n) (v : 'cV['F_2]_m) :=
  if qs is q :: rest then add_columns rest (v + col q H) else v.

Lemma parity_after qs v :
  odd #|support (add_columns qs v)| = odd #|support v| (+) odd (size qs).
Proof.
elim: qs v => [|q qs IH] v /=; first by rewrite addbF.
rewrite IH parity_of_sum every_column_odd /=.
by case: (odd #|support v|); case: (odd (size qs)).
Qed.

Theorem parity_prune qs v :
  odd #|support v| != odd (size qs) -> add_columns qs v != 0.
Proof.
move=> diff; apply/eqP=> zero.
have supp0 : support (0 : 'cV['F_2]_m) = set0 by apply/setP=> i; rewrite /support !inE mxE eqxx.
have := parity_after qs v; rewrite zero supp0 cards0 /=.
by move: diff; case: (odd #|support v|); case: (odd (size qs)).
Qed.
End Parity.
