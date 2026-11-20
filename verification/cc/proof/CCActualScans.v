(* Inspect each guard, counter, loop increment and set of modified temporaries
   directly in the frozen normalized Clight bodies. *)
Require Import VST.floyd.proofauto.
Require Import compcert.lib.Maps compcert.cfrontend.Clight.
Require Import CCV.ccv_core CCV.ccv_primitives CCV.CCLinkedProgram
 CCV.CCStructuredRuns CCV.CCScanFrames CCV.CCScanGuard CCV.CCCountedScan CCV.CCScanCallees.
Import ListNotations.
Local Notation ge := (Clight.globalenv linked_prog).
Create HintDb finite_helpers.
Lemma empty_call_env ge0 fn args m e le m' : fn_vars fn=[] ->
 Clight.function_entry2 ge0 fn args m e le m' -> e=Clight.empty_env.
Proof. intros Empty Entry; inversion Entry;subst.
 match goal with A:Clight.alloc_variables _ _ _ _ _ _ |- _ => rewrite Empty in A; inversion A;reflexivity end.
Qed.
Ltac closed_frame :=
 lazymatch goal with
 | |- framed _ _ _ Sskip => apply framed_skip
 | |- framed _ _ _ Sbreak => apply framed_break
 | |- framed _ _ _ (Sreturn _) => apply framed_return
 | |- framed _ _ _ (Sassign _ _) => apply framed_assign
 | |- framed _ _ _ (Sset _ _) => apply framed_set
 | |- framed _ _ _ (Ssequence _ _) => apply framed_seq;closed_frame
 | |- framed _ _ _ (Sifthenelse _ _ _) => apply framed_if;closed_frame
 | |- framed _ _ _ (Sloop (Ssequence _ _) (Sset ?id _)) =>
   apply (bounded_scan _ _ _ id);[closed_guard|closed_frame|vm_compute;intuition congruence]
 | |- checked_guard _ _ _ _ (Sifthenelse _ Sskip Sbreak) => apply simple_guard;reflexivity
 | |- checked_guard _ _ _ _ (Ssequence _ _) => apply guard_prefix;[closed_frame|closed_guard]
 | |- framed _ _ _ (Scall _ (Evar ?id _) _) =>
    let target := lazymatch id with
     | ccv_core._forbid => constr:(ccv_core.f_forbid)
     | ccv_core._toggle => constr:(ccv_core.f_toggle)
     | ccv_core._ccv_ceil_div => constr:(ccv_primitives.f_ccv_ceil_div)
     end in
    eapply (framed_direct_call linked_prog id _ target _ _ _);[reflexivity|apply PTree.gempty|solve[eauto with finite_helpers]]
 end
with closed_guard := closed_frame.
Ltac internal_body fname :=
 apply structured_function_returns; intros args m e le m' Entry;
 let E := fresh "EmptyEnvironment" in
 pose proof(empty_call_env _ fname _ _ _ _ _ eq_refl Entry) as E;subst e;
 cbn [fn_body fname];closed_frame.
Lemma shape_body_settles : call_settles ge ccv_core.f_shape.
Proof. internal_body ccv_core.f_shape. Qed.
Lemma validate_body_settles : call_settles ge ccv_core.f_validate.
Proof. internal_body ccv_core.f_validate. Qed.
Lemma forbid_body_settles : call_settles ge ccv_core.f_forbid.
Proof. internal_body ccv_core.f_forbid. Qed.
Lemma toggle_body_settles : call_settles ge ccv_core.f_toggle.
Proof. internal_body ccv_core.f_toggle. Qed.
Lemma ceil_body_settles : call_settles ge ccv_primitives.f_ccv_ceil_div.
Proof. internal_body ccv_primitives.f_ccv_ceil_div. Qed.
#[local] Hint Resolve forbid_body_settles toggle_body_settles ceil_body_settles : finite_helpers.
Lemma overlap_body_settles : call_settles ge ccv_core.f_overlap.
Proof. internal_body ccv_core.f_overlap. Qed.
Lemma bounds_body_settles : call_settles ge ccv_core.f_bounds.
Proof. internal_body ccv_core.f_bounds. Qed.
Lemma leaf_body_settles : call_settles ge ccv_core.f_leaf.
Proof. internal_body ccv_core.f_leaf. Qed.
Print Assumptions bounds_body_settles.
Print Assumptions leaf_body_settles.
