(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.zlist.list_solver.
Require Import OverlapColumnState OverlapRollback OverlapChildState SiblingCounters ActiveChildren ChildColumn.
Local Open Scope Z_scope.

Definition row_ready g q dir st word:=
 let r:=row_number word in valid_row g st r /\ r<Int.max_unsigned /\
 (if Int.eq (exempt_for g r) q then True else if dir:bool then
  Int.min_signed<Int.signed (Znth r (slack st)) else Int.signed (Znth r (slack st))<Int.max_signed).

Lemma row_after_other g q dir st first later:
 row_number first<>row_number later -> valid_qubits g st ->
 row_ready g q dir st first -> row_ready g q dir st later ->
 row_ready g q dir (update_row g q dir st first) later.
Proof.
 intros different qs [ok _] [valid [limit arith]].
 destruct (one_row_shape g q dir st first ok qs) as [sl bl].
 unfold row_ready,valid_row in *;rewrite sl,(unchanged_on_other_rows g q dir st first later different).
 auto.
Qed.
Lemma prefix_ready g q dir before after st word:
 NoDup (map row_number (before++word::after)) -> valid_qubits g st ->
 Forall (row_ready g q dir st) (before++word::after) ->
 let next:=fold_left (update_row g q dir) before st in
 row_ready g q dir next word /\ valid_qubits g next.
Proof.
 revert st;induction before as [|r rs IH];intros st unique qs all.
 - inversion all;auto.
 - inversion all as [|? ? first rest];subst.
   inversion unique as [|? ? fresh tail];subst.
   cbn [app fold_left] in *;apply IH;[exact tail| |].
   + destruct first as [ok _];unfold valid_qubits in *;rewrite (proj2 (one_row_shape g q dir st r ok qs));exact qs.
   + apply Forall_forall;intros later contains;eapply row_after_other;[|exact qs|exact first|].
     * intro equal;apply fresh;rewrite equal;apply in_map;exact contains.
     * apply Forall_forall with (x:=later) in rest;assumption.
Qed.

(* Check each CSR cell once in the initial snapshot. Uniqueness prevents
   an earlier row in this column from changing the signed value being read. *)
Theorem admissible_from_rows g q dir st:
 0<=q<Int.max_signed -> q+1<Zlength (column_offsets g) ->
 let lo:=offset (column_offsets g) q in let hi:=offset (column_offsets g) (q+1) in
 0<=lo<=hi -> hi<=Zlength (column_rows g) ->
 NoDup (map row_number (entries g q)) -> valid_qubits g st ->
 Forall (row_ready g (Int.repr q) dir st) (entries g q) -> admissible g q dir st.
Proof.
 intros signed slot lo hi span fits unique qs good.
 unfold admissible,endpoints;fold lo hi;split;[exact signed|];split;[exact slot|];split;[exact span|];split;[exact fits|].
 intros i within;unfold column_prefix,offset at 1.
 set (rows:=column_rows g);fold rows in fits.
 assert (parts:entries g q=sublist lo i rows ++ Znth i rows::sublist (i+1) hi rows).
 { unfold entries;fold rows lo hi;rewrite (sublist_split lo i hi rows) by lia.
   rewrite (sublist_split i (i+1) hi rows),(sublist_one i) by lia;reflexivity. }
 rewrite parts in unique,good.
 destruct (prefix_ready g (Int.repr q) dir (sublist lo i rows) (sublist (i+1) hi rows) st (Znth i rows)
    unique qs good) as [[row [limit safe]] members].
 exact (conj row (conj members (conj limit safe))).
Qed.
