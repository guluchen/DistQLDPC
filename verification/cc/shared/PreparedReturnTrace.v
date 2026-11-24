(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.floyd.reassoc_seq VerifDetected PreparedSeedDispatch
 PreparedSampling ClightSelect PreparedCandidateArena VerifChildVisit.
Require flag_level_ast.
Import flag_level_ast.
#[local] Existing Instance VerifDetected.CompSpecs.
Local Open Scope Z_scope.

Definition returning_scan (st:statement):=
 match st with
 | Ssequence check (Sreturn (Some (Etempvar r _))) =>andb (finished_test check) (Pos.eqb r _result)
 | _=>false
 end.
Definition finish_scan:statement:=ltac:(native_fragment returning_scan f_dfs).

(* Reduce a return from a selected fragment. The sample object belongs to
   the surrounding DFS stack frame and stays in the postcondition. *)
Ltac return_result_word code :=
 eapply semax_pre;[|apply semax_return];apply andp_right;[entailer!|];
 match goal with post:=_ : ret_assert |- _ => unfold post,abbreviate end;
 cbn [RA_return function_body_ret_assert liftx cast_expropt id ret_type];
 simpl liftx;go_lowerx;entailer!;
 lazymatch goal with
 | rho:environ, h:context[eval_id _result] |- _ =>
    let value:=fresh "stored" in
    assert (value:Vint (Int.repr code)=eval_id _result rho) by exact (proj1 h);
    unfold liftx;cbn;rewrite ?(eq_sym value);cbn;try solve [auto|entailer!|cancel]
 end.

(* The status local and the checked trace are passed through the actual
   tail of dfs. The sampling callback may update its own state. It
   must return the stack-allocated sample record for the return. *)
Theorem unsampled_returns_trace {Espec:OracleKind} ptr klass t1 t2 code (trace:mpred):
 Int.signed klass<0 ->
 semax (func_tycontext f_dfs prepared_vars [] [])
 (PROP() LOCAL(lvar _sample sample_type ptr;temp _result (Vint (Int.repr code)))
  SEP(sample_data ptr klass t1 t2;trace))
 finish_scan (function_body_ret_assert tint
  (PROP() LOCAL(temp ret_temp (Vint (Int.repr code))) SEP(data_at_ Tsh sample_type ptr;trace)))%assert.
Proof.
 intro below;unfold finish_scan,sample_data,sample_type;abbreviate_semax;reassoc_seq;forward.
 apply semax_if_seq;forward_if;[rep_lia|].
 return_result_word code.
Qed.

Theorem sampled_returns_trace {Espec:OracleKind} p cb owner ptr klass t1 t2 code
 (before after:val->val->mpred) (trace:mpred):
 0<=Int.signed klass -> is_pointer_or_null owner ->
 let input:=fun o a=>(sample_data a klass t1 t2 * before o a)%logic in
 let output:=fun o a=>(data_at_ Tsh sample_type a * after o a)%logic in
 let policy:=sample_policy p owner cb input output in
 semax (func_tycontext f_dfs prepared_vars [] [])
 (PROP() LOCAL(lvar _sample sample_type ptr;temp _policy p;temp _result (Vint (Int.repr code)))
  SEP(sample_data ptr klass t1 t2;before owner ptr;policy;trace))
 finish_scan (function_body_ret_assert tint
  (PROP() LOCAL(temp ret_temp (Vint (Int.repr code)))
   SEP(data_at_ Tsh sample_type ptr;after owner ptr;policy;trace)))%assert.
Proof.
 intros enabled owner_live input output policy;unfold finish_scan,policy,sample_policy,sample_data,sample_type.
 abbreviate_semax;reassoc_seq;Intros;assert_PROP (isptr ptr) by entailer!.
 forward;apply semax_if_seq;forward_if;[|rep_lia];do 2 forward;forward_call (owner,ptr).
 { unfold input,sample_data,sample_type;entailer!;cancel. }
 unfold output,sample_type;Intros;return_result_word code.
 unfold input,output,sample_type,sample_data;apply andp_right;[apply TT_right|].
 apply andp_right;[apply prop_right;repeat split;congruence|cancel;apply derives_refl].
Qed.

(* Each call gives back the rows at and below its own depth. Restoring
   this slice forgets writes to scratch storage while retaining the
   caller's separate heap, including the trace and its checked length. *)
Theorem return_releases_candidate_rows {Espec:OracleKind} ptr klass t1 t2 code
 base stride levels depth xs (trace:mpred):
 Int.signed klass<0 -> 0<=depth<levels -> 0<=stride -> Zlength xs<=stride ->
 field_compatible0 (tarray tuint ((levels-depth)*stride)) [ArraySubsc stride] (row_pointer base stride depth) ->
 let row:=row_pointer base stride depth in let tail:=remaining_arena base stride levels (depth+1) in
 semax (func_tycontext f_dfs prepared_vars [] [])
 (PROP() LOCAL(lvar _sample sample_type ptr;temp _result (Vint (Int.repr code)))
  SEP(sample_data ptr klass t1 t2;trace;child_array row xs;spare_words row stride xs;tail))
 finish_scan (function_body_ret_assert tint
  (PROP() LOCAL(temp ret_temp (Vint (Int.repr code)))
   SEP(data_at_ Tsh sample_type ptr;trace * remaining_arena base stride levels depth)))%assert.
Proof.
 intros unused valid step fits compatible row tail.
 eapply semax_pre;[|exact (@unsampled_returns_trace Espec ptr klass t1 t2 code
   (trace * remaining_arena base stride levels depth)%logic unused)].
 entailer!;exact (@release_after_descendants base stride levels depth xs valid step fits compatible).
Qed.
