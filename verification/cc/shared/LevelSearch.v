(* SPDX-License-Identifier: GPL-3.0-or-later *)
From mathcomp Require Import all_ssreflect all_algebra.
Require Import LeafMatrix MinimumPrefix.
Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.
Local Open Scope ring_scope.

(* Mathematical search at one weight. The loops enumerate siblings uniquely,
   remove each tried qubit, branch on an odd row and stop at a closed prefix.
   Specialized policies and the two unrolled leaf cases refine this model. *)
Section Visit.
Variable Q : finType.
Implicit Types (free need : {set Q}).
Fixpoint visit (next : Q -> {set Q} -> bool) (candidates : seq Q) free :=
  if candidates is q :: rest then
    next q (free :\ q) || visit next rest (free :\ q)
  else false.

Lemma visit_some next qs free :
  visit next qs free -> exists q free', next q free'.
Proof.
elim: qs free => [|q qs ih] free //= /orP[found|rest].
- by exists q, (free :\ q).
- exact: ih _ rest.
Qed.

Lemma visit_first (next : Q -> {set Q} -> bool) qs free need :
  need \subset free ->
  has (mem need) qs ->
  (forall q free', q \in need -> need :\ q \subset free' -> next q free') ->
  visit next qs free.
Proof.
elim: qs free => [|q qs ih] free //= contained /orP[hit|later] accept.
- apply/orP; left; apply: accept => //.
  apply/subsetP=> x; rewrite !inE => /andP[dif present].
  by rewrite dif (subsetP contained x present).
- case hit: (q \in need).
  + apply/orP; left; apply: accept => //.
    apply/subsetP=> x; rewrite !inE => /andP[dif present].
    by rewrite dif (subsetP contained x present).
  + apply/orP; right; apply: ih => //.
    apply/subsetP=> x present; rewrite !inE (subsetP contained x present) andbT.
    by apply/eqP=> eq; move: present; rewrite eq hit.
Qed.
End Visit.

Section Search.
Variables m n k : nat.
Variables (H : 'M['F_2]_(m,n)) (L : 'M['F_2]_(k,n)).
Implicit Types P F T : {set 'I_n}.
Definition indicator P : 'cV['F_2]_n := \col_i ((i \in P)%:R).
Lemma support_indicator P : support (indicator P) = P.
Proof. by apply/setP=> q; rewrite /support !inE /indicator mxE; case: (q \in P). Qed.

