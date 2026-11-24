(* SPDX-License-Identifier: GPL-3.0-or-later *)
From mathcomp Require Import all_ssreflect all_algebra.
Require Import LeafMatrix.
Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.
Import GRing.Theory.
Local Open Scope ring_scope.
Section Equations.
Variables m width:nat.
Record pivot_eq := Pivot { pivot_row:'I_m; row_set:{set 'I_m}; rhs:'cV['F_2]_width }.
Definition value (a:'I_m->'cV['F_2]_width) (u:pivot_eq):=\sum_(r in row_set u) a r.
Definition others (a:'I_m->'cV['F_2]_width) (u:pivot_eq):=\sum_(r in row_set u :\ pivot_row u) a r.
Definition set_pivot a u (r:'I_m):=if r==pivot_row u then rhs u-others a u else a r.
Fixpoint triangular (eqs:seq pivot_eq) : Prop :=
 if eqs is u::us then [ /\ pivot_row u \in row_set u,
    forall v, List.In v us -> pivot_row u \notin row_set v & triangular us] else True.
Fixpoint backsub eqs a : 'I_m->'cV['F_2]_width :=
 if eqs is u::us then set_pivot (backsub us a) u else a.

Lemma solve_pivot a u : pivot_row u \in row_set u -> value (set_pivot a u) u=rhs u.
Proof.
move=> hit;rewrite /value (bigD1 (pivot_row u) hit) //= /set_pivot eqxx.
have keep: (\sum_(r in row_set u | r!=pivot_row u)
            (if r==pivot_row u then rhs u-others a u else a r))=others a u.
  rewrite /others;apply:eq_big=>[r|r /andP[_ neq]].
  - by rewrite !inE andbC.
  - by rewrite (negbTE neq).
by rewrite keep subrK.
Qed.
Lemma preserve_pivot a u v : pivot_row u \notin row_set v ->
 value (set_pivot a u) v=value a v.
Proof.
move=> outside;apply:eq_bigr=> r inside;rewrite /set_pivot.
case eqr:(r==pivot_row u)=> //;move/eqP:eqr=> eqr;subst r.
by move:inside;rewrite (negbTE outside).
Qed.
Theorem backsub_solves eqs a :
 triangular eqs -> forall e, List.In e eqs -> value (backsub eqs a) e=rhs e.
Proof.
elim:eqs a=>[|u us IH] a //= [present absent tail] e [<-|partial].
- exact:solve_pivot present.
- rewrite preserve_pivot;[exact:IH tail _ partial|exact:absent partial].
Qed.
(* The solver uses XOR instead of subtraction for its packed binary labels. *)
Lemma binary_pivot a u : set_pivot a u (pivot_row u)=rhs u+others a u.
Proof. rewrite /set_pivot eqxx;change (rhs u + - (others a u) = rhs u + others a u);by rewrite binary_opp. Qed.
End Equations.
