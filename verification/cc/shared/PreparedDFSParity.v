(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.floyd.reassoc_seq.
Require Import PreparedSeedDispatch VerifDetected VerifClosedPrefix VerifPolicyParity.
Require flag_level_ast.
Import flag_level_ast.

Definition parity_fields s b w odd (budget:list int64) nodes cuts : mpred :=
  (field_at Tsh level_type [StructField _w] (Vint (Int.repr w)) s *
   field_at Tsh level_type [StructField _nodd] (Vint (Int.repr odd)) s *
   field_at Tsh level_type [StructField _nodes] (Vlong nodes) s *
   field_at Tsh level_type [StructField _by_budget] b s *
   data_at Tsh (tarray tulong (Zlength budget)) (map Vlong budget) b *
   field_at Tsh level_type [StructField _parprune] (Vlong cuts) s)%logic.

Definition policy_parity_spec : ident * funspec :=
 DECLARE _dfs
 WITH s:val, b:val, policy:val, w:Z, depth:Z, odd:Z, budgets:list int64,
   nodes:int64, cuts:int64,bits:int
 PRE [tptr level_type, tptr (Tstruct _cc_level_policy noattr), tint,tuint]
  PROP(1<=depth<w; w<=Int.max_signed; 0<odd<=Int.max_signed;
       w-depth<Zlength budgets; Z.testbit (w-depth-odd) 0=true;Int.and bits (Int.repr 2)=Int.zero;Int.and bits (Int.repr 8)<>Int.zero;is_pointer_or_null policy)
  PARAMS(s; policy; Vint (Int.repr depth);Vint bits)
  SEP(parity_fields s b w odd budgets nodes cuts)
 POST [tint]
  PROP() RETURN(Vint Int.zero)
  SEP(parity_fields s b w odd (bump budgets (w-depth))
       (Int64.add nodes Int64.one) (Int64.add cuts Int64.one)).

Definition PolicyParityGprog : funspecs := ltac:(with_library prog [policy_parity_spec]).

Theorem body_policy_parity : semax_body prepared_vars PolicyParityGprog f_dfs policy_parity_spec.
Proof.
  start_function. unfold parity_fields. Intros.
  do 8 (forward; try solve [entailer!]). reassoc_seq.
  apply semax_if_seq. forward_if;[solve [contradiction|congruence]|forward].
  apply semax_if_seq. forward_if;[solve [contradiction|congruence]|forward].
  apply semax_if_seq. forward_if;[contradiction|].
  forward. apply semax_if_seq. forward_if;[rep_lia|].
  assert (nonzero:Int.repr odd<>Int.zero).
  { intro bad; apply (f_equal Int.unsigned) in bad. rewrite Int.unsigned_repr in bad by rep_lia.
    change (odd=0) in bad;lia. }
  forward. apply semax_if_seq. forward_if;[congruence|]. reassoc_seq.
  apply semax_if_seq. forward_if;[|congruence].
  forward. forward. forward;try solve [entailer!].
  assert (bit : Int.and (Int.sub (Int.sub (Int.repr w) (Int.repr depth)) (Int.repr odd)) Int.one
                = Int.one) by (rewrite !sub_word;apply low_bit_set;assumption).
  apply semax_if_seq. forward_if.
  2: { change Int.one with (Int.repr 1) in bit;match goal with H:_ |- _=>rewrite bit in H;discriminate end. }
  forward. forward. forward. unfold parity_fields,bump;rewrite upd_Znth_Zlength by lia.
  entailer!. rewrite upd_Znth_map;apply derives_refl.
Qed.
