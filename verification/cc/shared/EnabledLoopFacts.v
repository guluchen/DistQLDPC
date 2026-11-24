(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto SiblingCounters VerifChildVisit
 OverlapColumnState OverlapRollback OverlapChildState ChildColumn.
Local Open Scope Z_scope.

Definition sibling_state root xs i:=counters root (slack root) (added xs (blocked root) i).
Definition child_entry g root xs i :=
 after_column g (Znth i xs) true (sibling_state root xs (i+1)).
Definition outcome c g root xs i:=child_outcome c (blocked (child_entry g root xs i)) (Znth i xs).
Lemma initial_siblings root xs : same_search root (sibling_state root xs 0).
Proof. unfold same_search,sibling_state,counters,added;rewrite sublist_nil by lia;split;reflexivity. Qed.
Lemma selected_sibling root xs i current :
 0<=i<Zlength xs -> same_search current (sibling_state root xs i) ->
 same_search (selected current (Znth i xs)) (sibling_state root xs (i+1)).
Proof.
 intros range [S B];unfold same_search,selected,counters,sibling_state in *;cbn [slack blocked] in *.
 rewrite added_next by lia;rewrite B,S;split;reflexivity.
Qed.
Lemma physical_child_congruence g q enter a b :
 same_search a b -> same_search (after_column g q enter a) (after_column g q enter b).
Proof. apply column_same_search. Qed.
Lemma actual_outcome c g root xs i current :
 0<=i<Zlength xs -> same_search current (sibling_state root xs i) ->
 child_outcome c (blocked (after_column g (Znth i xs) true (selected current (Znth i xs)))) (Znth i xs) =
 outcome c g root xs i.
Proof.
 intros pos before;unfold outcome,child_entry.
 destruct (@physical_child_congruence g (Znth i xs) true _ _ (@selected_sibling root xs i current pos before)) as [_ B].
 rewrite B;reflexivity.
Qed.
(* Returning a witness, an internal inconsistency, or a poll interruption all
   leave the caller's siblings in the identical state. An EMPTY result is
   followed by an extra sibling exclusion, accumulating exactly one mark. *)
Theorem child_exit g root xs i current returned :
 0<=i<Zlength xs -> same_search current (sibling_state root xs i) ->
 let q:=Znth i xs in let chosen:=selected current q in
 0<=q<Zlength (blocked current) -> column_bounds g q chosen ->
 same_search returned (after_column g q true chosen) ->
 let resumed:=released (after_column g q false returned) q in
 same_search resumed (sibling_state root xs i) /\
 same_search (selected resumed q) (sibling_state root xs (i+1)).
Proof.
 intros pos before q chosen key [distinct [rows valid]] kept resumed.
 assert (good:valid_qubits g current).
 { unfold chosen,selected,valid_qubits,counters in valid;cbn [blocked] in valid.
   unfold adjust in valid;rewrite upd_Znth_Zlength in valid by assumption;exact valid. }
 pose proof (@after_recursive_return g q current returned key distinct rows good kept) as [S B].
 assert (restore:same_search resumed (sibling_state root xs i)).
 { destruct before as [CS CB];split;etransitivity;eassumption. }
 split;[exact restore|apply selected_sibling;assumption].
Qed.

Lemma same_shape_bounds g q a b : same_search a b ->
 column_bounds g q a -> column_bounds g q b.
Proof. intros [S B];unfold column_bounds,valid_qubits;rewrite <-S,<-B;auto. Qed.
Definition check_child g q (parent:snapshot) :=
 column_bounds g q parent /\ admissible g q true parent /\
 admissible g q false (after_column g q true parent).
Lemma same_checked_child g q a b : same_search a b -> check_child g q a -> check_child g q b.
Proof.
 intros arrays [legal [push pop]];split;[eapply same_shape_bounds;eassumption|];split.
 - eapply same_admissible;eassumption.
 - eapply same_admissible;[apply physical_child_congruence;exact arrays|exact pop].
Qed.
Lemma checked_from_iterator g root xs i current :
 0<=i<Zlength xs -> same_search current (sibling_state root xs i) ->
 check_child g (Znth i xs) (sibling_state root xs (i+1)) ->
 check_child g (Znth i xs) (selected current (Znth i xs)).
Proof.
 intros pos before safe;destruct (@selected_sibling root xs i current pos before) as [S B].
 eapply same_checked_child;[split;symmetry;eassumption|exact safe].
Qed.
