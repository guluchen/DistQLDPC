(* The four previously open nested scans in the soundness driver's global
   environment. The evaluator executes the unchanged solver bodies. *)
Require Import VST.floyd.proofauto.
Require Import compcert.lib.Maps CCV.CCStructuredRuns CCV.CCScanFrames CCV.CCScanGuard
 CCV.CCCountedScan CCV.CCScanCallees CCV.CCActualScans CCV.CCVerificationDriver
 CCV.ccv_core CCV.ccv_primitives.
Local Notation ge := (Clight.globalenv driver_prog).
Lemma driver_forbid_scan : call_settles ge ccv_core.f_forbid.
Proof. internal_body ccv_core.f_forbid. Qed.
Lemma driver_toggle_scan : call_settles ge ccv_core.f_toggle.
Proof. internal_body ccv_core.f_toggle. Qed.
Lemma driver_ceil_scan : call_settles ge ccv_primitives.f_ccv_ceil_div.
Proof. internal_body ccv_primitives.f_ccv_ceil_div. Qed.
Ltac driver_frame :=
 lazymatch goal with
 | |- framed _ _ _ (Ssequence _ _) => apply framed_seq;driver_frame
 | |- framed _ _ _ (Sifthenelse _ _ _) => apply framed_if;driver_frame
 | |- framed _ _ _ (Sloop (Ssequence _ _) (Sset ?id _)) =>
   apply (bounded_scan _ _ _ id);[closed_guard|driver_frame|vm_compute;intuition congruence]
 | |- framed _ _ _ (Scall _ (Evar ?id _) _) =>
   let fn:=lazymatch id with
    | ccv_core._forbid => constr:(ccv_core.f_forbid)
    | ccv_core._toggle => constr:(ccv_core.f_toggle)
    | ccv_core._ccv_ceil_div => constr:(ccv_primitives.f_ccv_ceil_div) end in
   eapply (framed_direct_call driver_prog id _ fn _ _ _);[reflexivity|apply PTree.gempty|
    first [apply driver_ceil_scan|apply driver_toggle_scan|apply driver_forbid_scan]]
 | _ => closed_frame
 end.
Ltac driver_scan fn :=
 apply structured_function_returns;intros args m e le m' Entry;
 pose proof(empty_call_env _ fn _ _ _ _ _ eq_refl Entry) as Empty;subst e;
 cbn [fn_body fn];driver_frame.
Lemma driver_validate_scan : call_settles ge ccv_core.f_validate.
Proof. driver_scan ccv_core.f_validate. Qed.
Lemma driver_overlap_scan : call_settles ge ccv_core.f_overlap.
Proof. driver_scan ccv_core.f_overlap. Qed.
Lemma driver_bounds_scan : call_settles ge ccv_core.f_bounds.
Proof. driver_scan ccv_core.f_bounds. Qed.
Lemma driver_leaf_scan : call_settles ge ccv_core.f_leaf.
Proof. driver_scan ccv_core.f_leaf. Qed.
