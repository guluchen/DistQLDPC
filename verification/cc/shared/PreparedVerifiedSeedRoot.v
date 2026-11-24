(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto.
From mathcomp Require Import all_ssreflect all_algebra perm.
Require Import LeafMatrix MinimumPrefix LevelSearch TiebreakTarget VerifDetected VerifRootCall VerifRootAdmission
 SeedLoopModel SeedExecution PreparedSeedDispatch PreparedRootStages PreparedSeed PreparedSourceDriver
 PreparedSeedResult PreparedPreferredSeed PreparedRootWitness PreparedInteriorReport PreparedDepthSpec
 PreparedExhaustionEvidence RootDriver EnabledCall OverlapChildState OverlapColumnState PreparedPCMLeafVisit
 PreparedBudgetArena PreparedBudgetDriver PreparedArenaRoot PreparedRecursiveCall PreparedBudgetContract
 PreparedTablesDriver SeedBlockView ConcreteSeedSafety PreparedLevelStorage PreparedSeedDispatch SeedTableSafety
 RootTableInvariant VerifChildVisit PreparedCSSRootPost PreparedSeedAdmission PreparedZeroLimitRows.
Require flag_level_ast.
Import flag_level_ast.
#[local] Existing Instance VerifDetected.CompSpecs.
Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.
Local Open Scope ring_scope.
Local Delimit Scope Z_scope with coqZ.

Section WithCheckedSeedTables.
Variables m n r k:nat.
Variables (H:'M['F_2]_(m,n)) (S:'M['F_2]_(r,n)) (G:'M['F_2]_(k,n))
 (rank:'I_n->nat) (rep:nat->'I_n) (tail_order:nat->seq 'I_n)
 (orders:Integers.int->seq 'I_n) (e:seed_level) (initial:root_state) (array:Values.val) (bits:Integers.int).
Let qualified:=preferred_by_root H G orders.
Let rep_r:=root_projection (recursive_report H S G qualified (weight e)).
Let sched:=PreparedSourceDriver.schedule e rep_r initial.
Let s:=state_address e.
Let p:=p_address e.
Hypotheses (fit:(Z.of_nat n<=Int.max_signed)%coqZ) (level_range:(0<=weight e<=Z.of_nat n)%coqZ)
 (slots:forall q:'I_n,(rank q<seed_slots sched)%N)
 (numbers:forall i,(i<seed_slots sched)%N -> root_number e (Z.of_nat i)=Z.of_nat (rep i))
 (order_map:forall i,(i<seed_slots sched)%N -> orders (Int.repr (Z.of_nat (rep i)))=rep i::tail_order i)
 (transport:forall q:'I_n,exists p:{perm 'I_n},[ /\ p q=rep (rank q),forall a,rank (p a)=rank a &
    forall T,logical H G (indicator T)->logical H G (indicator (p @: T)) ]).
Variables (seed_rows:nat->root_state->seq (seed_row n))
 (row_sets:nat->root_state->Integers.int->{set 'I_n}) (row_limit:nat->root_state->Integers.int->nat).
Hypothesis encoded:forall i state,(i<seed_slots sched)%N ->
 PreparedSourceDriver.reached e rep_r initial (Z.of_nat i) state ->
 current_seed_tables H G rank e initial i state (rep i) (rep i::tail_order i)
    (seed_rows i state) (row_sets i state) (row_limit i state).

(* The public seed loop consumes a table representation. The safety
   obligations no longer quantify over a witness chosen by the search. *)
Theorem prepared_root_from_seed_tables packed base stride levels:
 let c:=policy e in let scratch:=pool base stride levels in
 (forall state,active_support (nested c) state None=(packed state [::] * scratch state 1%coqZ)%logic) ->
 (forall state q,active_support (nested c) state (Some q)=(packed state [::Int.repr q] * scratch state 1%coqZ)%logic) ->
 Int.and bits Int.one<>Int.zero -> Int.and bits (Int.repr 16)<>Int.zero ->
 Int.and bits (Int.repr 32)<>Int.zero -> Int.and bits (Int.repr 64)<>Int.zero ->
 checked_tables e (Z.of_nat n) -> tables_at_rest (Z.of_nat n) (database e) (remaining_rows initial) ->
 PreparedTablesDriver.admission_contract e rep_r initial -> (0<Zlength (block_members (orbits e)))%coqZ ->
 semax_body prepared_vars (recursive_policy c packed scratch (recursive_report H S G qualified) bits)
   f_cc_run_prepared_level (css_level_spec H S G orders e initial array bits).
Proof.
 move=>c scratch empty one flags overlap exempt notify tables rest allowed members.
 apply:(@installed_root_proves_css_post m n r k H S G rank rep tail_order orders e initial array bits
   fit level_range slots numbers order_map transport _ packed base stride levels empty one flags overlap exempt notify
   tables rest allowed members).
 move=>i x st within reached chosen seed first leader.
 have table:=encoded within reached.
 exact:(@current_tables_admit_preferred m n k H G rank e initial rep_r i st (rep i) (rep i::tail_order i)
   (seed_rows i st) (row_sets i st) (row_limit i st) x tables rest reached table chosen seed first).
Qed.
End WithCheckedSeedTables.
