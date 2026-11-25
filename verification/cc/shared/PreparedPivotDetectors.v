(* SPDX-License-Identifier: GPL-3.0-or-later *)
From mathcomp Require Import all_ssreflect all_algebra.
Require Import LeafMatrix MinimumPrefix LevelSearch CSSLevelDistance.
Set Implicit Arguments.
Unset Strict Implicit.
Import GRing.Theory.
Local Open Scope ring_scope.

(* The native raw-PCM path packs one detector per free column. Its
   signature is the component of the witness left in that coordinate
   after eliminating the pivot columns of the same-type stabilizers. *)
Section Residual.
Variables n r f:nat.
Variables (B:'M['F_2]_(r,n)) (P:'M['F_2]_(n,r)) (F:'M['F_2]_(n,f)).
Hypotheses (pivot_columns:B*m P = 1%:M)
 (partition:P*m P^T + F*m F^T = 1%:M).

Definition reduced (v:'rV['F_2]_n):=v-(v*m P)*m B.
Definition residual_detectors:=((1%:M-P*m B)*m F)^T.

Lemma clears_pivots v:reduced v*m P=0.
Proof. by rewrite /reduced mulmxBl -(mulmxA (v*m P) B P) pivot_columns mulmx1 subrr. Qed.

Lemma read_residual (x:'cV['F_2]_n):
 (residual_detectors*m x)^T=reduced x^T*m F.
Proof.
 by rewrite /residual_detectors trmx_mul trmxK (mulmxA x^T _ F) mulmxBr mulmx1 (mulmxA x^T P B).
Qed.

Lemma residual_vanishes v:reduced v*m F=0 <-> reduced v=0.
Proof.
 split;last by move=> ->;rewrite mul0mx.
 move=>off;have cols:=congr1 (fun A:'M['F_2]_n=>reduced v*m A) partition.
 by move:cols;rewrite mulmxDr (mulmxA (reduced v) P _) (mulmxA (reduced v) F _) clears_pivots off !mul0mx add0r mulmx1=> <-.
Qed.

Theorem detector_kernel_is_reduced_rowspan (x:'cV['F_2]_n):
 (residual_detectors*m x==0)=(x^T<=B)%MS.
Proof.
 rewrite -[LHS]trmx_eq0 read_residual.
 apply/idP/idP.
 - move/eqP/residual_vanishes;rewrite /reduced=>/eqP.
   rewrite subr_eq0=>/eqP same.
   apply/submxP;by exists (x^T*m P).
 - move/submxP=>[coef same];apply/eqP/residual_vanishes.
   by rewrite /reduced same -(mulmxA coef B P) pivot_columns mulmx1 subrr.
Qed.

Theorem detector_reads_raw_stabilizers s m (S:'M['F_2]_(s,n)) (H:'M['F_2]_(m,n)):
 (S:=:B)%MS -> forall x,logical H residual_detectors x=logical H (detectors S) x.
Proof.
 move=>space x;rewrite /logical detector_rowspan detector_kernel_is_reduced_rowspan.
 by rewrite space.
Qed.
End Residual.
