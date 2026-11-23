(* SPDX-License-Identifier: GPL-3.0-or-later *)
From mathcomp Require Import all_ssreflect all_algebra.
Require Import LeafMatrix MinimumPrefix LevelSearch.
Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.
Local Open Scope ring_scope.

Lemma visit_irrelevant (Q:finType) (h:Q->bool) qs (F:{set Q}) :
  visit (fun q _ => h q) qs F = has h qs.
Proof. by elim: qs F=> [|q qs IH] F //=;rewrite IH. Qed.
Lemma visit_extensional (Q:finType) (left right:Q->{set Q}->bool) qs F :
  (forall q G, left q G=right q G) -> visit left qs F=visit right qs F.
Proof. move=> same;by elim: qs F=> [|q qs IH] F //=;rewrite same IH. Qed.

Section Shortcut.
Variables m n k:nat.
Variables (H:'M['F_2]_(m,n)) (L:'M['F_2]_(k,n)).
Implicit Types P F : {set 'I_n}.
Definition terminal w P := (#|P| == w)%N && logical H L (indicator P).

(* With one move left, closing_qubit can test every free physical column
   that closes the syndrome, independently of the branching row order. *)
Definition last_move w P F := has (fun q => terminal w (q |: P)) (enum F).

Lemma any_closing_hits r P q :
  (H *m indicator P) r 0 != 0 -> H *m indicator (q |: P)=0 -> H r q != 0.
Proof.
move=> hr hz.
have inc : support (indicator P) \subset support (indicator (q |: P)).
  by rewrite !support_indicator subsetU1.
have [u [inside row]] := @odd_row_hits_residual m n H (indicator P) (indicator (q |: P)) r inc hz hr.
move: inside;rewrite !support_indicator !inE => /andP[out /orP[/eqP eq|old]].
- by move: row;rewrite eq.
- by move: out;rewrite old.
Qed.

Lemma shortcut_at_row w P F r : (H *m indicator P) r 0 != 0 ->
  has (fun q => terminal w (q |: P)) (candidates H r F) = last_move w P F.
Proof.
move=> hr;apply/hasP/hasP.
- move=> [q cand ok];exists q=> //.
  move: cand;rewrite /candidates mem_filter => /andP[/andP[free _] _].
  by rewrite mem_enum.
- move=> [q allowed valid];exists q=> //.
  move: allowed;rewrite mem_enum=> free.
  have /andP[_ /andP[/eqP closed _]] := valid.
  rewrite /candidates mem_filter;apply/andP;split;last exact: mem_enum.
  by rewrite free (any_closing_hits hr closed).
Qed.

Fixpoint unrolled fuel w P F :=
  if fuel is rest.+1 then
    if oddrow H P is Some r then
      if rest is O then last_move w P F
      else visit (fun q G => unrolled rest w (q |: P) G) (candidates H r F) F
    else false
  else terminal w P.

Theorem unrolled_equals_search fuel w P F :
  unrolled fuel w P F=descend H L fuel w P F.
Proof.
elim: fuel P F=> [|t IH] P F //=.
case hit: (oddrow H P)=> [r|] //.
have hr : (H *m indicator P) r 0 != 0.
  by move: hit; rewrite /oddrow;case: pickP=> // j hj [eq];subst.
case: t IH=> [|t] IH.
- rewrite visit_irrelevant;exact: esym (shortcut_at_row w F hr).
- apply: visit_extensional => q G;exact: IH.
Qed.
End Shortcut.
