(* Function-return ownership and mathematical answer contract for search. The
   two addressable scratch cells remain owned until normal Clight stack cleanup.
   Defining this assertion does not prove the complete search body or link. *)
Require Import VST.floyd.proofauto.
Require Import CCV.ccv_core CCV.CCSearchSpecs CCV.CCSearchHeap CCV.CCRowHeap
 CCV.CCAPIBridge CCV.VerifToggle.
Import ListNotations. Open Scope Z_scope.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
Definition search_exit_memory sh a p tp rp ret out s:mpred:=
 (problem_repr sh a p*workspace_fields sh p*
 (if Z.eq_dec ret 1 then workspace_any a p else workspace_zero a p)*
 data_at Tsh(tarray tuchar(model_n a))(tbytes out)(ptr_out p)*stats_repr(ptr_stats p)s*
 data_at_ Tsh tuint tp*data_at_ Tsh tuint rp)%logic.
Definition search_return sh a p tp rp cap budget s0:assert:=
 (EX ret:Z,EX out:list Z,EX s:stats_model,
 PROP(Zlength out=model_n a;Forall(fun z:Z=>z=0\/z=1)out;
 legal_stats budget s;stats_monotone s0 s;query_result a cap ret out)
 LOCAL(temp ret_temp(Vint(Int.repr ret)))
 SEP(search_exit_memory sh a p tp rp ret out s))%assert.
Lemma row_heap_found_memory sh a p tp rp top row xs fs ys zs pk buf frames out s:
 row_heap sh a p tp rp top row xs fs ys zs pk buf frames out s |--
 search_exit_memory sh a p tp rp 1 out s.
Proof.
 unfold row_heap,search_core_heap,search_exit_memory.
 destruct(Z.eq_dec 1 1)as[Eq|Ne];[|contradiction].
 sep_apply(data_at_data_at_ Tsh(tarray tuchar(model_n a))(tbytes xs)(ptr_selected p)).
 sep_apply(data_at_data_at_ Tsh(tarray tuchar(model_n a))(tbytes fs)(ptr_forbidden p)).
 sep_apply(data_at_data_at_ Tsh(tarray tuchar(model_m a))(tbytes ys)(ptr_syndrome p)).
 sep_apply(data_at_data_at_ Tsh(tarray tuchar(model_l a))(tbytes zs)(ptr_logical_value p)).
 sep_apply(data_at_data_at_ Tsh(tarray tuchar(model_n a))(tbytes pk)(ptr_packed p)).
 sep_apply(data_at_data_at_ Tsh(tarray tuint(model_n a))buf(ptr_undo p)).
 sep_apply(data_at_data_at_ Tsh(tarray CCSearchSpecs.frame_type(model_n a))frames(ptr_frames p)).
 sep_apply(data_at_data_at_ Tsh tuint(Vint(Int.repr top))tp).
 sep_apply(data_at_data_at_ Tsh tuint(Vint(Int.repr row))rp).
 unfold workspace_any;cancel.
Qed.
Lemma row_heap_zero_memory sh a p tp rp top row buf frames s ret:
 ret<>1 ->
 row_heap sh a p tp rp top row(Zrepeat 0(model_n a))(Zrepeat 0(model_n a))
 (Zrepeat 0(model_m a))(Zrepeat 0(model_l a))(Zrepeat 0(model_n a))buf frames
 (Zrepeat 0(model_n a))s |--
 search_exit_memory sh a p tp rp ret(Zrepeat 0(model_n a))s.
Proof.
 intros NotFound;unfold row_heap,search_core_heap,search_exit_memory.
 destruct(Z.eq_dec ret 1)as[Eq|Ne];[contradiction|].
 sep_apply(data_at_data_at_ Tsh(tarray tuint(model_n a))buf(ptr_undo p)).
 sep_apply(data_at_data_at_ Tsh(tarray CCSearchSpecs.frame_type(model_n a))frames(ptr_frames p)).
 sep_apply(data_at_data_at_ Tsh tuint(Vint(Int.repr top))tp).
 sep_apply(data_at_data_at_ Tsh tuint(Vint(Int.repr row))rp).
 unfold workspace_zero. rewrite !zero_bytes_repr.
 unfold tbytes,Zrepeat;rewrite !map_repeat;cancel.
Qed.
Print Assumptions row_heap_found_memory.
Print Assumptions row_heap_zero_memory.

Lemma search_heap_zero_memory sh a p tp rp top buf frames s ret:
 ret<>1 ->
 search_heap sh a p tp rp top(Zrepeat 0(model_n a))(Zrepeat 0(model_n a))
 (Zrepeat 0(model_m a))(Zrepeat 0(model_l a))(Zrepeat 0(model_n a))buf frames
 (Zrepeat 0(model_n a))s |--
 search_exit_memory sh a p tp rp ret(Zrepeat 0(model_n a))s.
Proof.
 intros NotFound;unfold search_heap,search_exit_memory.
 destruct(Z.eq_dec ret 1)as[Eq|Ne];[contradiction|].
 sep_apply(data_at_data_at_ Tsh(tarray tuint(model_n a))buf(ptr_undo p)).
 sep_apply(data_at_data_at_ Tsh(tarray CCSearchSpecs.frame_type(model_n a))frames(ptr_frames p)).
 sep_apply(data_at_data_at_ Tsh tuint(Vint(Int.repr top))tp).
 unfold workspace_zero. rewrite !zero_bytes_repr.
 unfold tbytes,Zrepeat;rewrite !map_repeat;cancel.
Qed.
Print Assumptions search_heap_zero_memory.
