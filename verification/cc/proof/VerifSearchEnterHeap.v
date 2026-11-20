(* Actual iteration-entry prefix framed by the complete owned search heap.
   Nonexhausted branch only. Does not prove the whole search body or termination. *)
Require Import VST.floyd.proofauto.
Require Import CCV.ccv_core CCV.CCSearchSpecs CCV.CCSearchContext CCV.CCSearchMemory
 CCV.CCSearchHeap CCV.CCStatsFields CCV.CCStatsInvariant CCV.CCAPIBridge
 CCV.CCBlockFrame CCV.VerifSearchEnter CCV.VerifToggle CCV.CCSearchFragments.
Import ListNotations. Open Scope Z_scope.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
Definition enter_rest_heap sh a p tp rp top xs fs ys zs pk buf out s:mpred:=
 (problem_repr sh a p*
 field_at sh workspace_type[StructField _capacity](Vint(Int.repr(workspace_capacity p)))(ptr_workspace p)*
 field_at sh workspace_type[StructField _frame_capacity](Vint(Int.repr(workspace_frame_capacity p)))(ptr_workspace p)*
 field_at sh workspace_type[StructField _selected](ptr_selected p)(ptr_workspace p)*
 field_at sh workspace_type[StructField _forbidden](ptr_forbidden p)(ptr_workspace p)*
 field_at sh workspace_type[StructField _syndrome](ptr_syndrome p)(ptr_workspace p)*
 field_at sh workspace_type[StructField _logical_value](ptr_logical_value p)(ptr_workspace p)*
 field_at sh workspace_type[StructField _packed](ptr_packed p)(ptr_workspace p)*
 field_at sh workspace_type[StructField _undo](ptr_undo p)(ptr_workspace p)*
 data_at Tsh(tarray tuchar(model_n a))(tbytes xs)(ptr_selected p)*
 data_at Tsh(tarray tuchar(model_n a))(tbytes fs)(ptr_forbidden p)*
 data_at Tsh(tarray tuchar(model_m a))(tbytes ys)(ptr_syndrome p)*
 data_at Tsh(tarray tuchar(model_l a))(tbytes zs)(ptr_logical_value p)*
 data_at Tsh(tarray tuchar(model_n a))(tbytes pk)(ptr_packed p)*
 data_at Tsh(tarray tuint(model_n a))buf(ptr_undo p)*
 data_at Tsh(tarray tuchar(model_n a))(tbytes out)(ptr_out p)*
 field_at Tsh stats_type[StructField _nodes](Vint(Int.repr(stat_nodes s)))(ptr_stats p)*
 field_at Tsh stats_type[StructField _pack_prunes](Vint(Int.repr(stat_pack s)))(ptr_stats p)*
 field_at Tsh stats_type[StructField _charge_prunes](Vint(Int.repr(stat_charge s)))(ptr_stats p)*
 field_at Tsh stats_type[StructField _overlap_prunes](Vint(Int.repr(stat_overlap s)))(ptr_stats p)*
 data_at Tsh tuint(Vint(Int.repr top))tp*data_at_ Tsh tuint rp)%logic.
Lemma search_heap_enter sh a p tp rp top xs fs ys zs pk buf frames out s:
 search_heap sh a p tp rp top xs fs ys zs pk buf frames out s=
 (enter_memory sh(ptr_workspace p)(ptr_frames p)(ptr_stats p)(model_n a)(stat_steps s)frames*
 enter_rest_heap sh a p tp rp top xs fs ys zs pk buf out s)%logic.
Proof.
 unfold search_heap,enter_memory,enter_rest_heap,workspace_fields.
 rewrite stats_repr_fields. unfold stats_fields.
 apply pred_ext;cancel.
Qed.
Definition enter_heap_frame sh a p tp rp cap seed rules top xs fs ys zs pk buf out s:assert:=
 (PROP()LOCAL(temp _p(ptr_problem p);temp _cap(Vint(Int.repr cap));
 temp _seed(Vint(Int.repr seed));temp _rules(Vint(Int.repr rules));temp _out(ptr_out p);
 lvar _top tuint tp;lvar _row tuint rp)
 SEP(enter_rest_heap sh a p tp rp top xs fs ys zs pk buf out s))%assert.
