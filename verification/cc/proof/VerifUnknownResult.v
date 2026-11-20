(* The actual verified budget return satisfies the complete search UNKNOWN
   result contract. No distance or lower bound is asserted on UNKNOWN. *)
Require Import VST.floyd.proofauto.
Require Import CCV.ccv_core CCV.CCSearchSpecs CCV.CCSearchContext CCV.CCSearchHeap
 CCV.CCSearchExit CCV.CCAPIBridge CCV.CCBoundsLoop CCV.CCReturnCompose
 CCV.VerifSearchEnter CCV.VerifSearchUnknown.
Import ListNotations. Open Scope Z_scope.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
Definition unknown_cleared_post sh a p tp rp top buf frames s:assert:=
 (PROP()LOCAL(temp ret_temp(Vint(Int.repr(-1))))
 SEP(search_heap sh a p tp rp top(Zrepeat 0(model_n a))(Zrepeat 0(model_n a))
 (Zrepeat 0(model_m a))(Zrepeat 0(model_l a))(Zrepeat 0(model_n a))buf frames
 (Zrepeat 0(model_n a))s))%assert.
Lemma unknown_cleared_result sh a p tp rp top buf frames s cap budget s0:
 legal_model a ->legal_stats budget s ->stats_monotone s0 s ->
 unknown_cleared_post sh a p tp rp top buf frames s |--search_return sh a p tp rp cap budget s0.
Proof.
 intros Legal Stats Mono.
 pose proof(legal_model_ranges a Legal)as[NR More].
 assert(Len:Zlength(Zrepeat 0(model_n a))=model_n a)by(rewrite Zlength_Zrepeat;lia).
 pose proof(zero_packed_bits(model_n a))as Bits.
 assert(Query:query_result a cap(-1)(Zrepeat 0(model_n a)))by(left;split;reflexivity).
 unfold unknown_cleared_post,search_return;go_lowerx;normalize.
 Exists(-1)(Zrepeat 0(model_n a))s.
 sep_apply(search_heap_zero_memory sh a p tp rp top buf frames s(-1)ltac:(lia)).
 entailer!.
Qed.
Section Proof.
Context{Espec:OracleKind}.
Lemma block_unknown_search_result:forall sh a p tp rp top xs fs ys zs pk buf frames out s cap budget s0,
 readable_share sh ->legal_model a ->legal_stats budget s ->stats_monotone s0 s ->
 Zlength xs=model_n a ->Zlength fs=model_n a ->Zlength ys=model_m a ->
 Zlength zs=model_l a ->Zlength pk=model_n a ->Zlength out=model_n a ->
 semax CCSearchContext.Delta
 (PROP()LOCAL(temp _p(ptr_problem p);temp _w(ptr_workspace p);temp _out(ptr_out p))
 SEP(search_heap sh a p tp rp top xs fs ys zs pk buf frames out s))%assert
 fuel_unknown_return(function_body_ret_assert tint(search_return sh a p tp rp cap budget s0)).
Proof.
 intros sh a p tp rp top xs fs ys zs pk buf frames out s cap budget s0
 SH Legal Stats Mono XL FL YL ZL PL OL.
 eapply function_block_post with(PostOld:=unknown_cleared_post sh a p tp rp top buf frames s).
 - apply unknown_cleared_result;assumption.
 - unfold unknown_cleared_post;apply block_unknown_return;assumption.
Qed.
Lemma block_exhausted_guard_result:forall sh a p tp rp top xs fs ys zs pk buf frames out s cap budget s0,
 readable_share sh ->legal_model a ->legal_stats budget s ->stats_monotone s0 s ->
 budget<=stat_steps s ->Zlength xs=model_n a ->Zlength fs=model_n a ->Zlength ys=model_m a ->
 Zlength zs=model_l a ->Zlength pk=model_n a ->Zlength out=model_n a ->
 semax CCSearchContext.Delta
 (PROP()LOCAL(temp _p(ptr_problem p);temp _w(ptr_workspace p);temp _out(ptr_out p);
 temp _stats(ptr_stats p);temp _budget(Vint(Int.repr budget)))
 SEP(search_heap sh a p tp rp top xs fs ys zs pk buf frames out s))%assert
 enter_guard(function_body_ret_assert tint(search_return sh a p tp rp cap budget s0)).
Proof.
 intros sh a p tp rp top xs fs ys zs pk buf frames out s cap budget s0
 SH Legal Stats Mono Exhausted XL FL YL ZL PL OL.
 eapply function_block_post with(PostOld:=unknown_cleared_post sh a p tp rp top buf frames s).
 - apply unknown_cleared_result;assumption.
 - unfold unknown_cleared_post;apply block_exhausted_fuel_guard;assumption.
Qed.
End Proof.
Print Assumptions block_unknown_search_result.
Print Assumptions block_exhausted_guard_result.
