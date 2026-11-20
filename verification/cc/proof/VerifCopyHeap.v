(* Actual output-copy loop with the complete owned search state. Does not yet
   infer a mathematical witness; its caller must establish Good and cap. *)
Require Import VST.floyd.proofauto.
Require Import CCV.ccv_core CCV.CCSearchSpecs CCV.CCSearchContext CCV.CCRowHeap
 CCV.CCCopyHeap CCV.CCBlockFrame CCV.VerifOutputCopy.
Import ListNotations. Open Scope Z_scope.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
Definition copy_heap_frame sh a p tp rp top row fs ys zs pk buf frames s:assert:=
 (PROP()LOCAL(lvar _top tuint tp;lvar _row tuint rp)
 SEP(copy_heap_extra sh a p tp rp top row fs ys zs pk buf frames s))%assert.
Definition copy_heap_result sh a p tp rp top row xs fs ys zs pk buf frames s:assert:=
 (PROP()LOCAL(temp _p(ptr_problem p);temp _w(ptr_workspace p);temp _out(ptr_out p);
 lvar _top tuint tp;lvar _row tuint rp)
 SEP(row_heap sh a p tp rp top row xs fs ys zs pk buf frames xs s))%assert.
Section Proof.
Context{Espec:OracleKind}.
Lemma block_copy_heap:forall sh a p tp rp top row xs fs ys zs pk buf frames out s,
 readable_share sh ->0<=model_n a<=Int.max_signed ->Zlength xs=model_n a ->Zlength out=model_n a ->
 Forall(fun z:Z=>z=0\/z=1)xs ->
 semax CCSearchContext.Delta
 (PROP()LOCAL(temp _p(ptr_problem p);temp _w(ptr_workspace p);temp _out(ptr_out p);
 lvar _top tuint tp;lvar _row tuint rp)
 SEP(row_heap sh a p tp rp top row xs fs ys zs pk buf frames out s))%assert
 output_copy(normal_ret_assert(copy_heap_result sh a p tp rp top row xs fs ys zs pk buf frames s)).
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
 { unfold F,copy_heap_frame,output_copy;auto 50 with closed. }
 apply(block_output_copy sh(ptr_problem p)(ptr_workspace p)(ptr_selected p)(ptr_out p)(model_n a)xs out);
 assumption.
 }
 apply andp_left2. unfold copy_result,F,copy_heap_frame,copy_heap_result.
 go_lowerx;normalize. rewrite row_heap_copy_split;normalize;cancel.
Qed.
End Proof.
Print Assumptions block_copy_heap.