Definition entered_heap_assert sh a p tp rp cap seed budget rules depth top
 xs fs ys zs pk buf frames out s:assert:=
 (PROP()LOCAL(temp _p(ptr_problem p);temp _w(ptr_workspace p);temp _stats(ptr_stats p);
 temp _cap(Vint(Int.repr cap));temp _seed(Vint(Int.repr seed));temp _budget(Vint(Int.repr budget));
 temp _rules(Vint(Int.repr rules));temp _out(ptr_out p);temp _depth(Vint(Int.repr depth));
 temp _f(offset_val(20*(depth-1))(ptr_frames p));temp _finish(Vint Int.zero);
 lvar _top tuint tp;lvar _row tuint rp)
 SEP(search_heap sh a p tp rp top xs fs ys zs pk buf frames out(step_stats s)))%assert.
Section Proof.
Context{Espec:OracleKind}.
Lemma block_search_enter_heap:forall sh a p tp rp cap seed budget rules depth top
 xs fs ys zs pk buf frames out s,
 readable_share sh ->legal_model a ->legal_stats budget s ->stat_steps s<budget ->
 1<=depth<=model_n a ->Zlength frames=model_n a ->
 semax CCSearchContext.Delta
 (PROP()LOCAL(temp _p(ptr_problem p);temp _w(ptr_workspace p);temp _stats(ptr_stats p);
 temp _cap(Vint(Int.repr cap));temp _seed(Vint(Int.repr seed));temp _budget(Vint(Int.repr budget));
 temp _rules(Vint(Int.repr rules));temp _out(ptr_out p);temp _depth(Vint(Int.repr depth));
 lvar _top tuint tp;lvar _row tuint rp)
 SEP(search_heap sh a p tp rp top xs fs ys zs pk buf frames out s))%assert
 iteration_enter
 (normal_ret_assert(entered_heap_assert sh a p tp rp cap seed budget rules depth top
 xs fs ys zs pk buf frames out s)).
Proof.
 intros sh a p tp rp cap seed budget rules depth top xs fs ys zs pk buf frames out s
 SH Legal Stats Fuel Depth Len.
 assert(N:0<model_n a)by(unfold legal_model in Legal;lia).
 assert(Extent:20*model_n a<=Int.max_signed).
 { unfold legal_model in Legal;change Int.max_signed with 2147483647;lia. }
 set(F:=enter_heap_frame sh a p tp rp cap seed rules top xs fs ys zs pk buf out s).
 eapply semax_post' with(R':=(enter_result sh(ptr_workspace p)(ptr_frames p)(ptr_stats p)
 (model_n a)depth budget(stat_steps s)frames*F)%logic).
 2:{ eapply semax_pre with(P':=((PROP()LOCAL(temp _w(ptr_workspace p);
 temp _stats(ptr_stats p);temp _budget(Vint(Int.repr budget));temp _depth(Vint(Int.repr depth)))
 SEP(enter_memory sh(ptr_workspace p)(ptr_frames p)(ptr_stats p)(model_n a)(stat_steps s)frames))*F)%logic).
 { unfold F,enter_heap_frame;rewrite search_heap_enter;go_lowerx;normalize;cancel.
 apply andp_right;[apply prop_right;tauto|cancel]. }
 apply semax_normal_block_frame.
 { unfold F,enter_heap_frame,iteration_enter,enter_guard,enter_step,enter_reload,enter_finish,
 iteration_piece,search_main_iteration,search_fragment,main_iteration_path;auto 50 with closed. }
 apply block_search_enter;try assumption;unfold legal_stats in Stats;lia.
 }
 apply andp_left2. unfold enter_result,F,enter_heap_frame,entered_heap_assert.
 go_lowerx;normalize. rewrite search_heap_enter.
 cbn[step_stats stat_steps stat_nodes stat_pack stat_charge stat_overlap].
 unfold enter_rest_heap. normalize;cancel.
Qed.
End Proof.
Print Assumptions block_search_enter_heap.
