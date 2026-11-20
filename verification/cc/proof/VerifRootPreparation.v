(* Full caller state for actual root preparation. The top scratch may be
   Vundef before the first root; no rule assumes an initialized value. *)
Require Import VST.floyd.proofauto.
Require Import CCV.ccv_core CCV.CCSearchSpecs CCV.CCSearchContext CCV.CCSearchFragments
 CCV.CCSearchHeap CCV.CCRawTopHeap CCV.CCRootMaskHeap CCV.CCRootArray CCV.CCAPIBridge
 CCV.CCBlockFrame CCV.VerifClearRawTop CCV.VerifRootMask.
Import ListNotations. Open Scope Z_scope.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
Definition root_state_raw sh a p tp rp cap seed budget rules top xs fs ys zs pk buf frames out s:assert:=
 (PROP()LOCAL(temp _p(ptr_problem p);temp _w(ptr_workspace p);temp _out(ptr_out p);
 temp _stats(ptr_stats p);temp _cap(Vint(Int.repr cap));temp _seed(Vint(Int.repr seed));
 temp _budget(Vint(Int.repr budget));temp _rules(Vint(Int.repr rules));lvar _top tuint tp;lvar _row tuint rp)
 SEP(search_heap_raw_top sh a p tp rp top xs fs ys zs pk buf frames out s))%assert.
Definition root_register_frame p tp rp cap seed budget rules:assert:=
 (PROP()LOCAL(temp _stats(ptr_stats p);temp _cap(Vint(Int.repr cap));temp _seed(Vint(Int.repr seed));
 temp _budget(Vint(Int.repr budget));temp _rules(Vint(Int.repr rules));lvar _top tuint tp;lvar _row tuint rp)SEP())%assert.
Definition root_mask_caller_frame sh a p tp rp cap(seed:Z)budget rules top xs ys zs pk buf frames out s:assert:=
 (PROP()LOCAL(temp _p(ptr_problem p);temp _out(ptr_out p);temp _stats(ptr_stats p);
 temp _cap(Vint(Int.repr cap));temp _budget(Vint(Int.repr budget));temp _rules(Vint(Int.repr rules));
 lvar _top tuint tp;lvar _row tuint rp)
 SEP(root_mask_rest sh a p tp rp top xs ys zs pk buf frames out s))%assert.
Section Proof.
Context{Espec:OracleKind}.
Lemma block_clear_root_state:forall sh a p tp rp cap seed budget rules top xs fs ys zs pk buf frames out s,
 readable_share sh ->legal_model a ->Zlength xs=model_n a ->Zlength fs=model_n a ->Zlength ys=model_m a ->
 Zlength zs=model_l a ->Zlength pk=model_n a ->Zlength out=model_n a ->
 semax CCSearchContext.Delta
 (root_state_raw sh a p tp rp cap seed budget rules top xs fs ys zs pk buf frames out s)
 raw_top_clear_call
 (normal_ret_assert(root_state_raw sh a p tp rp cap seed budget rules top
 (Zrepeat 0(model_n a))(Zrepeat 0(model_n a))(Zrepeat 0(model_m a))(Zrepeat 0(model_l a))
 (Zrepeat 0(model_n a))buf frames(Zrepeat 0(model_n a))s)).
Proof.
 intros sh a p tp rp cap seed budget rules top xs fs ys zs pk buf frames out s SH Legal XL FL YL ZL PL OL.
 pose(F:=root_register_frame p tp rp cap seed budget rules).
 eapply semax_post'.
 2:{ eapply semax_pre with(P':=((PROP()LOCAL(temp _p(ptr_problem p);temp _w(ptr_workspace p);temp _out(ptr_out p))
 SEP(search_heap_raw_top sh a p tp rp top xs fs ys zs pk buf frames out s))*F)%logic).
 { unfold root_state_raw,F,root_register_frame;go_lowerx;normalize;cancel;
 try(apply andp_right;[apply prop_right;tauto|cancel]). }
 apply semax_normal_block_frame.
 { unfold F,root_register_frame,raw_top_clear_call;auto 50 with closed. }
 apply block_clear_raw_top;assumption.
 }
 apply andp_left2;unfold root_state_raw,F,root_register_frame;go_lowerx;normalize;cancel;
 try(apply andp_right;[apply prop_right;tauto|cancel]).
Qed.
Lemma block_mask_root_state:forall sh a p tp rp cap seed budget rules top xs ys zs pk buf frames out s,
 readable_share sh ->legal_model a ->0<=seed<=model_n a ->
 semax CCSearchContext.Delta
 (root_state_raw sh a p tp rp cap seed budget rules top xs(root_mask(model_n a)0)ys zs pk buf frames out s)
 root_mask_block
 (normal_ret_assert(root_state_raw sh a p tp rp cap seed budget rules top xs(root_mask(model_n a)seed)ys zs pk buf frames out s)).
Proof.
 intros sh a p tp rp cap seed budget rules top xs ys zs pk buf frames out s SH Legal Seed.
 pose proof(legal_model_ranges a Legal)as[NR More].
 assert(N:0<=model_n a<=Int.max_signed)by lia.
 pose(F:=root_mask_caller_frame sh a p tp rp cap seed budget rules top xs ys zs pk buf frames out s).
 eapply semax_post' with(R':=(mask_result sh(ptr_workspace p)(ptr_forbidden p)(model_n a)seed*F)%logic).
 2:{ eapply semax_pre with(P':=((PROP()LOCAL(temp _w(ptr_workspace p);temp _seed(Vint(Int.repr seed)))
 SEP(mask_memory sh(ptr_workspace p)(ptr_forbidden p)(model_n a)0))*F)%logic).
 { unfold root_state_raw,F,root_mask_caller_frame;rewrite raw_top_heap_mask_split;
 go_lowerx;normalize;cancel;try(apply andp_right;[apply prop_right;tauto|cancel]). }
 apply semax_normal_block_frame.
 { unfold F,root_mask_caller_frame,root_mask_block;auto 50 with closed. }
 apply block_root_mask;assumption.
 }
 apply andp_left2;unfold root_state_raw,mask_result,F,root_mask_caller_frame.
 go_lowerx;normalize;rewrite raw_top_heap_mask_split;normalize;cancel;
 try(apply andp_right;[apply prop_right;tauto|cancel]).
Qed.
End Proof.
Print Assumptions block_clear_root_state.
Print Assumptions block_mask_root_state.
