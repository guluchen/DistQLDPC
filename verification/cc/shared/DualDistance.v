(* SPDX-License-Identifier: GPL-3.0-or-later *)
From mathcomp Require Import all_ssreflect all_algebra fingroup perm.
Require Import LeafMatrix MinimumPrefix LevelSearch CSSLevelDistance.
Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.
Local Open Scope ring_scope.
Section Dual.
Variables n h1 h2 k1 k2:nat.
Variables (A:'M['F_2]_(h1,n)) (D:'M['F_2]_(k1,n))
          (B:'M['F_2]_(h2,n)) (L:'M['F_2]_(k2,n)).
Variables p:{perm 'I_n}.
Definition transport_support (u:{perm 'I_n}) (x:'cV['F_2]_n) := indicator (u @: support x).
Lemma transported_weight u x : #|support (transport_support u x)|=#|support x|.
Proof. by rewrite /transport_support support_indicator card_imset //;exact:perm_inj. Qed.
Hypothesis go:forall x,logical A D x -> logical B L (transport_support p x).
Hypothesis back:forall x,logical B L x -> logical A D (transport_support (p^-1)%g x).
(* A checked map in both directions lets the driver copy completed lower
   bounds between halves, including when the common logical set is empty. *)
Theorem equal_half_distance : distance_index A D=distance_index B L.
Proof.
case exists1:([exists x,logical A D x]).
- have /existsP[u lu]:=exists1.
  have less1:=distance_index_lower lu;have less2:=distance_index_lower (go lu).
  have cap:(#|support u|<=n)%N by move:(max_card (support u));rewrite card_ord.
  rewrite transported_weight in less2.
  have [x [lx wx]]:=distance_index_attained (leq_trans less1 cap).
  have [y [ly wy]]:=distance_index_attained (leq_trans less2 cap).
  apply/eqP;rewrite eqn_leq;apply/andP;split.
  + move:(distance_index_lower (back ly));by rewrite transported_weight wy.
  + move:(distance_index_lower (go lx));by rewrite transported_weight wx.
- have none:forall x,~~logical A D x.
    move/existsPn:(negbT exists1)=> all;exact:all.
  have neither:forall x,~~logical B L x.
    move=>x;apply/negP=> ok;move:(none (transport_support (p^-1)%g x));by rewrite (back ok).
  by rewrite (distance_index_empty none) (distance_index_empty neither).
Qed.
End Dual.
