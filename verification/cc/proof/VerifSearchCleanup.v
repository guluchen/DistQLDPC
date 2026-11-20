(* Actual final clear-and-EMPTY return after every canonical seed completed. *)
Require Import VST.floyd.proofauto.
Require Import CCV.ccv_core CCV.CCSearchSpecs CCV.CCSearchContext CCV.CCSearchFragments
 CCV.CCSearchHeap CCV.CCRawTopHeap CCV.CCRawTopExit CCV.CCSeedLoopState CCV.CCSearchExit CCV.CCAPIBridge
 CCV.CCRootInvariant CCV.VerifClearRawTop CCV.VerifRootPreparation.
Import ListNotations. Open Scope Z_scope.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
Definition search_cleanup:=search_fragment[SeqNext;SeqNext;SeqNext].
Lemma search_cleanup_actual:search_cleanup=Ssequence raw_top_clear_call(Sreturn(Some(Econst_int(Int.repr 0)tint))).
Proof. reflexivity. Qed.
Section Proof.
Context{Espec:OracleKind}.
Lemma block_raw_empty_return:forall sh a p tp rp cap budget top buf frames s0 s,
 legal_model a ->legal_stats budget s ->stats_monotone s0 s ->query_result a cap 0(Zrepeat 0(model_n a)) ->
 semax CCSearchContext.Delta
 (PROP()LOCAL()SEP(search_heap_raw_top sh a p tp rp top
 (Zrepeat 0(model_n a))(Zrepeat 0(model_n a))(Zrepeat 0(model_m a))(Zrepeat 0(model_l a))
 (Zrepeat 0(model_n a))buf frames(Zrepeat 0(model_n a))s))%assert
 (Sreturn(Some(Econst_int(Int.repr 0)tint)))
 (function_body_ret_assert tint(search_return sh a p tp rp cap budget s0)).
Proof.
 intros sh a p tp rp cap budget top buf frames s0 s Legal Stats Mono Query.
 pose proof(legal_model_ranges a Legal)as[NR More].
 assert(OL:Zlength(Zrepeat 0(model_n a))=model_n a)by(rewrite Zlength_Zrepeat;lia).
 pose proof(root_zero_bits(model_n a))as Bits.
 unfold CCSearchContext.Delta;abbreviate_semax.
 eapply semax_pre;[|apply semax_return].
 unfold POSTCONDITION,abbreviate. change(ret_type Delta)with tint.
 cbn[tc_expropt cast_expropt RA_return function_body_ret_assert liftx bind_ret].
 unfold liftx;cbn[eval_expr];unfold bind_ret,search_return.
 go_lowerx;normalize. Exists 0(Zrepeat 0(model_n a))s.
 sep_apply(raw_top_zero_memory sh a p tp rp top buf frames s 0 ltac:(lia)).
 entailer!.
 unfold_lift;rewrite eval_id_same;split;[reflexivity|discriminate].
Qed.
Theorem block_search_cleanup:forall sh a p tp rp cap budget rules s0,
 readable_share sh ->legal_model a ->0<=cap ->
 semax CCSearchContext.Delta(seed_loop_finished sh a p tp rp cap budget rules s0)
 search_cleanup(function_body_ret_assert tint(search_return sh a p tp rp cap budget s0)).
Proof.
 intros sh a p tp rp cap budget rules s0 SH Legal Cap.
 unfold seed_loop_finished;Intros top xs fs ys zs pk buf frames out s.
 assert(Query:query_result a cap 0(Zrepeat 0(model_n a))).
 { apply all_seeds_empty_query;assumption. }
 rewrite search_cleanup_actual.
 eapply semax_seq' with(P':=root_state_raw sh a p tp rp cap(model_n a)budget rules top
 (Zrepeat 0(model_n a))(Zrepeat 0(model_n a))(Zrepeat 0(model_m a))(Zrepeat 0(model_l a))
 (Zrepeat 0(model_n a))buf frames(Zrepeat 0(model_n a))s).
 - eapply semax_pre.
   2:{ apply(block_clear_root_state sh a p tp rp cap(model_n a)budget rules top xs fs ys zs pk buf frames out s);assumption. }
   unfold root_state_raw;go_lowerx;normalize;cancel;try(apply andp_right;[apply prop_right;tauto|cancel]).
 - eapply semax_pre.
   2:{ apply(block_raw_empty_return sh a p tp rp cap budget top buf frames s0 s);assumption. }
   unfold root_state_raw;go_lowerx;normalize;cancel;try(apply andp_right;[apply prop_right;tauto|cancel]).
Qed.
End Proof.
Print Assumptions block_raw_empty_return.
Print Assumptions block_search_cleanup.
