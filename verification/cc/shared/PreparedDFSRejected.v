(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.floyd.reassoc_seq VerifDetected PreparedSeedDispatch
 VerifClosedPrefix VerifPolicyParity PreparedSampling PreparedChoiceCall PreparedCandidateSlice PreparedEmptyLoops.
Require flag_level_ast.
Import flag_level_ast.
#[local] Existing Instance VerifDetected.CompSpecs.
Local Open Scope Z_scope.

Definition chosen_empty depth odd (before after:val->mpred):funspec:=
 WITH owner:val,ptr:val PRE [tptr tvoid,tint,tint,tptr sample_type]
 PROP(is_pointer_or_null owner;isptr ptr)
 PARAMS(owner;Vint (Int.repr depth);Vint (Int.repr odd);ptr)
 SEP(sample_data ptr (Int.repr (-1)) Float.zero Float.zero;before owner)
 POST [tint] PROP() RETURN(Vint Int.zero)
 SEP(sample_data ptr (Int.repr (-1)) Float.zero Float.zero;after owner).

Definition visit_fields s bp w odd nodes (budget:list int64):=
 (field_at Tsh level_type [StructField _nodes] (Vlong nodes) s *
  field_at Tsh level_type [StructField _by_budget] bp s *
  data_at Tsh (tarray tulong (Zlength budget)) (map Vlong budget) bp *
  field_at Tsh level_type [StructField _w] (Vint (Int.repr w)) s *
  field_at Tsh level_type [StructField _nodd] (Vint (Int.repr odd)) s)%logic.

Definition pruned_dfs before after:ident*funspec:=
 DECLARE _dfs WITH s:val,p:val,bp:val,base:val,owner:val,cb:val,w:Z,depth:Z,odd:Z,stride:Z,
     nodes:int64,budgets:list int64,bits:int
 PRE [tptr level_type,tptr (Tstruct _cc_level_policy noattr),tint,tuint]
 PROP(1<=depth<=w-2;w<=Int.max_signed;0<odd<=Int.max_signed;0<=stride<=Int.max_signed;
      w-depth<Zlength budgets;is_pointer_or_null p;is_pointer_or_null owner;isptr base;
      Int.and bits Int.one<>Int.zero;Int.and bits (Int.repr 2)=Int.zero;Int.and bits (Int.repr 8)=Int.zero)
 PARAMS(s;p;Vint (Int.repr depth);Vint bits)
 SEP(visit_fields s bp w odd nodes budgets;candidate_fields s base stride;
   chooser_policy p owner cb (chosen_empty depth odd before after);before owner)
 POST [tint] PROP() RETURN(Vint Int.zero)
 SEP(visit_fields s bp w odd (Int64.add nodes Int64.one) (bump budgets (w-depth));
     candidate_fields s base stride;chooser_policy p owner cb (chosen_empty depth odd before after);after owner).

(* This class of calls permits an arbitrary depth and level. A rejected
   packing or charge branch never reads even the first candidate and
   executes neither the recursive sibling body nor the two-move leaf. *)
Theorem body_dfs_rejected_choice before after:
 semax_body prepared_vars [] f_dfs (pruned_dfs before after).
Proof.
 start_function;unfold visit_fields;Intros;do 8 (forward;try solve [entailer!]);reassoc_seq.
 apply semax_if_seq;forward_if;[solve [congruence|contradiction]|forward].
 apply semax_if_seq;forward_if;[solve [congruence|contradiction]|forward].
 apply semax_if_seq;forward_if;[contradiction|].
 forward;apply semax_if_seq;forward_if;[rep_lia|].
 assert (nonzero:Int.repr odd<>Int.zero).
 { intro bad;apply (f_equal Int.unsigned) in bad;rewrite Int.unsigned_repr in bad by rep_lia.
   change (odd=0) in bad;lia. }
 forward;apply semax_if_seq;forward_if;[congruence|];reassoc_seq.
 apply semax_if_seq;forward_if;[solve [congruence|contradiction]|forward].
 apply semax_if_seq;forward_if;[contradiction|].
 assert (sub:Int.sub (Int.repr w) (Int.repr 1)=Int.repr (w-1)) by
   (unfold Int.sub;rewrite !Int.unsigned_repr by rep_lia;reflexivity).
 forward;apply semax_if_seq;forward_if.
 { match goal with same:Int.repr depth=Int.sub _ _ |- _=>rewrite sub in same;
     apply (f_equal Int.signed) in same;rewrite !Int.signed_repr in same by rep_lia;lia end. }
 unfold candidate_fields,chooser_policy;Intros;do 6 forward.
 match goal with H:Int.and bits Int.one<>Int.zero |- _=>change Int.one with (Int.repr 1) in H end.
 apply semax_if_seq;forward_if;[|congruence];do 3 forward.
 assert_PROP (isptr v_sample) by entailer!.
 forward_call (owner,v_sample);try solve [assumption|unfold sample_data,sample_type;entailer!;cancel].
 do 2 forward;reassoc_seq.
 apply semax_if_seq;forward_if;
   [do 2 (forward;try solve [rep_lia|entailer!]);forward|forward;forward];do 2 forward.
 all: discard_zero_loop;discard_zero_loop;unfold sample_data,sample_type;forward.
 all: apply semax_if_seq;forward_if;[rep_lia|forward].
 all: unfold visit_fields,candidate_fields,chooser_policy,bump;rewrite ?upd_Znth_map,?upd_Znth_Zlength by lia;
      entailer!;try cancel;try apply derives_refl.
Qed.
