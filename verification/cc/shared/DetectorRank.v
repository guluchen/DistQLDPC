(* SPDX-License-Identifier: GPL-3.0-or-later *)
From mathcomp Require Import all_ssreflect all_algebra.
Require Import MinimumPrefix LevelSearch CSSLevelDistance.
Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.
Local Open Scope ring_scope.

(* These are the two orthogonality checks and the rank identity enforced
   by detector_check before it uses an input detector matrix G. *)
Section InputDetectors.
Variables m s k n : nat.
Variables (H : 'M['F_2]_(m,n)) (S : 'M['F_2]_(s,n)) (G : 'M['F_2]_(k,n)).
Let J := col_mx H G.
Hypotheses (orthH : H *m S^T = 0) (orthG : G *m S^T = 0).
Hypothesis dimensions : (\rank J + \rank S = n)%N.

Lemma validated_kernel : (S :=: kermx J^T)%MS.
Proof.
have included : (S <= kermx J^T)%MS.
  by rewrite sub_kermx -trmx_eq0 trmx_mul trmxK /J mul_col_mx orthH orthG col_mx0.
apply/eqmxP; rewrite -(eq_leqif (mxrank_leqif_eq included)) mxrank_ker mxrank_tr.
have cancel_rank (a b c : nat) : (a + b = c)%N -> b = (c-a)%N.
  by move=> <-; rewrite addKn.
apply/eqP; exact: cancel_rank dimensions.
Qed.

Theorem validated_detector (x : 'cV['F_2]_n) :
  H *m x = 0 -> (G *m x == 0) = (x^T <= S)%MS.
Proof.
move=> closed; rewrite validated_kernel sub_kermx -[RHS]trmx_eq0 trmx_mul !trmxK.
by rewrite /J mul_col_mx closed col_mx_eq0 eqxx.
Qed.

Theorem validated_logical (x : 'cV['F_2]_n) :
  logical H G x = logical H (detectors S) x.
Proof.
rewrite /logical detector_rowspan; case test: (H *m x == 0)=> //=.
by rewrite (validated_detector (eqP test)).
Qed.
End InputDetectors.
