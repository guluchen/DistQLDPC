(* Actual budget-exhaustion clear-and-return branch. No exact-distance claim is
   made on UNKNOWN. The enclosing guard/search body is a separate obligation. *)
Require Import VST.floyd.proofauto.
Require Import CCV.ccv_core CCV.CCSearchSpecs CCV.CCSearchContext CCV.CCSearchFragments
 CCV.CCSearchHeap CCV.VerifSearchEnter CCV.VerifClearHeap CCV.CCBlockReturn.
Import ListNotations. Open Scope Z_scope.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
Definition fuel_unknown_return:=match statement_at[SeqNext;ThenBranch]enter_guard with
 Some s=>s|None=>Sskip end.
Lemma fuel_unknown_layout:fuel_unknown_return=Ssequence root_clear_call
 (Sreturn(Some(Eunop Oneg(Econst_int(Int.repr 1)tint)tint))).
Proof. reflexivity. Qed.
Section Proof.
Context{Espec:OracleKind}.
Lemma block_unknown_return:forall sh a p tp rp top xs fs ys zs pk buf frames out s,
 readable_share sh ->legal_model a ->Zlength xs=model_n a ->Zlength fs=model_n a ->
 Zlength ys=model_m a ->Zlength zs=model_l a ->Zlength pk=model_n a ->Zlength out=model_n a ->
 semax CCSearchContext.Delta
 (PROP()LOCAL(temp _p(ptr_problem p);temp _w(ptr_workspace p);temp _out(ptr_out p))
 SEP(search_heap sh a p tp rp top xs fs ys zs pk buf frames out s))%assert
 fuel_unknown_return
 (function_body_ret_assert tint
 (PROP()LOCAL(temp ret_temp(Vint(Int.repr(-1))))
 SEP(search_heap sh a p tp rp top(Zrepeat 0(model_n a))(Zrepeat 0(model_n a))
 (Zrepeat 0(model_m a))(Zrepeat 0(model_l a))(Zrepeat 0(model_n a))buf frames
 (Zrepeat 0(model_n a))s))%assert).
Proof.
 intros sh a p tp rp top xs fs ys zs pk buf frames out s SH Legal XL FL YL ZL PL OL.
 rewrite fuel_unknown_layout.
 eapply semax_seq' with(P':=
 (PROP()LOCAL(temp _p(ptr_problem p);temp _w(ptr_workspace p);temp _out(ptr_out p))
 SEP(search_heap sh a p tp rp top(Zrepeat 0(model_n a))(Zrepeat 0(model_n a))
 (Zrepeat 0(model_m a))(Zrepeat 0(model_l a))(Zrepeat 0(model_n a))buf frames
 (Zrepeat 0(model_n a))s))%assert).
 - apply block_clear_heap;assumption.
 - unfold CCSearchContext.Delta;abbreviate_semax.
   eapply semax_pre;[|apply semax_return].
   unfold POSTCONDITION,abbreviate. change(ret_type Delta)with tint.
   cbn[tc_expropt cast_expropt RA_return function_body_ret_assert liftx bind_ret].
   unfold liftx. cbn[eval_expr]. unfold bind_ret. go_lowerx. normalize.
   apply andp_right.
   { apply prop_right;unfold_lift;rewrite eval_id_same;repeat split;congruence. }
   unfold tc_expr;cbn;normalize;entailer!.
Qed.
End Proof.
Print Assumptions block_unknown_return.

Require Import CCV.CCStatsFields.
Section Guard.
Context{Espec:OracleKind}.
Lemma block_exhausted_fuel_guard:forall sh a p tp rp top xs fs ys zs pk buf frames out s budget,
 readable_share sh ->legal_model a ->legal_stats budget s ->budget<=stat_steps s ->
 Zlength xs=model_n a ->Zlength fs=model_n a ->Zlength ys=model_m a ->
 Zlength zs=model_l a ->Zlength pk=model_n a ->Zlength out=model_n a ->
 semax CCSearchContext.Delta
 (PROP()LOCAL(temp _p(ptr_problem p);temp _w(ptr_workspace p);temp _out(ptr_out p);
 temp _stats(ptr_stats p);temp _budget(Vint(Int.repr budget)))
 SEP(search_heap sh a p tp rp top xs fs ys zs pk buf frames out s))%assert
 enter_guard
 (function_body_ret_assert tint
 (PROP()LOCAL(temp ret_temp(Vint(Int.repr(-1))))
 SEP(search_heap sh a p tp rp top(Zrepeat 0(model_n a))(Zrepeat 0(model_n a))
 (Zrepeat 0(model_m a))(Zrepeat 0(model_l a))(Zrepeat 0(model_n a))buf frames
 (Zrepeat 0(model_n a))s))%assert).
Proof.
 intros sh a p tp rp top xs fs ys zs pk buf frames out s budget
 SH Legal Stats Exhausted XL FL YL ZL PL OL.
 unfold CCSearchContext.Delta;abbreviate_semax.
 let C:=eval cbv -[Int.repr]in enter_guard in
 lazymatch goal with|-semax ?D ?P _ ?R=>change(semax D P C R)end.
 unfold search_heap at 1. rewrite stats_repr_fields. unfold stats_fields. Intros.
 forward. forward_if.
 2:{ unfold legal_stats in Stats;rewrite !Int.unsigned_repr in * by lia;lia. }
 eapply semax_pre with(P':=
 (PROP()LOCAL(temp _p(ptr_problem p);temp _w(ptr_workspace p);temp _out(ptr_out p))
 SEP(search_heap sh a p tp rp top xs fs ys zs pk buf frames out s))%assert).
 { unfold search_heap;rewrite stats_repr_fields;unfold stats_fields;entailer!;cancel. }
 apply(block_unknown_return sh a p tp rp top xs fs ys zs pk buf frames out s);assumption.
Qed.
End Guard.
Print Assumptions block_exhausted_fuel_guard.
