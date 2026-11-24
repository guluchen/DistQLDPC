(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto.
Require Import level_ast VerifDetected PackedDetector VerifPackedDetector VerifLastPair.
Definition pair_closed_fields s w par (words:list int64) closed saved : mpred :=
 (field_at Tsh level_type [StructField _w] (Vint (Int.repr w)) s *
  field_at Tsh level_type [StructField _nodd] (Vint Int.zero) s *
  field_at Tsh level_type [StructField _kw] (Vint (Int.repr (Zlength words))) s *
  field_at Tsh level_type [StructField _gpar] par s *
  parity_storage Tsh words par *
  field_at Tsh level_type [StructField _closed] (Vlong closed) s *
  field_at Tsh level_type [StructField _witness_size] (Vint saved) s)%logic.

(* A closure after the first of two moves produces a shorter witness.
   The native enum value is INCONSISTENT, which forces the driver to
   revisit its lower bound. A stabilizer leaves the result EMPTY. *)
Theorem semax_last_pair_closed {Espec:OracleKind} s par words closed saved depth :
  1<=depth<=Int.max_signed-2 -> Zlength words<=Int.max_signed ->
  semax pair_context
   (PROP() LOCAL(temp _s s;temp _size (Vint (Int.repr depth));temp _result (Vint Int.zero))
    SEP(pair_closed_fields s (depth+2) par words closed saved))
   native_dispatch
   (normal_ret_assert (PROP() LOCAL(temp _s s;temp _size (Vint (Int.repr depth));
       temp _result (Vint (Int.repr (if packed_detects words then 3 else 0))))
    SEP(pair_closed_fields s (depth+2) par words (Int64.add closed Int64.one)
      (if packed_detects words then Int.repr (depth+1) else saved)))).
Proof.
  intros fits len;pose proof (subtract_two depth fits) as same.
  unfold pair_context,native_dispatch,pair_closed_fields;abbreviate_semax. Intros.
  forward. forward_if;try solve [entailer!;rep_lia|rep_lia|congruence].
  forward. forward_if;try solve [exfalso;apply H0;reflexivity|entailer!;rep_lia|rep_lia|congruence].
  forward. forward. forward_call (s,par,words,Tsh).
  rewrite detected_return_bits. destruct (packed_detects words) eqn:Hres.
  - forward_if;try solve [contradiction|discriminate].
    forward;forward;try unfold pair_closed_fields;rewrite ?Hres;entailer!.
  - forward_if;try solve [contradiction|discriminate].
    forward;try unfold pair_closed_fields;rewrite ?Hres;entailer!.
Qed.
