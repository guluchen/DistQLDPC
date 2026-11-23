(* SPDX-License-Identifier: GPL-3.0-or-later *)
From mathcomp Require Import all_ssreflect all_algebra.
Require Import LeafMatrix MinimumPrefix LevelSearch.
Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.
Local Open Scope ring_scope.

(* MathComp supplies elimination and a right nullspace matrix. Its transpose
   detects non-membership in the row span, including dependent or empty PCMs. *)
Definition detectors m n (S : 'M['F_2]_(m,n)) := (cokermx S)^T.

Lemma detector_rowspan m n (S : 'M['F_2]_(m,n)) (x : 'cV['F_2]_n) :
  (detectors S *m x == 0) = (x^T <= S)%MS.
Proof. by rewrite /detectors submx.unlock -[LHS]trmx_eq0 trmx_mul trmxK. Qed.

Lemma distance_index_lower m n k (H : 'M['F_2]_(m,n)) (L : 'M['F_2]_(k,n)) x :
  logical H L x -> (distance_index H L <= #|support x|)%N.
Proof.
move=> found; have anyx : exists y, logical H L y by exists x.
have [y [[_ least] ->]] := distance_index_spec anyx.
exact: least _ found.
Qed.

Lemma distance_index_attained m n k (H : 'M['F_2]_(m,n)) (L : 'M['F_2]_(k,n)) :
  (distance_index H L <= n)%N ->
  exists x, logical H L x /\ #|support x| = distance_index H L.
Proof.
move=> within; case have_x: [exists x : 'cV['F_2]_n, logical H L x].
- move/existsP: have_x=> [x found]; have anyx : exists y, logical H L y by exists x.
  have [y [[good _] ->]] := distance_index_spec anyx; by exists y.
- have /existsPn none : ~~ [exists x : 'cV['F_2]_n, logical H L x] by rewrite have_x.
  by move: within; rewrite (distance_index_empty none) ltnn.
Qed.

Section CSS.
Variables mx mz n : nat.
Variables (X : 'M['F_2]_(mx,n)) (Z : 'M['F_2]_(mz,n)).
Definition mixed (x z : 'cV['F_2]_n) :=
  [&& Z *m x == 0, X *m z == 0 & ~~ ((x^T <= X)%MS && (z^T <= Z)%MS)].
Definition pauli_weight (x z : 'cV['F_2]_n) := #|support x :|: support z|.
Definition css_index := minn (distance_index Z (detectors X)) (distance_index X (detectors Z)).

Theorem css_lower x z : mixed x z -> (css_index <= pauli_weight x z)%N.
Proof.
move=> /and3P[hx hz nt]; move: nt; rewrite negb_and => /orP[lx|lz].
- have hit : logical Z (detectors X) x by rewrite /logical detector_rowspan hx lx.
  apply: leq_trans (geq_minl _ _) _; apply: leq_trans (distance_index_lower hit) _.
  exact: subset_leq_card (subsetUl _ _).
- have hit : logical X (detectors Z) z by rewrite /logical detector_rowspan hz lz.
  apply: leq_trans (geq_minr _ _) _; apply: leq_trans (distance_index_lower hit) _.
  exact: subset_leq_card (subsetUr _ _).
Qed.

Lemma support_zero : support (0 : 'cV['F_2]_n) = set0.
Proof. by apply/setP=> i; rewrite /support !inE mxE eqxx. Qed.

Theorem css_attained : (css_index <= n)%N ->
  exists x z, mixed x z /\ pauli_weight x z = css_index.
Proof.
rewrite /css_index.
case: (leqP (distance_index Z (detectors X)) (distance_index X (detectors Z))) => cmp.
- move=> /distance_index_attained [v [/andP[h l] wt]].
  exists v, 0; split; last by rewrite /pauli_weight support_zero setU0.
  by move: l; rewrite /mixed detector_rowspan h mulmx0 eqxx; case: (v^T <= X)%MS.
- move=> /distance_index_attained [v [/andP[h l] wt]].
  exists 0, v; split; last by rewrite /pauli_weight support_zero set0U.
  by move: l; rewrite /mixed detector_rowspan h mulmx0 eqxx; case: (v^T <= Z)%MS; rewrite ?andbF.
Qed.

(* For commuting PCMs encoding a logical qubit, this is the usual minimum
   CSS distance. If the mixed logical set is empty the sentinel is n+1. *)
Theorem css_distance_exact :
  (exists x z, mixed x z) ->
  exists x z, mixed x z /\ pauli_weight x z = css_index /\
      forall a b, mixed a b -> (css_index <= pauli_weight a b)%N.
Proof.
move=> [a [b allowed]]; have bounded := css_lower allowed.
have cap : (pauli_weight a b <= n)%N by move: (max_card (support a :|: support b)); rewrite card_ord.
have [x [z [ok wt]]] := css_attained (leq_trans bounded cap).
by exists x, z; split=> //; split=> //; exact: css_lower.
Qed.
Theorem css_distance_empty :
  (forall x z, ~~ mixed x z) -> css_index = n.+1.
Proof.
move=> no_pauli.
have no_x (v : 'cV['F_2]_n) : ~~ logical Z (detectors X) v.
  apply/negP=> /andP[check det].
  move: (no_pauli v 0) det; rewrite /mixed detector_rowspan check mulmx0 eqxx.
  by case: (v^T <= X)%MS.
have no_z (v : 'cV['F_2]_n) : ~~ logical X (detectors Z) v.
  apply/negP=> /andP[check det].
  move: (no_pauli 0 v) det; rewrite /mixed detector_rowspan check mulmx0 eqxx.
  by case: (v^T <= Z)%MS; rewrite ?andbF.
by rewrite /css_index (distance_index_empty no_x) (distance_index_empty no_z) minnn.
Qed.
End CSS.
