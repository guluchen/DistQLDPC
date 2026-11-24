(* SPDX-License-Identifier: GPL-3.0-or-later *)
From mathcomp Require Import all_ssreflect all_algebra.
Require Import LeafMatrix MinimumPrefix MinimumOverlap TiebreakTarget EvenOverlapLimit.
Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.
Local Open Scope ring_scope.

Lemma saturated_row (Q:finType) (P T E:{set Q}) limit :
 P \subset T -> #|P :&: E|=limit -> (#|T :&: E|<=limit)%N ->
 forall a,a \in T -> a \notin P -> a \notin E.
Proof.
move=> sub at_limit cap.
have nested : P :&: E \subset T :&: E.
  apply/subsetP=> a;rewrite !inE=> /andP[pin ein];by rewrite (subsetP sub a pin) ein.
have equal : P :&: E = T :&: E by apply/eqP;rewrite eqEcard nested at_limit.
move=> a member fresh;apply/negP=> included.
have hit : a \in T :&: E by rewrite inE member included.
by move:hit;rewrite -equal inE (negbTE fresh).
Qed.

Section Target.
Variables m n k:nat.
Variables (H:'M['F_2]_(m,n)) (L:'M['F_2]_(k,n)).
Variables (x g:'cV['F_2]_n) (P:{set 'I_n}).
Hypotheses (closed:H*m g=0) (undetected:L*m g=0) (prefix_of_target:P \subset support x).

(* The ordinary row limit is floor(weight/2), including odd weights. *)
Theorem ordinary_row_hit_safe :
 minimum H L x -> #|P :&: support g|=half #|support g| ->
 forall a,a \in support x -> a \notin P -> a \notin support g.
Proof.
move=> minx full;apply: (@saturated_row _ P (support x) (support g) _ prefix_of_target full).
have bound:=minimum_overlap minx closed undetected.
by move:(half_leq bound);rewrite addnn doubleK.
Qed.

(* The even-row tie-break omits its preferred qubit from the effective
   row and lowers the limit by one. The target is the preferred minimum. *)
Theorem exempt_row_hit_safe order earlier exempt later b :
 preferred H L order x -> order=earlier++exempt::later ->
 (forall a,a \in earlier -> a \notin support g) -> exempt \in support g ->
 #|support g|=(b+b)%N -> #|P :&: (support g :\ exempt)|=b.-1 ->
 forall a,a \in support x -> a \notin P -> a \notin (support g :\ exempt).
Proof.
move=> good layout first inrow even full.
apply: (@saturated_row _ P (support x) (support g :\ exempt) b.-1 prefix_of_target full).
exact: (exempt_overlap_limit good closed undetected layout first inrow even (subxx (support x))).
Qed.
End Target.