Definition candidates r F := [seq q <- enum 'I_n | (q \in F) && (H r q != 0)].
Definition oddrow P := [pick r : 'I_m | (H *m indicator P) r 0 != 0].
Fixpoint descend fuel w P F : bool :=
  if fuel is rest.+1 then
    if oddrow P is Some r then
      visit (fun q F' => descend rest w (q |: P) F') (candidates r F) F
    else false
  else (#|P| == w)%N && logical H L (indicator P).

Definition level w :=
  if w is rest.+1 then visit (fun q F => descend rest w [set q] F) (enum 'I_n) setT
  else false.

Lemma descend_sound fuel w P F :
  descend fuel w P F -> exists T, (#|T| == w)%N && logical H L (indicator T).
Proof.
elim: fuel P F=> [|rest ih] P F /=; first by exists P.
by case: (oddrow P)=> [r|] // /visit_some [q [F' hit]]; exact: ih _ _ hit.
Qed.

Theorem level_sound w :
  level w -> exists T, (#|T| == w)%N && logical H L (indicator T).
Proof.
by case: w=> [|w] //= /visit_some [q [F hit]]; exact: descend_sound hit.
Qed.

Lemma residual_add T P q : T :\: (q |: P) = (T :\: P) :\ q.
Proof. by apply/setP=> x; rewrite !inE; case: (x == q); case: (x \in P); case: (x \in T). Qed.

Lemma descend_complete fuel w P F (x : 'cV['F_2]_n) :
  minimum H L x -> #|support x| = w -> P != set0 ->
  P \subset support x -> support x :\: P \subset F ->
  (#|P| + fuel = w)%N -> descend fuel w P F.
Proof.
move=> minx weight; elim: fuel P F=> [|rest ih] P F present inside free count.
- have same : P = support x.
    apply/eqP; rewrite eqEcard inside /= weight.
    by rewrite addn0 in count; rewrite count.
  have eqx : indicator P = x by apply: binary_support_inj; rewrite support_indicator.
  by rewrite /= addn0 in count; rewrite /= count eqxx eqx (proj1 minx).
- have proper : P \proper support x.
    rewrite properEcard inside /= weight -count addnS ltnS leq_addr //.
  have odd : H *m indicator P != 0.
    apply: (@minimum_prefix_odd _ _ _ H L (indicator P) x minx);
    by rewrite support_indicator.
  simpl; case pickR: (oddrow P) => [r|].
  + have hr : (H *m indicator P) r 0 != 0.
      by move: pickR; rewrite /oddrow; case: pickP=> // a ha [eq]; subst.
    have hsub : support (indicator P) \subset support x by rewrite support_indicator.
    have hx : H *m x = 0 by move: (proj1 minx)=> /andP[/eqP h _].
    have [q [hq hrow]] := @odd_row_hits_residual m n H (indicator P) x r hsub hx hr.
    rewrite support_indicator in hq.
    apply: (@visit_first _ _ _ _ (support x :\: P)) => //.
    * apply/hasP; exists q => //; rewrite /candidates mem_filter mem_enum andbT.
      by rewrite (subsetP free q hq) hrow.
    * move=> a F' ha hfree; move: (ha); rewrite inE => /andP[out member].
      apply: ih.
      -- apply/set0Pn; exists a; by rewrite !inE eqxx.
      -- by rewrite subUset sub1set member inside.
      -- by rewrite residual_add.
      -- by rewrite cardsU1 (negbTE out) /= add1n addSn -addnS.
  + exfalso; move: pickR; rewrite /oddrow; case: pickP=> // miss _.
    move/eqP: odd; apply; apply/matrixP=> r j; rewrite (ord1 j) [RHS]mxE.
    have hr : ((H *m indicator P) r 0 != 0) = false := miss r.
    by apply/eqP; move: hr; case: ((H *m indicator P) r 0 == 0).
Qed.

Lemma logical_nonempty (x : 'cV['F_2]_n) :
  logical H L x -> support x != set0.
Proof.
move=> /andP[_ lit]; apply/eqP=> empty.
have zero : x = 0.
  apply: binary_support_inj; rewrite empty; apply/setP=> i.
  by rewrite /support !inE mxE eqxx.
by move: lit; rewrite zero mulmx0 eqxx.
Qed.

Theorem minimum_level (x : 'cV['F_2]_n) :
  minimum H L x -> level #|support x|.
Proof.
move=> minx; have nonempty := logical_nonempty (proj1 minx).
case W: #|support x| => [|w].
- by move: W; move/eqP; rewrite cards_eq0 (negbTE nonempty).
- rewrite /level; apply: (@visit_first _ _ _ _ (support x)).
  + exact: subsetT.
  + apply/hasP; move/set0Pn: nonempty=> [q hq]; exists q=> //; exact: mem_enum.
  + move=> q F hq allowed.
    apply: (@descend_complete w w.+1 [set q] F x minx W).
    * apply/set0Pn; exists q; exact: set11.
    * by rewrite sub1set.
    * exact allowed.
    * by rewrite cards1 add1n.
Qed.

Theorem smaller_levels_empty (x : 'cV['F_2]_n) w :
  minimum H L x -> (w < #|support x|)%N -> ~~ level w.
Proof.
move=> [_ least] smaller; apply/negP=> /level_sound [T /andP[/eqP wt found]].
by move: (least _ found); rewrite support_indicator wt leqNgt smaller.
Qed.

(* Ascending weight enumeration. At exhaustion find returns the length of
   the list, one greater than the largest admissible weight. *)
Definition distance_index := find level (iota 0 n.+1).

Theorem distance_index_exact (x : 'cV['F_2]_n) :
  minimum H L x -> distance_index = #|support x|.
Proof.
move=> minx; have cap : (#|support x| < n.+1)%N.
  by move: (max_card (support x)); rewrite card_ord ltnS.
have hit := minimum_level minx.
have anyhit : has level (iota 0 n.+1).
  apply/hasP; exists #|support x| => //; by rewrite mem_iota add0n.
have in_range : (distance_index < n.+1)%N.
  by move: anyhit; rewrite has_find size_iota.
have firsthit := nth_find 0 anyhit.
rewrite nth_iota in firsthit; last exact in_range.
rewrite add0n in firsthit.
change (is_true (level distance_index)) in firsthit.
case: (ltngtP distance_index #|support x|)=> [less|later|] //.
- by move: (smaller_levels_empty minx less); rewrite firsthit.
- have early := @before_find _ 0 level (iota 0 n.+1) _ later.
  by move: early; rewrite nth_iota // add0n hit.
Qed.
(* If a logical operator exists, MathComp's finite minimum supplies the
   witness required by the preceding reflection argument. *)
Theorem distance_index_spec :
  (exists x, logical H L x) ->
  exists x, minimum H L x /\ distance_index = #|support x|.
Proof.
move=> [some valid].
pose wt (x : 'cV['F_2]_n) := #|support x|.
pose best := arg_min some (logical H L) wt.
have bestP := @arg_minnP _ some (logical H L) wt valid.
rewrite /best in bestP.
case: bestP=> bestx found least.
have mb : minimum H L bestx by split.
by exists bestx; split=> //; exact: distance_index_exact mb.
Qed.

Theorem distance_index_empty :
  (forall x, ~~ logical H L x) -> distance_index = n.+1.
Proof.
move=> empty; rewrite /distance_index hasNfind ?size_iota //.
apply/hasPn=> w _; apply/negP=> /level_sound [T /andP[_ found]].
by move: (empty (indicator T)); rewrite found.
Qed.
End Search.
