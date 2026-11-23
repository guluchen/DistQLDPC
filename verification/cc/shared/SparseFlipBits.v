(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto.
Require Import VerifClosesBody VerifToggleBody ClosureWord.

Definition syndrome_bit (syn : list int64) (r : Z) :=
  Int64.testbit (Znth (r / 64) syn) (r mod 64).

Definition one_bit (b : Z) := Int64.shl Int64.one (Int64.repr b).

Lemma one_bit_at b j : 0 <= b < 64 -> 0 <= j < 64 ->
  Int64.testbit (one_bit b) j = Z.eqb j b.
Proof.
  intros B J. unfold one_bit. rewrite Int64.bits_shl by exact J.
  rewrite Int64.unsigned_repr by rep_lia.
  destruct (zlt j b).
  - symmetry. apply Z.eqb_neq. lia.
  - rewrite Int64.bits_one by (change Int64.zwordsize with 64; lia).
    destruct (zeq (j-b) 0); destruct (Z.eqb_spec j b); try reflexivity; lia.
Qed.

Lemma masked_bit w b : 0 <= b < 64 ->
  Int64.eq (Int64.and w (one_bit b)) Int64.zero = negb (Int64.testbit w b).
Proof.
  intros B. destruct (Int64.eq (Int64.and w (one_bit b)) Int64.zero) eqn:E;
    pose proof (Int64.eq_spec (Int64.and w (one_bit b)) Int64.zero) as test;
    rewrite E in test.
  - apply (f_equal (fun u => Int64.testbit u b)) in test.
    rewrite Int64.bits_and, one_bit_at, Z.eqb_refl, andb_true_r, Int64.bits_zero in test by exact B.
    now rewrite test.
  - destruct (Int64.testbit w b) eqn:D; [reflexivity | exfalso; apply test].
    apply Int64.same_bits_eq. intros j J.
    rewrite Int64.bits_and, one_bit_at, Int64.bits_zero by assumption.
    destruct (Z.eqb_spec j b); subst; [rewrite D | rewrite andb_false_r]; reflexivity.
Qed.

Lemma sparse_flip_bits syn odd r j :
  0 <= j < 64 * Zlength syn -> Int.unsigned r < 64 * Zlength syn ->
  syndrome_bit (fst (sparse_flip (syn,odd) r)) j =
    if Z.eq_dec j (Int.unsigned r) then negb (syndrome_bit syn j) else syndrome_bit syn j.
Proof.
  intros J R. pose proof (Int.unsigned_range_2 r) as Range.
  pose proof (Z.mod_pos_bound j 64 ltac:(lia)) as Jb.
  pose proof (Z.mod_pos_bound (Int.unsigned r) 64 ltac:(lia)) as Rb.
  assert (Jw: 0 <= j / 64 < Zlength syn) by (split; [apply Z.div_pos | apply Z.div_lt_upper_bound]; lia).
  assert (Rw: 0 <= Int.unsigned r / 64 < Zlength syn) by (split; [apply Z.div_pos | apply Z.div_lt_upper_bound]; lia).
  unfold syndrome_bit, sparse_flip. cbn [fst]. rewrite csr_word_index, csr_bit_index.
  destruct (Z.eq_dec (j/64) (Int.unsigned r/64)) as [W|W].
  - rewrite W, upd_Znth_same by exact Rw.
    rewrite Int64.bits_xor by exact Jb. fold (one_bit (Int.unsigned r mod 64)).
    rewrite one_bit_at by assumption. destruct (Z.eq_dec j (Int.unsigned r)) as [->|neq].
    + rewrite Z.eqb_refl, xorb_true_r; reflexivity.
    + assert (bits: j mod 64 <> Int.unsigned r mod 64).
      { intros same. pose proof (Z.div_mod j 64 ltac:(lia)).
        pose proof (Z.div_mod (Int.unsigned r) 64 ltac:(lia)); lia. }
      rewrite (proj2 (Z.eqb_neq _ _) bits), xorb_false_r; reflexivity.
  - rewrite upd_Znth_diff by assumption.
    destruct (Z.eq_dec j (Int.unsigned r)); [subst; contradiction | reflexivity].
Qed.

Lemma sparse_flip_count syn odd r :
  snd (sparse_flip (syn,odd) r) =
    if syndrome_bit syn (Int.unsigned r) then odd - 1 else odd + 1.
Proof.
  unfold sparse_flip, syndrome_bit. cbn [snd]. rewrite csr_word_index, csr_bit_index.
  set (b := Int.unsigned r mod 64).
  assert (B: 0 <= b < 64) by (unfold b; apply Z.mod_pos_bound; lia).
  fold (one_bit b). rewrite masked_bit, Int64.bits_xor, one_bit_at, Z.eqb_refl, xorb_true_r, Bool.negb_involutive by exact B.
  reflexivity.
Qed.
