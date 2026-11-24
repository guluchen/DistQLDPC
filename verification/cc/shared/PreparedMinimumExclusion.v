(* SPDX-License-Identifier: GPL-3.0-or-later *)
From Coq Require Import ZArith.
From mathcomp Require Import all_ssreflect all_algebra perm.
Require Import LeafMatrix MinimumPrefix LevelSearch PrunedLevel PreferredTraversal OrbitLevel
 TiebreakTarget PreferredTraversal CSSLevelDistance CSSSearchSchedule.
Require PreparedExhaustionEvidence.
Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.
Local Open Scope ring_scope.

Section PhysicalLevel.
Variables m n k:nat.
Variables (H:'M['F_2]_(m,n)) (L:'M['F_2]_(k,n)).
Variable rank:'I_n->nat.
Variable rep:nat->'I_n.
Variable ordering:nat->seq 'I_n.
Variable choose:nat->nat->{set 'I_n}->{set 'I_n}->seq 'I_n.
Variable c:SeedLoopModel.root_phases.
Let seeds:=iota 0 (PreparedExhaustionEvidence.seed_slots c).
Hypothesis scheduled:forall q,rank q \in seeds.
Hypothesis transport:forall q:'I_n,exists p:{perm 'I_n},
 [ /\ p q=rep (rank q),forall a,rank (p a)=rank a &
  forall S,logical H L (indicator S)->logical H L (indicator (p @: S)) ].
Hypothesis keeps:forall (i fuel:nat) (P F:{set 'I_n}) (x:'cV['F_2]_n),
 preferred H L (rep i::ordering i) x -> P!=set0 -> P \subset support x ->
 support x :\: P \subset F -> (#|P|+fuel=#|support x|)%N -> (1<fuel)%N ->
 has (mem (support x :\: P)) (choose i fuel P F).

(* This premise is root-local and must be established by the recursive
   search refinement. No conclusion about an unvisited root is available. *)
Theorem completed_level_excludes_minimum (i:Z) (fuel:nat):
 (fuel.+1<=n)%N ->
 (forall j,j \in seeds -> PreparedExhaustionEvidence.position_empty c j ->
  ~~pruned H L (choose j) fuel fuel.+1 [set rep j] (orbit_free rank rep j)) ->
 PreparedExhaustionEvidence.reported_stop c i BinNums.Z0 ->
 fuel.+1 != distance_index H L.
Proof.
move=> room each stopped.
apply:(@empty_level_excludes m n k H L rank rep seeds ordering choose scheduled transport keeps _ room).
apply/negP=> /hasP[j inside hit].
have within:(j<PreparedExhaustionEvidence.seed_slots c)%N by move:inside;rewrite /seeds mem_iota add0n.
have no:=each j inside (PreparedExhaustionEvidence.completed_positions c i stopped j (elimT ltP within)).
by move:no;rewrite hit.
Qed.
End PhysicalLevel.
