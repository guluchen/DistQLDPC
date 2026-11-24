(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.floyd.reassoc_seq VST.zlist.list_solver.
Require Import VerifDetected level_ast VerifChildVisit SeedLoopModel VerifRootCall VerifRootAdmission
 VerifSeedBranch EnabledCall EnabledLoopFacts OverlapColumnState OverlapChildState OverlapView SeedPolicyView
 SeedColumnModel SeedColumnRestore SeedResume RootOwnerMemory VerifSeedMove SeedCallFrame SeedFramedCallback RootSearchPhases PreparedRootStages PreparedSeedDispatch PreparedOwnerLoan.
Require flag_level_ast.
Import flag_level_ast.
#[local] Existing Instance VerifDetected.CompSpecs.
Local Open Scope Z_scope.
Definition row_heap c fp d:=seed_owner c fp (limit_address d) (base_address d) (fallback_address d) (seed_geom d) (seed_limits d).
Definition keep_seed c fp d:=seed_storage c fp (seed_geom d) (limit_address d) (base_address d) (fallback_address d) (seed_limits d).
Definition before_visit c s cp w path fp d moving st calls extra:=
 ((row_heap c fp d moving * root_storage c s cp w path st) *
  (active_support (nested c) s None * seed_counter s calls * extra))%logic.
Lemma transfer_dfs_heap c s cp w path fp d moving st calls extra:
 isptr (callback_owner c) -> @field_compatible SeedC seed_type [] (callback_owner c) ->
 column_offsets (geometry c)=col_starts (seed_geom d) -> column_rows (geometry c)=col_rows (seed_geom d) ->
 exempt_qubits (geometry c)=Some (exempts moving) -> blocked st=reference_counts moving ->
 forbidden st=forbidden_events moving -> 0<Zlength (exempts moving) -> 0<Zlength (reference_counts moving) ->
 before_visit c s cp w path fp d moving st calls extra =
 (enabled_memory c s cp w path st * active_support (nested c) s None * seed_counter s calls *
  (keep_seed c fp d * extra))%logic.
Proof.
 intros;unfold before_visit,row_heap,keep_seed;rewrite borrow_prepared_root by assumption;apply pred_ext;cancel.
Qed.


Definition saved_loc s i count (result:option int):=
 [temp _s s;temp _i (Vint (Int.repr i));temp _count (Vint (Int.repr count))] ++
 match result with Some r=>[temp _result (Vint r)]|None=>[] end.
Definition callback_loc s p q i count bits result:=prepared_loc p q bits ++ saved_loc s i count result.

Lemma callback_context flip dfs:
 tycontext_sub (func_tycontext f_cc_run_prepared_level prepared_vars [] [])
 (func_tycontext f_cc_run_prepared_level prepared_vars (prepared_calls flip dfs) []).
Proof.
 apply tycontext_sub_Gprog_nil;vm_compute;
 repeat (apply list_norepet_cons;[simpl;intuition congruence|]);apply list_norepet_nil.
Qed.

Lemma framed_exemption {Espec:OracleKind} flip dfs c s cp w path fp d moving st q enter i count bits result calls extra:
 Int.and bits (Int.repr 32)<>Int.zero -> is_pointer_or_null (callback_owner c) ->
 column_safe (seed_geom d) (seed_limits d) enter q moving ->
 semax (func_tycontext f_cc_run_prepared_level prepared_vars (prepared_calls flip dfs) [])
 (PROPx [] (LOCALx (callback_loc s (nested_policy (nested c)) q i count bits result)
  (SEPx [before_visit c s cp w path fp d moving st calls extra])))
 (if enter then begin_seed else end_seed)
 (normal_ret_assert (PROPx [] (LOCALx (callback_loc s (nested_policy (nested c)) q i count bits result)
  (SEPx [before_visit c s cp w path fp d (after_exemption d enter q moving) st calls extra])))).
Proof.
 intros enabled own valid;eapply semax_Delta_subsumption;[apply callback_context|].
 unfold before_visit;rewrite !sepcon_assoc;unfold callback_loc,SEPx,fold_right_sepcon;rewrite !sepcon_emp.
 match goal with |- semax ?D _ ?body _ =>
   let heap:=constr:((root_storage c s cp w path st * (active_support (nested c) s None * (seed_counter s calls * extra)))%logic) in
   pose proof (@preserve_caller_store Espec VerifDetected.CompSpecs D body [] [] (prepared_loc (nested_policy (nested c)) q bits)
    (prepared_loc (nested_policy (nested c)) q bits) (saved_loc s i count result) (row_heap c fp d moving)
    (row_heap c fp d (after_exemption d enter q moving)) heap) as lift end.
 unfold SEPx,fold_right_sepcon in lift;rewrite !sepcon_emp in lift;apply lift.
 - pose proof (@prepared_seed_enabled Espec (nested_policy (nested c)) (callback_owner c) fp
     (Build_seed_arrays (exemp (conn c)) (limit_address d) (blockp (conn c)) (forbidp (conn c)))
     (Build_seed_column_ptrs (colp (conn c)) (rowp (conn c)) (base_address d) (fallback_address d))
     (seed_geom d) (seed_limits d) moving q bits enter own enabled valid) as checked.
   unfold SEPx,fold_right_sepcon in checked;rewrite !sepcon_emp in checked;exact checked.
 - destruct enter,result;unfold begin_seed,end_seed,saved_loc;cbn [app];auto 100 with closed.
Qed.
