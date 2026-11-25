(* SPDX-License-Identifier: GPL-3.0-or-later *)
From mathcomp Require Import all_ssreflect all_algebra.
Require Import LeafMatrix MinimumPrefix LevelSearch CSSLevelDistance DetectorRank NativeHalfExists.
Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.
Local Open Scope ring_scope.

Section ValidatedHalf.
Variables m r k n:nat.
Variables (H:'M['F_2]_(m,n)) (S:'M['F_2]_(r,n)) (G:'M['F_2]_(k,n)).
Hypotheses (orth:H*m S^T=0) (det:G*m S^T=0) (shape:(\rank (col_mx H G)+\rank S=n)%N).
Lemma quotient_finite_from_detector_rank :
 (distance_index H (detectors S)<=n)%N = (\rank H<\rank (col_mx H G))%N.
Proof.
 apply/idP/idP.
 - move/distance_index_attained=>[x [ok _]];apply/rank_detects_logical;exists x.
   by rewrite (@validated_logical m r k n H S G orth det shape).
 - move/rank_detects_logical=>[x ok].
   rewrite (@validated_logical m r k n H S G orth det shape) in ok.
   apply:leq_trans (distance_index_lower ok) _.
   by have bound:=max_card (support x);rewrite card_ord in bound.
Qed.
End ValidatedHalf.

(* None represents +infinity. No sentinel is exposed as a finite weight. *)
Definition extended_css_distance mx mz n (X:'M['F_2]_(mx,n)) (Z:'M['F_2]_(mz,n)) :=
 if (css_index X Z<=n)%N then Some (css_index X Z) else None.

Lemma no_finite_value (d:nat) (x z:bool):
 (if x || z then Some d else None)=None <-> x=false /\ z=false.
Proof. destruct x,z;simpl;intuition congruence. Qed.

Section BothHalves.
Variables mx mz lx lz n:nat.
Variables (X:'M['F_2]_(mx,n)) (Z:'M['F_2]_(mz,n)) (DX:'M['F_2]_(lx,n)) (DZ:'M['F_2]_(lz,n)).
Hypotheses (zx:Z*m X^T=0) (xz:X*m Z^T=0) (dx:DX*m X^T=0) (dz:DZ*m Z^T=0)
 (rx:(\rank (col_mx Z DX)+\rank X=n)%N) (rz:(\rank (col_mx X DZ)+\rank Z=n)%N).
Let exists_x:=(\rank Z<\rank (col_mx Z DX))%N.
Let exists_z:=(\rank X<\rank (col_mx X DZ))%N.

Theorem no_logical_rank_exit :
 extended_css_distance X Z=None <-> exists_x=false /\ exists_z=false.
Proof.
 have finite:(css_index X Z<=n)%N=exists_x || exists_z.
 { have fx:=@quotient_finite_from_detector_rank mz mx lx n Z X DX zx dx rx.
   have fz:=@quotient_finite_from_detector_rank mx mz lz n X Z DZ xz dz rz.
   change ((minn (distance_index Z (detectors X)) (distance_index X (detectors Z)) <= n)%N
     = ((\rank Z < \rank (col_mx Z DX))%N || (\rank X < \rank (col_mx X DZ))%N)).
   exact: (etrans (geq_min n (distance_index Z (detectors X)) (distance_index X (detectors Z)))
      (congr2 orb fx fz)). }
 rewrite /extended_css_distance finite;apply no_finite_value.
Qed.

Theorem infinity_iff_zero_encoded_qubits :
 extended_css_distance X Z=None <-> (n-(\rank X+\rank Z)=0)%N.
Proof.
 have xflag:exists_x=(\rank X+\rank Z<n)%N.
 { by rewrite /exists_x -(ltn_add2r (\rank X)) rx addnC. }
 have zflag:exists_z=(\rank X+\rank Z<n)%N.
 { by rewrite /exists_z -(ltn_add2r (\rank Z)) rz. }
 rewrite no_logical_rank_exit xflag zflag.
 split.
 - move=>[absent _];apply/eqP;by rewrite subn_eq0 leqNgt absent.
 - move/eqP;rewrite subn_eq0 leqNgt=>/negPf absent;by split.
Qed.

Theorem infinity_iff_no_pauli :
 extended_css_distance X Z=None <-> forall x z, ~~ mixed X Z x z.
Proof.
 split.
 - rewrite /extended_css_distance;case finite:(css_index X Z<=n)%N;first discriminate.
   move=> _ x z;apply/negP=> hit.
   have cap:(pauli_weight x z<=n)%N by move:(max_card (support x :|: support z));rewrite card_ord.
   have within:=leq_trans (css_lower hit) cap;by rewrite finite in within.
 - move=> absent;by rewrite /extended_css_distance (css_distance_empty absent) ltnn.
Qed.

Theorem finite_result_is_minimum d :
 extended_css_distance X Z=Some d ->
 exists x z, mixed X Z x z /\ pauli_weight x z=d /\ forall a b,mixed X Z a b -> (d<=pauli_weight a b)%N.
Proof.
 rewrite /extended_css_distance;case bounded:(css_index X Z<=n)%N;last discriminate.
 move=> value;injection value as eqd;subst d.
 have [x [z [ok wt]]]:=css_attained bounded.
 by exists x,z;split=> //;split=> //;exact:css_lower.
Qed.
End BothHalves.
