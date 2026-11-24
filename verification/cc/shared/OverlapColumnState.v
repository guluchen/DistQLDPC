(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.zlist.list_solver OverlapRowState.
From Coq Require Import List Lia.
Import ListNotations.
Local Open Scope Z_scope.

(* Immutable CSR views and dynamic signed/unsigned fields of cc_overlap_view.
   The exempt array is optional: None uses the C sentinel -1 for every row. *)
Record layout := {
  column_offsets : list int; column_rows : list int;
  row_offsets : list int; row_qubits : list int;
  exempt_qubits : option (list int); first_extra : int
}.
Record snapshot := {
  slack : list int; blocked : list int;
  tight : int64; tight_extra : int64; forbidden : int64
}.
Definition offset (xs:list int) i := Int.unsigned (Znth i xs).
Definition exempt_for g r := match exempt_qubits g with
 | Some xs => Znth r xs | None => Int.repr (-1) end.
Definition counters st sl bl := Build_snapshot sl bl (tight st) (tight_extra st) (forbidden st).
Definition update_row g q (enter:bool) st row :=
 let r:=Int.unsigned row in let ex:=exempt_for g r in
 if Int.eq ex q then st else
 let old:=Znth r (slack st) in
 let next:=if enter then Int.sub old Int.one else Int.add old Int.one in
 let sl:=upd_Znth r (slack st) next in
 let lo:=offset (row_offsets g) r in let hi:=offset (row_offsets g) (r+1) in
 if enter then
   if Int.eq next Int.zero then
     let '(bl,k):=row_state ex (row_qubits g) (blocked st) lo hi in
     Build_snapshot sl bl (Int64.add (tight st) Int64.one)
       (if Int.ltu row (first_extra g) then tight_extra st else Int64.add (tight_extra st) Int64.one)
       (Int64.add (forbidden st) (Int64.repr k))
   else counters st sl (blocked st)
 else if Int.eq old Int.zero then
   counters st sl (row_return ex (row_qubits g) (blocked st) lo hi)
 else counters st sl (blocked st).
Definition column_prefix g q enter st lo j :=
 fold_left (update_row g q enter) (sublist lo j (column_rows g)) st.
Lemma next_column_row g q enter st lo i : 0<=lo<=i -> i<Zlength (column_rows g) ->
 column_prefix g q enter st lo (i+1)=
   update_row g q enter (column_prefix g q enter st lo i) (Znth i (column_rows g)).
Proof.
 intros;unfold column_prefix;rewrite (sublist_split lo i (i+1)),(sublist_one i),fold_left_app by lia;reflexivity.
Qed.
Definition valid_row g st r :=
 0<=r<Zlength (slack st) /\ r+1<Zlength (row_offsets g) /\
 offset (row_offsets g) r<=offset (row_offsets g) (r+1) /\
 offset (row_offsets g) (r+1)<=Zlength (row_qubits g) /\
 (match exempt_qubits g with Some xs=>r<Zlength xs | None=>True end).
Definition valid_qubits g st := Forall (fun a=>Int.unsigned a<Zlength (blocked st)) (row_qubits g).
Lemma one_row_shape g q enter st row : valid_row g st (Int.unsigned row) -> valid_qubits g st ->
 Zlength (slack (update_row g q enter st row))=Zlength (slack st) /\
 Zlength (blocked (update_row g q enter st row))=Zlength (blocked st).
Proof.
 intros [range _] qs;unfold update_row;destruct (Int.eq (exempt_for g (Int.unsigned row)) q);[auto|].
 set (ex:=exempt_for g (Int.unsigned row));set (lo:=offset (row_offsets g) (Int.unsigned row));
 set (hi:=offset (row_offsets g) (Int.unsigned row+1)).
 pose proof (@effective_length ex (sublist lo hi (row_qubits g)) (blocked st) ltac:(apply Forall_sublist;exact qs)) as [inc dec].
 change (Zlength (fst (row_state ex (row_qubits g) (blocked st) lo hi))=Zlength (blocked st)) in inc.
 change (Zlength (row_return ex (row_qubits g) (blocked st) lo hi)=Zlength (blocked st)) in dec.
 destruct enter;cbn [counters slack blocked].
 - destruct (Int.eq _ Int.zero);[destruct (row_state ex (row_qubits g) (blocked st) lo hi) eqn:E|];
     cbn [slack blocked counters fst] in *;rewrite upd_Znth_Zlength by exact range;auto.
 - destruct (Int.eq _ Int.zero);cbn [slack blocked counters];rewrite upd_Znth_Zlength by exact range;auto.
Qed.

(* A matched entry/exit of the same row restores both search arrays.
   The event statistics deliberately accumulate rather than rolling back. *)
Theorem row_search_inverse g q st row : valid_row g st (Int.unsigned row) -> valid_qubits g st ->
 let post:=update_row g q false (update_row g q true st row) row in
 slack post=slack st /\ blocked post=blocked st.
Proof.
 intros [pos _] allq;unfold update_row;destruct (Int.eq (exempt_for g (Int.unsigned row)) q);[auto|].
 set (r:=Int.unsigned row) in *;set (old:=Znth r (slack st)).
 set (lo:=offset (row_offsets g) r);set (hi:=offset (row_offsets g) (r+1));set (ex:=exempt_for g r).
 assert (incdec:Int.add (Int.sub old Int.one) Int.one=old).
 { rewrite Int.sub_add_opp,Int.add_assoc;rewrite (Int.add_commut (Int.neg Int.one) Int.one),Int.add_neg_zero,Int.add_zero;reflexivity. }
 assert (undo:upd_Znth r (upd_Znth r (slack st) (Int.sub old Int.one)) old=slack st).
 { unfold old;rewrite upd_Znth_twice by exact pos;apply upd_Znth_triv;[exact pos|reflexivity]. }
 destruct (Int.eq (Int.sub old Int.one) Int.zero) eqn:reaches.
 - destruct (row_state ex (row_qubits g) (blocked st) lo hi) as [bs k] eqn:entry.
   cbn [slack blocked counters];rewrite upd_Znth_same by exact pos;rewrite reaches,incdec;cbn [slack blocked counters].
   split;[exact undo|].
   pose proof (@inverse_row ex (sublist lo hi (row_qubits g)) (blocked st) ltac:(apply Forall_sublist;exact allq)) as inv.
   unfold row_return,row_state in *;rewrite entry in inv;exact inv.
 - cbn [slack blocked counters];rewrite upd_Znth_same by exact pos;rewrite reaches,incdec;cbn [slack blocked counters];auto.
Qed.

Definition endpoints g q := (offset (column_offsets g) q,offset (column_offsets g) (q+1)).
Definition admissible g q enter initial:=
 let '(lo,hi):=endpoints g q in
 0<=q<Int.max_signed /\ q+1<Zlength (column_offsets g) /\ 0<=lo<=hi /\ hi<=Zlength (column_rows g) /\
 forall i,lo<=i<hi ->
 let st:=column_prefix g (Int.repr q) enter initial lo i in
 let r:=offset (column_rows g) i in
 valid_row g st r /\ valid_qubits g st /\ r<Int.max_unsigned /\
 (if Int.eq (exempt_for g r) (Int.repr q) then True else
   if enter then Int.min_signed<Int.signed (Znth r (slack st)) else
                 Int.signed (Znth r (slack st))<Int.max_signed).
Definition after_column g q enter st :=
 let '(lo,hi):=endpoints g q in column_prefix g (Int.repr q) enter st lo hi.
