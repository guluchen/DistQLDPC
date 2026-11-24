(* SPDX-License-Identifier: GPL-3.0-or-later *)
From mathcomp Require Import all_ssreflect all_algebra.
Require Import LeafMatrix LevelSearch MinimumPrefix ChargeBound.
Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.
Import GRing.Theory.
Local Open Scope ring_scope.

(* The erasure policy computes two linear projections. Its test hook
   checks the following column equalities on each qubit in the region. *)
Lemma zero_on_region d n (A:'M['F_2]_(d,n)) (R:{set 'I_n}) (y:'cV['F_2]_n) :
  (forall q, q \in R -> col q A=0) -> support y \subset R -> A *m y=0.
Proof.
move=> columns inside;apply/matrixP=> i j;rewrite (ord1 j) !mxE;apply: big1=> q _.
case eqy: (y q 0 == 0).
- by rewrite (eqP eqy) mulr0.
- have nonzero : q \in support y by rewrite /support inE eqy.
  have zero := congr1 (fun u:'cV['F_2]_d => u i 0) (columns q (subsetP inside _ nonzero)).
  by move: zero;rewrite !mxE=> ->;rewrite mul0r.
Qed.

Section Projection.
Variables m n k h:nat.
Variables (H:'M['F_2]_(m,n)) (G:'M['F_2]_(k,n)).
Variables (phi:'M['F_2]_(h,m)) (F:'M['F_2]_(k,m)) (R:{set 'I_n}).
Let hash:=phi *m H.
Let label:=G + F *m H.
Hypothesis region_hash : forall q, q \in R -> col q hash=0.
Hypothesis region_label : forall q, q \in R -> col q label=0.

Lemma projected_completion (p y z:'cV['F_2]_n) :
  support y \subset R -> logical H G (p+y+z) ->
  (hash *m z == hash *m p) && (label *m z != label *m p).
Proof.
move=> inside /andP[/eqP closed detected].
have hy:=zero_on_region region_hash inside.
have ly:=zero_on_region region_label inside.
have zero:hash *m (p+y+z)=0 by rewrite /hash -mulmxA closed mulmx0.
have lit:label *m (p+y+z)!=0 by rewrite /label mulmxDl -mulmxA closed mulmx0 addr0.
move/eqP:zero;rewrite !mulmxDr hy addr0 addr_eq0 binary_opp eq_sym=> ->.
by move:lit;rewrite !mulmxDr ly addr0 addr_eq0 binary_opp eq_sym.
Qed.

Lemma split_region (T:{set 'I_n}) :
 indicator T=indicator (T :&: R)+indicator (T :\: R).
Proof.
apply/matrixP=> i j;rewrite /indicator !mxE !inE.
by case: (i \in R);case: (i \in T);rewrite /= ?addr0 ?add0r.
Qed.

(* Outside the region every valid completion must survive the hash and
   nonzero-label tests. Equalities of hashes alone never certify a witness. *)
Theorem erasure_completion_survives (P T eligible:{set 'I_n}) (extra:nat) :
 T :\: R \subset eligible -> (#|T :\: R|<=extra)%N ->
 logical H G (indicator P + indicator T) ->
 exists Z:{set 'I_n}, [ /\ Z \subset eligible, (#|Z|<=extra)%N,
   hash *m indicator Z=hash *m indicator P & label *m indicator Z!=label *m indicator P ].
Proof.
move=> allowed fits accepted;exists (T :\: R).
have inside:support (indicator (T :&: R)) \subset R by rewrite support_indicator subsetIr.
have joined:logical H G (indicator P + indicator (T :&: R) + indicator (T :\: R)).
  by move: accepted;rewrite (split_region T) addrA.
have /andP[/eqP hz lz]:=projected_completion inside joined.
by split.
Qed.
End Projection.

Section OutsideBudget.
Variables Row Q:finType.
Variables rows:{set Row}.
Variables R T:{set Q}.
Variable adjacent:Row->{set Q}.
Hypothesis covered:forall r, r \in rows -> exists2 q, q \in T & q \in adjacent r.
Hypothesis region:forall r q, r \in rows -> q \in T -> q \in adjacent r -> q \in R.
Hypothesis disjoint:forall q r s, q \in T -> r \in rows -> s \in rows ->
 q \in adjacent r -> q \in adjacent s -> r=s.
Theorem packed_outside_budget budget : (#|T|<=budget)%N ->
 (#|T :\: R|<=budget - #|rows|)%N.
Proof.
move=> fits.
have meet r : r \in rows -> exists2 q, q \in T :&: R & q \in adjacent r.
  move=> inside;have [q t edge]:=covered inside;exists q=> //.
  by rewrite inE t (@region r q inside t edge).
have distinct q r s : q \in T :&: R -> r \in rows -> s \in rows ->
   q \in adjacent r -> q \in adjacent s -> r=s.
  by move/setIP=> [t _];apply: disjoint t.
have packed:=@packing_bound Row Q rows (T :&: R) adjacent meet distinct.
have total:=cardsID R T.
have sumok:(#|rows|+#|T :\: R|<=budget)%N.
  apply: leq_trans fits;by rewrite -total leq_add2r.
have countok:(#|rows|<=budget)%N := leq_trans (leq_addr _ _) sumok.
by rewrite leq_subRL.
Qed.
End OutsideBudget.
