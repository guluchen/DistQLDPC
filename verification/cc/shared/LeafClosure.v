(* SPDX-License-Identifier: GPL-3.0-or-later *)
From mathcomp Require Import all_ssreflect.

Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.

Section Leaf.
Variables (row detector : finType).

(* The incident rows of one physical column are stored without duplicates.
   Auxiliary rows used only for pruning do not enter the odd-row count. *)
Definition row_scan (rows : seq row) (odd : {set row}) :=
  (size rows == #|odd|) && all (mem odd) rows.

Lemma row_scanP rows odd : uniq rows ->
  reflect ([set r in rows] = odd) (row_scan rows odd).
Proof.
move=> distinct; apply: (iffP andP).
- move=> [/eqP size_odd /allP included].
  apply/eqP; rewrite eqEcard; apply/andP; split.
  + by apply/subsetP=> r; rewrite inE; apply: included.
  + by rewrite cardsE (card_uniqP distinct) size_odd.
- move=> <-; split.
  + by rewrite cardsE (card_uniqP distinct) eqxx.
  + by apply/allP=> r hr; rewrite !inE.
Qed.

(* For both the physical syndrome and the logical detector parities,
   adding one qubit toggles exactly its incident bits over GF(2). *)
Definition leaf_test rows odd (current column : {set detector}) :=
  row_scan rows odd && (current != column).

Theorem leaf_testP (rows : seq row) (odd : {set row}) (current column : {set detector}) : uniq rows ->
  reflect
    ((forall r, xorb (r \in odd) (r \in rows) = false) /\
     (exists k, xorb (k \in current) (k \in column) = true))
    (leaf_test rows odd current column).
Proof.
move=> distinct; apply: (iffP andP).
- move=> [/(row_scanP odd distinct) <- different]; split.
  + by move=> r; rewrite inE; case: (r \in rows).
  + have /existsP [k hk] : [exists k, (k \in current) != (k \in column)].
      case E: [exists k, (k \in current) != (k \in column)] => //.
      exfalso; move/eqP: different; apply; apply/setP=> k.
      have no : ~~ [exists k, (k \in current) != (k \in column)] by rewrite E.
      move/existsPn: no => no. by move: (no k); rewrite negbK => /eqP.
    by exists k; move: hk; case: (k \in current); case: (k \in column).
- move=> [zero [k hk]]; split.
  + apply/(row_scanP odd distinct)/setP=> r; rewrite inE.
    by move: (zero r); case: (r \in odd); case: (r \in rows).
  + apply/eqP=> eq; move: hk; rewrite eq; by case: (k \in column).
Qed.
End Leaf.
