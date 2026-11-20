(* Function-return memory weakening from raw top ownership. No initialized
   top value is assumed at cap-zero or first-root entry. *)
Require Import VST.floyd.proofauto.
Require Import CCV.ccv_core CCV.CCSearchSpecs CCV.CCRawTopHeap CCV.CCSearchExit CCV.CCAPIBridge CCV.VerifToggle.
Import ListNotations. Open Scope Z_scope.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
Lemma raw_top_zero_memory sh a p tp rp top buf frames s ret:
 ret<>1 ->
 search_heap_raw_top sh a p tp rp top(Zrepeat 0(model_n a))(Zrepeat 0(model_n a))
 (Zrepeat 0(model_m a))(Zrepeat 0(model_l a))(Zrepeat 0(model_n a))buf frames
 (Zrepeat 0(model_n a))s |--
 search_exit_memory sh a p tp rp ret(Zrepeat 0(model_n a))s.
Proof.
 intros NotFound;unfold search_heap_raw_top,search_exit_memory.
 destruct(Z.eq_dec ret 1)as[Eq|Ne];[contradiction|].
 sep_apply(data_at_data_at_ Tsh(tarray tuint(model_n a))buf(ptr_undo p)).
 sep_apply(data_at_data_at_ Tsh(tarray CCSearchSpecs.frame_type(model_n a))frames(ptr_frames p)).
 sep_apply(data_at_data_at_ Tsh tuint top tp).
 unfold workspace_zero;rewrite !zero_bytes_repr.
 unfold tbytes,Zrepeat;rewrite !map_repeat;cancel.
Qed.
Print Assumptions raw_top_zero_memory.
