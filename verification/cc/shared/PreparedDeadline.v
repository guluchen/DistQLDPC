(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.floyd.reassoc_seq VerifDetected PreparedSeedDispatch.
Require flag_level_ast.
Import flag_level_ast.
#[local] Existing Instance VerifDetected.CompSpecs.
Local Open Scope Z_scope.

Definition evaluate_poll:=match fn_body f_dfs with
| Ssequence _ (Ssequence _ (Ssequence (Ssequence bits (Sifthenelse (Etempvar flag _) (Sreturn _) Sskip)) _))=>
 if Pos.eqb flag _t'2 then bits else Sskip
| _=>Sskip end.
Definition poll_loc s bits:=[temp _s s;temp _options (Vint bits)].
Definition polled_loc s bits (expired:bool):=temp _t'2 (Vint (if expired then Int.one else Int.zero))::poll_loc s bits.
Definition poll_counters s nodes mask:=
 (field_at Tsh level_type [StructField _nodes] (Vlong nodes) s *
  field_at Tsh level_type [StructField _poll_mask] (Vlong mask) s)%logic.
Definition poll_callback (before:val->mpred) (after:bool->val->mpred):funspec:=
 WITH ctx:val PRE [tptr tvoid] PROP(is_pointer_or_null ctx) PARAMS(ctx) SEP(before ctx)
 POST [tbool] EX expired:bool, PROP() RETURN(Vint (if expired then Int.one else Int.zero)) SEP(after expired ctx).
Definition polling s cb ctx before after:=
 (field_at Tsh level_type [StructField _poll] cb s *
  field_at Tsh level_type [StructField _poll_ctx] ctx s * func_ptr' (poll_callback before after) cb)%logic.

Theorem poll_disabled {Espec:OracleKind} s bits (frame:mpred):
 Int.and bits (Int.repr 2)=Int.zero ->
 semax (func_tycontext f_dfs prepared_vars [] [])
 (PROPx [] (LOCALx (poll_loc s bits) (SEPx [frame]))) evaluate_poll
 (normal_ret_assert (PROPx [] (LOCALx (polled_loc s bits false) (SEPx [frame])))).
Proof.
 intros off;unfold evaluate_poll,polled_loc,poll_loc;abbreviate_semax;reassoc_seq.
 apply semax_if_seq;forward_if;[congruence|forward];forward_if;[solve [contradiction|congruence|discriminate]|forward];entailer!.
Qed.

Theorem poll_between_checks {Espec:OracleKind} s bits nodes mask (frame:mpred):
 Int.and bits (Int.repr 2)<>Int.zero -> Int64.and nodes mask<>Int64.zero ->
 semax (func_tycontext f_dfs prepared_vars [] [])
 (PROPx [] (LOCALx (poll_loc s bits) (SEPx [poll_counters s nodes mask;frame]))) evaluate_poll
 (normal_ret_assert (PROPx [] (LOCALx (polled_loc s bits false) (SEPx [poll_counters s nodes mask;frame])))).
Proof.
 intros on skip;unfold evaluate_poll,polled_loc,poll_loc,poll_counters;abbreviate_semax;reassoc_seq;Intros.
 apply semax_if_seq;forward_if;[|congruence];do 3 forward.
 forward_if;[|forward;entailer!].
 destruct (Int64.eq (Int64.and nodes mask) Int64.zero) eqn:E;
 [apply Int64.same_if_eq in E;congruence|simpl in *;congruence].
Qed.

(* The deadline callback chooses its result at this node. No fixed outcome
   is shared between consecutive visits, including visits to the same qubit. *)
Theorem poll_due {Espec:OracleKind} s bits nodes mask cb ctx before after:
 Int.and bits (Int.repr 2)<>Int.zero -> Int64.and nodes mask=Int64.zero -> is_pointer_or_null ctx ->
 semax (func_tycontext f_dfs prepared_vars [] [])
 (PROPx [] (LOCALx (poll_loc s bits) (SEPx [poll_counters s nodes mask;polling s cb ctx before after;before ctx])))
 evaluate_poll (normal_ret_assert (EX expired:bool,PROPx [] (LOCALx (polled_loc s bits expired)
  (SEPx [poll_counters s nodes mask;polling s cb ctx before after;after expired ctx])))).
Proof.
 intros on due context;unfold evaluate_poll,polled_loc,poll_loc,poll_counters,polling;abbreviate_semax;reassoc_seq;Intros.
 apply semax_if_seq;forward_if;[|congruence];do 3 forward;rewrite due.
 forward_if;[|discriminate];do 2 forward;forward_call ctx.
 Intros expired;destruct expired;forward;[Exists true|Exists false];entailer!.
Qed.
