(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto.
From mathcomp Require Import all_ssreflect all_algebra.
Require Import LeafMatrix MinimumPrefix TiebreakTarget SeedExecution RootDriver
 SeedColumnModel SeedBlockModel SeedBlockView SeedPolicyView ConcreteSeedSafety RootTableInvariant
 PreparedSeed PreparedSourceDriver PreparedReachedOrbit PreparedZeroLimitRows
 PreparedSeedSlack PreparedPCMLeafVisit PreparedPreferredOverlap PreparedInteriorReport
 VerifRootAdmission OverlapRowState OverlapColumnState OverlapChildState
 SeedExemptionState SeedTransferTrace ChildColumn OverlapRollback PreparedRecursiveCall EnabledCall PCMOverlapHits.
Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.
Local Open Scope ring_scope.
Local Delimit Scope Z_scope with coqZ.

Section ReadTables.
Variables m n k:nat.
Variables (H:'M['F_2]_(m,n)) (G:'M['F_2]_(k,n)) (rank:'I_n->nat)
 (e:seed_level) (initial:root_state) (report:root_report) (i:nat) (st:root_state)
 (q:'I_n) (ordering:seq 'I_n) (rs:seq (seed_row n))
 (sets:Integers.int->{set 'I_n}) (limit:Integers.int->nat).
Let key:=Z.of_nat q.
Let active:=active_at e st key.
Let marked:=selected active key.
Let g:=geometry (root_at e st key).
Let seed_rows:=entries g key.
Let moving:=live_rows (remaining_rows initial).

(* These premises describe arrays, capacities and CSR incidence. None
   requires knowing a minimum, a witness or the answer to a search. *)
Record current_seed_tables:Prop:= {
 cursor_in_order:(0<=Z.of_nat i<Zlength (SeedExecution.order e))%coqZ;
 cursor_names_seed:root_number e (Z.of_nat i)=key;
 orbit_starts_at_zero:block_at (orbits e) 0=0%coqZ;
 visited_before:forall b:'I_n,List.In (Z.of_nat b) (past_orbit_members e (Z.of_nat i)) -> (rank b<i)%N;
 initial_limits_fit:limits e=map limit_word rs;
 initial_choices_fit:exempts moving=map initial_choice rs;
 active_choices_fit:exempts (entered_at e st key)=map active_choice rs;
 initially_counted:forall b:'I_n,Znth (Z.of_nat b) (reference_counts moving)=
   Int.repr (fold_right Z.add 0%coqZ (map (initial_count b) rs));
 rows_valid:forall b:'I_n,Forall (valid_zero_row H G ordering b) rs;
 width_matches:Zlength (blocked active)=Z.of_nat n;
 entered_cells_fit:column_bounds g key marked;
 seed_is_member:forall r,List.In r seed_rows ->
    Int.eq (exempt_for g (row_number r)) (Int.repr key)=false -> q \in sets r;
 effective_members:forall r (b:'I_n),List.In r seed_rows ->
    List.In (Z.of_nat b) (effective (exempt_for g (row_number r)) (row_words g r)) -> b \in sets r;
 initial_slack_fits:forall r,List.In r seed_rows ->
    Int.signed (Znth (row_number r) (slack active))=Z.of_nat (limit r);
 row_has_valid_limit:forall r,List.In r seed_rows -> stabilizer_limit H G ordering (sets r) (limit r)
}.

Theorem current_tables_admit_preferred x:
 checked_tables e (Z.of_nat n) -> tables_at_rest (Z.of_nat n) (database e) (remaining_rows initial) ->
 PreparedSourceDriver.reached e report initial (Z.of_nat i) st ->
 current_seed_tables -> preferred H G ordering x -> q \in support x ->
 (forall b,b \in support x -> (i<=rank b)%N) ->
 available active key=true /\ support x :\ q \subset @available_now n (after_column g key true marked).
Proof.
 move=> cfg rest reached table best seed earliest.
 case:table=>inside names start past caps old now counts valid width bounds member effective slack limits_ok.
 apply:(@starting_overlap_retains_preferred m n k H G ordering q g active sets limit
   width bounds member effective slack limits_ok x best seed).
 unfold active;rewrite -names.
 apply:(@preferred_before_seed m n k H G ordering x rs e report initial (Z.of_nat i) st
   best cfg rest start inside reached caps old _ _).
 - by rewrite names.
 - move=> b used;split;first exact:(@earlier_orbits_skip_target n rank (support x) i e past earliest b used).
   split;[exact:(valid b)|exact:(counts b)].
Qed.
End ReadTables.
