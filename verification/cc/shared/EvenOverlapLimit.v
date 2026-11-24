(* SPDX-License-Identifier: GPL-3.0-or-later *)
From Coq Require Import Lia Arith.PeanoNat.
From mathcomp Require Import all_ssreflect all_algebra.
Require Import LeafMatrix MinimumPrefix MinimumOverlap TiebreakTarget.
Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.
Import GRing.Theory.
Local Open Scope ring_scope.

Lemma support_tie_size n (x g:'cV['F_2]_n) :
 (#|support x :&: support g| + #|support x :&: support g| = #|support g|)%N ->
 #|support (x+g)|=#|support x|.
Proof.
move=> tie;rewrite support_sum.
pose A:=support x;pose G:=support g.
have empty:(A :\: G) :&: (G :\: A)=set0.
  apply/setP=> i;rewrite /A /G !inE;by case:(x i 0!=0);case:(g i 0!=0).
have inter:=cardsUI (A :\: G) (G :\: A);rewrite empty cards0 addn0 in inter.
have left:=cardsID G A;have right:=cardsID A G;rewrite (setIC G A) in right.
change (#|A :&: G|+#|A :&: G|=#|G|)%N in tie.
change (#|(A :\: G) :|: (G :\: A)|=#|A|).
rewrite -!plusE in inter left right tie;lia.
Qed.

Section Rules.
Variables m n k:nat.
Variables (H:'M['F_2]_(m,n)) (L:'M['F_2]_(k,n)) (order:seq 'I_n).
Theorem exempt_overlap_limit (x g:'cV['F_2]_n) (P:{set 'I_n}) q pre post b :
 preferred H L order x -> H *m g=0 -> L *m g=0 ->
 order=pre++q::post -> (forall r,r \in pre -> r \notin support g) ->
 q \in support g -> #|support g|=(b+b)%N -> P \subset support x ->
 (#|P :&: (support g :\ q)| <= b.-1)%N.
Proof.
move=> best hg lg layout prefix member wt sub.
pose A:=support x;pose G:=support g.
have full:(#|A :&: G|+#|A :&: G|<=b+b)%N by rewrite -wt;exact:minimum_overlap (proj1 best) hg lg.
have lesser:P :&: (G :\ q) \subset (A :&: G) :\ q.
  apply/subsetP=> j;rewrite !inE=> /andP[inp /andP[away ing]].
  have inA:=subsetP sub j inp;move:inA ing away;rewrite /A /G !inE=> iA iG neq.
  by rewrite neq iA iG.
have red:=subset_leq_card lesser.
have diff:=cardsD1 q (A :&: G).
case E:(#|A :&: G|==b)%N.
- have eqc:=eqP E.
  have tie:#|support (x+g)|=#|support x| by apply:support_tie_size;rewrite -/A -/G eqc wt.
  have chosen:=even_tie_contains_first best hg lg layout prefix member tie.
  have inrow:q \in A :&: G by rewrite inE chosen member.
  rewrite inrow add1n in diff.
  have remaining:#|(A :&: G) :\ q|=b.-1 by rewrite -eqc diff.
  by rewrite -remaining.
- move/leP:full=> full;move/eqP:E=> unequal.
  have lower:=subset_leq_card (subsetDl (A :&: G) [set q]).
  apply/leP;move/leP:lower=> lower;move/leP:red=> red;rewrite -!plusE in full.
  change (#|P :&: (G :\ q)| <= Nat.pred b)%coq_nat.
  have half (u v:nat): Nat.le (Nat.add u u) (Nat.add v v) -> u<>v -> Nat.le u (Nat.pred v).
    destruct v;unfold Nat.pred;intros;lia.
  exact:(Nat.le_trans _ _ _ red (Nat.le_trans _ _ _ lower (half _ _ full unequal))).
Qed.
End Rules.
