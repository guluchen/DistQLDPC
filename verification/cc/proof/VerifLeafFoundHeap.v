(* Actual leaf copy and FOUND return under the complete search ownership.
   Good and weight must come from the verified leaf candidate predicate. *)
Require Import VST.floyd.proofauto.
Require Import CCV.ccv_core CCV.CCSearchSpecs CCV.CCSearchContext CCV.CCSearchFragments
 CCV.CCSearchExit CCV.CCRowHeap CCV.CCRepresentation CCV.CCCopyHeap CCV.CCBlockFrame
 CCV.VerifCopyHeap CCV.VerifOutputCopy CCV.VerifLeafOutputCopy.
Import ListNotations. Open Scope Z_scope.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
Definition leaf_found_branch:=search_fragment leaf_found_path.
Lemma leaf_found_branch_layout:leaf_found_branch=Ssequence leaf_output_copy
 (Sreturn(Some(Econst_int(Int.repr 1)tint))).
Proof. reflexivity. Qed.
Section Proof.
Context{Espec:OracleKind}.
Lemma block_leaf_copy_heap:forall sh a p tp rp top row xs fs ys zs pk buf frames out s,
 readable_share sh ->0<=model_n a<=Int.max_signed ->Zlength xs=model_n a ->Zlength out=model_n a ->
 Forall(fun z:Z=>z=0\/z=1)xs ->
 semax CCSearchContext.Delta
 (PROP()LOCAL(temp _p(ptr_problem p);temp _w(ptr_workspace p);temp _out(ptr_out p);
 lvar _top tuint tp;lvar _row tuint rp)
 SEP(row_heap sh a p tp rp top row xs fs ys zs pk buf frames out s))%assert
 leaf_output_copy(normal_ret_assert(copy_heap_result sh a p tp rp top row xs fs ys zs pk buf frames s)).
Proof.
 intros sh a p tp rp top row xs fs ys zs pk buf frames out s SH N XL OL Bits.
 set(F:=copy_heap_frame sh a p tp rp top row fs ys zs pk buf frames s).
 eapply semax_post' with(R':=(copy_result sh(ptr_problem p)(ptr_workspace p)(ptr_selected p)
 (ptr_out p)(model_n a)xs*F)%logic).
 2:{ eapply semax_pre with(P':=((PROP()LOCAL(temp _p(ptr_problem p);temp _w(ptr_workspace p);temp _out(ptr_out p))
 SEP(copy_memory sh(ptr_problem p)(ptr_workspace p)(ptr_selected p)(ptr_out p)(model_n a)xs out))*F)%logic).
 { unfold F,copy_heap_frame;rewrite row_heap_copy_split;go_lowerx;normalize;cancel.
 apply andp_right;[apply prop_right;tauto|cancel]. }
 apply semax_normal_block_frame.
 { unfold F,copy_heap_frame,leaf_output_copy;auto 50 with closed. }
 apply(block_leaf_output_copy sh(ptr_problem p)(ptr_workspace p)(ptr_selected p)(ptr_out p)(model_n a)xs out);
 assumption.
 }
 apply andp_left2. unfold copy_result,F,copy_heap_frame,copy_heap_result.
 go_lowerx;normalize. rewrite row_heap_copy_split;normalize;cancel.
Qed.
Lemma block_leaf_found_heap:forall sh a p tp rp top row cap budget xs fs ys zs pk buf frames out s s0,
 readable_share sh ->0<=model_n a<=Int.max_signed ->Zlength xs=model_n a ->Zlength out=model_n a ->
 Forall(fun z:Z=>z=0\/z=1)xs ->legal_stats budget s ->stats_monotone s0 s ->
 model_good a(decode xs) ->output_weight a xs<=cap ->
 semax CCSearchContext.Delta
 (PROP()LOCAL(temp _p(ptr_problem p);temp _w(ptr_workspace p);temp _out(ptr_out p);
 lvar _top tuint tp;lvar _row tuint rp)
 SEP(row_heap sh a p tp rp top row xs fs ys zs pk buf frames out s))%assert
 leaf_found_branch(function_body_ret_assert tint(search_return sh a p tp rp cap budget s0)).
Proof.
 intros sh a p tp rp top row cap budget xs fs ys zs pk buf frames out s s0
 SH N XL OL Bits Stats Mono Good Weight.
 rewrite leaf_found_branch_layout.
 eapply semax_seq' with(P':=copy_heap_result sh a p tp rp top row xs fs ys zs pk buf frames s).
 - exact(block_leaf_copy_heap sh a p tp rp top row xs fs ys zs pk buf frames out s SH N XL OL Bits).
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
Print Assumptions block_leaf_copy_heap.
Print Assumptions block_leaf_found_heap.
