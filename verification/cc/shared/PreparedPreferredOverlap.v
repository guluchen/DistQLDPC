(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto.
From mathcomp Require Import all_ssreflect all_algebra.
Require Import LeafMatrix MinimumPrefix MinimumOverlap TiebreakTarget EvenOverlapLimit PCMOverlapHits
 PreparedResidualIndex OverlapColumnState OverlapRowState OverlapRollback OverlapChildState OverlapTargetProgress
 EnabledLoopFacts ChildColumn.
Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.
Local Open Scope ring_scope.
Local Delimit Scope Z_scope with coqZ.

Section Overlap.
Variables m n k:nat.
Variables (H:'M['F_2]_(m,n)) (G:'M['F_2]_(k,n)) (order:seq 'I_n).
(* The effective construction may omit precisely the first-ranked
   coordinate of an even stabilizer. Without that exemption it uses the
   ordinary half-weight capacity. The row's physical index is arbitrary. *)
Definition stabilizer_limit (effective_row:{set 'I_n}) (bound:nat):Prop:=
 exists g:'cV['F_2]_n,H*m g=0 /\ G*m g=0 /\
 ((effective_row=support g /\ bound=half #|support g|) \/
 exists earlier q later b,[ /\ order=earlier++q::later,(forall a,a \in earlier -> a \notin support g),
     q \in support g,#|support g|=(b+b)%N & effective_row=support g :\ q /\ bound=b.-1 ]).
Lemma preferred_fits_row x E bound:
 preferred H G order x -> stabilizer_limit E bound -> (#|support x :&: E|<=bound)%N.
Proof.
 move=> best [g [closed [neutral cases]]];destruct cases as [[-> ->]|special].
 - have overlap_count:=minimum_overlap (proj1 best) closed neutral;by move:(half_leq overlap_count);rewrite addnn doubleK.
 - move:special=>[before [q [after [b [layout first present even [-> ->]]]]]].
   exact:(exempt_overlap_limit best closed neutral layout first present even (subxx (support x))).
Qed.

Variables (P:{set 'I_n}) (root:snapshot) (xs:seq Z) (g:layout)
 (sets:Integers.int->{set 'I_n}) (limit:Integers.int->nat).
Hypotheses (rules:forall r,stabilizer_limit (sets r) (limit r))
 (cells:forall (q:'I_n) r,List.In r (entries g (Z.of_nat q)) ->
     Int.eq (exempt_for g (row_number r)) (Int.repr (Z.of_nat q))=false -> q \in sets r)
 (incident:forall (q b:'I_n) r,List.In r (entries g (Z.of_nat q)) ->
     List.In (Z.of_nat b) (effective (exempt_for g (row_number r)) (row_words g r)) -> b \in sets r)
 (slack_counts:forall (q:'I_n) r,List.In r (entries g (Z.of_nat q)) ->
     Int.signed (Znth (row_number r) (slack root))=(Z.of_nat (limit r)-Z.of_nat #|P :&: sets r|)%coqZ)
 (addressed:forall i,(0<=i<Zlength xs)%coqZ ->
     column_bounds g (Znth i xs) (sibling_state root xs (i+1)%coqZ)).

(* Sibling exclusions only touch block counters. Hence a single slack
   encoding at the parent suffices for every reached child, even after
   earlier siblings have been excluded. *)
Theorem preferred_survives_physical_overlap x:
 preferred H G order x -> P \subset support x ->
 let wanted:=physical_member (support x :\: P) in
 forall i,(0<=i<Zlength xs)%coqZ -> wanted (Znth i xs)=true ->
 let st:=sibling_state root xs (i+1)%coqZ in column_bounds g (Znth i xs) st /\
   forall a,wanted a=true -> a<>Znth i xs -> ~List.In a (new_blocks g (Znth i xs) st).
Proof.
 move=> best sub wanted i pos match_i st;split;first apply addressed;first exact pos.
 move/member_decodes:match_i=>[q [addr hit]].
 move:hit;rewrite inE=>/andP[fresh valid].
 have sub':q |: P \subset support x by rewrite subUset sub1set valid sub.
 move=>a /member_decodes[b [-> inres]] different.
 move:inres;rewrite inE=>/andP[notin inside].
 have another:b!=q by apply/eqP=>same;apply different;by rewrite same addr.
 have later:b \notin (q |: P) by rewrite !inE negb_or another notin.
 rewrite addr;eapply (@no_future_target_in_native_hits n P (support x) q g st sets limit fresh sub');
    [move=>r used;apply cells;exact used|move=>r b';apply incident|move=>r found;exact:(@slack_counts q r found)|
     move=>r _;exact:(preferred_fits_row best (rules r))|exact inside|exact later].
Qed.
End Overlap.
