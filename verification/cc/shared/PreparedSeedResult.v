(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto.
Require Import level_ast VerifDetected VerifChildVisit VerifRootCall VerifRootAdmission
 EnabledCall SeedPolicyView SeedBlockView OverlapColumnState OverlapChildState EnabledLoopFacts OverlapView SeedColumnModel
 SeedBlockModel SeedResume SeedColumnRestore RootOwnerMemory RootSearchPhases
 LiveRootPolicy UniversalRootSearch OrbitHeapLoan SeedExecution SeedLoopModel PreparedSeed PreparedSeedDispatch PreparedOwnerLoan PreparedOrbitLoan
 PreparedExemptionFrame PreparedRecursiveCall PreparedRootAdmission PreparedLevelStorage PreparedPhysicalVisit PreparedRootStages.
Require flag_level_ast.
Import flag_level_ast.
#[local] Existing Instance VerifDetected.CompSpecs.
Local Open Scope Z_scope.

Definition root_frame e frame:=
 (reusable_pointer (policy e) * pending_block (policy e) (orbits e) (done_address e) * frame)%logic.
Definition reported c report active q path tail r:=
 (available active q=false -> r=0 /\ tail=path) /\ (available active q=true ->
  let where_:=after_column (geometry c) q true (selected active q) in
  report (geometry c) where_ q r tail /\ Znth 0 tail=Int.repr q /\
   (witness_status r -> returned_trace (nested c) (blocked where_) q tail)).
Definition observed_return e report x q final tail left r:=
 same_search final (active_at e x q) /\ Zlength tail=Zlength (witness_path x) /\
 same_seed_state left (live_rows (remaining_rows x)) /\ reported (root_at e x q) report (active_at e x q) q (witness_path x) tail r.
Lemma seed_visit_storage e x ex frame:
 (seed_memory e x * frame)%logic=
 before_visit (at_seed (policy e) ex) (state_address e) (path_address e) (weight e) (witness_path x)
 (visit_address e) (source_at e x) (live_rows (remaining_rows x)) (running x) (seed_calls x) (root_frame e frame).
Proof.
 unfold seed_memory,before_visit,row_heap,source_at,root_frame;rewrite (specialize_root_storage _ _ _ _ _ _ ex).
 cbn [limit_address base_address fallback_address seed_geom seed_limits].
 unfold at_seed,with_rows,seed_owner;cbn [conn callback_owner nested].
 apply pred_ext;cancel;apply derives_refl.
Qed.
Definition visit_safe e x q:=
 1<=weight e<=Int.max_signed /\ weight e<=Zlength (witness_path x) /\
 0<=q<Zlength (blocked (active_at e x q)) /\ q<=Int.max_signed /\

 isptr (callback_owner (policy e)) /\
 @field_compatible VerifSeedMove.SeedC VerifSeedMove.seed_type [] (callback_owner (policy e)) /\
 column_offsets (geometry (policy e))=col_starts (database e) /\ column_rows (geometry (policy e))=col_rows (database e) /\
 0<Zlength (exempts (entered_at e x q)) /\ 0<Zlength (reference_counts (live_rows (remaining_rows x))) /\
 column_safe (seed_geom (source_at e x)) (limits e) true q (live_rows (remaining_rows x)) /\
 column_safe (seed_geom (source_at e x)) (limits e) false q (entered_at e x q) /\
 (forall k,0<=k<Zlength (exempts (live_rows (remaining_rows x))) ->
  touched (seed_geom (source_at e x)) q (index_at (database e) (q+1)) k=true ->
  Znth k (exempts (live_rows (remaining_rows x)))=
  Int.repr (seed_choice (base_order (database e)) (exhausted_fallback (remaining_rows x)) k q false)) /\
 (available (active_at e x q) q=true -> seed_checked (root_at e x q) (active_at e x q) q).

Definition root_loc e q i bits:=visit_loc (policy e) (state_address e) q i (Zlength (order e)) bits.
Theorem root_returns_at_weight {Espec:OracleKind} e report x q i bits frame :
 Int.and bits (Int.repr 32)<>Int.zero -> Int.and bits (Int.repr 16)<>Int.zero ->
 visit_safe e x q ->
 semax (func_tycontext f_cc_run_prepared_level prepared_vars (root_calls_at_weight (policy e) report bits) [])
 (PROPx [] (LOCALx (root_loc e q i bits) (SEPx [(seed_memory e x * frame)%logic])))
 run_root
 (normal_ret_assert (EX final:snapshot,EX tail:list int,EX left:moving_state,EX r:Z,
   PROPx [0<=r<=3;observed_return e (report (weight e)) x q final tail left r]
    (LOCALx (temp _result (Vint (Int.repr r))::root_loc e q i bits)
     (SEPx [(seed_memory e (returned_state e x q final tail left) * frame)%logic])))).
Proof.
 intros seed_bit overlap_bit safe;destruct safe as [size [room [key [signed [own [layout_ok [starts [rows
   [extent [n [entry [exit [rest choose]]]]]]]]]]]]].
 eapply semax_post'.
 2:{ rewrite (seed_visit_storage e x (exempts (entered_at e x q)) frame).
     apply (@PreparedPhysicalVisit.seed_visit_at_weight Espec (root_at e x q) report (state_address e) (path_address e) (weight e)
       (witness_path x) (visit_address e) (source_at e x) (live_rows (remaining_rows x)) (running x)
       q i (Zlength (order e)) (seed_calls x) bits (root_frame e frame));try assumption;try reflexivity. }
 Intros final tail left r;Exists final tail left r.
 rewrite (seed_visit_storage e (returned_state e x q final tail left) (exempts (entered_at e x q)) frame).
 unfold observed_return,reported,root_loc,returned_state;cbn [running witness_path seed_calls remaining_rows live_rows].
 apply andp_left2;unfold PROPx;cbn [fold_right];apply andp_right.
 - apply prop_right;exact (conj H0 (conj (conj H (conj H1 (conj H2 (conj H3 H4)))) I)).
 - apply andp_left2;apply derives_refl.
Qed.

Definition physical_root_returns {Espec:OracleKind} e (report:root_report):=
 @root_returns_at_weight Espec e (fun _=>report).
