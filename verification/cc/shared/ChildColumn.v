(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto SiblingCounters OverlapColumnState OverlapRollback OverlapChildState.
Local Open Scope Z_scope.

Definition column_bounds g q st :=
 NoDup (map row_number (entries g q)) /\
 Forall (fun row=>row_number row<Zlength (slack st)) (entries g q) /\ valid_qubits g st.
Lemma entered_block_count g q st : column_bounds g q st ->
 Zlength (blocked (after_column g q true st))=Zlength (blocked st).
Proof.
 intros [uniq [rs qs]].
 destruct (@column_effect g (Int.repr q) true (entries g q) st uniq) as [_ b].
 unfold after_column,endpoints,column_prefix;fold (entries g q);rewrite b;apply sweep_size;apply hits_range;exact qs.
Qed.
Lemma after_child_column g q st result :
 column_bounds g q st -> same_search result (after_column g q true st) ->
 same_search (after_column g q false result) st.
Proof.
 intros [uniq [rs qs]] restored.
 pose proof (@restore_declared_column g q st uniq rs qs) as [S B].
 pose proof (@column_same_search g (Int.repr q) false (entries g q) result
      (after_column g q true st) restored) as [CS CB].
 unfold same_search;split;[etransitivity;[exact CS|exact S]|etransitivity;[exact CB|exact B]].
Qed.
