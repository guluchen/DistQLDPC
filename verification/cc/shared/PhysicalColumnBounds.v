(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.zlist.list_solver.
From mathcomp Require Import all_ssreflect all_algebra.
Require Import SparseSyndrome FlipRoundtrip ClosureWord VerifClosesBody VerifToggleBody VerifFlipBody NativeFlipPayload NativeRootFlip.
Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.
Local Delimit Scope Z_scope with coqZ.
Local Open Scope Z_scope.

Lemma encoded_prefix m (rs:seq 'I_m) lo hi i (cells:list Integers.int):
 0<=lo<=i -> i<=hi -> sublist lo hi cells=map (@encode m) rs ->
 sublist lo i cells=map (@encode m) (sublist 0 (i-lo) rs).
Proof.
move=> span fits enc;change (sublist lo hi cells=List.map (@encode m) rs) in enc.
change (sublist lo i cells=List.map (@encode m) (sublist 0 (i-lo) rs));rewrite -sublist_map -enc sublist_sublist;try lia.
by replace (0+lo) with lo by lia;replace (i-lo+lo) with i by lia.
Qed.
Lemma physical_count_range m (A:{set 'I_m}) state:
 Z.of_nat m<Int.max_signed -> stores_odd state A ->
 Int.min_signed<snd state<Int.max_signed.
Proof.
move=> size [_ [_ count]].
have le:=(max_card A);rewrite card_ord in le;have lte:=elimT leP le.
rewrite count;change Int.min_signed with (-2147483648);lia.
Qed.
Definition static_column p (keys:list int64) q v:=
 q+1<Zlength (offsets v) /\ q<Zlength keys /\
 0<=Znth q (offsets v)<=Znth (q+1) (offsets v) /\ Znth (q+1) (offsets v)<=Zlength (rows v) /\
 Zlength (rows v)<=Int.max_unsigned /\ 0<width v<=Int.max_signed /\
 (q+1)*width v<=Zlength (masks v) /\ extra_bounds p q (Zlength (syndrome v)).

Theorem signed_and_addressed_from_pcm m (inc:seq 'I_m) (A:{set 'I_m}) p keys q v odd key:
 Z.of_nat m<Int.max_signed -> column_list v q=map (@encode m) inc ->
 stores_odd (syndrome v,odd) A -> static_column p keys q v ->
 valid_payload p keys q (Build_packed_support v odd key).
Proof.
move=> dim encoded stored [slot [key_slot [ordered [finish [bounded [width_ok [remaining extra]]]]]]].
have fits:(Z.of_nat m<=Int.modulus)%coqZ by change Int.max_signed with 2147483647 in dim;
 change Int.modulus with 4294967296;lia.
have initial:=@physical_count_range m A _ dim stored.
pose lo:=@Znth Z Inhabitant_Z q (offsets v);pose hi:=@Znth Z Inhabitant_Z (q+1) (offsets v);fold lo hi in ordered;fold hi in finish.
change (sublist lo hi (rows v)=map (@encode m) inc) in encoded.
unfold valid_payload;cbn [words_at odd_count];fold lo hi.
split;first exact slot. split;first exact key_slot. split;first exact ordered. split;first exact finish.
split;first exact bounded. change (Int.min_signed<odd<Int.max_signed) in initial. split;first lia.
split;first exact width_ok. split;first exact remaining.
split.
- move=> i inside.
  have in_slice:List.In (Znth i (rows v)) (sublist lo hi (rows v)).
  { have member:=@Znth_In Integers.int ltac:(typeclasses eauto) (i-lo) (sublist lo hi (rows v)).
    rewrite Zlength_sublist in member;try lia.
    specialize (member ltac:(lia));rewrite Znth_sublist in member;try lia.
    by replace (i-lo+lo) with i in member by lia. }
  rewrite encoded in in_slice;apply in_map_iff in in_slice as [r [<- _]].
  rewrite csr_word_index /encode Int.unsigned_repr;last first.
  { have lim:=elimT ltP (ltn_ord r);change Int.max_signed with 2147483647 in dim;change Int.max_unsigned with 4294967295;lia. }
  apply Z.div_lt_upper_bound;first lia.
  have lim:=elimT ltP (ltn_ord r);move:(proj1 stored)=> /= cap;lia.
- split;last exact extra.
  move=> i inside;unfold flipped;fold lo.
  rewrite (@encoded_prefix m inc lo hi i (rows v) ltac:(lia) ltac:(lia) encoded).
  have count:=@trace_correct m (sublist 0 (i-lo) inc) _ A fits stored.
  exact:(@physical_count_range m _ _ dim count).
Qed.
