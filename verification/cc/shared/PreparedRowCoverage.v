(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto.
From mathcomp Require Import all_ssreflect all_algebra.
Require Import LeafMatrix MinimumPrefix RowTally IndexRowBridge.
Local Open Scope ring_scope.
Local Delimit Scope Z_scope with coqZ.
Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.

Lemma member_as_in (T:eqType) (q:T) xs: q \in xs -> List.In q xs.
Proof. elim:xs=>[|a xs ih] //=;rewrite inE=>/orP[/eqP ->|member];auto. Qed.

Section ChosenRow.
Variables m n:nat.
Variables (H:'M['F_2]_(m,n)) (prefix target:'cV['F_2]_n) (r:'I_m) (ids:seq 'I_n).
Variables (blocks:seq Integers.int) (allowed:{set 'I_n}).
Hypotheses (fits:(Z.of_nat n<=Int.max_unsigned)%coqZ)
 (available:forall q:'I_n,Znth (Z.of_nat q) blocks=Int.zero <-> q \in allowed).
Hypothesis covers:forall q:'I_n,H r q != 0 -> q \in ids.
Let remaining:=support target :\: support prefix.
Let words:=free_row blocks (map (@address n) ids).

(* Any chosen odd check, in any CSR order, leaves at least one remaining
   target entry in the physical filtered candidate buffer. *)
Theorem odd_candidate_buffer_hits:
 support prefix \subset support target -> H*m target=0 -> (H*m prefix) r 0 != 0 ->
 remaining \subset allowed ->
 exists q:'I_n,q \in remaining /\ List.In (Z.of_nat q) (map Int.unsigned words).
Proof.
 move=> sub closed odd free.
 have [q [live incident]]:=@odd_row_hits_residual m n H prefix target r sub closed odd.
 exists q;split;first exact live.
 rewrite /words (@physical_free_row n allowed blocks fits available ids).
 apply/List.in_map_iff;exists (address q);split;first exact:(unsigned_address fits q).
 apply/List.in_map_iff;exists q;split=> //.
 apply:member_as_in;by rewrite mem_filter (subsetP free q live) (@covers q incident).
Qed.
End ChosenRow.
