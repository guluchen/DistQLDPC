(* SPDX-License-Identifier: GPL-3.0-or-later *)
From Coq Require Import Lia.
From mathcomp Require Import all_ssreflect all_algebra.
Require Import LeafMatrix MinimumPrefix.
Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.
Import GRing.Theory.
Local Open Scope ring_scope.

Lemma support_sum n (x g : 'cV['F_2]_n) :
  support (x+g) = (support x :\: support g) :|: (support g :\: support x).
Proof.
apply/setP=> i; rewrite /support !inE mxE.
have bin (a : 'F_2) : a = 0 \/ a = 1.
  case: a=> a ha; case: a ha=> [|[|a]] ha; [left|right|]; try by apply: val_inj.
  by [].
by case: (bin (x i 0))=> ->; case: (bin (g i 0))=> ->.
Qed.

(* Adding a stabilizer preserves the logical class. Hence a minimum
   representative cannot occupy more than half of any stabilizer row. *)
Theorem minimum_overlap m n k (H : 'M['F_2]_(m,n)) (L : 'M['F_2]_(k,n))
    (x g : 'cV['F_2]_n) :
  minimum H L x -> H *m g = 0 -> L *m g = 0 ->
  (#|support x :&: support g| + #|support x :&: support g| <= #|support g|)%N.
Proof.
move=> [found least] hg lg.
have alt : logical H L (x+g) by move: found; rewrite /logical !mulmxDr hg lg !addr0.
have le := least _ alt; rewrite support_sum in le.
set A := support x in le *; set G := support g in le *.
have disj : (A :\: G) :&: (G :\: A) = set0.
  by apply/setP=> i; rewrite !inE; case: (g i 0 != 0); case: (x i 0 != 0).
have U := cardsUI (A :\: G) (G :\: A); rewrite disj cards0 addn0 in U.
have XA := cardsID G A; have XG := cardsID A G; rewrite (setIC G A) in XG.
move/leP: le=> le; apply/leP; rewrite -!plusE in U XA XG *; lia.
Qed.
