(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto.
From mathcomp Require Import all_ssreflect all_algebra.
From Coq Require Import Logic.FinFun.
Require Import LeafMatrix MinimumPrefix RowTally IndexRowBridge PreparedRowCoverage SiblingCounters.
Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.
Local Open Scope ring_scope.
Local Delimit Scope Z_scope with coqZ.

Definition physical_member n (members:{set 'I_n}) (index:Z):bool:=
 has (fun q:'I_n=>Z.eqb index (Z.of_nat q)) (enum members).

Lemma member_decodes n (T:{set 'I_n}) index:
 physical_member T index <-> exists q:'I_n,index=Z.of_nat q /\ q \in T.
Proof.
 split.
 - by move/hasP=>[q];rewrite mem_enum=> live /Z.eqb_eq eqn;exists q.
 - move=> [q [-> live]];apply/hasP;exists q;[by rewrite mem_enum|exact:Z.eqb_refl].
Qed.

Section Row.
Variables m n:nat.
Variables (H:'M['F_2]_(m,n)) (prefix target:'cV['F_2]_n) (r:'I_m) (ids:seq 'I_n).
Variables (blocks:seq Integers.int) (allowed:{set 'I_n}).
Hypotheses (fits:(Z.of_nat n<=Int.max_unsigned)%coqZ)
 (length_ok:Zlength blocks=Z.of_nat n)
 (available:forall q:'I_n,Znth (Z.of_nat q) blocks=Int.zero <-> q \in allowed).
Let T:=support target :\: support prefix.
Let actual:=map Int.unsigned (free_row blocks (map (@address n) ids)).

Lemma emitted_values:
 actual=map (fun q:'I_n=>Z.of_nat q) [seq q<-ids | q \in allowed].
Proof.
 rewrite /actual (@physical_free_row n allowed blocks fits available ids) -map_comp.
 apply eq_map=>q;exact:(unsigned_address fits q).
Qed.

Lemma as_member (A:eqType) (q:A) (ls:seq A):List.In q ls -> q \in ls.
Proof.
 elim:ls=>[|a ls ih] //=;rewrite inE=>[[->|later]];[by rewrite eqxx|by rewrite (ih later) orbT].
Qed.

Lemma nodup_members (A:eqType) (ls:seq A):uniq ls -> List.NoDup ls.
Proof.
 elim:ls=>[|a ls ih] /=;first by constructor.
 move/andP=>[missing unique];constructor;last exact:(ih unique).
 by move/as_member=>member;exact:(negP missing member).
Qed.

Theorem emitted_unique:uniq ids -> List.NoDup actual.
Proof.
 move=> unique;rewrite emitted_values.
 apply FinFun.Injective_map_NoDup.
 - move=> a b equal;apply val_inj;exact:(Nat2Z.inj _ _ equal).
 - apply nodup_members;exact:filter_uniq.
Qed.

Theorem emitted_range_and_availability:
 in_array (Zlength blocks) actual /\ Forall (fun i=>Znth i blocks=Int.zero) actual.
Proof.
 rewrite emitted_values;split;apply Forall_forall=> i /List.in_map_iff [q [<- included]].
 - rewrite length_ok;have ord:=elimT ltP (ltn_ord q);lia.
 - apply (proj2 (available q)).
   move:(as_member included);by rewrite mem_filter=>/andP[ok row].
Qed.

Theorem residual_inputs_for_scan:
 (forall q:'I_n,H r q!=0 -> q \in ids) ->
 support prefix \subset support target -> H*m target=0 -> (H*m prefix) r 0!=0 -> T \subset allowed ->
 (forall i,physical_member T i -> (0<=i<Zlength blocks)%coqZ /\ Znth i blocks=Int.zero) /\
 (exists i,List.In i actual /\ physical_member T i).
Proof.
 move=> covers sub closed odd free;split.
 - move=> i /member_decodes[q [-> live]];split.
   + rewrite length_ok;have ord:=elimT ltP (ltn_ord q);lia.
   + apply (proj2 (available q));exact:(subsetP free _ live).
 - have [q [live yes]]:=@odd_candidate_buffer_hits m n H prefix target r ids blocks allowed fits
    available covers sub closed odd free.
   exists (Z.of_nat q);split=> //;apply/member_decodes;by exists q.
Qed.
End Row.
