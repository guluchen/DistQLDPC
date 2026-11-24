(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.floyd.reassoc_seq VerifDetected VerifClosedPrefix
 VerifPolicyParity PreparedSeedDispatch PreparedSampling PreparedInteriorEntry PreparedDFSRejected.
Require flag_level_ast.
Import flag_level_ast.
#[local] Existing Instance VerifDetected.CompSpecs.
Local Open Scope Z_scope.

(* Stop immediately before the native candidate/sampling frame is built. *)
Fixpoint through_guards (s:statement):statement:=
 match s with
 | Ssequence a b=>if sample_prefix b then a else Ssequence a (through_guards b)
 | _=>Sskip end.
Definition interior_guards:statement:=ltac:(let t:=eval cbv beta iota zeta delta
 [through_guards sample_prefix andb Pos.eqb fn_body f_dfs _sample _class_id] in (through_guards (fn_body f_dfs)) in exact t).

Lemma guards_then_search {Espec:OracleKind} D P M R:
 semax D P interior_guards (normal_ret_assert M) -> semax D M nonterminal_search R ->
 semax D P (fn_body f_dfs) R.
Proof.
 intros guards search;apply (semax_unfold_seq (Ssequence interior_guards nonterminal_search) (fn_body f_dfs) eq_refl).
 eapply semax_seq';eassumption.
Qed.

Lemma low_bit_clear z:Z.testbit z 0=false -> Int.and (Int.repr z) Int.one=Int.zero.
Proof.
 intro low;apply Int.same_bits_eq;intros i bound;rewrite Int.bits_and by assumption.
 rewrite Int.bits_one,Int.bits_zero;destruct (zeq i 0).
 - subst i;rewrite Int.testbit_repr by assumption;rewrite low;reflexivity.
 - apply Bool.andb_false_r.
Qed.

Definition guard_loc s p depth bits ptr:=[temp _s s;temp _policy p;temp _size (Vint (Int.repr depth));
  temp _options (Vint bits);lvar _sample sample_type ptr].
Definition mask_field s mask:=field_at Tsh level_type [StructField _poll_mask] (Vlong mask) s.

(* A live poll flag may skip its callback on this visit. A live parity
   flag may pass this node. The node counter tested is the incremented
   64-bit value. Neither option has to be disabled on the search. *)
Theorem enter_interior_on_live_flags {Espec:OracleKind} s p bp w depth odd nodes budgets bits mask ptr (frame:mpred):
 1<=depth<=w-2 -> w<=Int.max_signed -> 0<odd<=Int.max_signed -> w-depth<Zlength budgets ->
 (Int.and bits (Int.repr 2)<>Int.zero -> Int64.and (Int64.add nodes Int64.one) mask<>Int64.zero) ->
 (Int.and bits (Int.repr 8)<>Int.zero -> Z.testbit (w-depth-odd) 0=false) ->
 let local_:=guard_loc s p depth bits ptr in
 semax (func_tycontext f_dfs prepared_vars [] [])
 (PROPx [] (LOCALx local_ (SEPx [visit_fields s bp w odd nodes budgets;mask_field s mask;frame])))
 interior_guards (normal_ret_assert (PROPx [] (LOCALx local_ (SEPx
   [visit_fields s bp w odd (Int64.add nodes Int64.one) (bump budgets (w-depth));mask_field s mask;frame])))).
Proof.
 intros range bound live room between even local_;unfold local_,guard_loc,interior_guards,visit_fields,mask_field;
 abbreviate_semax;Intros;do 8 (forward;try solve [entailer!]);reassoc_seq.
 apply semax_if_seq;forward_if.
 1: (do 3 forward;apply semax_if_seq;forward_if).
 1: (exfalso;apply (between H);exact H0).
 all: forward.
 2: (apply semax_if_seq;forward_if;[solve [contradiction|congruence]|forward]).
 all: apply semax_if_seq;forward_if;[contradiction|].
 all: forward;apply semax_if_seq;forward_if;[rep_lia|].
 all: assert (nonzero:Int.repr odd<>Int.zero) by
  (intro bad;apply (f_equal Int.unsigned) in bad;rewrite Int.unsigned_repr in bad by rep_lia;change (odd=0) in bad;lia).
 all: forward;apply semax_if_seq;forward_if;[congruence|];reassoc_seq.
 all: apply semax_if_seq;forward_if.
 all: lazymatch goal with
 | on:Int.and ?flags (Int.repr 8)<>Int.zero |- _=>
   do 3 (forward;try solve [entailer!]);
   assert (low:Int.and (Int.sub (Int.sub (Int.repr w) (Int.repr depth)) (Int.repr odd)) (Int.repr 1)=Int.zero)
     by (rewrite !sub_word;apply low_bit_clear;apply even;exact on);
   apply semax_if_seq;forward_if;[solve [congruence|contradiction|
     match goal with h:_<>Int.zero |- _=>apply h;exact low end|
     match goal with h:(if Int.eq _ _ then _ else _)<>Int.zero |- _=>
       exfalso;apply h;rewrite low;reflexivity end]|]
 | _=>forward;apply semax_if_seq;forward_if;[contradiction|]
 end.
 all: forward;forward_if.
 all: try solve [rep_lia|match goal with same:Int.repr ?lev=Int.sub _ _ |- _=>rewrite sub_word in same;
   apply (f_equal Int.signed) in same;rewrite !Int.signed_repr in same by rep_lia;lia end].
 all: forward;unfold bump;rewrite ?upd_Znth_map,?upd_Znth_Zlength by lia;entailer!;try cancel;apply derives_refl.
Qed.
