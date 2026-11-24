(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.floyd.reassoc_seq VerifDetected PreparedSeedDispatch ClightSelect.
Require flag_level_ast.
Import flag_level_ast.
#[local] Existing Instance VerifDetected.CompSpecs.
Local Open Scope Z_scope.

Definition sample_type:=Tstruct _cc_erasure_sample noattr.
Definition sample_prefix (s:statement):=match s with
 | Ssequence (Sassign (Efield (Evar obj _) fld _) _) _=>andb (Pos.eqb obj _sample) (Pos.eqb fld _class_id)
 | _=>false end.
Definition init_sample:statement:=ltac:(let whole:=constr:(ltac:(native_fragment sample_prefix f_dfs):statement) in
 let xs:=eval cbv beta iota zeta in whole in lazymatch xs with Ssequence ?a (Ssequence ?b (Ssequence ?c _))=>exact (Ssequence a (Ssequence b c)) end).
Definition sample_data ptr klass t1 t2:=data_at Tsh sample_type (Vint klass,(Vfloat t1,Vfloat t2)) ptr.
Definition finished_test (s:statement):= match s with
 | Ssequence (Sset _ (Efield (Evar obj _) fld _)) (Sifthenelse _ _ Sskip)=>andb (Pos.eqb obj _sample) (Pos.eqb fld _class_id)
 | _=>false end.
Definition notify_sample:statement:=ltac:(native_fragment finished_test f_dfs).

Theorem initialize_actual_sample {Espec:OracleKind} ptr (frame:mpred):
 semax (func_tycontext f_dfs prepared_vars [] [])
 (PROP() LOCAL(lvar _sample sample_type ptr) SEP(data_at_ Tsh sample_type ptr;frame)) init_sample
 (normal_ret_assert (PROP() LOCAL(lvar _sample sample_type ptr) SEP(sample_data ptr (Int.repr (-1)) Float.zero Float.zero;frame))).
Proof.
 unfold init_sample,sample_data,sample_type;abbreviate_semax;do 3 forward;entailer!.
Qed.

Theorem skip_unrecorded_sample {Espec:OracleKind} ptr klass t1 t2 (frame:mpred):
 Int.signed klass<0 ->
 semax (func_tycontext f_dfs prepared_vars [] [])
 (PROP() LOCAL(lvar _sample sample_type ptr) SEP(sample_data ptr klass t1 t2;frame)) notify_sample
 (normal_ret_assert (PROP() LOCAL(lvar _sample sample_type ptr) SEP(sample_data ptr klass t1 t2;frame))).
Proof.
 intro unused;unfold notify_sample,sample_data,sample_type;abbreviate_semax;forward;forward_if;[rep_lia|forward;entailer!].
Qed.

Definition sample_completed (before after:val->val->mpred):funspec:=WITH owner:val,ptr:val
 PRE [tptr tvoid,tptr sample_type] PROP(is_pointer_or_null owner;isptr ptr) PARAMS(owner;ptr) SEP(before owner ptr)
 POST [tvoid] PROP() RETURN() SEP(after owner ptr).
Definition sample_policy p owner cb before after:=
 (field_at Tsh (Tstruct _cc_level_policy noattr) [StructField _owner] owner p *
  field_at Tsh (Tstruct _cc_level_policy noattr) [StructField _sample_done] cb p *
  func_ptr' (sample_completed before after) cb)%logic.

(* The callback borrows the record itself, including both floating point
   fields. The updated measurement state is returned to the caller. *)
Theorem finish_recorded_sample {Espec:OracleKind} p owner cb ptr klass t1 t2 before after (frame:mpred):
 0<=Int.signed klass -> is_pointer_or_null owner ->
 let input:=fun o a=> (sample_data a klass t1 t2 * before o a)%logic in
 semax (func_tycontext f_dfs prepared_vars [] [])
 (PROP() LOCAL(lvar _sample sample_type ptr;temp _policy p)
  SEP(sample_data ptr klass t1 t2;before owner ptr;sample_policy p owner cb input after;frame)) notify_sample
 (normal_ret_assert (PROP() LOCAL(lvar _sample sample_type ptr;temp _policy p)
  SEP(after owner ptr;sample_policy p owner cb input after;frame))).
Proof.
 intros enabled valid input;unfold notify_sample,sample_policy,sample_data,sample_type;abbreviate_semax;Intros.
 assert_PROP (isptr ptr) by entailer!.
 forward;forward_if;[|rep_lia];do 2 forward;forward_call (owner,ptr);try solve [entailer!].
 { instantiate (Frame:=[sample_policy p owner cb input after;frame]);unfold Frame,sample_policy,input,sample_data,sample_type;cbn [fold_right_sepcon];cancel. }
 unfold sample_policy,input,sample_data,sample_type;entailer!;cancel.
Qed.
