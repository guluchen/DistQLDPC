(* SPDX-License-Identifier: GPL-3.0-or-later *)
From Coq Require Import ZArith Lia List.
From compcert.lib Require Import Integers.
From mathcomp Require Import all_ssreflect all_algebra.
Require Import PackedDetector LeafMatrix DetectorMatrix.
Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.
Local Open Scope ring_scope.
Local Delimit Scope Z_scope with coqZ.

Definition unpack ws := flatten [seq word_bits w | w <- ws].
Lemma word_size w : size (word_bits w) = 64%N.
Proof. by rewrite /word_bits size_map size_enum_ord. Qed.

Lemma word_bit_at w (i : 'I_64) :
  nth false (word_bits w) i = Int64.testbit w (Z.of_nat i).
Proof.
rewrite /word_bits (nth_map ord0); first by rewrite nth_ord_enum.
by rewrite size_enum_ord.
Qed.

Lemma word_bits_inj : injective word_bits.
Proof.
move=> a b eqb; apply Int64.same_bits_eq => z range.
have nz : (0 <= z < 64)%coqZ := range.
have jbound : (Z.to_nat z < 64)%coq_nat by lia.
pose i : 'I_64 := Ordinal (introT ltP jbound).
have := congr1 (fun s => nth false s i) eqb.
by rewrite !word_bit_at /i /= Z2Nat.id; last lia.
Qed.

Lemma unpack_size ws : size (unpack ws) = (64 * size ws)%N.
Proof. elim: ws=> //= w ws ih; by rewrite /unpack /= size_cat word_size -/(unpack ws) ih mulnS. Qed.

Lemma unpack_inj : injective unpack.
Proof.
elim=> [|a xs ih] [|b ys] //=.
- by move/(congr1 size); rewrite !unpack_size /= mulnS.
- by move/(congr1 size); rewrite !unpack_size /= mulnS.
- rewrite /unpack /= => eqb.
  have heads := congr1 (take 64) eqb; rewrite !take_size_cat ?word_size // in heads.
  have tails := congr1 (drop 64) eqb; rewrite !drop_size_cat ?word_size // in tails.
  by rewrite (word_bits_inj heads) (ih _ tails).
Qed.

Definition vecbits j (x : 'cV['F_2]_j) := [seq x i 0 != 0 | i : 'I_j].
Lemma vecbits_size j (x : 'cV['F_2]_j) : size (vecbits x) = j.
Proof. by rewrite /vecbits size_map size_enum_ord. Qed.

Lemma vecbit_at j (x : 'cV['F_2]_j) (i : 'I_j) :
  nth false (vecbits x) i = (x i 0 != 0).
Proof.
rewrite /vecbits (nth_map i); first by rewrite nth_ord_enum.
by rewrite size_enum_ord.
Qed.

Lemma vecbits_inj j : injective (@vecbits j).
Proof.
move=> x y same; apply: binary_support_inj; apply/setP=> i.
have at_x := congr1 (fun s => nth false s i) same.
have equal_bit : (x i 0 != 0) = (y i 0 != 0).
  by move: at_x; rewrite !vecbit_at.
by rewrite /support !inE equal_bit.
Qed.

Lemma represented_equal j a b (x y : 'cV['F_2]_j) :
  represents a x -> represents b y -> size a = size b -> (a = b <-> x = y).
Proof.
move=> [pa ha] [pb hb] sz; change (unpack a = vecbits x ++ nseq pa false) in ha.
change (unpack b = vecbits y ++ nseq pb false) in hb.
split.
- move=> ab; apply: vecbits_inj.
  have eqb : unpack a = unpack b by rewrite ab.
  move/(congr1 (take j)): eqb; by rewrite ha hb !take_size_cat ?vecbits_size.
- move=> exy; apply: unpack_inj.
  have same : size (unpack a) = size (unpack b) by rewrite !unpack_size sz.
  rewrite ha hb !size_cat !vecbits_size !size_nseq in same.
  by rewrite ha hb exy (addnI same).
Qed.

Definition xors (a b : seq int64) :=
  [seq Int64.xor p.1 p.2 | p <- zip a b].
Lemma xor_dark a b : size a = size b -> (packed_detects (xors a b) = false <-> a = b).
Proof.
elim: a b => [|u us ih] [|v vs] //=.
move/succn_inj=> size_eq.
  change ((lit_word (Int64.xor u v) || packed_detects (xors us vs)) = false
          <-> u :: us = v :: vs).
  split.
  + move/Bool.orb_false_iff=> [/lit_word_zero huv tail].
    by rewrite (Int64.xor_zero_equal _ _ huv) ((proj1 (ih vs size_eq)) tail).
  + move=> [-> eqtail]; apply/Bool.orb_false_iff; split.
    * by apply/lit_word_zero; rewrite Int64.xor_idem.
    * exact: (proj2 (ih vs size_eq)).
Qed.

Theorem packed_column_differs j a b (x y : 'cV['F_2]_j) :
  represents a x -> represents b y -> size a = size b ->
  packed_detects (xors a b) = (x != y).
Proof.
move=> ax by_ sz; have dark := xor_dark sz; have equal := represented_equal ax by_ sz.
case h: (packed_detects (xors a b)).
- apply/esym/negP=> /eqP e; by move: (proj2 dark (proj2 equal e)); rewrite h.
- by rewrite (proj1 equal (proj1 dark h)) eqxx.
Qed.
