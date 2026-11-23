(* SPDX-License-Identifier: GPL-3.0-or-later *)
From mathcomp Require Import all_ssreflect all_algebra.
Require Import LeafMatrix MinimumPrefix MinimumOverlap LevelSearch.
Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.

Section Score.
Variable Q:finType.
(* Smaller ranks prefer membership in the first differing coordinate.
   The numeric encoding is proof-only. The solver keeps an exempt qubit. *)
Fixpoint score (order:seq Q) (A:{set Q}) : nat :=
  if order is q::rest then
    (if q \in A then 0 else 2 ^ size rest) + score rest A
  else 0.
Lemma tail_bound order A : score order A < 2 ^ size order.
Proof.
elim: order=>[|q tail IH] //=;rewrite expnS mul2n -addnn.
case: (q \in A);last by rewrite ltn_add2l.
rewrite add0n;exact: leq_trans IH (leq_addl _ _).
Qed.
Lemma first_wins earlier q later (A B:{set Q}) :
  (forall t, t \in earlier -> (t \in A)=(t \in B)) ->
  q \in A -> q \notin B ->
  score (earlier ++ q::later) A < score (earlier ++ q::later) B.
Proof.
move=> same selected absent;elim: earlier same=> [|t ts IH] same /=.
- rewrite selected (negbTE absent) add0n.
  exact: leq_trans (tail_bound _ _) (leq_addr _ _).
- have eqt := same t (mem_head _ _).
  rewrite eqt ltn_add2l;apply: IH=> u inside;apply: same.
  by rewrite inE inside orbT.
Qed.
End Score.

Local Open Scope ring_scope.
Import GRing.Theory.
Section Choice.
Variables m n k:nat.
Variables (H:'M['F_2]_(m,n)) (L:'M['F_2]_(k,n)) (order:seq 'I_n).
Definition preferred (x:'cV['F_2]_n) := minimum H L x /\
  forall y, logical H L y -> #|support x|=#|support y| ->
    (score order (support x) <= score order (support y))%N.

Lemma preferred_exists (x:'cV['F_2]_n) : minimum H L x ->
  exists y, preferred y /\ #|support y|=#|support x|.
Proof.
move=> minx;pose A (y:'cV['F_2]_n) := logical H L y && (#|support y|==#|support x|)%N.
have init : A x by rewrite /A (proj1 minx) eqxx.
case: (@arg_minnP _ x A (fun y => score order (support y)) init)=> y /andP[valid /eqP same] best.
exists y;split=> //;split.
- split=> // z ok;rewrite same;exact: (proj2 minx z ok).
- move=> z ok sz;apply: best;by rewrite /A ok -sz same eqxx.
Qed.

(* For an equal-weight stabilizer move, the least support contains the
   exempt position of this row. Otherwise the move strictly improves
   its rank at the first position on which the two supports differ. *)
Theorem even_tie_contains_first (x g:'cV['F_2]_n) earlier q later :
  preferred x -> H *m g=0 -> L *m g=0 ->
  order=earlier ++ q::later ->
  (forall t, t \in earlier -> t \notin support g) ->
  q \in support g -> #|support (x+g)|=#|support x| ->
  q \in support x.
Proof.
move=> [minx best] hg lg layout preceding hit tie.
have ok : logical H L (x+g) by move: (proj1 minx);rewrite /logical !mulmxDr hg lg !addr0.
have no_better := best _ ok (esym tie).
case present: (q \in support x)=> //.
have equiv t : t \in earlier -> (t \in support (x+g))=(t \in support x).
  move=> inpre;have outside := negbTE (preceding _ inpre).
  rewrite !inE in outside;rewrite support_sum !inE outside.
  by case: (x t 0 != 0).
have flipped : q \in support (x+g).
  move: present hit;rewrite support_sum !inE=> -> ->;done.
have improves := @first_wins _ earlier q later (support (x+g)) (support x) equiv flipped (negbT present).
by move: no_better;rewrite layout leqNgt improves.
Qed.
End Choice.
