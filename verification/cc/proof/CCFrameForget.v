(* Forget a popped frame without retaining stale initialized fields.
   Generic spatial fact; not a proof of the main stack invariant. *)
Require Import VST.floyd.proofauto.
Require Import CCV.CCFrameFields.
Import ListNotations. Open Scope Z_scope.
Section ArrayProof.
Context{CS:compspecs}.
Lemma forget_frame_slot sh n i(frames:list(reptype CCFrameFields.frame_type))p:
 Zlength frames=n ->0<=i<n ->
 data_at sh(tarray CCFrameFields.frame_type n)frames p |--
 data_at sh(tarray CCFrameFields.frame_type n)
   (upd_Znth i frames(default_val CCFrameFields.frame_type))p.
Proof.
 intros Len Index.
 rewrite(frame_array_focus sh n i frames p Len Index).
 rewrite(frame_array_reassemble sh n i frames p(default_val CCFrameFields.frame_type)Len Index).
 apply sepcon_derives;[apply data_at_data_at_|apply derives_refl].
Qed.
End ArrayProof.
Require Import CCV.ccv_core CCV.CCSearchSpecs CCV.VerifSearchPush.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
Definition default_frame:=@default_val CCSearchSpecs.CompSpecs VerifSearchPush.frame_type.
Lemma default_frame_fields:
 default_frame=(Vundef,(Vundef,(Vundef,(Vundef,Vundef)))).
Proof. reflexivity. Qed.
Lemma initialized_default_child mark:
 initialized_child default_frame mark=
 (Vundef,(Vundef,(Vundef,(Vint(Int.repr mark),Vint Int.zero)))).
Proof. reflexivity. Qed.
Print Assumptions forget_frame_slot.
