(* SPDX-License-Identifier: GPL-3.0-or-later *)
From mathcomp Require Import all_ssreflect all_algebra perm.
Require Import LeafMatrix MinimumPrefix LevelSearch LeafShortcut PrunedLevel OrbitLevel TiebreakTarget OrbitPreferred.
Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.
Local Open Scope ring_scope.
Section Search.
Variables m n k:nat.
Variables (H:'M['F_2]_(m,n)) (L:'M['F_2]_(k,n)).
Variable rank:'I_n->nat.
Variable rep:nat->'I_n.
Variables (seeds:seq nat) (ordering:nat->seq 'I_n).
Variable choose:nat->nat->{set 'I_n}->{set 'I_n}->seq 'I_n.
Hypothesis all_seeds:forall q,rank q \in seeds.
Hypothesis transport:forall q:'I_n,exists p:{perm 'I_n},
 [ /\ p q=rep (rank q),forall a,rank (p a)=rank a &
     forall S,logical H L (indicator S)->logical H L (indicator (p @: S)) ].
(* A seed may prune ties that destroy other minimum supports. It suffices
   to preserve the first remaining member of its own preferred support. *)
Hypothesis keeps:forall (i fuel:nat) (P F:{set 'I_n}) (y:'cV['F_2]_n),
 preferred H L (rep i::ordering i) y -> P!=set0 -> P \subset support y ->
 support y :\: P \subset F -> (#|P|+fuel=#|support y|)%N -> (1<fuel)%N ->
 has (mem (support y :\: P)) (choose i fuel P F).

Lemma descend_preferred i fuel w (P F:{set 'I_n}) y :
 preferred H L (rep i::ordering i) y -> #|support y|=w ->
 P!=set0 -> P \subset support y -> support y :\: P \subset F ->
 (#|P|+fuel=w)%N -> pruned H L (choose i) fuel w P F.
Proof.
move=> best weight;have miny:=proj1 best.
elim: fuel P F=> [|t IH] P F present sub free count.
- exact: (@descend_complete _ _ _ H L 0 w P F y miny weight present sub free count).
- have plain:=@descend_complete _ _ _ H L t.+1 w P F y miny weight present sub free count.
  case E:(oddrow H P)=>[r|];last by move:plain;rewrite /= E.
  rewrite /= E;case:t IH count plain=>[|t] IH count plain.
  + move:plain;rewrite -unrolled_equals_search /= E;done.
  + have hits:has (mem (support y :\: P)) (choose i t.+2 P F).
      apply:(@keeps i t.+2 P F y best present sub free);by rewrite ?weight.
    apply:(@visit_first _ _ _ _ (support y :\: P))=> // a G member available.
    move:(member);rewrite inE=> /andP[out inside].
    apply:IH.
    * apply/set0Pn;exists a;by rewrite !inE eqxx.
    * by rewrite subUset sub1set inside sub.
    * by rewrite residual_add.
    * by rewrite cardsU1 (negbTE out) /= add1n addSn -addnS.
Qed.
Definition seeded_level w :=
 if w is r.+1 then has (fun i=>pruned H L (choose i) r w [set rep i] (orbit_free rank rep i)) seeds else false.
Theorem seeded_level_minimum x : minimum H L x -> seeded_level #|support x|.
Proof.
move=> mx;have [i [y [best weight contains accessible same_rank]]]:=reachable_preferred ordering transport mx.
have ins:i \in seeds by rewrite -same_rank;apply:all_seeds.
case W:#|support x|=>[|w].
- have empty:support y=set0 by apply/eqP;rewrite -cards_eq0 weight W.
  by move:contains;rewrite empty inE.
- apply/hasP;exists i=> //;apply:(descend_preferred best).
  + by rewrite weight W.
  + apply/set0Pn;exists (rep i);exact:set11.
  + by rewrite sub1set.
  + apply/subsetP=> a;rewrite !inE => /andP[away inside].
    have member:a \in support y by rewrite inE.
    by rewrite away (accessible _ member).
  + by rewrite cards1 add1n.
Qed.
Theorem seeded_level_sound w : seeded_level w -> exists T,terminal H L w T.
Proof. case:w=>[|w] //= /hasP[i _ found];exact:pruned_sound found. Qed.
End Search.
