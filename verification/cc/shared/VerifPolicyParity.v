(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.floyd.reassoc_seq.
Require Import level_ast VerifDetected VerifClosedPrefix.

Require Import VerifFlipBody.
Notation policy_t := policy_type.
#[local] Hint Resolve owner_valid : valid_pointer.
Definition parity_fields s b policy w odd (budget:list int64) nodes cuts : mpred :=
  (field_at Tsh level_type [StructField _w] (Vint (Int.repr w)) s *
   field_at Tsh level_type [StructField _nodd] (Vint (Int.repr odd)) s *
   field_at Tsh level_type [StructField _nodes] (Vlong nodes) s *
   field_at Tsh level_type [StructField _by_budget] b s *
   data_at Tsh (tarray tulong (Zlength budget)) (map Vlong budget) b *
   field_at Tsh level_type [StructField _poll] nullval s *
   field_at Tsh level_type [StructField _parprune] (Vlong cuts) s *
   field_at_ Tsh policy_t [StructField _owner] policy *
   field_at Tsh policy_t [StructField _parity] (Vint Int.one) policy)%logic.

Lemma sub_word a b : Int.sub (Int.repr a) (Int.repr b)=Int.repr (a-b).
Proof.
  unfold Int.sub;apply Int.eqm_samerepr;apply Int.eqm_sub;
    apply Int.eqm_sym;apply Int.eqm_unsigned_repr.
Qed.

Lemma low_bit_set z : Z.testbit z 0=true -> Int.and (Int.repr z) Int.one=Int.one.
Proof.
  intro low;apply Int.same_bits_eq;intros i bound.
  rewrite Int.bits_and by assumption;rewrite Int.bits_one.
  destruct (zeq i 0);[subst i; rewrite Int.testbit_repr by assumption; rewrite low|apply Bool.andb_false_r].
  reflexivity.
Qed.

Definition policy_parity_spec : ident * funspec :=
 DECLARE _dfs
 WITH s:val, b:val, policy:val, w:Z, depth:Z, odd:Z, budgets:list int64,
   nodes:int64, cuts:int64
 PRE [tptr level_type, tptr policy_t, tint]
  PROP(1<=depth<w; w<=Int.max_signed; 0<odd<=Int.max_signed;
       w-depth<Zlength budgets; Z.testbit (w-depth-odd) 0=true)
  PARAMS(s; policy; Vint (Int.repr depth))
  SEP(parity_fields s b policy w odd budgets nodes cuts)
 POST [tint]
  PROP() RETURN(Vint Int.zero)
  SEP(parity_fields s b policy w odd (bump budgets (w-depth))
       (Int64.add nodes Int64.one) (Int64.add cuts Int64.one)).

Definition PolicyParityGprog : funspecs := ltac:(with_library prog [policy_parity_spec]).

Theorem body_policy_parity : semax_body Vprog PolicyParityGprog f_dfs policy_parity_spec.
Proof.
  start_function. unfold parity_fields. Intros.
  do 9 (forward; try solve [entailer!]).
  apply semax_if_seq. forward_if;[contradiction|forward].
  apply semax_if_seq. forward_if;[contradiction|forward].
  apply semax_if_seq. forward_if;[contradiction|].
  forward. apply semax_if_seq. forward_if;[rep_lia|].
  assert (nonzero:Int.repr odd<>Int.zero).
  { intro bad; apply (f_equal Int.unsigned) in bad. rewrite Int.unsigned_repr in bad by rep_lia.
    change (odd=0) in bad;lia. }
  forward. apply semax_if_seq. forward_if;[congruence|]. reassoc_seq.
  assert_PROP (isptr policy) as policy_ok by entailer!.
  apply semax_if_seq. forward_if;[|subst policy;contradiction]. forward. forward.
  apply semax_if_seq. forward_if;[|solve [discriminate|congruence]].
  forward. forward. forward;try solve [entailer!].
  assert (bit : Int.and (Int.sub (Int.sub (Int.repr w) (Int.repr depth)) (Int.repr odd)) Int.one
                = Int.one) by (rewrite !sub_word;apply low_bit_set;assumption).
  apply semax_if_seq. forward_if.
  2: { change Int.one with (Int.repr 1) in bit;rewrite bit in H11;discriminate. }
  forward. forward. forward. unfold parity_fields,bump;rewrite upd_Znth_Zlength by lia.
  entailer!. rewrite upd_Znth_map;apply derives_refl.
Qed.
