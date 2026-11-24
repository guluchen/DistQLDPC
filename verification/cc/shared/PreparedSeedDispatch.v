(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto ClightSelect VerifDetected SeedPolicyView SeedColumnModel.
Require flag_level_ast level_ast.
Import flag_level_ast.
#[local] Existing Instance VerifDetected.CompSpecs.
Local Open Scope Z_scope.

Lemma level_layout_preserved : prog_comp_env flag_level_ast.prog=prog_comp_env level_ast.prog.
Proof. reflexivity. Qed.
Definition prepared_vars:varspecs. mk_varspecs flag_level_ast.prog. Defined.
Definition exemption_arm (enter:bool) (s:statement):bool :=
 match s with
 | Sifthenelse (Ebinop Oand (Etempvar id _) (Econst_int mask _) _)
     (Ssequence (Sset _ (Efield _ field _)) (Ssequence _ (Scall None _ [_;_;Econst_int arg _]))) Sskip =>
     Pos.eqb id _options && Pos.eqb field _seed_exemption && Int.eq mask (Int.repr 32) &&
       Int.eq arg (if enter then Int.one else Int.zero)
 | _=>false end.
Definition begin_seed:statement:=ltac:(native_fragment (exemption_arm true) f_cc_run_prepared_level).
Definition end_seed:statement:=ltac:(native_fragment (exemption_arm false) f_cc_run_prepared_level).
Definition prepared_loc p q bits := [temp _policy p;temp _q (Vint (Int.repr q));temp _options (Vint bits)].
Definition optional_seed p owner fp a pa g limits st:=
 (field_at Tsh (Tstruct _cc_level_policy noattr) [StructField _owner] owner p *
  field_at Tsh (Tstruct _cc_level_policy noattr) [StructField _seed_exemption] fp p *
  func_ptr' (snd seed_visit_spec) fp * scans_at owner pa g * moving_at owner a limits st)%logic.

(* The function address need only satisfy its call contract. No byte of the
   policy or function block is lent solely to test a pointer for non-nullness. *)
Theorem prepared_seed_enabled {Espec:OracleKind} (p owner fp:val) a pa g limits st q bits enter :
 is_pointer_or_null owner -> Int.and bits (Int.repr 32) <> Int.zero -> column_safe g limits enter q st ->
 semax (func_tycontext f_cc_run_prepared_level prepared_vars [] [])
 (PROPx [] (LOCALx (prepared_loc p q bits) (SEPx [optional_seed p owner fp a pa g limits st])))
 (if enter then begin_seed else end_seed)
 (normal_ret_assert (PROPx [] (LOCALx (prepared_loc p q bits)
  (SEPx [optional_seed p owner fp a pa g limits (prefix g limits enter q st (index_at g (q+1)))])))).
Proof.
 intros owner_ok enabled valid;destruct enter;unfold begin_seed,end_seed,prepared_loc,optional_seed;abbreviate_semax;Intros.
 all:forward_if;try solve [congruence|contradiction].
 all:do 2 (forward;try solve [entailer!]).
 all:first [forward_call (owner,a,pa,g,limits,st,q,true);solve [entailer!|auto] |
            forward_call (owner,a,pa,g,limits,st,q,false);solve [entailer!|auto]].
Qed.
Theorem prepared_seed_disabled {Espec:OracleKind} p q bits (enter:bool) (storage:mpred):
 Int.and bits (Int.repr 32)=Int.zero ->
 semax (func_tycontext f_cc_run_prepared_level prepared_vars [] [])
 (PROPx [] (LOCALx (prepared_loc p q bits) (SEPx [storage])))
 (if enter then begin_seed else end_seed)
 (normal_ret_assert (PROPx [] (LOCALx (prepared_loc p q bits) (SEPx [storage])))).
Proof.
 intro disabled;destruct enter;unfold begin_seed,end_seed,prepared_loc;abbreviate_semax;Intros.
 all:forward_if;try solve [congruence|contradiction];forward;entailer!.
Qed.
