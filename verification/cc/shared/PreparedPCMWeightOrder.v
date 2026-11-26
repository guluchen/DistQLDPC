(* SPDX-License-Identifier: GPL-3.0-or-later *)
From mathcomp Require Import all_ssreflect all_algebra.
Require Import LeafMatrix MinimumPrefix LevelSearch CSSLevelDistance PreparedNoLogical PreparedRawPCM.
Set Implicit Arguments.
Unset Strict Implicit.
Local Open Scope ring_scope.

(* run_weights checks both halves at each weight before incrementing w.
   Its invariant only needs the per-level promise about true minima. *)
Section Half.
Variables m r n:nat.
Variables (H:'M['F_2]_(m,n)) (S:'M['F_2]_(r,n)).
Let G:=detectors S.
Definition lower_at w:=forall x,minimum H G x -> (w<=#|support x|)%N.
Lemma first_weight:lower_at 1.
Proof. move=>x [hit _];rewrite lt0n cards_eq0;exact:(logical_nonempty hit). Qed.
Lemma next_weight w:lower_at w -> (forall x,minimum H G x -> #|support x|<>w) -> lower_at w.+1.
Proof.
 move=>earlier empty x best;rewrite ltn_neqAle (earlier x best) andbT.
 by apply/eqP=>wrong;apply (empty x best);symmetry;exact wrong.
Qed.
Lemma lower_applies_to_witness w:lower_at w -> forall x,logical H G x -> (w<=#|support x|)%N.
Proof.
 move=>lower x hit;have exists_x:exists v,logical H G v by exists x.
 have [v [best _]]:=distance_index_spec exists_x.
 exact:(leq_trans (lower v best) (proj2 best x hit)).
Qed.
Lemma lower_applies_to_half w:(w<=n)%N -> lower_at w -> (w<=distance_index H G)%N.
Proof.
 move=>within lower;case finite:(distance_index H G<=n)%N.
 - have [x [hit eqd]]:=distance_index_attained finite.
   by rewrite -eqd;apply:(lower_applies_to_witness lower hit).
 - apply:(leq_trans within);apply:ltnW;by rewrite ltnNge finite.
Qed.
End Half.

Local Opaque distance_index detectors.
Lemma both_lower w a b : (w<=a)%N -> (w<=b)%N -> (w<=minn a b)%N.
Proof. move=>left right;rewrite leq_min;apply/andP;by split. Qed.
Section Both.
Variables mx mz n:nat.
Variables (X:'M['F_2]_(mx,n)) (Z:'M['F_2]_(mz,n)).
Lemma reached_mixed_minimum w:
 (w<=n)%N -> lower_at Z X w -> lower_at X Z w ->
 (exists x,logical Z (detectors X) x /\ #|support x|=w) \/
 (exists z,logical X (detectors Z) z /\ #|support z|=w) ->
 extended_css_distance X Z=Some w.
Proof.
 move=>fits xlower zlower hit.
 have xbound:=@lower_applies_to_half mz mx n Z X w fits xlower.
 have zbound:=@lower_applies_to_half mx mz n X Z w fits zlower.
 have lo:(w<=css_index X Z)%N := both_lower xbound zbound.
 have hi:(css_index X Z<=w)%N.
 { case:hit=>[[x [valid <-]]|[z [valid <-]]].
   - exact:(leq_trans (geq_minl (distance_index Z (detectors X)) (distance_index X (detectors Z))) (distance_index_lower valid)).
   - exact:(leq_trans (geq_minr (distance_index Z (detectors X)) (distance_index X (detectors Z))) (distance_index_lower valid)). }
 have eqd:css_index X Z=w by apply/eqP;rewrite eqn_leq;apply/andP;split.
 by rewrite /extended_css_distance eqd fits.
Qed.
Lemma all_weights_cannot_be_empty:
 X*m Z^T=0 -> (0<n-(\rank X+\rank Z))%N ->
 lower_at Z X n.+1 -> lower_at X Z n.+1 -> False.
Proof.
 move=>orth encoded exclude_x exclude_z.
 have nz:(n-(\rank X+\rank Z))%N<>0%N by move=>zero;rewrite zero in encoded.
 have some_d:exists d,extended_css_distance X Z=Some d.
 { case e:(extended_css_distance X Z)=>[d|];first by exists d.
   by exfalso;apply:nz;apply:(proj1 (proj1 (raw_pcm_distance_spec orth)) e). }
 have [d value]:=some_d;move:value;rewrite /extended_css_distance.
 case within:(css_index X Z<=n)%N;last by discriminate.
 move=>_;move:within;rewrite /css_index geq_min=>/orP[left|right].
 - have [x [hit _]]:=distance_index_attained left.
   have too_big:=@lower_applies_to_witness mz mx n Z X n.+1 exclude_x x hit.
   by move:(max_card (support x));rewrite card_ord leqNgt too_big.
 - have [z [hit _]]:=distance_index_attained right.
   have too_big:=@lower_applies_to_witness mx mz n X Z n.+1 exclude_z z hit.
   by move:(max_card (support z));rewrite card_ord leqNgt too_big.
Qed.
End Both.
