(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.floyd.reassoc_seq VerifDetected VerifChildVisit EnabledCall
 PreparedSeedDispatch PreparedSampling PreparedReturnTrace PreparedOwnerFields PreparedSampleOwnerReturn.
Require flag_level_ast.
Import flag_level_ast.
#[local] Existing Instance VerifDetected.CompSpecs.
Local Open Scope Z_scope.

(* The function installed on the level owner is fixed. The class and timing data
   vary at each call, including recursive calls with the same owner. *)
Definition sample_input_for (valid:Z->Prop) (stats:val->mpred) o a:mpred:=
 EX k:int,EX t1:float,EX t2:float,
  !!(0<=Int.signed k /\ valid (Int.signed k)) && (sample_data a k t1 t2 * stats o).
Definition sample_output_for (stats:val->mpred) o a:mpred:=
 (data_at_ Tsh sample_type a * stats o)%logic.

Theorem notify_current_sample {Espec:OracleKind} p cb owner ptr klass t1 t2 code
 (valid:Z->Prop) (stats:val->mpred) (trace:mpred):
 0<=Int.signed klass -> valid (Int.signed klass) -> is_pointer_or_null owner ->
 let pol:=sample_policy p owner cb (sample_input_for valid stats) (sample_output_for stats) in
 semax (func_tycontext f_dfs prepared_vars [] [])
 (PROP() LOCAL(lvar _sample sample_type ptr;temp _policy p;temp _result (Vint (Int.repr code)))
  SEP(sample_data ptr klass t1 t2;stats owner;pol;trace))
 finish_scan (function_body_ret_assert tint
  (PROP() LOCAL(temp ret_temp (Vint (Int.repr code)))
   SEP(data_at_ Tsh sample_type ptr;stats owner;pol;trace)))%assert.
Proof.
 intros active measured own pol;unfold finish_scan,pol,sample_policy,sample_data,sample_type;abbreviate_semax;reassoc_seq;Intros.
 assert_PROP (isptr ptr) by entailer!.
 forward;apply semax_if_seq;forward_if;[|rep_lia];do 2 forward;forward_call (owner,ptr).
 { unfold sample_input_for;Exists klass t1 t2;unfold sample_data,sample_type;entailer!;cancel. }
 unfold sample_output_for,sample_type;Intros;return_result_word code.
 unfold sample_input_for,sample_output_for,sample_type;apply andp_right;[apply TT_right|].
 apply andp_right;[apply prop_right;repeat split;congruence|cancel;apply derives_refl].
Qed.

Theorem owner_returns_from_current_sample {Espec:OracleKind} c cb ptr klass t1 t2 code s cp w path st
 (valid:Z->Prop) (stats:val->mpred) (trace:mpred):
 0<=Int.signed klass -> valid (Int.signed klass) -> is_pointer_or_null (callback_owner c) ->
 let owner:=callback_owner c in let p:=nested_policy (nested c) in
 let fn:=sample_field c cb (sample_input_for valid stats) (sample_output_for stats) in
 semax (func_tycontext f_dfs prepared_vars [] [])
 (PROP() LOCAL(lvar _sample sample_type ptr;temp _policy p;temp _result (Vint (Int.repr code)))
  SEP(sample_data ptr klass t1 t2;stats owner;enabled_memory c s cp w path st * fn;trace))
 finish_scan (function_body_ret_assert tint
   (PROP() LOCAL(temp ret_temp (Vint (Int.repr code)))
    SEP(data_at_ Tsh sample_type ptr;stats owner;enabled_memory c s cp w path st * fn;trace)))%assert.
Proof.
 intros active measured live owner p fn;unfold fn;rewrite !lend_owner_once.
 set (rest:=(dormant_overlap c s cp w path st * trace)%logic).
 set (policy:=sample_policy p owner cb (sample_input_for valid stats) (sample_output_for stats)).
 assert (grouping:(policy * dormant_overlap c s cp w path st * trace)%logic=(policy * rest)%logic)
   by apply sepcon_assoc.
 unfold SEPx;cbn [fold_right_sepcon];rewrite !sepcon_emp;fold p owner policy;rewrite !grouping.
 pose proof (@notify_current_sample Espec p cb owner ptr klass t1 t2 code valid stats rest active measured live) as call.
 fold policy in call;unfold SEPx in call;cbn [fold_right_sepcon] in call;rewrite !sepcon_emp in call;exact call.
Qed.
