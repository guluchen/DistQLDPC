(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.zlist.list_solver SeedExemptionState SeedColumnModel SeedPolicyView
 SeedBlockModel SeedBlockView SeedTransferTrace ActualOrbitCommit SeedOrbitStorage SeedExecution
 RootTableInvariant SeedTableSafety BlockTableSafety PreparedSeed PreparedSeedResult PreparedSourceDriver
 PreparedTablesDriver ConcreteSeedSafety SiblingCounters PreparedOrbitCredit RootDriver RootSearchPhases
 SeedColumnRestore RootOwnerMemory OverlapColumnState.
Local Open Scope Z_scope.

Definition past_orbit_members e i:=sublist 0 (block_at (orbits e) i) (raw_members (orbits e)).

(* This invariant only consumes evidence produced by the physical seed
   loop. A failed DFS rolls its temporary counts back; the C orbit loop
   permanently increases counts only for the members before cursor i. *)
Theorem reached_seed_has_exact_orbit_credit e report n initial i x a:
 checked_tables e n -> tables_at_rest n (database e) (remaining_rows initial) ->
 block_at (orbits e) 0=0 -> 0<=a<n ->
 PreparedSourceDriver.reached e report initial i x ->
 let credit:=fun state=>conserved a (limits e) (live_rows (remaining_rows state)) in
 credit x=Int.add (credit initial) (Int.repr (visits (past_orbit_members e i) a)).
Proof.
 intros config start base key route credit.
 induction route as [|i state final tail left prior IH index summary].
 - unfold past_orbit_members;rewrite base,sublist_nil;apply eq_sym,Int.add_zero.
 - destruct (PreparedTablesDriver.reached_root_invariant e report n initial i state config start prior) as [old _].
   destruct summary as [_ [_ [same _]]].
   set (y:=returned_state e state (root_number e i) final tail left).
   assert (rest:tables_at_rest n (database e) (remaining_rows y))
     by (apply restored_tables_at_rest;assumption).
   assert (back:credit y=credit state).
   { unfold credit,y,returned_state,conserved;cbn [remaining_rows live_rows].
     destruct same as [ex counts];rewrite ex,counts;reflexivity. }
   destruct config as [cap lengths positive csr seeds slots ids offsets].
   pose proof (offsets i index) as [_ [span end_ok]].
   change (conserved a (limits e) (live_rows (after_exhaustion (database e) (orbits e) (limits e) i
     (remaining_rows y)))=Int.add (credit initial) (Int.repr (visits (past_orbit_members e (i+1)) a))).
   rewrite (@exhausted_seed_changes_only_orbit_members n (database e) (orbits e) (limits e) i
     (remaining_rows y) a lengths cap key csr (proj1 rest) ids).
   fold (credit y);rewrite back,IH,Int.add_assoc,add_encoded;f_equal;f_equal.
   unfold past_orbit_members,visits.
   assert (end_raw:block_at (orbits e) (i+1)<=Zlength (raw_members (orbits e))) by
      (unfold raw_members;rewrite Zlength_map;exact end_ok).
   rewrite (sublist_split 0 (block_at (orbits e) i) (block_at (orbits e) (i+1)) (raw_members (orbits e))) by lia.
   rewrite count_occ_app,Nat2Z.inj_add;reflexivity.
Qed.

Theorem active_seed_keeps_unvisited_qubit_free e report n initial i state a:
 checked_tables e n -> tables_at_rest n (database e) (remaining_rows initial) ->
 block_at (orbits e) 0=0 -> 0<=a<n -> 0<=i<Zlength (order e) ->
 PreparedSourceDriver.reached e report initial i state -> ~In a (past_orbit_members e i) ->
 let q:=root_number e i in let current:=entered_at e state q in
 conserved a (limits e) (live_rows (remaining_rows initial))=Int.repr (credits a (limits e) (exempts current)) ->
 Znth a (blocked (active_at e state q))=Int.zero.
Proof.
 intros cfg start base pos index path absent q current covered.
 pose proof (reached_seed_has_exact_orbit_credit e report n initial i state a cfg start base pos path) as total.
 unfold visits in total;apply (proj1 (count_occ_not_In Z.eq_dec _ a)) in absent.
 rewrite absent,Int.add_zero in total.
 destruct (PreparedTablesDriver.reached_root_invariant e report n initial i state cfg start path) as [rest _].
 destruct rest as [[defaults choices] _];destruct cfg as [cap lengths many csr seeds slots members offsets].
 pose proof (seeds i index) as key;change (0<=q<n) in key.
 destruct (csr q key) as [room [span [end_ok valid]]].
 set (g:=dynamic_rows (database e) (remaining_rows state)).
 set (old:=live_rows (remaining_rows state)).
 pose proof (csr_seed_column_safe n g (limits e) true q old key cap room span end_ok valid lengths defaults choices)
   as [legal installed].
 assert (bounded:0<=a<Zlength (reference_counts old)) by (unfold old;rewrite (proj1 (proj2 choices));lia).
 assert (range:index_at g q<=index_at g (q+1)<=index_at g (q+1)) by (destruct legal as [_ [_ [[_ bound] _]]];lia).
 destruct (prefix_preserves_credit g (limits e) true q old a (index_at g (q+1)) legal range bounded)
   as [_ transfer].
 change (conserved a (limits e) current=conserved a (limits e) old) in transfer.
 fold old in total;rewrite total,covered in transfer.
 change (Znth a (reference_counts current)=Int.zero).
 unfold conserved in transfer;apply (f_equal (fun v=>Int.add v (Int.neg (Int.repr (credits a (limits e) (exempts current)))))) in transfer.
 rewrite Int.add_assoc,Int.add_neg_zero,Int.add_zero in transfer;exact transfer.
Qed.
