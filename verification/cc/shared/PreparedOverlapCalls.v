(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VerifDetected PreparedSeedDispatch ClightSelect
 OverlapColumnState OverlapView VerifOverlapDispatch DynamicOverlapCallback SeedBlockView.
Require flag_level_ast.
Import flag_level_ast.
#[local] Existing Instance VerifDetected.CompSpecs.
Local Open Scope Z_scope.
Definition overlap_arm (enter:bool) (s:statement):bool :=
 match s with
 | Sifthenelse (Ebinop Oand (Etempvar id _) (Econst_int mask _) _)
    (Ssequence (Sset _ (Efield _ field _)) (Ssequence _ (Scall None _ [_;_;Econst_int arg _]))) Sskip =>
     Pos.eqb id _options && Pos.eqb field _overlap && Int.eq mask (Int.repr 16) &&
     Int.eq arg (if enter then Int.one else Int.zero)
 | _=>false end.
Definition overlap_in:statement:=ltac:(native_fragment (overlap_arm true) f_cc_run_prepared_level).
Definition overlap_out:statement:=ltac:(native_fragment (overlap_arm false) f_cc_run_prepared_level).
Definition overlap_call_resources p owner fp a g st:=
 (callback_fields p owner fp * func_ptr' (dynamic_overlap owner a) fp * view_mem owner a g st)%logic.

Theorem prepared_overlap_enabled {Espec:OracleKind} p owner fp a g st q bits (enter:bool):
 is_pointer_or_null owner -> Int.and bits (Int.repr 16)<>Int.zero -> admissible g q enter st ->
 semax (func_tycontext f_cc_run_prepared_level prepared_vars [] [])
 (PROPx [] (LOCALx (prepared_loc p q bits) (SEPx [overlap_call_resources p owner fp a g st])))
 (if enter then overlap_in else overlap_out)
 (normal_ret_assert (PROPx [] (LOCALx (prepared_loc p q bits)
    (SEPx [overlap_call_resources p owner fp a g (after_column g q enter st)])))).
Proof.
 intros owner_ok enabled valid;destruct enter;unfold overlap_in,overlap_out,prepared_loc,overlap_call_resources,callback_fields;
 abbreviate_semax;Intros;forward_if;try solve [congruence|contradiction].
 all:do 2 (forward;try solve [entailer!]).
 all:first [forward_call (g,st,q,true);solve [entailer!|auto] | forward_call (g,st,q,false);solve [entailer!|auto]].
Qed.
Theorem prepared_overlap_disabled {Espec:OracleKind} p q bits (enter:bool) (storage:mpred):
 Int.and bits (Int.repr 16)=Int.zero ->
 semax (func_tycontext f_cc_run_prepared_level prepared_vars [] [])
 (PROPx [] (LOCALx (prepared_loc p q bits) (SEPx [storage])))
 (if enter then overlap_in else overlap_out)
 (normal_ret_assert (PROPx [] (LOCALx (prepared_loc p q bits) (SEPx [storage])))).
Proof.
 intro disabled;destruct enter;unfold overlap_in,overlap_out,prepared_loc;abbreviate_semax;Intros.
 all:forward_if;try solve [congruence|contradiction];forward;entailer!.
Qed.

Definition block_arm (s:statement):bool:=
 match s with Sifthenelse (Ebinop Oand (Etempvar id _) (Econst_int mask _) _)
   (Ssequence (Sset _ (Efield _ field _)) (Ssequence _ (Scall None _ [_;_]))) Sskip =>
   Pos.eqb id _options && Pos.eqb field _block_done && Int.eq mask (Int.repr 64)
 | _=>false end.
Definition notify_exhaustion:statement:=ltac:(native_fragment block_arm f_cc_run_prepared_level).
Definition done_loc p i bits:=[temp _policy p;temp _i (Vint (Int.repr i));temp _options (Vint bits)].
Definition done_fields p owner fp:=
 (field_at Tsh (Tstruct _cc_level_policy noattr) [StructField _owner] owner p *
  field_at Tsh (Tstruct _cc_level_policy noattr) [StructField _block_done] fp p *
  func_ptr' (snd exhausted_spec) fp)%logic.
Theorem prepared_block_enabled {Espec:OracleKind} (p owner fp:val) a pa g b limits st i bits:
 is_pointer_or_null owner -> Int.and bits (Int.repr 64)<>Int.zero -> block_safe g b limits i st ->
 semax (func_tycontext f_cc_run_prepared_level prepared_vars [] [])
 (PROPx [] (LOCALx (done_loc p i bits) (SEPx [done_fields p owner fp;exhausted_at owner a pa g b limits st])))
 notify_exhaustion
 (normal_ret_assert (PROPx [] (LOCALx (done_loc p i bits) (SEPx [done_fields p owner fp;exhausted_at owner a pa g b limits
   (crossed_block g b limits st (block_at b i) (block_at b (i+1)))])))).
Proof.
 intros own enabled valid;unfold notify_exhaustion,done_loc,done_fields;abbreviate_semax;Intros.
 forward_if;try solve [congruence|contradiction];do 2 (forward;try solve [entailer!]).
 forward_call (owner,a,pa,g,b,limits,i,st);entailer!.
Qed.
Theorem prepared_block_disabled {Espec:OracleKind} p i bits (storage:mpred):
 Int.and bits (Int.repr 64)=Int.zero ->
 semax (func_tycontext f_cc_run_prepared_level prepared_vars [] [])
 (PROPx [] (LOCALx (done_loc p i bits) (SEPx [storage]))) notify_exhaustion
 (normal_ret_assert (PROPx [] (LOCALx (done_loc p i bits) (SEPx [storage])))).
Proof.
 intro disabled;unfold notify_exhaustion,done_loc;abbreviate_semax;Intros.
 forward_if;try solve [congruence|contradiction];forward;entailer!.
Qed.
