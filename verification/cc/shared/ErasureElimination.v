(* SPDX-License-Identifier: GPL-3.0-or-later *)
From mathcomp Require Import all_ssreflect all_algebra.
Require Import LeafMatrix.
Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.
Import GRing.Theory.
Local Open Scope ring_scope.

(* A dense basis entry carries a syndrome column and its label. Every
   XOR during forward reduction is applied to both. Satisfying the
   stored basis equations suffices to lift the final residual equality
   back to the unmodified physical column, regardless of pivot order. *)
Section Reduction.
Variables m k:nat.
Definition labelled := ('cV['F_2]_m * 'cV['F_2]_k)%type.
Definition satisfies (F:'M['F_2]_(k,m)) (b:labelled) := F *m b.1 = b.2.
Definition combine (a b:labelled):labelled:=(a.1+b.1,a.2+b.2).
Lemma reduce_preserves F a b : satisfies F b ->
 (satisfies F (combine a b) <-> satisfies F a).
Proof.
rewrite /satisfies /combine /= mulmxDr => ->;split.
- move=> eqv;apply:(addIr b.2);exact:eqv.
- by move=> ->.
Qed.
Variable pivot:labelled->'I_m.
Definition reduce_one (a b:labelled) := if b.1 (pivot a) 0!=0 then combine b a else b.
Theorem reduce_columns (F:'M['F_2]_(k,m)) bs b :
 (forall a,List.In a bs -> satisfies F a) ->
 (satisfies F (foldl (fun x a=>reduce_one a x) b bs) <-> satisfies F b).
Proof.
elim:bs b=>[|a bs IH] b valid //=.
have sat:satisfies F a by apply:valid;left.
have tail:forall u,List.In u bs->satisfies F u by move=> u iu;apply:valid;right.
rewrite (IH _ tail) /reduce_one.
by case:(b.1 (pivot a) 0!=0)=> //;apply:reduce_preserves.
Qed.
Lemma zero_consistent F (b:labelled) : b.1=0 -> (satisfies F b <-> b.2=0).
Proof. by rewrite /satisfies => ->;rewrite mulmx0;split=> ->. Qed.
End Reduction.

(* A row with one live region qubit cannot be part of a nontrivial
   kernel restriction at that qubit. This justifies peeling such a
   column before reducing the remaining stopping set. *)
Section Peeling.
Variables m n:nat.
Variable H:'M['F_2]_(m,n).
Lemma peeled_coordinate (r:'I_m) (q:'I_n) (v:'cV['F_2]_n) :
 H r q = 1 -> (forall a,a!=q->H r a=0 \/ v a 0=0) ->
 H *m v=0 -> v q 0=0.
Proof.
move=> pivot others nul.
have atrow:=congr1 (fun a:'cV['F_2]_m=>a r 0) nul.
move:atrow;rewrite !mxE (bigD1 q) //= pivot mul1r.
have zero:(\sum_(i:'I_n | i!=q) H r i*v i 0)=0.
  apply:big1=>i neq;case:(others i neq)=> ->;by rewrite ?mulr0 ?mul0r.
by rewrite zero addr0.
Qed.
End Peeling.
