(* Public search_spec body proof, including actual local-stack ownership.
   Whole-program linkage, total termination and C++ refinement are separate. *)
Require Import VST.floyd.proofauto.
Require Import CCV.ccv_core CCV.CCSearchSpecs CCV.CCSearchContext CCV.CCSearchEntryState
 CCV.CCSearchExit CCV.VerifSearchBodyBlock CCV.CCAPIBridge.
Import ListNotations. Open Scope Z_scope.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
Lemma body_search:semax_body CCSearchContext.Vprog CCSearchContext.Gprog f_search search_spec.
Proof.
 start_function.
 set(Names:=(PROP()LOCAL(lvar _top tuint v_top;lvar _row tuint v_row)SEP())%assert).
 assert(Closed:closed_wrt_modvars(fn_body f_search)Names).
 { unfold Names,closed_wrt_modvars;auto with closed. }
 lazymatch goal with|-semax ?D ?P _ ?R=>change(semax D P(fn_body f_search)R)end.
 eapply semax_pre with(P':=(search_entry_state sh a p v_top v_row cap budget rules s0 *Names)%logic).
 - unfold search_entry_state,search_entry_memory,Names;go_lowerx;normalize;cancel;
   try(apply andp_right;[apply prop_right;tauto|cancel]).
 - eapply semax_post with(R':=frame_ret_assert
   (function_body_ret_assert tint(search_return sh a p v_top v_row cap budget s0))Names).
   5:{ apply semax_frame;[exact Closed|].
       apply(block_search_body sh a p v_top v_row cap budget rules s0);assumption. }
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
       rewrite(lvar_eval_lvar _top tuint v_top rho H7),(lvar_eval_lvar _row tuint v_row rho H8);cancel. }
     Exists x x0 x1. unfold search_exit_memory. sep_apply Frame. entailer!;cancel.
Qed.
Print Assumptions body_search.
