(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto.
Require Import level_ast VerifDetected VerifChildVisit VerifRootCall VerifRootAdmission
 EnabledCall SeedPolicyView SeedBlockView OverlapColumnState OverlapChildState EnabledLoopFacts OverlapView SeedColumnModel
 SeedBlockModel SeedResume SeedColumnRestore RootOwnerMemory RootSearchPhases
 LiveRootPolicy UniversalRootSearch OrbitHeapLoan SeedExecution SeedLoopModel.
#[local] Existing Instance VerifDetected.CompSpecs.
Local Open Scope Z_scope.

Definition source_at e x:=Build_exemption_source (dynamic_rows (database e) (remaining_rows x))
 (SeedExecution.limit_address e) (SeedExecution.base_address e) (SeedExecution.fallback_address e) (limits e).
Definition entered_at e x q:=after_exemption (source_at e x) true q (live_rows (remaining_rows x)).
Definition root_at e x q:=at_seed (policy e) (exempts (entered_at e x q)).
Definition active_at e x q:=make_run (running x) (entered_at e x q).
Definition verdict e x q:=seed_outcome (root_at e x q) (active_at e x q) q.
Definition root_frame e frame:=
 (reusable_pointer (policy e) * pending_block (policy e) (orbits e) (done_address e) * frame)%logic.
Definition returned_state e x q final tail left:=
 Build_root_state (Build_exhausted_state (exhausted_fallback (remaining_rows x)) left) final tail
 (seed_calls_count (active_at e x q) q (seed_calls x)).
Definition returned_summary e x q final tail left:=
 same_search final (active_at e x q) /\ Zlength tail=Zlength (witness_path x) /\
 same_seed_state left (live_rows (remaining_rows x)) /\
 (available (active_at e x q) q=false -> tail=witness_path x) /\
 (available (active_at e x q) q=true -> root_trace (root_at e x q)
   (after_column (geometry (root_at e x q)) q true (selected (active_at e x q) q)) q (witness_path x) tail).

(* Keep both calls on the same allocation, including if DFS changed the
   statistics and witness path. The exit still borrows the entered layout. *)
Lemma seed_visit_storage e x ex frame:
 (seed_memory e x * frame)%logic=
 before_visit (at_seed (policy e) ex) (state_address e) (path_address e) (weight e) (witness_path x)
 (visit_address e) (source_at e x) (live_rows (remaining_rows x)) (running x) (seed_calls x) (root_frame e frame).
Proof.
 unfold seed_memory,before_visit,row_heap,source_at,root_frame;rewrite (specialize_root_storage _ _ _ _ _ _ ex).
 cbn [limit_address base_address fallback_address seed_geom seed_limits].
 unfold at_seed,with_rows,seed_heap;cbn [conn callback_owner nested].
 apply pred_ext;cancel;apply derives_refl.
Qed.
Definition visit_safe e x q:=
 1<=weight e<=Int.max_signed /\ weight e<=Zlength (witness_path x) /\
 0<=q<Zlength (blocked (active_at e x q)) /\ q<=Int.max_signed /\
 isptr (nested_policy (nested (policy e))) /\ isptr (visit_address e) /\ isptr (callback_addr (policy e)) /\
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

Definition root_loc e q i:=root_call_loc (policy e) (state_address e) q i (Zlength (order e)).
Theorem physical_root_returns {Espec:OracleKind} e x q i frame :
 visit_safe e x q ->
 semax (func_tycontext f_cc_run_level Vprog (all_roots (policy e)) [])
 (PROPx [] (LOCALx (root_loc e q i) (SEPx [(seed_memory e x * frame)%logic])))
 visit_and_restore
 (normal_ret_assert (EX final:snapshot,EX tail:list int,EX left:moving_state,
   PROPx [0<=verdict e x q<=3;returned_summary e x q final tail left]
    (LOCALx (temp _result (Vint (Int.repr (verdict e x q)))::root_loc e q i)
     (SEPx [(seed_memory e (returned_state e x q final tail left) * frame)%logic])))).
Proof.
 intro safe;destruct safe as [size [room [key [signed [pp [sf [ofp [own [layout_ok [starts [rows
   [extent [n [entry [exit [rest choose]]]]]]]]]]]]]]]].
 eapply semax_Delta_subsumption;[apply (all_roots_subsumes_seed (policy e) (installed_rows (geometry (policy e)) (exempts (entered_at e x q))))|].
 eapply semax_post'.
 2:{ rewrite (seed_visit_storage e x (exempts (entered_at e x q)) frame).
     apply (@physical_seed_visit Espec (root_at e x q) (state_address e) (path_address e) (weight e)
       (witness_path x) (visit_address e) (source_at e x) (live_rows (remaining_rows x)) (running x)
       q i (Zlength (order e)) (seed_calls x) (root_frame e frame));try assumption;try reflexivity. }
 Intros final tail left;Exists final tail left.
 rewrite (seed_visit_storage e (returned_state e x q final tail left) (exempts (entered_at e x q)) frame).
 unfold returned_summary,root_loc,verdict,returned_state;cbn [running witness_path seed_calls remaining_rows live_rows].
 apply andp_left2;unfold PROPx;cbn [fold_right];apply andp_right.
 - apply prop_right;exact (conj H0 (conj (conj H (conj H1 (conj H2 (conj H3 H4)))) I)).
 - apply andp_left2;apply derives_refl.
Qed.
