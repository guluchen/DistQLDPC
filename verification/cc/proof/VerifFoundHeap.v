(* Actual output-copy and FOUND return with full caller ownership and the
   search result assertion. The caller must prove Good and the weight bound. *)
Require Import VST.floyd.proofauto.
Require Import CCV.ccv_core CCV.CCSearchSpecs CCV.CCSearchContext CCV.CCSearchExit
 CCV.CCRowHeap CCV.CCRepresentation CCV.VerifCopyHeap CCV.VerifOutputFound CCV.VerifOutputCopy.
Import ListNotations. Open Scope Z_scope.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
Section Proof.
Context{Espec:OracleKind}.
Lemma block_found_heap:forall sh a p tp rp top row cap budget xs fs ys zs pk buf frames out s s0,
 readable_share sh ->0<=model_n a<=Int.max_signed ->Zlength xs=model_n a ->Zlength out=model_n a ->
 Forall(fun z:Z=>z=0\/z=1)xs ->legal_stats budget s ->stats_monotone s0 s ->
 model_good a(decode xs) ->output_weight a xs<=cap ->
 semax CCSearchContext.Delta
 (PROP()LOCAL(temp _p(ptr_problem p);temp _w(ptr_workspace p);temp _out(ptr_out p);
 lvar _top tuint tp;lvar _row tuint rp)
 SEP(row_heap sh a p tp rp top row xs fs ys zs pk buf frames out s))%assert
 found_branch(function_body_ret_assert tint(search_return sh a p tp rp cap budget s0)).
Proof.
 intros sh a p tp rp top row cap budget xs fs ys zs pk buf frames out s s0
 SH N XL OL Bits Stats Mono Good Weight.
 rewrite found_branch_layout.
 eapply semax_seq' with(P':=copy_heap_result sh a p tp rp top row xs fs ys zs pk buf frames s).
 - exact(block_copy_heap sh a p tp rp top row xs fs ys zs pk buf frames out s SH N XL OL Bits).
 - unfold CCSearchContext.Delta;abbreviate_semax. unfold copy_heap_result.
   eapply semax_pre;[|apply semax_return].
   unfold POSTCONDITION,abbreviate. change(ret_type Delta)with tint.
   cbn[tc_expropt cast_expropt RA_return function_body_ret_assert liftx bind_ret].
   unfold liftx. cbn[eval_expr]. unfold bind_ret,search_return.
   go_lowerx;normalize. Exists 1 xs s.
   sep_apply(row_heap_found_memory sh a p tp rp top row xs fs ys zs pk buf frames xs s).
   entailer!.
   split.
   { unfold query_result;right;right;split;[reflexivity|split;assumption]. }
   unfold_lift;rewrite eval_id_same;split;[reflexivity|discriminate].
Qed.
End Proof.
Print Assumptions block_found_heap.
