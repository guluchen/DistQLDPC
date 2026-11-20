(* Actual shared finish conditional when finish=1. Both phase0 and phase1
   callers must justify that no minimum target remains at the popped frame. *)
Require Import VST.floyd.proofauto.
Require Import CCV.ccv_core CCV.CCSearchSpecs CCV.CCSearchContext CCV.CCSearchFragments
 CCV.CCSearchHeap CCV.CCSearchMemory CCV.CCLoopInvariant CCV.CCStackInvariant
 CCV.CCJournalArray CCV.CCRootArray CCV.CCModel CCV.CCFunctional CCV.VerifFinishLoop.
Import ListNotations. Open Scope Z_scope.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
Section Proof.
Context{Espec:OracleKind}.
Lemma block_finish_taken:forall sh a p tp rp cap seed budget rules s0 s parent_path prefix g
 log buf xs ys zs pk frames q,
 readable_share sh ->legal_model a ->0<=seed<=model_n a ->legal_stats budget s ->stats_monotone s0 s ->
 (ghost_phase g=0%nat\/ghost_phase g=1%nat) ->
 loop_shape a cap seed(parent_path++[q])(prefix++[g])log buf xs ys zs pk frames ->
 (forall e,model_minimum a e ->(weight(Z.to_nat(model_n a))e<=Z.to_nat cap)%nat ->
 e(Z.to_nat seed)=true ->
 ~critical_at(Z.to_nat(model_n a))(model_h_rows a)(root_mask(model_n a)seed)log
 (parent_path++[q])(prefix++[g])e(length prefix)) ->
 semax CCSearchContext.Delta
 (PROP()LOCAL(temp _p(ptr_problem p);temp _w(ptr_workspace p);temp _out(ptr_out p);
 temp _stats(ptr_stats p);temp _cap(Vint(Int.repr cap));temp _seed(Vint(Int.repr seed));
 temp _budget(Vint(Int.repr budget));temp _rules(Vint(Int.repr rules));temp _finish(Vint(Int.repr 1));
 temp _depth(Vint(Int.repr(Z.of_nat(length(parent_path++[q])))));
 temp _f(active_frame_address p(model_n a)(Z.of_nat(length(parent_path++[q]))));
 lvar _top tuint tp;lvar _row tuint rp)
 SEP(search_heap sh a p tp rp(Zlength log)xs(journal_bitmap(root_mask(model_n a)seed)log)
 ys zs pk buf frames(Zrepeat 0(model_n a))s))%assert
 search_finish(normal_ret_assert(search_while_invariant sh a p tp rp cap seed budget rules s0)).
Proof.
 intros sh a p tp rp cap seed budget rules s0 s parent_path prefix g log buf xs ys zs pk frames q
 SH Legal Seed Stats Mono Kind Whole NoLast.
 unfold CCSearchContext.Delta;abbreviate_semax.
 let C:=eval cbv -[Int.repr]in search_finish in
 lazymatch goal with|-semax ?D ?P _ ?R=>change(semax D P C R)end.
 forward_if.
 2:{ pose proof(f_equal Int.unsigned H)as Bad;change(1=0)%Z in Bad;discriminate. }
 eapply semax_pre.
 2:{ exact(block_finish_loop sh a p tp rp cap seed budget rules s0 s parent_path prefix g
 log buf xs ys zs pk frames q SH Legal Seed Stats Mono Kind Whole NoLast). }
 entailer!;cancel.
Qed.
End Proof.
Print Assumptions block_finish_taken.
