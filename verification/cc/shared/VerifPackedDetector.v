(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto.
Require Import level_ast VerifDetected PackedDetector.

Lemma detected_return_bits words :
  detected_value words =
  Vint (if packed_detects words then Int.one else Int.zero).
Proof.
  destruct (detected_value_correct words) as [[Hz Hret]|[Hnz Hret]];
    rewrite Hret.
  - rewrite (proj2 (packed_dark_words words) Hz). reflexivity.
  - destruct (packed_detects words) eqn:H; [reflexivity|].
    exfalso. apply Hnz. now apply packed_dark_words.
Qed.

Definition bit_result (words : list int64) :=
  Vint (if packed_detects words then Int.one else Int.zero).

Definition detected_bits_spec : ident * funspec :=
 DECLARE _detected
 WITH s : val, parity : val, words : list int64, sh : share
 PRE [tptr level_type]
   PROP (readable_share sh; Zlength words <= Int.max_signed) PARAMS (s)
   SEP (field_at sh level_type [StructField _kw] (Vint (Int.repr (Zlength words))) s;
        field_at sh level_type [StructField _gpar] parity s;
        parity_storage sh words parity)
 POST [tint] PROP ()
   RETURN (bit_result words)
   SEP (field_at sh level_type [StructField _kw] (Vint (Int.repr (Zlength words))) s;
        field_at sh level_type [StructField _gpar] parity s;
        parity_storage sh words parity).

Theorem body_detected_bits : semax_body Vprog Gprog f_detected detected_bits_spec.
Proof.
  assert (E : bit_result = detected_value).
  { extensionality words. symmetry. apply detected_return_bits. }
  unfold detected_bits_spec. rewrite E. exact body_detected.
Qed.
