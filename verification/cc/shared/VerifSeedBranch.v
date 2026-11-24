(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.floyd.reassoc_seq.
Require Import level_ast VerifDetected SeedLoopModel SeedPolicyView SeedColumnModel.
Require VerifSeedMove seed_ast.
#[local] Existing Instance VerifDetected.CompSpecs.
Local Open Scope Z_scope.

Definition seed_slot p owner fp :=
 (field_at Tsh (Tstruct level_ast._cc_level_policy noattr) [StructField level_ast._seed_exemption] fp p *
  field_at Tsh (Tstruct level_ast._cc_level_policy noattr) [StructField level_ast._owner] owner p *
  weak_valid_pointer p)%logic.
Definition seed_function fp :=
 (func_ptr' (snd seed_visit_spec) fp * weak_valid_pointer fp)%logic.
Definition seed_preserved s p q i count (r:option int) :=
 [temp level_ast._s s;temp level_ast._policy p;temp level_ast._q (Vint (Int.repr q));temp level_ast._i (Vint (Int.repr i));
  temp level_ast._count (Vint (Int.repr count))] ++
 match r with Some result=>[temp level_ast._result (Vint result)] | None=>[] end.
Definition seed_step p owner fp a pa geom limits st:=
 (seed_slot p owner fp * seed_function fp * scans_at owner pa geom * moving_at owner a limits st)%logic.

Theorem dispatch_tiebreak {Espec:OracleKind} policies s p owner fp a pa geom limits st q enter i count r :
 isptr p -> isptr fp -> is_pointer_or_null owner ->
 column_safe geom limits enter q st ->
 semax (func_tycontext f_cc_run_level Vprog (RootG policies) [])
  (PROPx [] (LOCALx (seed_preserved s p q i count r) (SEPx [seed_step p owner fp a pa geom limits st])))
  (if enter then exempt_in else exempt_out)
  (normal_ret_assert (PROPx [] (LOCALx (seed_preserved s p q i count r)
   (SEPx [seed_step p owner fp a pa geom limits (prefix geom limits enter q st (index_at geom (q+1)))])))).
Proof.
 intros pp pf owner_ok safe;destruct enter;unfold seed_preserved,seed_step,seed_slot,seed_function,
   exempt_in,exempt_out;destruct p;try contradiction;destruct fp;try contradiction.
 all:destruct r;cbn [app];abbreviate_semax;Intros;reassoc_seq;apply semax_if_seq;forward_if;try solve [discriminate|congruence].
 all:try solve [cbn [denote_tc_test_eq];apply andp_right;[entailer!|auto 40 with valid_pointer]].
 all:do 2 forward;try solve [entailer!;cbn [denote_tc_test_eq];apply andp_right;[entailer!|auto 40 with valid_pointer]].
 all:forward_if;try solve [discriminate|congruence].
 all:do 2 forward.
 all:first [forward_call (owner,a,pa,geom,limits,st,q,true);solve [entailer! | auto] |
            forward_call (owner,a,pa,geom,limits,st,q,false);solve [entailer! | auto]].
Qed.
