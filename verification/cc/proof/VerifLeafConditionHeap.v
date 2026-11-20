(* Exact short-circuit conditions with complete caller heap preserved. *)
Require Import VST.floyd.proofauto.
Require Import CCV.ccv_core CCV.CCSearchSpecs CCV.CCSearchContext CCV.CCSearchFragments
 CCV.CCSearchMemory CCV.CCSearchHeap CCV.CCRowHeap CCV.CCJournalArray CCV.CCRootArray
 CCV.CCBlockFrame CCV.VerifZeroRemaining CCV.VerifLeafConditions.
Import ListNotations. Open Scope Z_scope.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
Definition leaf_condition_heap_frame sh a p tp rp cap seed budget s(path:list nat)log buf xs ys zs pk frames row:assert:=
 (PROP()LOCAL(temp _p(ptr_problem p);temp _w(ptr_workspace p);temp _out(ptr_out p);
 temp _stats(ptr_stats p);temp _cap(Vint(Int.repr cap));temp _seed(Vint(Int.repr seed));
 temp _budget(Vint(Int.repr budget));temp _depth(Vint(Int.repr(Z.of_nat(length path))));
 temp _f(active_frame_address p(model_n a)(Z.of_nat(length path)));lvar _top tuint tp;lvar _row tuint rp)
 SEP(row_heap sh a p tp rp(Zlength log)row xs(journal_bitmap(root_mask(model_n a)seed)log)
 ys zs pk buf frames(Zrepeat 0(model_n a))s))%assert.
Definition leaf_condition_state_result sh a p tp rp cap seed budget rules s path log buf xs ys zs pk frames row:assert:=
 (EX enabled:bool,!!(enabled=true ->cap-Z.of_nat(length path)=1)&&
 local(locald_denote(temp _t'8(Vint(Int.repr(if enabled then 1 else 0)))))&&
 zero_row_state sh a p tp rp cap seed budget rules s path log buf xs ys zs pk frames row 0)%logic.
Section Proof.
Context{Espec:OracleKind}.
Lemma block_leaf_condition_heap:forall sh a p tp rp cap seed budget rules s path log buf xs ys zs pk frames row,
 0<=cap-Z.of_nat(length path)<=Int.max_unsigned ->
 semax CCSearchContext.Delta
 (zero_row_state sh a p tp rp cap seed budget rules s path log buf xs ys zs pk frames row 0)
 zero_leaf_conditions
 (normal_ret_assert(leaf_condition_state_result sh a p tp rp cap seed budget rules s path log buf xs ys zs pk frames row)).
Proof.
 intros sh a p tp rp cap seed budget rules s path log buf xs ys zs pk frames row Range.
 pose(F:=leaf_condition_heap_frame sh a p tp rp cap seed budget s path log buf xs ys zs pk frames row).
 eapply semax_post' with(R':=(leaf_condition_output(cap-Z.of_nat(length path))rules*F)%logic).
 2:{ eapply semax_pre with(P':=(leaf_condition_input(cap-Z.of_nat(length path))rules*F)%logic).
 { unfold zero_row_state,leaf_condition_input,F,leaf_condition_heap_frame;go_lowerx;normalize;cancel;
 try(apply andp_right;[apply prop_right;tauto|cancel]). }
 apply semax_normal_block_frame.
 { unfold F,leaf_condition_heap_frame,zero_leaf_conditions;auto 50 with closed. }
 apply block_leaf_conditions;assumption.
 }
 apply andp_left2;unfold leaf_condition_output,F,leaf_condition_heap_frame,leaf_condition_state_result.
 Intros enabled. Exists enabled.
 unfold zero_row_state;go_lowerx;normalize;cancel;
 try(apply andp_right;[apply prop_right;tauto|cancel]).
Qed.
End Proof.
Print Assumptions block_leaf_condition_heap.
