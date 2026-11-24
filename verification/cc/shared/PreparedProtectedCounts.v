(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto SiblingCounters OverlapColumnState OverlapRowState OverlapRollback
 OverlapChildState OverlapTargetProgress ChildColumn.
From Coq Require Import List Lia.
Local Open Scope Z_scope.

Lemma distinct_rows_bound_hits (rows:list int) (f:int->list Z) a:
 Forall (fun r=>NoDup (f r)) rows ->
 visits (flat_map f rows) a<=Zlength rows.
Proof.
 induction rows as [|r rest IH];intro distinct;[reflexivity|].
 inversion distinct as [|? ? once more];subst.
 specialize (IH more);rewrite Zlength_cons;cbn [flat_map];unfold visits in *.
 rewrite count_occ_app,Nat2Z.inj_add.
 pose proof ((proj1 (NoDup_count_occ Z.eq_dec (f r))) once a) as one;lia.
Qed.

(* The ABI stores the block count in uint32_t. A distinct PCM row can
   add at most one to this particular counter. The bound below is local
   to the current column and also allows a qubit to occur in many rows. *)
Theorem entering_preserves_protected_count g q st a:
 column_bounds g q st -> 0<=a<Zlength (blocked st) ->
 Forall (fun r=>NoDup (hits g (Int.repr q) true (slack st) r)) (entries g q) ->
 Int.unsigned (Znth a (blocked st))+Zlength (entries g q)<=Int.max_unsigned ->
 Znth a (blocked st)<>Int.zero -> Znth a (blocked (after_column g q true st))<>Int.zero.
Proof.
 intros [unique [rows valid]] index once fits old returned.
 destruct (@column_effect g (Int.repr q) true (entries g q) st unique) as [_ effect].
 unfold after_column,endpoints,column_prefix in returned;fold (entries g q) in returned.
 rewrite effect,sweep_cell in returned by (try assumption;apply hits_range;exact valid).
 change (bdelta true) with 1 in returned;rewrite Z.mul_1_l in returned.
 set (word:=Znth a (blocked st)) in *.
 set (inc:=visits (hits_in g (Int.repr q) true (slack st) (entries g q)) a) in *.
 assert (upper:inc<=Zlength (entries g q)) by (apply distinct_rows_bound_hits;exact once).
 assert (count:0<=inc) by (unfold inc,visits;lia).
 assert (positive:0<Int.unsigned word).
 { pose proof (Int.unsigned_range_2 word).
   assert (Int.unsigned word<>0) by (intro zero;apply old;rewrite <-(Int.repr_unsigned word),zero;reflexivity).
   lia. }
 rewrite <- (Int.repr_unsigned word) in returned;rewrite add_encoded in returned.
 apply (f_equal Int.unsigned) in returned;rewrite Int.unsigned_repr in returned by lia.
 change (Int.unsigned Int.zero) with 0 in returned;lia.
Qed.
