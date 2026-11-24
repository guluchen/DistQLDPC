(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto.
From mathcomp Require Import all_ssreflect all_algebra.
Require Import LeafMatrix MinimumPrefix TiebreakTarget PCMOverlapHits OverlapTargetProgress
 OverlapRowState OverlapColumnState OverlapRollback OverlapChildState ChildColumn ExemptionRollback
 VerifRootAdmission PreparedPCMLeafVisit PreparedPreferredOverlap.
Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.
Local Open Scope ring_scope.
Local Delimit Scope Z_scope with coqZ.

Section Seed.
Variables m n k:nat.
Variables (H:'M['F_2]_(m,n)) (G:'M['F_2]_(k,n)) (order:seq 'I_n)
 (q:'I_n) (g:layout) (active:snapshot) (sets:Integers.int->{set 'I_n}) (limit:Integers.int->nat).
Let key:=Z.of_nat q.
Let marked:=selected active key.
Let rows:=entries g key.
Hypotheses (extent:Zlength (blocked active)=Z.of_nat n) (inbounds:column_bounds g key marked)
 (cells:forall r,List.In r rows -> Int.eq (exempt_for g (row_number r)) (Int.repr key)=false -> q \in sets r)
 (members:forall r (b:'I_n),List.In r rows ->
     List.In (Z.of_nat b) (effective (exempt_for g (row_number r)) (row_words g r)) -> b \in sets r)
 (limits:forall r,List.In r rows -> Int.signed (Znth (row_number r) (slack active))=Z.of_nat (limit r))
 (stabilizers:forall r,List.In r rows -> stabilizer_limit H G order (sets r) (limit r)).

(* For a seed the prefix was empty before the selected qubit was
   pushed. All remaining members of its preferred minimum survive both
   the explicit seed mark and the newly saturated stabilizer rows. *)
Theorem starting_overlap_retains_preferred x:
 preferred H G order x -> q \in support x -> support x \subset @available_now n active ->
 available active key=true /\ support x :\ q \subset @available_now n (after_column g key true marked).
Proof.
 move=>pref contains /subsetP free;split.
 - have zero:=proj2 (@available_in_view n active q) (free q contains).
   by rewrite /available /key zero Int.eq_true.
 - apply/subsetP=>b;rewrite inE=>/andP[other member].
   have range (a:'I_n):(0<=Z.of_nat a<Zlength (blocked active))%coqZ.
   { rewrite extent;have bound:=elimT ltP (ltn_ord a);lia. }
   have outside:~List.In (Z.of_nat b) (new_blocks g key marked).
   { apply:(@no_future_target_in_native_hits n set0 (support x) q g marked sets limit _ _ cells members _ _ b member _).
     - by rewrite inE.
     - by rewrite setU0 sub1set.
     - move=>r seen;rewrite set0I cards0 Z.sub_0_r;exact:(@limits r seen).
     - move=>r seen;exact:(preferred_fits_row pref (@stabilizers r seen)).
     - by rewrite setU0. }
   have bounded:(0<=Z.of_nat b<Zlength (blocked marked))%coqZ.
   { unfold marked,selected,counters;cbn [blocked];rewrite length_adjust;[exact:(range b)|exact:(range q)]. }
   apply (proj1 (@available_in_view n _ b));rewrite (@other_qubit_unchanged g key marked (Z.of_nat b) inbounds bounded outside).
   unfold marked,selected,counters;cbn [blocked].
   rewrite (cell_adjust _ _ _ _ (range b) (range q));destruct (Z.eq_dec (Z.of_nat b) (Z.of_nat q)) as [same|neq].
   + have same_coord:b=q by apply val_inj;exact:(Nat2Z.inj _ _ same).
     by move:other;rewrite same_coord inE eqxx.
   + change (Int.add (Znth (Z.of_nat b) (blocked active)) Int.zero=Int.zero).
     rewrite Int.add_zero;exact:(proj2 (@available_in_view n active b) (free b member)).
Qed.
End Seed.
