(* SPDX-License-Identifier: GPL-3.0-or-later *)
From Coq Require Import ZArith Lia List.
From compcert.lib Require Import Integers.
From mathcomp Require Import all_ssreflect.

(* Include every stored bit. The producer is responsible for zero padding
   when the number of physical detectors is not divisible by 64. *)
Definition lit_word (w : int64) :=
  [exists i : 'I_64, Int64.testbit w (Z.of_nat i)].

Lemma lit_word_zero w : lit_word w = false <-> w = Int64.zero.
Proof.
split; last by move=> ->; apply/negbTE/existsPn=> i; rewrite Int64.bits_zero.
move=> dark; apply Int64.same_bits_eq => i hi.
rewrite Int64.bits_zero.
have irange : (0 <= i < 64)%Z by exact hi.
have hi64 : (Z.to_nat i < 64)%coq_nat by lia.
pose j : 'I_64 := Ordinal (introT ltP hi64).
have /existsPn none : ~~ lit_word w by rewrite dark.
have := none j; rewrite /j /= Z2Nat.id; last lia.
by case: (Int64.testbit w i).
Qed.

Definition packed_detects (words : seq int64) := has lit_word words.

Lemma packed_dark_words words :
  packed_detects words = false <-> List.Forall (eq Int64.zero) words.
Proof.
elim: words=> [|w ws IH]; first by split=> //; constructor.
change ((lit_word w || packed_detects ws) = false <-> List.Forall (eq Int64.zero) (w :: ws)).
split.
- move/Bool.orb_false_iff=> [/lit_word_zero -> /IH tail]; by constructor.
- move=> h; inversion h; subst.
  by rewrite (proj2 (lit_word_zero _) erefl) (proj2 IH ltac:(assumption)).
Qed.
