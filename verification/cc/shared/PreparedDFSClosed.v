(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.floyd.reassoc_seq.
Require flag_level_ast.
Require Import PreparedSeedDispatch VerifDetected PackedDetector VerifPackedDetector.
Import flag_level_ast.

Definition prefix_fields (s b par : val) (w : Z) (words budgets : list int64)
  (nodes closed : int64) (witness : int) : mpred :=
  (field_at Tsh level_type [StructField _nodes] (Vlong nodes) s *
   field_at Tsh level_type [StructField _by_budget] b s *
   data_at Tsh (tarray tulong (Zlength budgets)) (map Vlong budgets) b *
   field_at Tsh level_type [StructField _w] (Vint (Int.repr w)) s *

   field_at Tsh level_type [StructField _nodd] (Vint Int.zero) s *
   field_at Tsh level_type [StructField _closed] (Vlong closed) s *
   field_at Tsh level_type [StructField _witness_size] (Vint witness) s *
   field_at Tsh level_type [StructField _kw] (Vint (Int.repr (Zlength words))) s *
   field_at Tsh level_type [StructField _gpar] par s *
   parity_storage Tsh words par)%logic.

Definition bump (budgets : list int64) (i : Z) :=
  upd_Znth i budgets (Int64.add (Znth i budgets) Int64.one).

(* The early closed-prefix return is reachable at any strictly interior
   depth. An early logical witness yields INCONSISTENT so that callers can
   distinguish a violated lower bound from exhaustion. *)
Definition dfs_closed_spec : ident * funspec :=
 DECLARE _dfs
 WITH s : val, policy : val, b : val, par : val, w : Z, depth : Z,
   words : list int64, budgets : list int64, nodes : int64, closed : int64, saved : int, bits:int
 PRE [tptr level_type, tptr (Tstruct _cc_level_policy noattr), tint, tuint]
   PROP (Int.and bits (Int.repr 2)=Int.zero; is_pointer_or_null policy; 1<=depth<w; w<=Int.max_signed;
         w-depth < Zlength budgets; Zlength words <= Int.max_signed)
   PARAMS (s; policy; Vint (Int.repr depth);Vint bits)
   SEP (prefix_fields s b par w words budgets nodes closed saved)
 POST [tint]
   PROP () RETURN (Vint (Int.repr (if packed_detects words then 3 else 0)))
   SEP (prefix_fields s b par w words (bump budgets (w-depth))
          (Int64.add nodes Int64.one) (Int64.add closed Int64.one)
          (if packed_detects words then Int.repr depth else saved)).

Definition ClosedGprog : funspecs := ltac:(with_library prog [detected_spec]).

Theorem body_dfs_closed : semax_body prepared_vars ClosedGprog f_dfs dfs_closed_spec.
Proof.
  start_function. unfold prefix_fields. Intros.
  do 8 (forward; try solve [entailer!]). reassoc_seq.
  apply semax_if_seq. forward_if; [solve [contradiction|congruence] | forward].
  apply semax_if_seq. forward_if; [solve [contradiction|congruence] | forward].
  apply semax_if_seq. forward_if; [contradiction | ].
  forward. apply semax_if_seq. forward_if; [rep_lia | ].
  forward. apply semax_if_seq. forward_if; [ | solve [contradiction|discriminate|congruence] ].
  forward. forward. forward_call (s,par,words,Tsh).
  rewrite detected_return_bits. destruct (packed_detects words) eqn:E.
  - apply semax_if_seq. forward_if; [discriminate|]. forward. forward.
    unfold prefix_fields,bump; rewrite ?E, upd_Znth_Zlength by lia. entailer!.
    rewrite upd_Znth_map. apply derives_refl.
  - apply semax_if_seq. forward_if; [|solve [contradiction|discriminate|congruence]]. forward.
    unfold prefix_fields,bump; rewrite ?E, upd_Znth_Zlength by lia. entailer!.
    rewrite upd_Znth_map. apply derives_refl.
Qed.
