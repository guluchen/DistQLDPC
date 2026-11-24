(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto RowTally.
From mathcomp Require Import all_ssreflect.
Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.
Local Delimit Scope Z_scope with coqZ.

Section PackedRow.
Variable n:nat.
Variables free marked:{set 'I_n}.
Variables (blocks:seq Integers.int) (tags:seq int64) (stamp:int64).
Hypothesis fits:(Z.of_nat n<=Int.max_unsigned)%coqZ.
Hypothesis available:forall q:'I_n,Znth (Z.of_nat q) blocks=Int.zero <-> q \in free.
Hypothesis marking:forall q:'I_n,Znth (Z.of_nat q) tags=stamp <-> q \in marked.
Definition address (q:'I_n):=Int.repr (Z.of_nat q).
Lemma unsigned_address q:Int.unsigned (address q)=Z.of_nat q.
Proof. apply:Int.unsigned_repr;have small:=(elimT ltP (ltn_ord q));lia. Qed.
Lemma free_address q:is_free blocks (address q)=(q \in free).
Proof.
rewrite /is_free unsigned_address;apply/idP/idP.
- move=> eqv;apply:(proj1 (available q));apply:Int.same_if_eq;exact:eqv.
- move=> ok;rewrite (proj2 (available q) ok);exact:Int.eq_true.
Qed.
Lemma stamp_address q:has_stamp tags stamp (address q)=(q \in marked).
Proof.
rewrite /has_stamp unsigned_address;apply/idP/idP.
- move=> eqv;apply:(proj1 (marking q));apply:Int64.same_if_eq;exact:eqv.
- move=> ok;rewrite (proj2 (marking q) ok);exact:Int64.eq_true.
Qed.
Theorem physical_free_row ids :
 free_row blocks (map address ids)=map address [seq q <- ids | q \in free].
Proof. rewrite /free_row;elim:ids=>[|a ids IH] //=;rewrite free_address;by case:(a \in free)=> /=;rewrite IH. Qed.
Lemma physical_clash ids :
 row_clash blocks tags stamp (map address ids)=has (fun q=>(q \in free) && (q \in marked)) ids.
Proof. rewrite /row_clash;elim:ids=>[|a ids IH] //=;by rewrite free_address stamp_address IH. Qed.
Theorem clash_is_disjoint ids :
 ~~row_clash blocks tags stamp (map address ids) =
 [disjoint ([set q in ids] :&: free) & marked].
Proof.
rewrite physical_clash -setI_eq0;apply/idP/idP.
- move/hasPn=> none;apply/eqP/setP=> q;rewrite !inE.
  case inrow:(q \in ids)=> //=;move:(none _ inrow).
  by case:(q \in free);case:(q \in marked).
- move/eqP=> empty;apply/hasPn=> q inrow;apply/negP=> /andP[avail hit].
  have occupied:q \in ([set q in ids] :&: free) :&: marked by rewrite !inE inrow avail hit.
  by move:occupied;rewrite empty inE.
Qed.
End PackedRow.
