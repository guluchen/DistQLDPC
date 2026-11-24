(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto ClightSelect VerifDetected SeedLoopModel PreparedSeedDispatch.
Require flag_level_ast.
Import flag_level_ast.
#[local] Existing Instance VerifDetected.CompSpecs.
Local Open Scope Z_scope.

Definition for_seeds:statement:=ltac:(native_fragment (counts_on _i) f_cc_run_prepared_level).
Definition one_seed:=at_branch [true;false;true] for_seeds.
Definition stages:=
 match one_seed with Ssequence a (Ssequence b (Ssequence c (Ssequence d (Ssequence e (Ssequence f g))))) =>
 [a;b;c;d;e;f;g]|_=>[] end.
Ltac component n:=
 let s:=eval cbv beta iota zeta delta [List.nth stages one_seed at_branch for_seeds] in (List.nth n stages Sskip) in exact s.
Definition pick_root:statement:=ltac:(component 0%nat).
Definition clear_verdict:statement:=ltac:(component 2%nat).
Definition visit_root:statement:=ltac:(component 3%nat).
Definition early_return:statement:=ltac:(component 5%nat).
Definition close_block:statement:=ltac:(component 6%nat).
Definition run_root:=Ssequence begin_seed (Ssequence clear_verdict (Ssequence visit_root end_seed)).
Lemma actual_iteration:
 one_seed=Ssequence pick_root (Ssequence begin_seed (Ssequence clear_verdict
 (Ssequence visit_root (Ssequence end_seed (Ssequence early_return close_block))))).
Proof. reflexivity. Qed.

Definition seed_fields c p array:=
 (field_at Tsh (Tstruct _cc_level_policy noattr) [StructField _seed_count] (Vint (Int.repr (root_count c))) p *
  field_at Tsh (Tstruct _cc_level_policy noattr) [StructField _seed] array p * seed_vector c array)%logic.
Definition driver_loc c s p i bits:=
 [temp _s s;temp _policy p;temp _options (Vint bits);temp _i (Vint (Int.repr i));
  temp _count (Vint (Int.repr (root_count c)))].
Definition seed_loc c s p i bits:=temp _q (Vint (Znth i (seed_order c)))::driver_loc c s p i bits.
Definition before_root c s p a i bits:=PROPx [] (LOCALx (seed_loc c s p i bits) (SEPx [seed_fields c p a;waiting c i])).
Definition after_root c s p a i bits r:=
 PROPx [0<=r<=3;observation c i r]
 (LOCALx (temp _result (Vint (Int.repr r))::seed_loc c s p i bits) (SEPx [seed_fields c p a;returned c i r])).
Definition after_block c s p a i bits:=PROPx []
 (LOCALx (driver_loc c s p i bits) (SEPx [seed_fields c p a;waiting c (i+1)])).
Definition prepared_spec c s p a bits:ident*funspec:=
 DECLARE _cc_run_prepared_level WITH u:unit
 PRE [tptr level_type,tptr (Tstruct _cc_level_policy noattr),tuint]
 PROP(Int.and bits Int.one<>Int.zero;0<=root_count c<=Int.max_signed)
 PARAMS(s;p;Vint bits) SEP(seed_fields c p a;waiting c 0)
 POST [tint] EX i:Z,EX r:Z, PROP(exhausted_before c i;stop_at c i r;0<=r<=3)
 RETURN(Vint (Int.repr r)) SEP(seed_fields c p a;after_stop c i r).
Definition prepared_calls (flip dfs:funspec):funspecs:=
 ltac:(let fs:=constr:([(_flip,flip);(_dfs,dfs)]) in with_library flag_level_ast.prog fs).
