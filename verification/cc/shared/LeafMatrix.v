(* SPDX-License-Identifier: GPL-3.0-or-later *)
From mathcomp Require Import all_ssreflect all_algebra.
Require Import LeafClosure.

Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.
Import GRing.Theory.
Local Open Scope ring_scope.

Section MatrixLeaf.
Variables m n k : nat.
Variables (H : 'M['F_2]_(m,n)) (L : 'M['F_2]_(k,n)).

Definition support j (v : 'cV['F_2]_j) := [set i | v i 0 != 0].

Lemma binary_support_inj j : injective (@support j).
Proof.
move=> a b same; apply/matrixP=> i z; rewrite (ord1 z).
have E := congr1 (fun s : {set 'I_j} => i \in s) same.
move: E; rewrite /support !inE.
have bin (x : 'F_2) : x = 0 \/ x = 1.
  case: x=> x hx; case: x hx=> [|[|x]] hx; [left|right|]; try by apply: val_inj.
  by [].
by case: (bin (a i 0))=> ->; case: (bin (b i 0))=> ->.
Qed.

Lemma binary_opp j (v : 'cV['F_2]_j) : - v = v.
Proof.
apply/matrixP=> i t; rewrite mxE.
have two_prime : prime 2 by [].
exact: (oppr_char2 (char_Fp two_prime)).
Qed.

(* No rank or distance hint. L is the supplied detector matrix; its spanning
   condition for CSS nontriviality belongs to the caller. *)
Theorem leaf_matrix_exact (x : 'cV['F_2]_n) (q : 'I_n) (rows : seq 'I_m) :
  uniq rows -> [set r in rows] = support (col q H) ->
  leaf_test rows (support (H *m x)) (support (L *m x)) (support (col q L)) =
    ((H *m (x + delta_mx q 0) == 0) && (L *m (x + delta_mx q 0) != 0)).
Proof.
move=> distinct hrs.
rewrite !mulmxDr -!colE !addr_eq0 !binary_opp.
rewrite /leaf_test (inj_eq (@binary_support_inj k)).
congr (_ && _).
apply/idP/eqP.
- move/(row_scanP _ distinct)=> h.
  by apply: binary_support_inj; rewrite -h hrs.
- move=> h; apply/(row_scanP _ distinct). by rewrite h hrs.
Qed.
End MatrixLeaf.

(* The degree mismatch rejected by the first branch of C closes is a
   sufficient reason to discard q, independently of the detector matrix. *)
Theorem count_mismatch_nonzero m n (H : 'M['F_2]_(m,n)) (x : 'cV['F_2]_n)
    (q : 'I_n) (rows : seq 'I_m) :
  uniq rows -> [set r in rows] = support (col q H) ->
  size rows != #|support (H *m x)| -> H *m (x + delta_mx q 0) != 0.
Proof.
move=> distinct hrs diff; rewrite mulmxDr -colE addr_eq0 binary_opp.
apply/eqP=> same; move/eqP: diff; apply.
by rewrite same -hrs cardsE (card_uniqP distinct).
Qed.
