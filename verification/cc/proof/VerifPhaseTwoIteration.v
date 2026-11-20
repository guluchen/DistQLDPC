(* Actual selected phase2 branch and shared finish continuation. The finish
   register is framed with emp, preserving exact caller ownership. This is not
   a complete dispatch, while, seed-loop or whole-search theorem. *)
Require Import VST.floyd.proofauto.
Require Import CCV.ccv_core CCV.CCSearchSpecs CCV.CCSearchContext CCV.CCSearchFragments
 CCV.CCSearchMemory CCV.CCSearchHeap CCV.CCLoopInvariant CCV.CCStackInvariant
 CCV.CCJournalArray CCV.CCRootArray CCV.CCBlockFrame CCV.VerifPhaseTwoLoop
 CCV.VerifFinishSkip.
Import ListNotations. Open Scope Z_scope.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
Section Proof.
Context{Espec:OracleKind}.
Lemma block_phase_two_iteration:forall sh a p tp rp cap seed budget rules s0 s
 path prefix g log buf xs ys zs pk frames,
 readable_share sh ->legal_model a ->0<=seed<=model_n a ->0<=rules<=63 ->
 legal_stats budget s ->stats_monotone s0 s ->ghost_phase g=2%nat ->
 loop_shape a cap seed path(prefix++[g])log buf xs ys zs pk frames ->
 semax CCSearchContext.Delta
 (PROP()LOCAL(temp _p(ptr_problem p);temp _w(ptr_workspace p);
 temp _f(active_frame_address p(model_n a)(Z.of_nat(length path)));
 temp _depth(Vint(Int.repr(Z.of_nat(length path))));temp _finish(Vint Int.zero);
 temp _cap(Vint(Int.repr cap));temp _seed(Vint(Int.repr seed));temp _budget(Vint(Int.repr budget));
 temp _rules(Vint(Int.repr rules));temp _out(ptr_out p);temp _stats(ptr_stats p);
 lvar _top tuint tp;lvar _row tuint rp)
 SEP(search_heap sh a p tp rp(Zlength log)xs(journal_bitmap(root_mask(model_n a)seed)log)
 ys zs pk buf frames(Zrepeat 0(model_n a))s))%assert
 (Ssequence search_phase_two search_finish)
 (normal_ret_assert(search_while_invariant sh a p tp rp cap seed budget rules s0)).
Proof.
 intros sh a p tp rp cap seed budget rules s0 s path prefix g log buf xs ys zs pk frames
 SH Legal Seed Rules Stats Mono Phase Whole.
 set(P2:=(PROP()LOCAL(temp _p(ptr_problem p);temp _w(ptr_workspace p);
 temp _f(active_frame_address p(model_n a)(Z.of_nat(length path)));
 temp _depth(Vint(Int.repr(Z.of_nat(length path))));
 temp _cap(Vint(Int.repr cap));temp _seed(Vint(Int.repr seed));temp _budget(Vint(Int.repr budget));
 temp _rules(Vint(Int.repr rules));temp _out(ptr_out p);temp _stats(ptr_stats p);
 lvar _top tuint tp;lvar _row tuint rp)
 SEP(search_heap sh a p tp rp(Zlength log)xs(journal_bitmap(root_mask(model_n a)seed)log)
 ys zs pk buf frames(Zrepeat 0(model_n a))s))%assert).
 eapply semax_seq' with(P':=(search_while_invariant sh a p tp rp cap seed budget rules s0&&finish_zero)%logic).
 - eapply semax_post' with(R':=(search_while_invariant sh a p tp rp cap seed budget rules s0*finish_zero_frame)%logic).
   + apply andp_left2;apply finish_zero_frame_elim.
   + eapply semax_pre with(P':=(P2*finish_zero_frame)%logic).
     { eapply derives_trans;[|apply finish_zero_frame_intro].
       unfold P2,finish_zero;go_lowerx;normalize;entailer!. }
     apply semax_normal_block_frame.
     { unfold finish_zero_frame,search_phase_two;auto 50 with closed. }
     unfold P2.
     apply(block_phase_two_loop sh a p tp rp cap seed budget rules s0 s
     path prefix g log buf xs ys zs pk frames);assumption.
 - apply block_finish_skip.
Qed.
End Proof.
Print Assumptions block_phase_two_iteration.
