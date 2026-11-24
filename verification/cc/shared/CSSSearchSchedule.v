(* SPDX-License-Identifier: GPL-3.0-or-later *)
From mathcomp Require Import all_ssreflect all_algebra perm.
Require Import LeafMatrix MinimumPrefix LevelSearch CSSLevelDistance PreferredTraversal
  OrbitLevel OrbitPreferred TiebreakTarget ColumnParityPCM CertifiedSchedule.
Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.
Local Open Scope ring_scope.

Section HalfCertificate.
Variables m n k:nat.
Variables (H:'M['F_2]_(m,n)) (L:'M['F_2]_(k,n)).
Variable rank:'I_n->nat.
Variable rep:nat->'I_n.
Variables (seeds:seq nat) (order:nat->seq 'I_n).
Variable choose:nat->nat->{set 'I_n}->{set 'I_n}->seq 'I_n.
Hypothesis all_seeds:forall q,rank q \in seeds.
Hypothesis transport:forall q:'I_n,exists p:{perm 'I_n},
 [ /\ p q=rep (rank q),forall a,rank (p a)=rank a &
     forall S,logical H L (indicator S)->logical H L (indicator (p @: S)) ].
Hypothesis keeps:forall (i fuel:nat) (P F:{set 'I_n}) (x:'cV['F_2]_n),
 preferred H L (rep i::order i) x -> P!=set0 -> P \subset support x ->
 support x :\: P \subset F -> (#|P|+fuel=#|support x|)%N -> (1<fuel)%N ->
 has (mem (support x :\: P)) (choose i fuel P F).
Theorem empty_level_excludes w : (w<=n)%N ->
 ~~seeded_level H L rank rep seeds choose w -> w!=distance_index H L.
Proof.
move=> cap miss;apply:(pcm_level_excluded cap)=> x best;apply/eqP=> wt.
have hit:=@seeded_level_minimum m n k H L rank rep seeds order choose all_seeds transport keeps x best.
by move:miss;rewrite -wt hit.
Qed.
Lemma parity_skip_excludes w : (w<=n)%N ->
 (forall q,odd #|support (col q H)|) -> odd w -> w!=distance_index H L.
Proof.
move=> cap oddH oddW;apply:(pcm_level_excluded cap);exact:(@odd_level_empty m n H oddH k L w oddW).
Qed.
End HalfCertificate.

Section Replay.
Variables mx mz n:nat.
Variables (X:'M['F_2]_(mx,n)) (Z:'M['F_2]_(mz,n)).
Let dx:=distance_index Z (detectors X).
Let dz:=distance_index X (detectors Z).
(* No logical support has zero weight, including in an empty-width PCM. *)
Lemma distance_positive m k (H:'M['F_2]_(m,n)) (L:'M['F_2]_(k,n)):
 (0<distance_index H L)%N.
Proof.
by case d:(distance_index H L)=> [|w].
Qed.
Lemma sentinel_upper m k (H:'M['F_2]_(m,n)) (L:'M['F_2]_(k,n)):
 (distance_index H L<=n.+1)%N.
Proof. have fine:=find_size (@level m n k H L) (iota 0 n.+1);by rewrite size_iota in fine. Qed.
Lemma initial_valid : invariant dx dz (Bounds 1 1 n.+1).
Proof.
split=> /=;try apply:distance_positive.
exact: leq_trans (geq_minl _ _) (sentinel_upper Z (detectors X)).
Qed.
Theorem finish_from_pcm b : panel dx dz (Bounds 1 1 n.+1) b ->
 (upper b<=minn (xlo b) (zlo b))%N -> upper b=css_index X Z.
Proof. move=> run stop;exact:(css_driver_stop run initial_valid stop). Qed.
End Replay.
