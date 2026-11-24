(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto.
Require Import level_ast VerifDetected VerifChildVisit EnabledCall OverlapColumnState
 SeedPolicyView SeedBlockModel SeedBlockView SeedColumnModel SeedColumnRestore SeedResume
 SeedExecution PreparedSeed RootDriver SeedTableSafety BlockTableSafety RootTableInvariant
 VerifSeedMove SeedLoopModel RootOwnerMemory RootSearchPhases ActualOrbitCommit VerifOrbitBlock
 SiblingCounters PCMSeedSafety StableSeedPreference VerifRootAdmission UniversalRootSearch ConcreteSeedSafety PreparedSeedDispatch PreparedRootStages
 PreparedRecursiveCall PreparedSeedResult PreparedSourceDriver.
Require flag_level_ast.
Import flag_level_ast.
#[local] Existing Instance VerifDetected.CompSpecs.
Local Open Scope Z_scope.

Lemma reached_root_invariant e report n initial i x:
 checked_tables e n -> tables_at_rest n (database e) (remaining_rows initial) ->
 reached e report initial i x ->
 tables_at_rest n (database e) (remaining_rows x) /\ Zlength (witness_path x)=Zlength (witness_path initial).
Proof.
 intros cfg init route;induction route as [|i x run tail left prior IH ix summary];[auto|].
 destruct IH as [old extent];destruct summary as [_ [size [rest _]]].
 set (y:=returned_state e x (root_number e i) run tail left).
 assert (live:tables_at_rest n (database e) (remaining_rows y)) by (apply restored_tables_at_rest;assumption).
 split;[apply (proj2 (safe_orbit_at e n i y cfg ix live))|exact (eq_trans size extent)].
Qed.

Definition admission_contract e report initial:=
 1<=weight e<=Int.max_signed /\ weight e<=Zlength (witness_path initial) /\
 isptr (callback_owner (policy e)) /\ @field_compatible SeedC seed_type [] (callback_owner (policy e)) /\
 column_offsets (geometry (policy e))=col_starts (database e) /\ column_rows (geometry (policy e))=col_rows (database e) /\
 forall i x,0<=i<Zlength (order e) -> reached e report initial i x ->
  let q:=root_number e i in available (active_at e x q) q=true -> seed_checked (root_at e x q) (active_at e x q) q.

Theorem native_root_driver_from_tables e report n initial array bits:
 Int.and bits Int.one<>Int.zero -> Int.and bits (Int.repr 16)<>Int.zero ->
 Int.and bits (Int.repr 32)<>Int.zero -> Int.and bits (Int.repr 64)<>Int.zero ->
 checked_tables e n -> tables_at_rest n (database e) (remaining_rows initial) ->
 admission_contract e report initial -> 0<Zlength (block_members (orbits e)) ->
 semax_body prepared_vars (RecG (policy e) report bits) f_cc_run_prepared_level
   (prepared_spec (schedule e report initial) (state_address e) (p_address e) array bits).
Proof.
 intros preset overlap seed notify cfg start [size [room [own [owner_layout [columns [rows allowed]]]]]] members.
 assert (owner_pointer:is_pointer_or_null (callback_owner (policy e))) by (destruct (callback_owner (policy e));try contradiction;constructor).
 apply verified_prepared_driver;try assumption.
 - intros i x pos route;pose proof (reached_root_invariant e report n initial i x cfg start route) as [stable len].
   pose proof stable as [[defaults choices] between];destruct choices as [shape [qubits admissible]].
   destruct cfg as [cap len_limit many incidence seeds total blocks offsets];pose proof (seeds i pos) as key.
   destruct (incidence _ key) as [rs [idx [available_rows valid_indices]]].
   set (q:=root_number e i) in *;set (g:=dynamic_rows (database e) (remaining_rows x)).
   assert (choices:live_choices n (base_order g) (live_rows (remaining_rows x))) by
     (unfold live_choices;cbn [g dynamic_rows base_order];auto).
   pose proof (csr_seed_column_safe n g (limits e) true q (live_rows (remaining_rows x))
     key cap rs idx available_rows valid_indices len_limit defaults choices) as [forward installed].
   pose proof (csr_seed_column_safe n g (limits e) false q (entered_at e x q)
     key cap rs idx available_rows valid_indices len_limit defaults installed) as [back _].
   change (live_choices n (base_order g) (entered_at e x q)) in installed;destruct installed as [live_rows_count [all_q _]].
   unfold PreparedSeedResult.visit_safe.
   split;[assumption|];split;[lia|];split;[change (0<=q<Zlength (reference_counts (entered_at e x q)));lia|].
   split;[lia|];do 4 (split;[assumption|]).
   split;[change (0<Zlength (exempts (entered_at e x q)));rewrite live_rows_count;exact many|].
   split;[lia|];split;[exact forward|];split;[exact back|];split.
   + apply stable_exemption_on_return;assumption.
   + apply allowed;assumption.
 - intros i y pos [x [run [tail [left [route [summary ->]]]]]].
   destruct (reached_root_invariant e report n initial i x cfg start route) as [old _].
   set (y:=returned_state e x (root_number e i) run tail left).
   assert (rest:tables_at_rest n (database e) (remaining_rows y)) by
      (apply restored_tables_at_rest;[exact old|exact (proj1 (proj2 (proj2 summary)))]).
   exact (proj1 (safe_orbit_at e n i y cfg pos rest)).
Qed.
