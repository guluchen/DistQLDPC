(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.zlist.list_solver SiblingCounters ActiveChildren.
Require Import OverlapRowState OverlapColumnState.
From Coq Require Import List Lia.
Import ListNotations.
Local Open Scope Z_scope.

(* Flatten the updates in a column without changing their order. Several
   different tight checks may forbid the same physical qubit. *)
Definition row_number (word:int):=Int.unsigned word.
Definition affected g q row :=
 if Int.eq (exempt_for g (row_number row)) q then [] else [row_number row].
Definition touches g q rs:=flat_map (affected g q) rs.
Definition hits g q (enter:bool) (sl:list int) row :=
 let r:=row_number row in let ex:=exempt_for g r in
 if Int.eq ex q then [] else
 let old:=Znth r sl in
 if Int.eq (if enter then Int.sub old Int.one else old) Int.zero then
   effective ex (sublist (offset (row_offsets g) r) (offset (row_offsets g) (r+1)) (row_qubits g))
 else [].
Definition hits_in g q enter sl rs:=flat_map (hits g q enter sl) rs.
Definition sdelta (enter:bool):=if enter then -1 else 1.
Definition bdelta (enter:bool):=if enter then 1 else -1.
Lemma sweep_join k xs ys base:
 sweep k (xs++ys) base=sweep k ys (sweep k xs base).
Proof. unfold sweep;apply fold_left_app. Qed.
Lemma single_effect g q enter st row :
 slack (update_row g q enter st row)=sweep (sdelta enter) (affected g q row) (slack st) /\
 blocked (update_row g q enter st row)=sweep (bdelta enter) (hits g q enter (slack st) row) (blocked st).
Proof.
 unfold update_row,affected,hits,row_number.
 destruct (Int.eq (exempt_for g (Int.unsigned row)) q);[split;reflexivity|].
 set (r:=Int.unsigned row);set (ex:=exempt_for g r);set (lo:=offset (row_offsets g) r);
 set (hi:=offset (row_offsets g) (r+1));set (old:=Znth r (slack st)).
 destruct enter;cbn [sdelta bdelta].
 - destruct (Int.eq (Int.sub old Int.one) Int.zero).
   + destruct (row_state ex (row_qubits g) (blocked st) lo hi) as [bs k] eqn:E.
     cbn [slack blocked];split.
     * unfold sweep,adjust;cbn [fold_left];rewrite decrement_word;reflexivity.
     * rewrite <- (@block_sweep ex (sublist lo hi (row_qubits g)) (blocked st) 0);
       change (bs=fst (row_state ex (row_qubits g) (blocked st) lo hi));rewrite E;reflexivity.
   + cbn [slack blocked counters];split;[unfold sweep,adjust;cbn [fold_left];rewrite decrement_word|];reflexivity.
 - destruct (Int.eq old Int.zero);cbn [slack blocked counters];split;try reflexivity.
   unfold row_return;apply unblock_sweep.
Qed.
Lemma unchanged_on_other_rows g q enter st first later :
 row_number first<>row_number later ->
 Znth (row_number later) (slack (update_row g q enter st first))=Znth (row_number later) (slack st).
Proof.
 intro distinct;rewrite (proj1 (single_effect g q enter st first));unfold affected;
 destruct (Int.eq _ _);[reflexivity|].
 unfold sweep,adjust;cbn [fold_left];pose proof (Int.unsigned_range first) as nn;fold (row_number first) in nn.
 destruct (Z_lt_dec (row_number first) (Zlength (slack st)));[rewrite upd_Znth_diff' by lia|rewrite upd_Znth_out_of_range by lia];reflexivity.
Qed.
Lemma hits_at g q enter a b row :
 Znth (row_number row) a=Znth (row_number row) b -> hits g q enter a row=hits g q enter b row.
Proof. unfold hits;intro same;rewrite same;reflexivity. Qed.
Lemma flat_hits_other g q enter st row rs :
 ~In (row_number row) (map row_number rs) ->
 hits_in g q enter (slack (update_row g q enter st row)) rs = hits_in g q enter (slack st) rs.
Proof.
 induction rs as [|later rest IH];intros absent;[reflexivity|].
 change (hits g q enter (slack (update_row g q enter st row)) later ++ hits_in g q enter (slack (update_row g q enter st row)) rest =
         hits g q enter (slack st) later ++ hits_in g q enter (slack st) rest).
 f_equal;[apply hits_at;apply unchanged_on_other_rows;intro same;apply absent;left;congruence|apply IH;intro inside;apply absent;right;assumption].
Qed.
Theorem column_effect g q enter rs st :
 NoDup (map row_number rs) ->
 let final:=fold_left (update_row g q enter) rs st in
 slack final=sweep (sdelta enter) (touches g q rs) (slack st) /\
 blocked final=sweep (bdelta enter) (hits_in g q enter (slack st) rs) (blocked st).
Proof.
 revert st;induction rs as [|row rs IH];intros st distinct;[split;reflexivity|].
 inversion distinct as [|? ? fresh tail];subst.
 set (next:=update_row g q enter st row).
 destruct (IH next tail) as [all_sl all_bl];destruct (single_effect g q enter st row) as [sl bl].
 fold next in sl,bl;cbn [fold_left];fold next;split.
 - unfold touches;cbn [flat_map];rewrite sweep_join,<-sl;exact all_sl.
 - unfold hits_in;cbn [flat_map];rewrite sweep_join,<-bl.
   unfold next in all_bl;rewrite (@flat_hits_other g q enter st row rs fresh) in all_bl;exact all_bl.
Qed.
Lemma touches_sub g q rs k : In k (touches g q rs) -> In k (map row_number rs).
Proof.
 intros chosen;apply in_flat_map in chosen as [row [member local]].
 unfold affected in local;destruct (Int.eq _ _) in local;[contradiction|].
 destruct local as [<-|[]];apply in_map;exact member.
Qed.
Lemma touches_distinct g q rs:NoDup (map row_number rs)->NoDup (touches g q rs).
Proof.
 induction rs as [|a rs IH];intro unique;[constructor|].
 inversion unique as [|? ? fresh rest];subst;unfold touches;cbn [flat_map];unfold affected at 1.
 destruct (Int.eq _ _);cbn [app];[apply IH;assumption|constructor].
 - intro seen;apply fresh;eapply touches_sub;exact seen.
 - apply IH;assumption.
Qed.
Lemma member_touches g q rs row:
 In row rs -> Int.eq (exempt_for g (row_number row)) q=false -> In (row_number row) (touches g q rs).
Proof. intros inside used;apply in_flat_map;exists row;split;[exact inside|unfold affected;rewrite used;left;reflexivity]. Qed.
Lemma touches_range g q rs n:
 Forall (fun row=>row_number row<n) rs -> in_array n (touches g q rs).
Proof.
 intro valid;apply Forall_forall;intros k included;apply touches_sub in included;apply in_map_iff in included as [row [<- member]].
 apply Forall_forall with (x:=row) in valid;[|assumption].
 unfold row_number in *;pose proof (Int.unsigned_range row);lia.
Qed.
Lemma hits_range g q enter sl rs n:
 Forall (fun a=>Int.unsigned a<n) (row_qubits g) -> in_array n (hits_in g q enter sl rs).
Proof.
 intro valid;apply Forall_forall;intros k found;apply in_flat_map in found as [row [inside hit]].
 unfold hits in hit;destruct (Int.eq (exempt_for g (row_number row)) q);[contradiction|].
 destruct (Int.eq _ Int.zero);[|contradiction].
 eapply (proj1 (Forall_forall (fun x:Z=>0<=x<n) _));[apply effective_range;apply Forall_sublist;exact valid|exact hit].
Qed.
Lemma hits_in_agree g q left right a b rs :
 (forall row,In row rs -> hits g q left a row=hits g q right b row) ->
 hits_in g q left a rs=hits_in g q right b rs.
Proof.
 induction rs as [|r rs IH];intro agree;[reflexivity|].
 unfold hits_in;cbn [flat_map];f_equal;[apply agree;left;reflexivity|apply IH;intros;apply agree;right;assumption].
Qed.
Lemma undo_slacks xs base:in_array (Zlength base) xs -> sweep 1 xs (sweep (-1) xs base)=base.
Proof.
 intro range;pose proof (sweep_size (-1) xs base range) as len.
 assert (after:in_array (Zlength (sweep (-1) xs base)) xs) by (rewrite len;exact range).
 apply Znth_eq_ext.
 - rewrite sweep_size by exact after;exact len.
 - intros k valid;rewrite sweep_size,len in valid by assumption.
   rewrite !sweep_cell by (rewrite ?len;assumption).
   rewrite Int.add_assoc,add_encoded;replace (-1*visits xs k+1*visits xs k) with 0 by ring;apply Int.add_zero.
Qed.
Theorem column_search_inverse g q rs st:
 NoDup (map row_number rs) ->
 Forall (fun row=>row_number row<Zlength (slack st)) rs ->
 valid_qubits g st ->
 let during:=fold_left (update_row g q true) rs st in
 let restored:=fold_left (update_row g q false) rs during in
 slack restored=slack st /\ blocked restored=blocked st.
Proof.
 intros unique rows qubits during restored.
 destruct (@column_effect g q true rs st unique) as [add_sl add_bl];fold during in add_sl,add_bl.
 destruct (@column_effect g q false rs during unique) as [rem_sl rem_bl];fold restored in rem_sl,rem_bl.
 pose proof (@touches_range g q rs (Zlength (slack st)) rows) as valid.
 split.
 - rewrite rem_sl,add_sl;apply undo_slacks;assumption.
 - assert (same:forall row,In row rs->
       hits g q false (slack during) row=hits g q true (slack st) row).
   { intros row member;unfold hits.
     destruct (Int.eq (exempt_for g (row_number row)) q) eqn:skip;[reflexivity|].
     pose proof (proj1 (Forall_forall _ _) rows _ member) as idx.
     pose proof (Int.unsigned_range row) as nn;fold (row_number row) in nn.
     change (row_number row<Zlength (slack st)) in idx.
     assert (inside:0<=row_number row<Zlength (slack st)) by (split;[exact (proj1 nn)|exact idx]).
     rewrite add_sl,sweep_cell by assumption.
     rewrite unique_visits by (apply touches_distinct;exact unique).
     destruct (in_dec Z.eq_dec (row_number row) (touches g q rs));[|exfalso;apply n;apply member_touches;assumption].
     change (sdelta true * 1) with (-1);rewrite <-decrement_word;reflexivity. }
   assert (equal_hits:hits_in g q false (slack during) rs=hits_in g q true (slack st) rs).
   { apply hits_in_agree;exact same. }
   rewrite rem_bl,equal_hits,add_bl;apply rollback_siblings;apply hits_range;exact qubits.
Qed.

Corollary restore_declared_column g qi st :
 let rows:=sublist (offset (column_offsets g) qi) (offset (column_offsets g) (qi+1)) (column_rows g) in
 NoDup (map row_number rows) ->
 Forall (fun row=>row_number row<Zlength (slack st)) rows -> valid_qubits g st ->
 let entered:=after_column g qi true st in
 let restored:=after_column g qi false entered in
 slack restored=slack st /\ blocked restored=blocked st.
Proof.
 intros rows uniq indices valid;unfold after_column,endpoints,column_prefix;fold rows.
 apply column_search_inverse;assumption.
Qed.
