Require Import VST.floyd.proofauto.
Require Import CCV.ccv_core CCV.CCSearchSpecs CCV.CCSearchContext CCV.CCSearchEntryState
 CCV.CCSearchExit CCV.VerifSearchBodyBlock CCV.CCAPIBridge.
Require Import CCV.CCExpandedBody CCV.CCSearchContextProof CCV.CCSearchExpansion CCV.CCBoundedMain.
Import ListNotations. Open Scope Z_scope.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
Section BodyReplacement.
Variable c:statement.
Hypothesis checked_body:forall {Espec:OracleKind} sh a p tp rp cap budget rules s0,
 readable_share sh ->legal_model a ->0<=cap<=Int.max_unsigned ->0<=rules<=63 ->legal_stats budget s0 ->
 semax CCSearchContext.Delta (search_entry_state sh a p tp rp cap budget rules s0) c
 (function_body_ret_assert tint(search_return sh a p tp rp cap budget s0)).
Lemma checked_search_entry: semax_body CCSearchContext.Vprog CCSearchContext.Gprog (with_body f_search c) search_spec.
Proof.
 unfold search_spec,NDmk_funspec',NDmk_funspec.
 split3;[reflexivity|reflexivity|].
 intros Espec ts [[[[[[a p] sh] cap] budget] rules] s0].
 simpl fn_body;simpl fn_params;simpl fn_return.
 try match goal with |- semax _ (fun rho => ?A rho * ?B rho) _ _ =>
   change (fun rho => A rho * B rho) with (A * B) end.
 simpl functors.MixVariantFunctor._functor in *;simpl rmaps.dependent_type_functor_rec;clear ts.
 try start_func_convert_precondition.
 start_function2.
 simpl app. simplify_func_tycontext. try expand_main_pre.
 lazymatch goal with |- semax ?D (fun rho => (?a rho * ?b rho)%logic) ?st ?R =>
   change (semax D (a*b)%logic st R) end.
 change (stackframe_of (with_body f_search c)) with (stackframe_of f_search).
 process_stackframe_of.
 repeat change_mapsto_gvar_to_data_at;repeat rewrite <-data_at__offset_zero;
 try simple apply start_function_aux1;repeat(apply semax_extract_PROP;intro);abbreviate_semax.
 set(Names:=(PROP()LOCAL(lvar _top tuint v_top;lvar _row tuint v_row)SEP())%assert).
 assert(Closed:closed_wrt_modvars c Names).
 { unfold Names,closed_wrt_modvars;auto with closed. }
 lazymatch goal with|-semax ?D ?P _ ?R=>change(semax D P c R)end.
 eapply semax_pre with(P':=(search_entry_state sh a p v_top v_row cap budget rules s0 *Names)%logic).
 - unfold search_entry_state,search_entry_memory,Names;go_lowerx;normalize;cancel;
   try(apply andp_right;[apply prop_right;tauto|cancel]).
 - eapply semax_post with(R':=frame_ret_assert
   (function_body_ret_assert tint(search_return sh a p v_top v_row cap budget s0))Names).
   5:{ apply semax_frame;[exact Closed|].
       apply(checked_body sh a p v_top v_row cap budget rules s0);assumption. }
   + cbn[RA_normal frame_ret_assert function_body_ret_assert];normalize.
   + cbn[RA_break frame_ret_assert function_body_ret_assert];normalize.
   + cbn[RA_continue frame_ret_assert function_body_ret_assert];normalize.
   + intros vl. unfold POSTCONDITION,abbreviate.
     cbn[RA_return frame_ret_assert function_body_ret_assert].
     unfold bind_ret;destruct vl as[v|];[|normalize].
     unfold search_return,Names;go_lowerx;normalize.
     assert(Frame:(data_at_ Tsh tuint v_top *data_at_ Tsh tuint v_row |-- stackframe_of f_search rho)%logic).
     { unfold stackframe_of;cbn[fn_vars f_search fold_right map].
       rewrite(var_block_data_at_ Tsh _top tuint),(var_block_data_at_ Tsh _row tuint)
       by(try reflexivity;auto).
       change(data_at_ Tsh tuint v_top *data_at_ Tsh tuint v_row |--
       data_at_ Tsh tuint(eval_lvar _top tuint rho) *(data_at_ Tsh tuint(eval_lvar _row tuint rho)*emp))%logic.
       rewrite(lvar_eval_lvar _top tuint v_top rho ltac:(assumption)),(lvar_eval_lvar _row tuint v_row rho ltac:(assumption));cancel. }
     Exists x x0 x1. unfold search_exit_memory. sep_apply Frame. entailer!;cancel.
Qed.
End BodyReplacement.
Theorem expanded_search_entry :
 semax_body CCSearchContext.Vprog CCSearchContext.Gprog
 (with_body f_search (body_with (bounded_main word_heads))) search_spec.
Proof.
 apply checked_search_entry;intros.
 eapply parameterized_block_search_body;try eassumption;apply expanded_main_spec.
Qed.
