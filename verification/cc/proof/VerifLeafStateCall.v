(* Actual leaf helper call framed by all phase0 caller locals. The helper
   owns the complete row heap; the frame owns no extra memory. *)
Require Import VST.floyd.proofauto.
Require Import CCV.ccv_core CCV.CCSearchSpecs CCV.CCSearchContext CCV.CCSearchFragments
 CCV.CCRowHeap CCV.CCSearchHeap CCV.CCSearchMemory CCV.CCLeaf CCV.CCJournalArray CCV.CCRootArray CCV.CCBlockFrame
 CCV.VerifZeroRemaining CCV.VerifLeafHeap CCV.VerifPhaseOneTail.
Import ListNotations. Open Scope Z_scope.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
Definition leaf_caller_frame a p cap seed budget rules(path:list nat):assert:=
 (PROP()LOCAL(temp _out(ptr_out p);temp _stats(ptr_stats p);temp _cap(Vint(Int.repr cap));
 temp _seed(Vint(Int.repr seed));temp _budget(Vint(Int.repr budget));temp _rules(Vint(Int.repr rules));
 temp _depth(Vint(Int.repr(Z.of_nat(length path))));temp _finish(Vint(Int.repr 0));
 temp _remaining(Vint(Int.repr(cap-Z.of_nat(length path))));
 temp _f(active_frame_address p(model_n a)(Z.of_nat(length path))))SEP())%assert.
Definition leaf_state_result sh a p tp rp cap seed budget rules s path log buf xs ys zs pk frames row:assert:=
 (EX hit:bool,EX chosen:Z,
 !!(if hit then 0<=chosen<model_n a /\
 leaf_candidate(model_n a)(model_m a)(model_l a)xs(journal_bitmap(root_mask(model_n a)seed)log)
 ys zs(model_h a)(model_lg a)chosen=true
 else forall q,0<=q<model_n a ->leaf_candidate(model_n a)(model_m a)(model_l a)xs
 (journal_bitmap(root_mask(model_n a)seed)log)ys zs(model_h a)(model_lg a)q=false)&&
 local(locald_denote(temp _t'6(Vint(Int.repr(if hit then 1 else 0)))))&&
 zero_row_state sh a p tp rp cap seed budget rules s path log buf
 (if hit then chosen_xs chosen xs else xs)
 (if hit then chosen_ys(model_n a)(model_m a)chosen(model_h a)ys else ys)
 (if hit then chosen_ys(model_n a)(model_l a)chosen(model_lg a)zs else zs)
 pk frames row 0)%logic.
Section Proof.
Context{Espec:OracleKind}.
Lemma block_leaf_state_call:forall sh a p tp rp cap seed budget rules s path log buf xs ys zs pk frames row,
 readable_share sh ->legal_model a ->Zlength xs=model_n a ->
 Zlength(journal_bitmap(root_mask(model_n a)seed)log)=model_n a ->
 Zlength ys=model_m a ->Zlength zs=model_l a ->
 Forall(fun z:Z=>z=0\/z=1)xs ->
 Forall(fun z:Z=>z=0\/z=1)(journal_bitmap(root_mask(model_n a)seed)log) ->
 Forall(fun z:Z=>z=0\/z=1)ys ->Forall(fun z:Z=>z=0\/z=1)zs ->
 semax CCSearchContext.Delta
 (zero_row_state sh a p tp rp cap seed budget rules s path log buf xs ys zs pk frames row 0)
 zero_leaf_call(normal_ret_assert(leaf_state_result sh a p tp rp cap seed budget rules s path log buf xs ys zs pk frames row)).
Proof.
 intros sh a p tp rp cap seed budget rules s path log buf xs ys zs pk frames row
 SH Legal XL FL YL ZL XB FB YB ZB.
 pose(F:=leaf_caller_frame a p cap seed budget rules path).
 eapply semax_post'.
 2:{ eapply semax_pre with(P':=((PROP()LOCAL(temp _p(ptr_problem p);temp _w(ptr_workspace p);
 lvar _top tuint tp;lvar _row tuint rp)
 SEP(row_heap sh a p tp rp(Zlength log)row xs(journal_bitmap(root_mask(model_n a)seed)log)
 ys zs pk buf frames(Zrepeat 0(model_n a))s))*F)%logic).
 { unfold zero_row_state,F,leaf_caller_frame;go_lowerx;normalize;cancel;
 try(apply andp_right;[apply prop_right;tauto|cancel]). }
 apply semax_normal_block_frame.
 { unfold F,leaf_caller_frame,zero_leaf_call;auto 50 with closed. }
 exact(block_leaf_heap sh a p tp rp(Zlength log)row xs
 (journal_bitmap(root_mask(model_n a)seed)log)ys zs pk buf frames(Zrepeat 0(model_n a))s
 SH Legal XL FL YL ZL XB FB YB ZB).
 }
 apply andp_left2;unfold leaf_state_result,F,leaf_caller_frame.
 Intros hit chosen. Exists hit chosen.
 unfold zero_row_state;go_lowerx;normalize;cancel;
 try(apply andp_right;[apply prop_right;tauto|cancel]).
Qed.
End Proof.
Print Assumptions block_leaf_state_call.
