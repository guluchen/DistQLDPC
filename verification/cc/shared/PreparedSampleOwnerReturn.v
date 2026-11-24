(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VerifDetected VerifChildVisit EnabledCall VerifOverlapDispatch
 PreparedSeedDispatch PreparedOwnerFields PreparedSampling PreparedReturnTrace OverlapView OverlapSharedBlocks.
Require flag_level_ast.
Import flag_level_ast.
#[local] Existing Instance VerifDetected.CompSpecs.
Local Open Scope Z_scope.

Definition sample_field c cb input output:=let p:=nested_policy (nested c) in
 function_field (field_at Tsh (Tstruct _cc_level_policy noattr) [StructField _sample_done] cb p)
   cb (sample_completed input output).
Definition dormant_overlap c s cp w path st:=
 (level_links s cp (blockp (conn c)) w path * cols c st * saved_overlap c)%logic.

Lemma lend_owner_once c cb input output s cp w path st:
 (enabled_memory c s cp w path st * sample_field c cb input output =
    sample_policy (nested_policy (nested c)) (callback_owner c) cb input output *
    dormant_overlap c s cp w path st)%logic.
Proof.
 unfold enabled_memory,dormant_overlap,sample_field.
 rewrite sepcon_assoc, (borrow_sample_owner c cb input output).
 apply pred_ext;cancel.
Qed.

(* The overlap and sampling calls share the single writable owner
   field. The return restores the exact overlap view and C trace it
   borrowed. The callback may change its own statistics. *)
Theorem recorded_returns_restored_state {Espec:OracleKind} c cb ptr klass t1 t2 code s cp w path st
 (before after:val->val->mpred) (trace:mpred):
 0<=Int.signed klass -> is_pointer_or_null (callback_owner c) ->
 let owner:=callback_owner c in let p:=nested_policy (nested c) in
 let input:=fun o a=>(sample_data a klass t1 t2 * before o a)%logic in
 let output:=fun o a=>(data_at_ Tsh sample_type a * after o a)%logic in
 let fn:=sample_field c cb input output in
 semax (func_tycontext f_dfs prepared_vars [] [])
 (PROP() LOCAL(lvar _sample sample_type ptr;temp _policy p;temp _result (Vint (Int.repr code)))
  SEP(sample_data ptr klass t1 t2;before owner ptr;enabled_memory c s cp w path st * fn;trace))
 finish_scan (function_body_ret_assert tint
   (PROP() LOCAL(temp ret_temp (Vint (Int.repr code)))
    SEP(data_at_ Tsh sample_type ptr;after owner ptr;enabled_memory c s cp w path st * fn;trace)))%assert.
Proof.
 intros active live owner p input output fn;unfold fn;rewrite !lend_owner_once.
 set (rest:=(dormant_overlap c s cp w path st * trace)%logic).
 set (policy:=sample_policy p owner cb input output).
 assert (grouping: (policy * dormant_overlap c s cp w path st * trace)%logic=(policy * rest)%logic)
   by apply sepcon_assoc.
 unfold SEPx;cbn [fold_right_sepcon];rewrite !sepcon_emp.
 fold p owner policy;rewrite !grouping.
 pose proof (@sampled_returns_trace Espec p cb owner ptr klass t1 t2 code before after rest active live) as call.
 fold input output policy in call;unfold SEPx in call;cbn [fold_right_sepcon] in call;rewrite !sepcon_emp in call.
 exact call.
Qed.
