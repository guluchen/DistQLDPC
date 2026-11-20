(* Search entry ownership and clamped-cap result bridge. *)
Require Import VST.floyd.proofauto.
Require Import CCV.ccv_core CCV.CCSearchSpecs CCV.CCSearchHeap CCV.CCRawTopHeap CCV.CCRootInvariant
 CCV.CCFrameForget CCV.CCSearchExit CCV.CCSearchResults CCV.CCAPIBridge CCV.VerifToggle.
Import ListNotations. Open Scope Z_scope.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
Definition search_entry_memory sh a p tp rp s:mpred:=
 (problem_repr sh a p*workspace_fields sh p*workspace_zero a p*
 data_at Tsh(tarray tuchar(model_n a))(zero_bytes(model_n a))(ptr_out p)*stats_repr(ptr_stats p)s*
 data_at_ Tsh tuint tp*data_at_ Tsh tuint rp)%logic.
Definition search_entry_state sh a p tp rp cap budget rules s:assert:=
 (PROP()LOCAL(temp _p(ptr_problem p);temp _w(ptr_workspace p);temp _out(ptr_out p);temp _stats(ptr_stats p);
 temp _cap(Vint(Int.repr cap));temp _budget(Vint(Int.repr budget));temp _rules(Vint(Int.repr rules));
 lvar _top tuint tp;lvar _row tuint rp)SEP(search_entry_memory sh a p tp rp s))%assert.
Lemma entry_memory_raw sh a p tp rp s:
 search_entry_memory sh a p tp rp s=
 search_heap_raw_top sh a p tp rp Vundef(Zrepeat 0(model_n a))(Zrepeat 0(model_n a))
 (Zrepeat 0(model_m a))(Zrepeat 0(model_l a))(Zrepeat 0(model_n a))(root_buf(model_n a))
 (Zrepeat(default_frame:frame_value)(model_n a))(Zrepeat 0(model_n a))s.
Proof.
 unfold search_entry_memory,search_heap_raw_top,workspace_zero,zero_bytes.
 change(@data_at CCSearchSpecs.CompSpecs Tsh(tarray tuint(model_n a))(root_buf(model_n a))(ptr_undo p))with
 (@data_at_ CCSearchSpecs.CompSpecs Tsh(tarray tuint(model_n a))(ptr_undo p)).
 change(@data_at CCSearchSpecs.CompSpecs Tsh(tarray CCSearchSpecs.frame_type(model_n a))
 (Zrepeat(default_frame:frame_value)(model_n a))(ptr_frames p))with
 (@data_at_ CCSearchSpecs.CompSpecs Tsh(tarray CCSearchSpecs.frame_type(model_n a))(ptr_frames p)).
 apply pred_ext;cancel.
Qed.
Lemma search_return_clamp_cap sh a p tp rp cap budget s0:
 0<=model_n a ->model_n a<=cap ->
 search_return sh a p tp rp(model_n a)budget s0 |--search_return sh a p tp rp cap budget s0.
Proof.
 intros N Cap;unfold search_return;Intros ret out s.
 go_lowerx;normalize.
 assert(Old:query_result a(model_n a)ret out)by assumption.
 pose proof(cap_clamp_query_result a cap ret out N Cap Old)as Query.
 Exists ret out s. normalize;cancel;try(apply andp_right;[apply prop_right;tauto|cancel]).
Qed.
Print Assumptions entry_memory_raw.
Print Assumptions search_return_clamp_cap.
