(* SPDX-License-Identifier: GPL-3.0-or-later *)
From mathcomp Require Import all_ssreflect all_algebra.
Require Import LeafMatrix MinimumPrefix LevelSearch CSSLevelDistance.
Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.
Local Open Scope ring_scope.

Section One.
Variables m n k:nat.
Variables (H:'M['F_2]_(m,n)) (L:'M['F_2]_(k,n)).
Lemma at_minimum w : (w<=n)%N -> distance_index H L=w ->
 exists x,minimum H L x /\ #|support x|=w.
Proof.
move=> cap eqd;have inside:(distance_index H L<=n)%N by rewrite eqd.
have [x [ok wt]]:=distance_index_attained inside.
exists x;split;last by rewrite wt eqd.
split=> // y found;rewrite wt;exact:distance_index_lower found.
Qed.
Lemma next_lower w : (w<=n)%N -> (w<=distance_index H L)%N ->
 (forall x,minimum H L x -> #|support x|!=w) -> (w.+1<=distance_index H L)%N.
Proof.
move=> room lb empty;rewrite ltn_neqAle lb andbT;apply/eqP=> equal.
have [x [mn wt]]:=at_minimum room (esym equal).
by move:(empty x mn);rewrite wt eqxx.
Qed.
End One.

Section Bounds.
Variables dx dz:nat.
Record bounds:= Bounds { xlo:nat;zlo:nat;upper:nat }.
Definition invariant s := [ /\ (xlo s<=dx)%N,(zlo s<=dz)%N & (minn dx dz<=upper s)%N ].
Inductive event:bounds->bounds->Prop :=
| empty_x s : xlo s!=dx -> event s (Bounds (xlo s).+1 (zlo s) (upper s))
| empty_z s : zlo s!=dz -> event s (Bounds (xlo s) (zlo s).+1 (upper s))
| checked_witness s w : (minn dx dz<=w)%N -> event s (Bounds (xlo s) (zlo s) (minn (upper s) w))
| interrupted s : event s s
| dual_lower s : dx=dz -> event s (Bounds (xlo s) (xlo s) (upper s)).
Lemma event_preserves s t : event s t -> invariant s -> invariant t.
Proof.
case=> a.
- move=> different [lo other upper_ok];split=> //;by rewrite ltn_neqAle different lo.
- move=> different [other lo upper_ok];split=> //;by rewrite ltn_neqAle different lo.
- move=> w checked [x z old];split=> //;by rewrite leq_min old checked.
- by [].
- move=> equal [x z up];split=> //=;by rewrite -equal.
Qed.
Inductive panel:bounds->bounds->Prop :=
| begin_panel s:panel s s
| more a b c:panel a b->event b c->panel a c.
Lemma panel_preserves a b : panel a b -> invariant a -> invariant b.
Proof. elim=>[s|p q r prior IH step] //;move/IH;exact:event_preserves step. Qed.
Theorem exact_at_stop a b : panel a b -> invariant a ->
 (upper b<=minn (xlo b) (zlo b))%N -> upper b=minn dx dz.
Proof.
move=> path initial stop;case:(panel_preserves path initial)=> xl zl up.
apply/eqP;rewrite eqn_leq up andbT;apply:(leq_trans stop).
rewrite leq_min;apply/andP;split.
- exact:leq_trans (geq_minl _ _) xl.
- exact:leq_trans (geq_minr _ _) zl.
Qed.
End Bounds.
Section PCM.
Variables mx mz n:nat.
Variables (X:'M['F_2]_(mx,n)) (Z:'M['F_2]_(mz,n)).
Let dx:=distance_index Z (detectors X).
Let dz:=distance_index X (detectors Z).
Lemma pcm_upper x z : mixed X Z x z -> (minn dx dz<=pauli_weight x z)%N.
Proof. exact:css_lower. Qed.
Lemma pcm_level_excluded m k (H:'M['F_2]_(m,n)) (L:'M['F_2]_(k,n)) w :
 (w<=n)%N -> (forall x,minimum H L x -> #|support x|!=w) -> w!=distance_index H L.
Proof.
move=> cap exclude;apply/eqP=> equal;have [x [mn wt]]:=at_minimum cap (esym equal).
by move:(exclude x mn);rewrite wt eqxx.
Qed.
Theorem css_driver_stop a b : panel dx dz a b -> invariant dx dz a ->
 (upper b<=minn (xlo b) (zlo b))%N -> upper b=css_index X Z.
Proof. exact:exact_at_stop. Qed.
End PCM.
