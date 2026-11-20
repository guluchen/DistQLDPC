(* Forget old undo/frame contents before root initialization. This weakens
   spatial knowledge; it does not claim that C zeroes those arrays. *)
Require Import VST.floyd.proofauto.
Require Import CCV.ccv_core CCV.CCSearchSpecs CCV.CCSearchHeap CCV.CCRawTopHeap CCV.CCRootInvariant CCV.CCFrameForget.
Import ListNotations. Open Scope Z_scope.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
Lemma raw_top_forget_root_scratch sh a p tp rp top xs fs ys zs pk buf frames out s:
 search_heap_raw_top sh a p tp rp top xs fs ys zs pk buf frames out s |--
 search_heap_raw_top sh a p tp rp top xs fs ys zs pk(root_buf(model_n a))
 (Zrepeat(default_frame:frame_value)(model_n a))out s.
Proof.
 unfold search_heap_raw_top.
 sep_apply(data_at_data_at_ Tsh(tarray tuint(model_n a))buf(ptr_undo p)).
 sep_apply(data_at_data_at_ Tsh(tarray CCSearchSpecs.frame_type(model_n a))frames(ptr_frames p)).
 change(@data_at CCSearchSpecs.CompSpecs Tsh(tarray tuint(model_n a))(root_buf(model_n a))(ptr_undo p))with
 (@data_at_ CCSearchSpecs.CompSpecs Tsh(tarray tuint(model_n a))(ptr_undo p)).
 change(@data_at CCSearchSpecs.CompSpecs Tsh(tarray CCSearchSpecs.frame_type(model_n a))
 (Zrepeat(default_frame:frame_value)(model_n a))(ptr_frames p))with
 (@data_at_ CCSearchSpecs.CompSpecs Tsh(tarray CCSearchSpecs.frame_type(model_n a))(ptr_frames p)).
 cancel.
Qed.
Print Assumptions raw_top_forget_root_scratch.
