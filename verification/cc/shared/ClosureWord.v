(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto.
Require Import level_ast VerifDetected VerifClosesBody.

Lemma csr_word_index r : word_index r = Int.unsigned r / 64.
Proof.
  unfold word_index. rewrite Int.shru_div_two_p.
  change (two_p (Int.unsigned (Int.repr 6))) with 64.
  rewrite Int.unsigned_repr; [reflexivity | ].
  pose proof (Int.unsigned_range_2 r). split; [apply Z.div_pos | apply Z.le_trans with (Int.unsigned r); [apply Z.div_le_upper_bound | ]]; lia.
Qed.

Lemma csr_bit_index r : bit_index r = Int.unsigned r mod 64.
Proof.
  unfold bit_index, Int.and. change (Int.unsigned (Int.repr 63)) with (Z.ones 6).
  rewrite Z.land_ones by lia. change (2^6) with 64.
  rewrite Int.unsigned_repr; [reflexivity | ].
  pose proof (Z.mod_pos_bound (Int.unsigned r) 64 ltac:(lia)); rep_lia.
Qed.

Lemma low_mask_dark w : Int64.and w Int64.one = Int64.zero <-> Int64.testbit w 0 = false.
Proof.
  split.
  - intro eqword. apply (f_equal (fun u => Int64.testbit u 0)) in eqword.
    rewrite Int64.bits_and, Int64.bits_one, Int64.bits_zero in eqword by rep_lia.
    change ((Int64.testbit w 0 && true)%bool = false) in eqword. now rewrite andb_true_r in eqword.
  - intro dark. apply Int64.same_bits_eq; intros i bound.
    rewrite Int64.bits_and, Int64.bits_one, Int64.bits_zero by assumption.
    destruct (zeq i 0); subst; [rewrite dark | rewrite andb_false_r]; reflexivity.
Qed.

Lemma scan_bit_dark v i :
  let r := Znth i (rows v) in
  scan_bit v i = Int64.zero <->
  Int64.testbit (Znth (Int.unsigned r / 64) (syndrome v)) (Int.unsigned r mod 64) = false.
Proof.
  simpl. unfold scan_bit. rewrite low_mask_dark, csr_word_index.
  rewrite Int64.bits_shru' by rep_lia.
  fold (bit_index (Znth i (rows v))). rewrite Z.add_0_l, csr_bit_index.
  destruct (zlt _ Int64.zwordsize) as [small|large]; [reflexivity | ].
  change Int64.zwordsize with 64 in large.
  pose proof (Z.mod_pos_bound (Int.unsigned (Znth i (rows v))) 64 ltac:(lia)); lia.
Qed.
