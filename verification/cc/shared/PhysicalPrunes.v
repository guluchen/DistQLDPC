(* SPDX-License-Identifier: GPL-3.0-or-later *)
From mathcomp Require Import all_ssreflect all_algebra.
Require Import LeafMatrix MinimumPrefix LevelSearch ChargeBound MinimumOverlap IndexPacking PrunedLevel.
Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.
Local Open Scope ring_scope.

Section Policies.
Variables m n k h : nat.
Variables (H:'M['F_2]_(m,n)) (L:'M['F_2]_(k,n)) (stabilizer:'I_h -> 'cV['F_2]_n).
Hypothesis harmless : forall j, H *m stabilizer j=0 /\ L *m stabilizer j=0.
Definition neighbors (r:'I_m) := [set q:'I_n | H r q != 0].
Definition odd_checks (P:{set 'I_n}) := support (H *m indicator P).
Definition within_overlap (P:{set 'I_n}) :=
  [forall j:'I_h, (#|P :&: support (stabilizer j)|.*2 <= #|support (stabilizer j)|)%N].

(* Rows, branch candidates and charge allocation can each use their own
   order. Extra marks may already exist before a packing pass. *)
Variables (rows : {set 'I_n} -> seq 'I_m) (order : seq 'I_n)
          (initial_marks : {set 'I_n} -> {set 'I_n}).
Hypothesis only_odd : forall P, {subset rows P <= odd_checks P}.
Hypothesis nonempty_scan : forall P, odd_checks P != set0 -> rows P != [::].
Hypothesis order_all : forall q:'I_n, q \in order.
Variables (charge : {set 'I_n} -> {set 'I_n} -> 'I_m -> nat)
          (cap : {set 'I_n} -> {set 'I_n} -> nat).
Hypothesis feasible : forall (P F:{set 'I_n}) (q:'I_n), q \in F ->
  (\sum_(r in odd_checks P) load neighbors (charge P F) r q <= cap P F)%N.

Definition select_physical fuel (P F : {set 'I_n}) :=
  if rows P is r :: more then
    if scan neighbors F fuel (r :: more) (initial_marks P) 0 &&
       (\sum_(i in odd_checks P) charge P F i <= fuel * cap P F)%N then
      [seq q <- order | [&& q \in neighbors r, q \in F & within_overlap (q |: P)]]
    else [::]
  else [::].

Lemma extension_overlap (x:'cV['F_2]_n) (T:{set 'I_n}) :
  minimum H L x -> T \subset support x -> within_overlap T.
Proof.
move=> best sub;apply/forallP=> j.
have [hc lc] := harmless j;have twice := minimum_overlap best hc lc.
have inter : T :&: support (stabilizer j) \subset support x :&: support (stabilizer j).
  apply/subsetP=> a /setIP[inT hit];apply/setIP;split=> //;exact: (subsetP sub _ inT).
apply: leq_trans _ twice;rewrite -addnn;exact: leq_add (subset_leq_card inter) (subset_leq_card inter).
Qed.

Theorem physical_keeps : keeps_minima H L select_physical.
Proof.
move=> fuel P F x best present sub free count multi.
pose target := support x :\: P.
have card_target : #|target|=fuel.
  have card := cardsID P (support x).
  have inter : support x :&: P = P := elimT setIidPr sub.
  rewrite inter -count in card. exact: addnI card.
have proper : P \proper support x.
  rewrite properEcard sub /= -count -{1}(addn0 #|P|) ltn_add2l.
  exact: ltn_trans (ltn0Sn 0) multi.
have active := @minimum_prefix_odd _ _ _ H L (indicator P) x best.
rewrite support_indicator in active;have nz := active present proper.
have nonempty : odd_checks P != set0.
  apply/negP=> /eqP empty;apply: (negP nz);apply/eqP;apply: binary_support_inj.
  rewrite -/(odd_checks P) empty;apply/setP=> r;by rewrite /support !inE mxE eqxx.
have cover r : r \in odd_checks P -> exists2 q, q \in target & q \in neighbors r.
  rewrite /odd_checks /support inE=> hr.
  have hsub : support (indicator P) \subset support x by rewrite support_indicator.
  have /andP[/eqP hx _] := proj1 best.
  have [q [mem hit]] := @odd_row_hits_residual m n H (indicator P) x r hsub hx hr.
  exists q;first by rewrite support_indicator in mem.
  by rewrite /neighbors inE.
have fits : (#|target|<=fuel)%N by rewrite card_target.
have pack := @scan_keeps_target _ _ neighbors F target (odd_checks P) fuel free
                 fits cover (rows P) (initial_marks P) 0 (@only_odd P) (leq0n _).
have enough : (\sum_(r in odd_checks P) charge P F r <= fuel * cap P F)%N.
  rewrite -card_target;apply: (@charge_bound _ _ (odd_checks P) target neighbors (charge P F) (cap P F) cover).
  move=> q inside;exact: (@feasible P F q (subsetP free _ inside)).
case rowE: (rows P) => [|r rs];first by move: (nonempty_scan nonempty);rewrite rowE.
have in_row : r \in rows P by rewrite rowE inE eqxx.
have [q member hit] := cover _ (@only_odd P r in_row).
have in_full : q \in support x by move: member;rewrite /target inE=> /andP[_ inx].
have overlaps := extension_overlap best (T:=q |: P).
rewrite /select_physical rowE;rewrite rowE in pack;rewrite pack enough /=.
apply/hasP;exists q=> //;rewrite mem_filter (order_all q) andbT hit (subsetP free _ member) /=.
apply: overlaps;by rewrite subUset sub1set in_full sub.
Qed.

Theorem physical_distance : pruned_distance H L select_physical = distance_index H L.
Proof. exact: pruned_distance_exact physical_keeps. Qed.
End Policies.
