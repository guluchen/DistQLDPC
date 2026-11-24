(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto.
From mathcomp Require Import all_ssreflect all_algebra.
Require Import LeafMatrix MinimumPrefix TiebreakTarget SeedTransferTrace SeedExemptionState
 PreparedPreferredOverlap SiblingCounters SeedExecution SeedBlockModel SeedBlockView PreparedSeed
 PreparedSourceDriver ConcreteSeedSafety RootTableInvariant RootDriver OverlapColumnState
 PreparedReachedOrbit PreparedPCMLeafVisit SeedColumnModel SeedPolicyView VerifRootAdmission.
Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.
Local Open Scope ring_scope.
Local Delimit Scope Z_scope with coqZ.

Record seed_row n := SeedRow {
  members:{set 'I_n}; limit_word:Integers.int; initial_choice:Integers.int; active_choice:Integers.int
}.
Arguments limit_word {n} _.
Arguments initial_choice {n} _.
Arguments active_choice {n} _.
Definition effective_at n (row:seed_row n) (ex:Integers.int):=
 [set a in members row | ~~Z.eqb (Z.of_nat a) (Int.signed ex)].
Definition initial_count n (a:'I_n) (row:seed_row n):Z:=
 if Int.eq (limit_word row) Int.zero && (a \in effective_at row (initial_choice row)) then 1%coqZ else 0%coqZ.

Section AtSeed.
Variables m n k:nat.
Variables (H:'M['F_2]_(m,n)) (G:'M['F_2]_(k,n)) (order:seq 'I_n)
 (x:'cV['F_2]_n) (a:'I_n).
Hypotheses (preferred_target:preferred H G order x) (target:a \in support x).
Definition valid_zero_row (row:seed_row n):Prop:=
 Int.eq (limit_word row) Int.zero=true ->
 (forall ex,ex=initial_choice row \/ ex=active_choice row -> Z.of_nat a=Int.signed ex -> a \in members row) /\
 stabilizer_limit H G order (effective_at row (active_choice row)) 0.

(* A tight row of capacity zero initially blocks each member except
   its exemption. After the exemption moves to the seed ordering,
   every target member of that row must itself be exempt. *)
Lemma account_one_zero_row row:valid_zero_row row ->
 (initial_count a row + exemption_credit (Z.of_nat a) (limit_word row) (initial_choice row))%coqZ =
 exemption_credit (Z.of_nat a) (limit_word row) (active_choice row).
Proof.
 move=>good;unfold initial_count,exemption_credit;case zero:(Int.eq (limit_word row) Int.zero);last reflexivity.
 have [member valid]:=good zero.
 have fits:=preferred_fits_row preferred_target valid.
 have none:support x :&: effective_at row (active_choice row)=set0.
 { apply/eqP;rewrite -cards_eq0;apply/eqP;apply/le_antisym;[exact:(elimT leP fits)|lia]. }
 have outside:a \notin effective_at row (active_choice row).
 { apply/negP=>inside;have bad:a \in support x :&: effective_at row (active_choice row)
      by rewrite inE target inside.
   by move:bad;rewrite none inE. }
 unfold eq_cell,effective_at in *;rewrite !inE in outside |- *.
 destruct (Z.eq_dec (Z.of_nat a) (Int.signed (active_choice row))) as [active|different].
 - have inside:=member _ (or_intror (erefl _)) active;rewrite inside /=.
   destruct (Z.eq_dec (Z.of_nat a) (Int.signed (initial_choice row))) as [old|changed].
   + by rewrite old Z.eqb_refl.
   + by rewrite (proj2 (Z.eqb_neq _ _) changed).
 - rewrite (proj2 (Z.eqb_neq _ _) different) in outside.
   have absent:a \notin members row by move:outside;case:(a \in members row).
   rewrite (negbTE absent) /=;destruct (Z.eq_dec (Z.of_nat a) (Int.signed (initial_choice row))) as [old|_];last reflexivity.
   by move:absent;rewrite (member _ (or_introl (erefl _)) old).
Qed.

Theorem account_zero_limit_rows (rs:seq (seed_row n)):
 Forall valid_zero_row rs ->
 (fold_right Z.add 0%coqZ (map (initial_count a) rs) +
  credits (Z.of_nat a) (map limit_word rs) (map initial_choice rs))%coqZ =
 credits (Z.of_nat a) (map limit_word rs) (map active_choice rs).
Proof.
 move=> valid;elim:valid=>[|row rows ok rest ih];first reflexivity.
 cbn [map fold_right credits];have one:=account_one_zero_row ok;lia.
Qed.
End AtSeed.

Lemma earlier_orbits_skip_target n (rank:'I_n->nat) (T:{set 'I_n}) (cursor:nat) e:
 (forall b:'I_n,List.In (Z.of_nat b) (past_orbit_members e (Z.of_nat cursor)) -> (rank b<cursor)%N) ->
 (forall b,b \in T -> (cursor<=rank b)%N) ->
 forall b,b \in T -> ~List.In (Z.of_nat b) (past_orbit_members e (Z.of_nat cursor)).
Proof. move=> past earliest b member visited;have later:=earliest b member;by move:(past b visited);rewrite ltnNge later. Qed.

(* Match the initial physical counts, the orbit cursor and the exemption
   vector to these row records. Together these imply that every member
   of the preferred minimum is free when its earliest seed is reached. *)
Theorem preferred_before_seed m n k (H:'M['F_2]_(m,n)) (G:'M['F_2]_(k,n)) ordering x
 (rs:seq (seed_row n)) e report initial i state:
 preferred H G ordering x ->
 checked_tables e (Z.of_nat n) -> tables_at_rest (Z.of_nat n) (database e) (remaining_rows initial) ->
 block_at (orbits e) 0=0%coqZ -> (0<=i<Zlength (SeedExecution.order e))%coqZ ->
 PreparedSourceDriver.reached e report initial i state ->
 let q:=root_number e i in let moving:=live_rows (remaining_rows initial) in
 limits e=map limit_word rs -> exempts moving=map initial_choice rs ->
 exempts (entered_at e state q)=map active_choice rs ->
 (forall a:'I_n,a \in support x ->
   ~List.In (Z.of_nat a) (past_orbit_members e i) /\ Forall (valid_zero_row H G ordering a) rs /\
   Znth (Z.of_nat a) (reference_counts moving)=Int.repr (fold_right Z.add 0%coqZ (map (initial_count a) rs))) ->
 support x \subset @available_now n (active_at e state q).
Proof.
 move=> best cfg initial_ok off ix reached q moving caps old new encoding;apply/subsetP=>a contains.
 have [absent [valid row_count]]:=encoding a contains.
 apply (proj1 (@available_in_view n _ a)).
 apply:(@active_seed_keeps_unvisited_qubit_free e report (Z.of_nat n) initial i state (Z.of_nat a)
     cfg initial_ok off _ ix reached absent).
 - have ord:=elimT ltP (ltn_ord a);lia.
 - unfold conserved;fold moving;fold q;rewrite row_count old caps new add_encoded.
   by rewrite (@account_zero_limit_rows m n k H G ordering x a best contains rs valid).
Qed.
