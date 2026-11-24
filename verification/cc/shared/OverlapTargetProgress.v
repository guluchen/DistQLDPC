(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto SiblingCounters SiblingSearchCoverage
 VerifChildVisit EnabledCall EnabledLoopFacts VerifEnabledSiblings
 OverlapColumnState OverlapRollback OverlapChildState ChildColumn.
Local Open Scope Z_scope.

Definition new_blocks g q st:=hits_in g (Int.repr q) true (slack st) (entries g q).
Lemma other_qubit_unchanged g q st a :
 column_bounds g q st -> 0<=a<Zlength (blocked st) -> ~ In a (new_blocks g q st) ->
 Znth a (blocked (after_column g q true st))=Znth a (blocked st).
Proof.
 intros [unique [rows qubits]] key outside.
 destruct (@column_effect g (Int.repr q) true (entries g q) st unique) as [_ B].
 unfold after_column,endpoints,column_prefix;fold (entries g q);rewrite B.
 rewrite sweep_cell by (try assumption;apply hits_range;exact qubits).
 unfold visits;apply (proj1 (count_occ_not_In Z.eq_dec _ a)) in outside.
 unfold new_blocks in outside;rewrite outside;apply Int.add_zero.
Qed.

(* Sibling exclusion and tight-row pruning write the same block array.
   A retained target must survive both. The active qubit may acquire
   additional marks when several rows become tight simultaneously. *)
Theorem physical_first_target g root xs target :
 in_array (Zlength (blocked root)) xs -> NoDup xs ->
 Forall (fun q=>Znth q (blocked root)=Int.zero) xs ->
 (forall q,target q=true -> 0<=q<Zlength (blocked root) /\ Znth q (blocked root)=Int.zero) ->
 (exists q,In q xs /\ target q=true) ->
 (forall i,0<=i<Zlength xs -> target (Znth i xs)=true ->
   let st:=sibling_state root xs (i+1) in
   column_bounds g (Znth i xs) st /\
   forall a,target a=true -> a<>Znth i xs -> ~In a (new_blocks g (Znth i xs) st)) ->
 exists i,0<=i<Zlength xs /\ target (Znth i xs)=true /\
   forall a,target a=true -> a<>Znth i xs -> Znth a (blocked (child_entry g root xs i))=Int.zero.
Proof.
 intros inrange distinct free fits covered safe.
 destruct (@first_entered_child target xs (blocked root) inrange distinct free fits covered)
  as [i [ix [chosen [marked others]]]].
 exists i;split;[exact ix|split;[exact chosen|]].
 specialize (safe i ix chosen) as [legal surviving].
 intros a wanted different;specialize (fits a wanted) as [inside prior].
 unfold child_entry;rewrite other_qubit_unchanged.
 - exact (others a wanted different).
 - exact legal.
 - change (0<=a<Zlength (added xs (blocked root) (i+1)));rewrite added_length by exact inrange;exact inside.
 - exact (surviving a wanted different).
Qed.

Theorem enabled_exhaustion c root xs stop result :
 done_children c root xs stop result ->
 (result=0 <-> forall j,0<=j<Zlength xs -> outcome (nested c) (geometry c) root xs j=0).
Proof.
 intros [clear [[end_i empty]|[ix [value nonzero]]]].
 - subst stop result;tauto.
 - split;[contradiction|intro all;rewrite value;apply all;exact ix].
Qed.
