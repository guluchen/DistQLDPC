(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto.
From mathcomp Require Import all_ssreflect all_algebra perm.
Require Import LeafMatrix MinimumPrefix LevelSearch TiebreakTarget VerifDetected VerifRootCall VerifRootAdmission
 SeedLoopModel SeedExecution PreparedSeedDispatch PreparedRootStages PreparedSeed PreparedSourceDriver
 PreparedSeedResult PreparedPreferredSeed PreparedRootWitness PreparedInteriorReport PreparedDepthSpec
 PreparedExhaustionEvidence RootDriver EnabledCall OverlapChildState OverlapColumnState PreparedPCMLeafVisit
 PreparedBudgetArena PreparedBudgetDriver PreparedArenaRoot PreparedRecursiveCall PreparedBudgetContract
 PreparedTablesDriver SeedBlockView ConcreteSeedSafety PreparedLevelStorage PreparedSeedDispatch SeedTableSafety
 RootTableInvariant VerifChildVisit.
Require flag_level_ast.
Import flag_level_ast.
#[local] Existing Instance VerifDetected.CompSpecs.
Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.
Local Open Scope ring_scope.
Local Delimit Scope Z_scope with coqZ.

Section CompleteLevel.
Variables m n r k:nat.
Variables (H:'M['F_2]_(m,n)) (S:'M['F_2]_(r,n)) (G:'M['F_2]_(k,n))
 (rank:'I_n->nat) (rep:nat->'I_n) (tail_order:nat->seq 'I_n)
 (orders:Integers.int->seq 'I_n) (e:seed_level) (initial:root_state) (array:Values.val) (bits:Integers.int).
Let qualified:=preferred_by_root H G orders.
Let rep_r:=root_projection (recursive_report H S G qualified (weight e)).
Let sched:=PreparedSourceDriver.schedule e rep_r initial.
Let s:=state_address e.
Let p:=p_address e.
Definition css_level_spec:ident*funspec:=
 DECLARE _cc_run_prepared_level WITH u:unit
 PRE [tptr level_type,tptr (Tstruct _cc_level_policy noattr),tuint]
 PROP(Int.and bits Int.one<>Int.zero;(0<=root_count sched<=Int.max_signed)%coqZ)
 PARAMS(s;p;Vint bits) SEP(seed_fields sched p array;waiting sched 0%coqZ)
 POST [tint] EX i:Z,EX code:Z,PROP(exhausted_before sched i;stop_at sched i code;(0<=code<=3)%coqZ;
    code=0%coqZ -> weight e<>Z.of_nat (distance_index H G))
 RETURN(Vint (Int.repr code)) SEP(seed_fields sched p array;after_css_stop H S G qualified e initial i code).

Hypotheses (fit:(Z.of_nat n<=Int.max_signed)%coqZ) (level_range:(0<=weight e<=Z.of_nat n)%coqZ)
 (slots:forall q:'I_n,(rank q<seed_slots sched)%N)
 (numbers:forall i,(i<seed_slots sched)%N -> root_number e (Z.of_nat i)=Z.of_nat (rep i))
 (order_map:forall i,(i<seed_slots sched)%N -> orders (Int.repr (Z.of_nat (rep i)))=rep i::tail_order i)
 (transport:forall q:'I_n,exists p:{perm 'I_n},[ /\ p q=rep (rank q),forall a,rank (p a)=rank a &
    forall T,logical H G (indicator T)->logical H G (indicator (p @: T)) ]).
Hypothesis admission:forall i y state,(i<seed_slots sched)%N ->
 PreparedSourceDriver.reached e rep_r initial (Z.of_nat i) state ->
 preferred H G (rep i::tail_order i) y -> rep i \in support y ->
 (forall b,b \in support y -> (i<=rank b)%N) -> rank (rep i) = i ->
 let q:=Z.of_nat (rep i) in let active:=active_at e state q in
 let entered:=after_column (geometry (root_at e state q)) q true (selected active q) in
 available active q=true /\ support y :\ rep i \subset @available_now n entered.

(* This is a refinement of the actual public C entry. It can be applied
   to the installed root proof without changing the solver ABI or caller
   storage. The callback, table and recursive contracts of that proof,
   as well as the orbit representation above, still have to hold. *)
Theorem prepared_root_proves_css_post prog:
 semax_body prepared_vars prog f_cc_run_prepared_level (prepared_spec sched s p array bits) ->
 semax_body prepared_vars prog f_cc_run_prepared_level css_level_spec.
Proof.
 move=>checked;eapply semax_body_funspec_sub;[exact checked| |].
 - do_funspec_sub;destruct w;normalize;Exists emp;apply andp_right.
   + Exists x;entailer!;cancel.
   + apply prop_right;intro rho;normalize;Exists x0 x1.
     have outcome:x1=0%coqZ -> weight e<>Z.of_nat (distance_index H G).
     { move=>empty;subst x1;apply (@exhausted_native_orbits_exclude_distance m n r k H S G rank rep tail_order
         orders e initial fit slots numbers order_map transport admission x0 level_range);split;assumption. }
     rewrite -stopped_memory_contains_css_trace;entailer!;try cancel;apply derives_refl.
 - apply compute_list_norepet_e;vm_compute;reflexivity.
Qed.

(* Instantiate the strengthened postcondition with the verified seed
   traversal and the same recursive symbol and scratch rows used by
   the sibling loop. This discharges the root-body premise above. *)
Theorem installed_root_proves_css_post packed base stride levels:
 let c:=policy e in let scratch:=pool base stride levels in
 (forall state,active_support (nested c) state None=(packed state [::] * scratch state 1%coqZ)%logic) ->
 (forall state q,active_support (nested c) state (Some q)=(packed state [::Int.repr q] * scratch state 1%coqZ)%logic) ->
 Int.and bits Int.one<>Int.zero -> Int.and bits (Int.repr 16)<>Int.zero ->
 Int.and bits (Int.repr 32)<>Int.zero -> Int.and bits (Int.repr 64)<>Int.zero ->
 checked_tables e (Z.of_nat n) -> tables_at_rest (Z.of_nat n) (database e) (remaining_rows initial) ->
 PreparedTablesDriver.admission_contract e rep_r initial -> (0<Zlength (block_members (orbits e)))%coqZ ->
 semax_body prepared_vars (recursive_policy c packed scratch (recursive_report H S G qualified) bits)
   f_cc_run_prepared_level css_level_spec.
Proof.
 move=> c scratch empty one flags overlap exempt notify tables rest allowed members.
 apply prepared_root_proves_css_post;apply (@one_weight_through_recursive_driver e (Z.of_nat n) initial array bits
   packed (recursive_report H S G qualified) base stride levels);assumption.
Qed.
End CompleteLevel.
