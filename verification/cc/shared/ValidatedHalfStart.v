(* SPDX-License-Identifier: GPL-3.0-or-later *)
From mathcomp Require Import all_ssreflect all_algebra.
Require Import LeafMatrix MinimumPrefix LevelSearch CSSLevelDistance DetectorRank NativeHalfExists.
Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.
Local Open Scope ring_scope.

Section Start.
Variables m s k n:nat.
Variables (H:'M['F_2]_(m,n)) (S:'M['F_2]_(s,n)) (G:'M['F_2]_(k,n)).
Hypotheses (orthH:H*m S^T=0) (orthG:G*m S^T=0)
 (dimensions:(\rank (col_mx H G)+\rank S=n)%N).
Let present := (\rank H < \rank (col_mx H G))%N.
Let d := distance_index H (detectors S).
Lemma same_pred x : logical H G x = logical H (detectors S) x.
Proof. exact: (@validated_logical m s k n H S G orthH orthG dimensions x). Qed.

(* Use exactly the detector test admitted by the driver.  The result holds
   for rectangular matrices with dependent rows and for empty logical sets. *)
Theorem validated_distance : distance_index H G=d.
Proof.
case flag:present.
- have /rank_detects_logical witness : (\rank H<\rank (col_mx H G))%N by exact: flag.
  have [x [[ok least] ->]]:=distance_index_spec witness.
  have good:minimum H (detectors S) x.
    split;first by rewrite -same_pred.
    move=>y;rewrite -same_pred;exact:least.
  exact: esym (distance_index_exact good).
- have none:forall x, ~~ logical H G x.
    move=>x;apply/negP=> ok;have /rank_detects_logical:exists y,logical H G y by exists x.
    by fold present;rewrite flag.
  have neither:forall x,~~ logical H (detectors S) x by move=>x;rewrite -same_pred;exact:none.
  exact: etrans (distance_index_empty none) (esym (distance_index_empty neither)).
Qed.

Theorem validated_half_initial_interval :
 if present then is_true (0<d<=n)%N else d=n.+1.
Proof.
case flag:present.
- have /rank_detects_logical witness : (\rank H<\rank (col_mx H G))%N by exact:flag.
  have [x [[ok least] weight]]:=distance_index_spec witness.
  rewrite -validated_distance weight;apply/andP;split.
  + by rewrite card_gt0;exact:logical_nonempty ok.
  + by move:(max_card (support x));rewrite card_ord.
- rewrite -validated_distance;apply:distance_index_empty=> x;apply/negP=> ok.
  have /rank_detects_logical:exists y,logical H G y by exists x.
  by fold present;rewrite flag.
Qed.
End Start.
