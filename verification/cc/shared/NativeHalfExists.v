(* SPDX-License-Identifier: GPL-3.0-or-later *)
From Coq Require Import Lia.
From mathcomp Require Import all_ssreflect all_algebra.
Require Import LeafMatrix MinimumPrefix LevelSearch CSSLevelDistance DetectorRank.
Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.
Local Open Scope ring_scope.

Lemma nested_rank (r u v:nat) (P:'M['F_2]_(u,r)) (Q:'M['F_2]_(v,r)) :
 (P<=Q)%MS -> ~~(Q<=P)%MS = (\rank P<\rank Q)%N.
Proof.
move=> included.
have s1 : (P<Q)%MS = ~~(Q<=P)%MS.
  by rewrite ltmxE included.
have s2 := ltmxErank P Q.
by rewrite -s1 s2 included.
Qed.

Section Existence.
Variables m k n:nat.
Variables (H:'M['F_2]_(m,n)) (G:'M['F_2]_(k,n)).
Let J:=col_mx H G.
Let A:=kermx H^T.
Let B:=kermx J^T.
Lemma row_closed (v:'rV['F_2]_n): (v<=A)%MS = (H*m v^T==0).
Proof. by rewrite /A sub_kermx -[RHS]trmx_eq0 trmx_mul trmxK. Qed.
Lemma row_undetected (v:'rV['F_2]_n):
 (v<=B)%MS = (H*m v^T==0) && (G*m v^T==0).
Proof. by rewrite /B sub_kermx -trmx_eq0 trmx_mul !trmxK /J mul_col_mx col_mx_eq0. Qed.
Lemma detected_kernel_order : (B<=A)%MS.
Proof.
apply/row_subP=> i;rewrite row_closed.
have ok:=(row_sub i B);by move:ok;rewrite row_undetected=> /andP[].
Qed.
Lemma strict_kernel_rank :
 ~~(A<=B)%MS = (\rank H<\rank J)%N.
Proof.
transitivity (\rank B < \rank A)%N.
- exact: (@nested_rank n n n B A detected_kernel_order).
- have rb : \rank B = (n - \rank J)%N :=
    etrans (mxrank_ker J^T) (congr1 (subn n) (mxrank_tr J)).
  have ra : \rank A = (n - \rank H)%N :=
    etrans (mxrank_ker H^T) (congr1 (subn n) (mxrank_tr H)).
  exact: (etrans (congr2 ltn rb ra) (@ltn_sub2lE n (\rank H) (\rank J) (rank_leq_col J))).
Qed.
Theorem rank_detects_logical :
 reflect (exists x,logical H G x) (\rank H<\rank J)%N.
Proof.
rewrite -strict_kernel_rank;apply:(iffP idP).
- move/row_subPn=>[i odd];exists (row i A)^T.
  have closed:=row_sub i A;rewrite row_closed in closed.
  by move:odd;rewrite row_undetected closed /logical closed.
- move=> [x /andP[closed detected]];apply/negP=> included.
  have member:(x^T<=A)%MS by rewrite row_closed trmxK.
  have both:=submx_trans member included.
  by move:both;rewrite row_undetected trmxK closed /= (negbTE detected).
Qed.
Theorem finite_iff_rank : (distance_index H G<=n)%N=(\rank H<\rank J)%N.
Proof.
case grow:(\rank H<\rank J)%N.
- have /rank_detects_logical[x ok] : (\rank H<\rank J)%N by rewrite grow.
  apply/idP;apply:leq_trans (distance_index_lower ok) _.
  by have bound:=max_card (support x);rewrite card_ord in bound.
- have absent:forall x,~~logical H G x.
  { move=> x;apply/negP=> ok;have /rank_detects_logical : exists y,logical H G y by exists x.
    by rewrite grow. }
  by rewrite (distance_index_empty absent) ltnn.
Qed.
End Existence.
