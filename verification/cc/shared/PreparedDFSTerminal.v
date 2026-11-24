(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.floyd.reassoc_seq.
Require DetectorMatrix.
Require flag_level_ast.
Require Import PreparedSeedDispatch VerifDetected PackedDetector VerifPackedDetector.
Import flag_level_ast.

Definition leaf_accept (odd : Z) (words : list int64) :=
  (Z.eqb odd 0 && packed_detects words)%bool.

Definition terminal_fields (s b par : val) (w odd : Z) (words : list int64)
    (nodes budget : int64) (witness : val) : mpred :=
  (field_at Tsh level_type [StructField _nodes] (Vlong nodes) s *
  field_at Tsh level_type [StructField _by_budget] b s *
  data_at Tsh (tarray tulong 1) [Vlong budget] b *
  field_at Tsh level_type [StructField _w] (Vint (Int.repr w)) s *

  field_at Tsh level_type [StructField _nodd] (Vint (Int.repr odd)) s *
  field_at Tsh level_type [StructField _witness_size] witness s *
  field_at Tsh level_type [StructField _kw] (Vint (Int.repr (Zlength words))) s *
  field_at Tsh level_type [StructField _gpar] par s *
  parity_storage Tsh words par)%logic.

(* A disabled polling bit requires no poll fields or callback resource. *)
Definition dfs_leaf_spec : ident * funspec :=
 DECLARE _dfs
 WITH s : val, policy : val, b : val, par : val, w : Z, odd : Z,
      words : list int64, nodes : int64, budget : int64, saved : int, bits:int
 PRE [tptr level_type, tptr (Tstruct _cc_level_policy noattr), tint, tuint]
   PROP (Int.and bits (Int.repr 2)=Int.zero; is_pointer_or_null policy; 1 <= w <= Int.max_signed;
         0 <= odd <= Int.max_signed; Zlength words <= Int.max_signed)
   PARAMS (s; policy; Vint (Int.repr w);Vint bits)
   SEP (terminal_fields s b par w odd words nodes budget (Vint saved))
 POST [tint]
   PROP () RETURN (Vint (if leaf_accept odd words then Int.one else Int.zero))
   SEP (terminal_fields s b par w odd words
          (Int64.add nodes Int64.one) (Int64.add budget Int64.one)
          (Vint (if leaf_accept odd words then Int.repr w else saved))).

Definition LeafGprog : funspecs := ltac:(with_library prog [detected_spec; dfs_leaf_spec]).

Theorem body_dfs_terminal : semax_body prepared_vars LeafGprog f_dfs dfs_leaf_spec.
Proof.
  start_function. unfold terminal_fields. Intros.
  do 8 (forward; try solve [rewrite ?Z.sub_diag; entailer!]). reassoc_seq.
  rewrite ?Z.sub_diag.
  apply semax_if_seq. forward_if; [solve [contradiction|congruence] | forward].
  apply semax_if_seq. forward_if; [solve [contradiction|congruence] | forward].
  apply semax_if_seq. forward_if; [contradiction | ].
  forward. apply semax_if_seq. forward_if; [ | congruence ].
  forward. apply semax_if_seq. forward_if.
  - forward. apply semax_if_seq. forward_if; [ | discriminate ].
    forward. unfold terminal_fields, leaf_accept.
    rewrite (proj2 (Z.eqb_neq odd 0) ltac:(rep_lia)). entailer!.
  - match goal with Hodd : Int.repr odd = Int.zero |- _ =>
      apply (f_equal Int.unsigned) in Hodd;
      rewrite Int.unsigned_repr in Hodd by rep_lia;
      change (odd = 0) in Hodd; subst odd end.
    forward_call (s, par, words, Tsh).
    rewrite detected_return_bits. destruct (packed_detects words) eqn:E.
    + forward. apply semax_if_seq. forward_if; [solve [contradiction | discriminate | congruence] | ].
      forward. forward. unfold terminal_fields, leaf_accept; rewrite E. entailer!.
    + forward. apply semax_if_seq. forward_if; [ | discriminate ].
      forward. unfold terminal_fields, leaf_accept; rewrite E. entailer!.
Qed.

Corollary dfs_leaf_accept_pcm m n k H L x words :
  DetectorMatrix.stores_response L x words ->
  leaf_accept (@DetectorMatrix.number_odd m n H x) words =
    @DetectorMatrix.valid_terminal m n k H L x.
Proof. apply DetectorMatrix.terminal_bits_correct. Qed.
