(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.floyd.reassoc_seq.
Require Import PreparedSeedDispatch VerifDetected VerifPackedDetector PackedDetector VerifClosesBody VerifLookup
 PreparedDFSTerminal PreparedDFSClosed flag_level_ast.
#[local] Existing Instance VerifDetected.CompSpecs.
Local Open Scope Z_scope.

(* No recursive call occurs at any of these exits. This map can be
   included under the same recursive contract as the deep C body. *)
Definition base_calls : funspecs := ltac:(with_library prog [detected_spec;lookup_spec]).

Definition budget_leaf_fields (s b par : val) (w odd : Z) (words : list int64)
    (nodes : int64) (budgets:list int64) (witness : val) : mpred :=
  (field_at Tsh level_type [StructField _nodes] (Vlong nodes) s *
  field_at Tsh level_type [StructField _by_budget] b s *
  data_at Tsh (tarray tulong (Zlength budgets)) (map Vlong budgets) b *
  field_at Tsh level_type [StructField _w] (Vint (Int.repr w)) s *

  field_at Tsh level_type [StructField _nodd] (Vint (Int.repr odd)) s *
  field_at Tsh level_type [StructField _witness_size] witness s *
  field_at Tsh level_type [StructField _kw] (Vint (Int.repr (Zlength words))) s *
  field_at Tsh level_type [StructField _gpar] par s *
  parity_storage Tsh words par)%logic.

(* A disabled polling bit requires no poll fields or callback resource. *)
Definition budget_leaf_spec : ident * funspec :=
 DECLARE _dfs
 WITH s : val, policy : val, b : val, par : val, w : Z, odd : Z,
      words : list int64, nodes : int64, budgets : list int64, saved : int, bits:int
 PRE [tptr level_type, tptr (Tstruct _cc_level_policy noattr), tint, tuint]
   PROP (Int.and bits (Int.repr 2)=Int.zero; is_pointer_or_null policy; 1 <= w <= Int.max_signed;
         0 <= odd <= Int.max_signed; Zlength words <= Int.max_signed;0<Zlength budgets)
   PARAMS (s; policy; Vint (Int.repr w);Vint bits)
   SEP (budget_leaf_fields s b par w odd words nodes budgets (Vint saved))
 POST [tint]
   PROP () RETURN (Vint (if leaf_accept odd words then Int.one else Int.zero))
   SEP (budget_leaf_fields s b par w odd words
          (Int64.add nodes Int64.one) (PreparedDFSClosed.bump budgets 0)
          (Vint (if leaf_accept odd words then Int.repr w else saved))).

Theorem terminal_on_native_budget_array : semax_body prepared_vars base_calls f_dfs budget_leaf_spec.
Proof.
  start_function. unfold budget_leaf_fields. Intros.
  do 8 (forward; try solve [rewrite ?Z.sub_diag; entailer!]). reassoc_seq.
  rewrite ?Z.sub_diag.
  apply semax_if_seq. forward_if; [solve [contradiction|congruence] | forward].
  apply semax_if_seq. forward_if; [solve [contradiction|congruence] | forward].
  apply semax_if_seq. forward_if; [contradiction | ].
  forward. apply semax_if_seq. forward_if; [ | congruence ].
  forward. apply semax_if_seq. forward_if.
  - forward. apply semax_if_seq. forward_if; [ | discriminate ].
    forward. unfold budget_leaf_fields, leaf_accept,PreparedDFSClosed.bump.
    rewrite (proj2 (Z.eqb_neq odd 0) ltac:(rep_lia)). rewrite ?upd_Znth_Zlength by lia;entailer!;rewrite ?upd_Znth_map;try apply derives_refl.
  - match goal with Hodd : Int.repr odd = Int.zero |- _ =>
      apply (f_equal Int.unsigned) in Hodd;
      rewrite Int.unsigned_repr in Hodd by rep_lia;
      change (odd = 0) in Hodd; subst odd end.
    forward_call (s, par, words, Tsh).
    rewrite detected_return_bits. destruct (packed_detects words) eqn:E.
    + forward. apply semax_if_seq. forward_if; [solve [contradiction | discriminate | congruence] | ].
      forward. forward. unfold budget_leaf_fields, leaf_accept,PreparedDFSClosed.bump; rewrite E,upd_Znth_Zlength by lia;entailer!;rewrite ?upd_Znth_map;try apply derives_refl.
    + forward. apply semax_if_seq. forward_if; [ | discriminate ].
      forward. unfold budget_leaf_fields, leaf_accept,PreparedDFSClosed.bump; rewrite E,upd_Znth_Zlength by lia;entailer!;rewrite ?upd_Znth_map;try apply derives_refl.
Qed.

