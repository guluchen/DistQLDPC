(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.zlist.list_solver SiblingCounters ActiveChildren
 VerifChildVisit EnabledLoopFacts OverlapChildState OverlapColumnState.
Local Open Scope Z_scope.

(* A row contains only initially free, distinct candidates. Every
   already-selected prefix qubit stays blocked and the new one joins it. *)
Lemma actual_child_blocks root st xs i:
 in_array (Zlength (blocked root)) xs -> NoDup xs ->
 Forall (fun q=>Znth q (blocked root)=Int.zero) xs ->
 0<=i<Zlength xs -> same_search st (sibling_state root xs i) ->
 let q:=Znth i xs in let blocks:=blocked (selected st q) in
 Zlength blocks=Zlength (blocked root) /\
 Znth q blocks<>Int.zero /\
 forall a,0<=a<Zlength (blocked root) -> Znth a (blocked root)<>Int.zero -> Znth a blocks<>Int.zero.
Proof.
 intros valid distinct free inside [_ same] q blocks.
 assert (shape:blocks=added xs (blocked root) (i+1)).
 { unfold blocks,selected;cbn [blocked counters];rewrite same,added_next by exact inside;reflexivity. }
 rewrite shape,added_length by exact valid.
 set (past:=sublist 0 (i+1) xs).
 assert (range:in_array (Zlength (blocked root)) past) by (apply Forall_sublist;assumption).
 assert (unique:NoDup past).
 { assert (parts:xs=past++sublist (i+1) (Zlength xs) xs).
   { unfold past;rewrite <-sublist_split by lia;symmetry;apply sublist_same;lia. }
   rewrite parts in distinct;apply NoDup_app_iff in distinct;tauto. }
 assert (unused:Forall (fun a=>Znth a (blocked root)=Int.zero) past) by (apply Forall_sublist;assumption).
 assert (incl:In q past).
 { unfold past;rewrite (sublist_split 0 i (i+1)) by lia;rewrite (sublist_one i) by lia;apply in_or_app;right;left;reflexivity. }
 assert (qin:0<=q<Zlength (blocked root)).
 { eapply Forall_forall in range;[exact range|exact incl]. }
 split;[reflexivity|split].
 - intro empty;apply (@machine_free_after_excluding (blocked root) past q range unique unused qin) in empty;tauto.
 - intros a bounded before empty;apply (@machine_free_after_excluding (blocked root) past a range unique unused bounded) in empty;tauto.
Qed.
