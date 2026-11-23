(* SPDX-License-Identifier: GPL-3.0-or-later *)
From mathcomp Require Import all_ssreflect all_algebra.
Require Import LeafMatrix MinimumPrefix LevelSearch LeafShortcut.
Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.
Local Open Scope ring_scope.

Section Traversal.
Variables m n k : nat.
Variables (H:'M['F_2]_(m,n)) (L:'M['F_2]_(k,n)).
Implicit Types P F T : {set 'I_n}.
(* The callback returns an ordered list. It can reorder the row, filter
   by overlap, or return an empty list after a packing or charge cut. *)
Variable select : nat -> {set 'I_n} -> {set 'I_n} -> seq 'I_n.

Fixpoint pruned fuel w P F :=
  if fuel is t.+1 then
    if oddrow H P is Some _ then
      if t is O then last_move H L w P F
      else visit (fun q G => pruned t w (q |: P) G) (select fuel P F) F
    else false
  else terminal H L w P.

Lemma pruned_sound fuel w P F : pruned fuel w P F ->
  exists T, terminal H L w T.
Proof.
elim: fuel P F=> [|t IH] P F /=;first by exists P.
case: (oddrow H P)=> [r|] //;case: t IH=> [|t] IH.
- move/hasP=> [q _ hit];by exists (q |: P).
- move/visit_some=> [q [G hit]]; exact: IH _ _ hit.
Qed.

(* Sound pruning need only preserve a member of each attainable minimum
   continuation. Other candidates may be tried in any order. *)
Definition keeps_minima := forall fuel P F (x:'cV['F_2]_n),
  minimum H L x -> P != set0 -> P \subset support x ->
  support x :\: P \subset F -> (#|P| + fuel = #|support x|)%N ->
  (1 < fuel)%N -> has (mem (support x :\: P)) (select fuel P F).

Theorem pruned_complete (keeps:keeps_minima) fuel w P F (x:'cV['F_2]_n) :
  minimum H L x -> #|support x|=w -> P != set0 -> P \subset support x ->
  support x :\: P \subset F -> (#|P|+fuel=w)%N -> pruned fuel w P F.
Proof.
move=> minx weight;elim: fuel P F=> [|t IH] P F present sub free count.
- exact: (@descend_complete _ _ _ H L 0 w P F x minx weight present sub free count).
- have plain := @descend_complete _ _ _ H L t.+1 w P F x minx weight present sub free count.
  case E: (oddrow H P) => [r|];last by move: plain;rewrite /= E.
  rewrite /= E;case: t IH count plain=> [|t] IH count plain.
  + move: plain;rewrite -unrolled_equals_search /= E;done.
  + have hits : has (mem (support x :\: P)) (select t.+2 P F).
      apply: (keeps _ _ _ _ minx present sub free);by rewrite ?weight.
    apply: (@visit_first _ _ _ _ (support x :\: P)) => //.
    move=> a G member available;move: (member);rewrite inE=> /andP[out inside].
    apply: IH.
    * apply/set0Pn;exists a;by rewrite !inE eqxx.
    * by rewrite subUset sub1set inside sub.
    * by rewrite residual_add.
    * by rewrite cardsU1 (negbTE out) /= add1n addSn -addnS.
Qed.

Definition pruned_level w :=
  if w is rest.+1 then visit (fun q F => pruned rest w [set q] F) (enum 'I_n) setT
  else false.
Definition pruned_distance := find pruned_level (iota 0 n.+1).

Lemma pruned_level_sound w : pruned_level w -> exists T, terminal H L w T.
Proof.
by case: w=> [|w] //= /visit_some [q [G hit]];exact: pruned_sound hit.
Qed.

Lemma pruned_minimum (keeps:keeps_minima) (x:'cV['F_2]_n) :
  minimum H L x -> pruned_level #|support x|.
Proof.
move=> minx; have nz := logical_nonempty (proj1 minx).
case W: #|support x|=> [|w].
- by move: W;move/eqP;rewrite cards_eq0 (negbTE nz).
- rewrite /pruned_level;apply: (@visit_first _ _ _ _ (support x)).
  + exact: subsetT.
  + apply/hasP;move/set0Pn: nz=> [q hit];exists q=> //;exact: mem_enum.
  + move=> q F member allowed;apply: (pruned_complete keeps (x:=x) minx W).
    * apply/set0Pn;exists q;exact: set11.
    * by rewrite sub1set.
    * exact: allowed.
    * by rewrite cards1 add1n.
Qed.

Theorem pruned_distance_exact (keeps:keeps_minima) :
  pruned_distance=distance_index H L.
Proof.
case anyx: [exists x:'cV['F_2]_n, logical H L x].
- move/existsP:anyx=> [x hit];have ex : exists x, logical H L x by exists x.
  have [y [miny ->]] := distance_index_spec ex.
  have cap : (#|support y| < n.+1)%N by move: (max_card (support y));rewrite card_ord.
  have goal_hit := pruned_minimum keeps miny.
  have hitlist : has pruned_level (iota 0 n.+1).
    apply/hasP;exists #|support y|=> //;by rewrite mem_iota add0n.
  have bound : (pruned_distance < n.+1)%N by move: hitlist;rewrite has_find size_iota.
  have first_ok := nth_find 0 hitlist.
  rewrite nth_iota // add0n in first_ok. change (is_true (pruned_level pruned_distance)) in first_ok.
  have [T /andP[/eqP weight valid]] := pruned_level_sound first_ok.
  apply/eqP;rewrite eqn_leq;apply/andP;split.
  + rewrite leqNgt;apply/negP=> earlier;have := @before_find _ 0 pruned_level (iota 0 n.+1) _ earlier.
    by rewrite nth_iota // add0n goal_hit.
  + by move: (proj2 miny _ valid);rewrite support_indicator weight.
- have /existsPn none : ~~ [exists x:'cV['F_2]_n, logical H L x] by rewrite anyx.
  rewrite (distance_index_empty none) /pruned_distance hasNfind ?size_iota //.
  apply/hasPn=> w _;apply/negP=> /pruned_level_sound[T /andP[_ hit]].
  by move: (none (indicator T));rewrite hit.
Qed.
End Traversal.
