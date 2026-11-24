(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto OverlapColumnState OverlapRollback SiblingCounters.
Local Open Scope Z_scope.

(* A recursive search may change all three event counters on either an EMPTY
   or an early return. Sibling eligibility depends only on these two arrays. *)
Definition same_search (a b:snapshot) := slack a=slack b /\ blocked a=blocked b.
Lemma update_same_search g q dir a b row :
 same_search a b -> same_search (update_row g q dir a row) (update_row g q dir b row).
Proof.
 intros [S B];destruct (single_effect g q dir a row) as [SL BL];
 destruct (single_effect g q dir b row) as [SR BR];unfold same_search;rewrite SL,SR,BL,BR,S,B;split;reflexivity.
Qed.
Lemma column_same_search g q dir rs a b :
 same_search a b -> same_search (fold_left (update_row g q dir) rs a) (fold_left (update_row g q dir) rs b).
Proof.
 revert a b;induction rs as [|row rs IH];cbn [fold_left];auto;intros;apply IH;apply update_same_search;assumption.
Qed.
Definition selected st q := counters st (slack st) (adjust 1 (blocked st) q).
Definition released st q := counters st (slack st) (adjust (-1) (blocked st) q).
Definition entries g q:=sublist (offset (column_offsets g) q) (offset (column_offsets g) (q+1)) (column_rows g).

(* This is the order in f_dfs: mark the selected qubit, enter its column,
   recurse, undo the column on the returned state, then undo the mark. *)
Theorem after_recursive_return g q parent returned :
 0<=q<Zlength (blocked parent) -> NoDup (map row_number (entries g q)) ->
 Forall (fun row=>row_number row<Zlength (slack parent)) (entries g q) -> valid_qubits g parent ->
 same_search returned (after_column g q true (selected parent q)) ->
 same_search (released (after_column g q false returned) q) parent.
Proof.
 intros key distinct rows inside restore.
 assert (valid:valid_qubits g (selected parent q)).
 { unfold valid_qubits,selected,counters;cbn [blocked];unfold adjust;rewrite upd_Znth_Zlength by assumption;exact inside. }
 pose proof (@restore_declared_column g q (selected parent q) distinct rows valid) as [undo_s undo_b].
 pose proof (@column_same_search g (Int.repr q) false (entries g q) returned
    (after_column g q true (selected parent q)) restore) as coupled.
 change (same_search (after_column g q false returned)
    (after_column g q false (after_column g q true (selected parent q)))) in coupled.
 destruct coupled as [s b];unfold same_search,released,counters;cbn [slack blocked].
 rewrite s,b,undo_s,undo_b;cbn [selected counters blocked slack];rewrite cancel_child by assumption;split;reflexivity.
Qed.

Lemma same_admissible g q dir a b : same_search a b ->
 admissible g q dir a -> admissible g q dir b.
Proof.
 intros eq safe;unfold admissible,endpoints in *.
 destruct safe as [n [room [slice [last safe]]]];do 4 (split;[assumption|]).
 intros i pos;specialize (safe i pos).
 set (before:=column_prefix g (Int.repr q) dir a (offset (column_offsets g) q) i) in *.
 set (after:=column_prefix g (Int.repr q) dir b (offset (column_offsets g) q) i) in *.
 assert (match_fields:same_search before after) by (apply column_same_search;exact eq).
 destruct match_fields as [S B];unfold valid_row,valid_qubits in *;rewrite <-S,<-B;exact safe.
Qed.
