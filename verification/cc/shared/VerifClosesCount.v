(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto.
Require Import level_ast VerifDetected.

(* With an unequal column degree and odd-check count the function must reject
   before it consults the row, syndrome or logical-detector arrays. *)
Definition closes_count_spec : ident * funspec :=
 DECLARE _closes
 WITH s : val, offsets : val, sh : share, entries : list Z,
      q : Z, odd : Z
 PRE [tptr level_type, tint]
   PROP (readable_share sh; 0 <= q < Int.max_signed; q+1 < Zlength entries;
         0 <= Znth q entries <= Znth (q+1) entries;
         Znth (q+1) entries <= Int.max_unsigned; 0 <= odd <= Int.max_signed;
         Znth (q+1) entries - Znth q entries <> odd)
   PARAMS (s; Vint (Int.repr q))
   SEP (field_at sh level_type [StructField _cstart] offsets s;
        field_at sh level_type [StructField _nodd] (Vint (Int.repr odd)) s;
        data_at sh (tarray tuint (Zlength entries))
          (map (fun z => Vint (Int.repr z)) entries) offsets)
 POST [tint]
   PROP () RETURN (Vint Int.zero)
   SEP (field_at sh level_type [StructField _cstart] offsets s;
        field_at sh level_type [StructField _nodd] (Vint (Int.repr odd)) s;
        data_at sh (tarray tuint (Zlength entries))
          (map (fun z => Vint (Int.repr z)) entries) offsets).

Definition CountGprog : funspecs := ltac:(with_library prog [closes_count_spec]).

Theorem body_closes_count : semax_body Vprog CountGprog f_closes closes_count_spec.
Proof.
  start_function.
  forward. forward. forward. forward. forward.
  forward_if.
  - forward.
  - exfalso.
    repeat match goal with H : context [Int.sub (Int.repr _) (Int.repr _)] |- _ =>
      rewrite sub_repr in H end.
    apply H4. apply (f_equal Int.unsigned) in H5.
    rewrite !Int.unsigned_repr in H5 by rep_lia. exact H5.
Qed.
