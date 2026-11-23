(* SPDX-License-Identifier: GPL-3.0-or-later *)
From mathcomp Require Import all_ssreflect.
Require Import ChargeBound.
Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.

Section Scaled.
Variables (R Q:finType) (rows:{set R}) (incident:R -> {set Q}) (cap:nat).
Definition touching q := [set r in rows | q \in incident r].
Definition degree q := #|touching q|.
Definition largest r := \max_(q in incident r) degree q.
Definition initial r := cap %/ largest r.
Definition total (y:R -> nat) q := \sum_(r in rows) load incident y r q.
Definition feasible (y:R -> nat) := forall q, total y q <= cap.

Lemma total_at y q : total y q=\sum_(r in touching q) y r.
Proof.
rewrite /total [LHS]big_mkcond [RHS]big_mkcond;apply: eq_bigr=> r _.
rewrite /touching inE /load;by case: (r \in rows);case: (q \in incident r).
Qed.

(* The integer division in pass two stays feasible for any nonnegative
   scale. Using an LCM gives the native bound its exact rational value. *)
Lemma initial_feasible : feasible initial.
Proof.
move=> q;rewrite total_at.
case d:(degree q)=>[|t].
- have E : touching q=set0 by apply/eqP;rewrite -cards_eq0;exact/eqP.
  by rewrite E big_set0.
- apply: (@leq_trans (#|touching q| * (cap %/ degree q))).
  + rewrite -sum_nat_const;apply: leq_sum=> r inrow.
    move: inrow;rewrite /touching inE=> /andP[_ member].
    apply: leq_div2l;first by rewrite d.
    exact: leq_bigmax_cond q member.
  + rewrite -/(degree q) mulnC;exact: leq_trunc_div.
Qed.

Fixpoint residual (y:R->nat) (qs:seq Q) :=
  if qs is q::tail then minn (cap-total y q) (residual y tail) else cap.
Lemma residual_at y qs q : q \in qs -> residual y qs <= cap-total y q.
Proof.
elim: qs=>[|a tail IH] //=;rewrite inE=> /orP[/eqP ->|later].
- exact: geq_minl.
- exact: leq_trans (geq_minr _ _) (IH later).
Qed.
Definition raise_row (y:R->nat) (u:R) :=
  fun r => y r + (if r==u then residual y (enum (incident u)) else 0).

Lemma raised_total y u q : total (raise_row y u) q =
  total y q + (if u \in touching q then residual y (enum (incident u)) else 0).
Proof.
rewrite !total_at /raise_row big_split;congr (_ + _).
case h:(u \in touching q).
- rewrite (bigD1 u h) //= eqxx big1 ?addn0 //.
  by move=> r /andP[_ diff];rewrite (negbTE diff).
- apply: big1=> r at_q;case equal:(r==u)=> //.
  by move/eqP: equal=> ru;move: at_q;rewrite ru h.
Qed.

Theorem raise_feasible y u : feasible y -> feasible (raise_row y u).
Proof.
move=> ok q;rewrite raised_total;case mem:(u \in touching q);last by rewrite addn0.
move: mem;rewrite /touching inE=> /andP[_ hit].
have inside : q \in enum (incident u) by rewrite mem_enum.
have limit := residual_at y inside.
apply: leq_trans (leq_add (leqnn _) limit) _;by rewrite subnKC //.
Qed.

Fixpoint passes (rs:seq R) (y:R->nat) :=
  if rs is r::tail then passes tail (raise_row y r) else y.
Lemma passes_feasible rs y : feasible y -> feasible (passes rs y).
Proof. by elim: rs y=> [|r rs IH] y //= current;apply: IH;exact: raise_feasible current. Qed.

Theorem scaled_bound rs (target:{set Q}) :
  (forall r, r \in rows -> exists2 q, q \in target & q \in incident r) ->
  \sum_(r in rows) passes rs initial r <= #|target| * cap.
Proof.
move=> cover;apply: (@charge_bound R Q rows target incident (passes rs initial) cap cover).
by move=> q _;apply: (@passes_feasible rs initial initial_feasible q).
Qed.
End Scaled.
