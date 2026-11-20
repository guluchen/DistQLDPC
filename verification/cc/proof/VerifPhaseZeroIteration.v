(* Complete actual phase0 branch plus shared finish under the full loop
   shape: scan, kernel/logical return, overlap, bounds, leaf and activation. *)
Require Import VST.floyd.proofauto.
Require Import CCV.ccv_core CCV.CCSearchSpecs CCV.CCSearchContext CCV.CCSearchFragments
 CCV.CCSearchMemory CCV.CCSearchHeap CCV.CCRowHeap CCV.CCLoopInvariant CCV.CCStackInvariant
 CCV.CCSearchExit CCV.CCJournalArray CCV.CCRootArray CCV.CCAPIBridge CCV.CCPhaseZeroFacts
 CCV.CCPhaseZeroStats CCV.CCStatsInvariant CCV.CCStatsFields CCV.VerifPhaseZeroEnter CCV.VerifPhaseZeroPrefix
 CCV.VerifRowScanHeap CCV.VerifZeroRemaining CCV.VerifZeroAfterRow.
Import ListNotations. Open Scope Z_scope.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
Section Proof.
Context{Espec:OracleKind}.
Lemma block_phase_zero_iteration:forall sh a p tp rp cap seed budget rules s0 s
 path prefix g log buf xs ys zs pk frames,
 readable_share sh ->legal_model a ->1<=cap<=model_n a ->0<=seed<=model_n a ->
 legal_stats budget s ->stats_monotone s0 s ->stat_nodes s<stat_steps s ->ghost_phase g=0%nat ->
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
 (Ssequence search_phase_zero search_finish)
 (overridePost(search_while_invariant sh a p tp rp cap seed budget rules s0)
 (function_body_ret_assert tint(search_return sh a p tp rp cap budget s0))).
Proof.
 intros sh a p tp rp cap seed budget rules s0 s path prefix g log buf xs ys zs pk frames
 SH Legal Cap Seed Stats Mono NodeRoom Phase Whole.
 pose proof(phase_zero_path_facts a cap seed path prefix g log buf xs ys zs pk frames Phase Whole)
 as[Nonempty[Weight[Selected Depth]]].
 assert(DRange:0<=Z.of_nat(length path)<=cap)by lia.
 assert(YL:Zlength ys=model_m a)by(unfold loop_shape in Whole;tauto).
 assert(YB:Forall(fun z:Z=>z=0\/z=1)ys)by(unfold loop_shape in Whole;tauto).
 pose proof(node_only_safe budget s Stats NodeRoom)as[NewStats[NewMono[PF[CF OF]]]].
 pose proof(stats_monotone_trans s0 s(node_only_stats s)Mono NewMono)as TotalMono.
 pose proof(legal_model_ranges a Legal)as[NR[MR[LR[KR Rest]]]].
 assert(M:0<=model_m a<=Int.max_signed)by(split;[lia|nia]).
 assert(Add:Int.add(Int.repr(stat_nodes s))(Int.repr 1)=Int.repr(stat_nodes s+1)).
 { unfold Int.add;rewrite !Int.unsigned_repr by(unfold legal_stats in Stats;rep_lia);reflexivity. }
 assert(Sub:Int.sub(Int.repr cap)(Int.repr(Z.of_nat(length path)))=Int.repr(cap-Z.of_nat(length path))).
 { unfold Int.sub;rewrite !Int.unsigned_repr by rep_lia;reflexivity. }
 unfold CCSearchContext.Delta;abbreviate_semax.
 let C:=eval cbv -[Int.repr]in(Ssequence search_phase_zero search_finish)in
 lazymatch goal with|-semax ?D ?P _ ?R=>change(semax D P C R)end.
 unfold search_heap,problem_repr,workspace_fields.
 rewrite stats_repr_fields;unfold stats_fields. Intros.
 forward. forward. rewrite Add.
 forward. rewrite Sub.
 forward. forward.
 lazymatch goal with|-semax ?D ?P _ ?R=>
 change(semax D P(Ssequence(Ssequence VerifSearchRow.row_scan zero_after_row)search_finish)R)end.
 apply seq_assoc1.
 eapply semax_seq' with(P':=row_scan_heap_result sh a p tp rp
 (active_frame_address p(model_n a)(Z.of_nat(length path)))cap seed budget rules
 (Z.of_nat(length path))(Zlength log)(cap-Z.of_nat(length path))xs
 (journal_bitmap(root_mask(model_n a)seed)log)ys zs pk buf frames(Zrepeat 0(model_n a))(node_only_stats s)).
 - eapply semax_pre.
   2:{ apply(block_row_scan_heap sh a p tp rp(active_frame_address p(model_n a)(Z.of_nat(length path)))
   cap seed budget rules(Z.of_nat(length path))(Zlength log)(cap-Z.of_nat(length path))xs
   (journal_bitmap(root_mask(model_n a)seed)log)ys zs pk buf frames(Zrepeat 0(model_n a))(node_only_stats s));assumption. }
   unfold row_heap,search_core_heap,problem_repr,workspace_fields.
   rewrite stats_repr_fields;unfold stats_fields.
   cbn[node_only_stats stat_steps stat_nodes stat_pack stat_charge stat_overlap].
   go_lowerx;normalize;cancel;try(apply andp_right;[apply prop_right;tauto|cancel]).
 - unfold row_scan_heap_result;Intros row.
 eapply semax_pre.
 2:{ apply(block_zero_after_row sh a p tp rp cap seed budget rules s0(node_only_stats s)
 path prefix g log buf xs ys zs pk frames row);assumption. }
 unfold zero_row_state;go_lowerx;normalize;cancel;try(apply andp_right;[apply prop_right;tauto|cancel]).
Qed.
End Proof.
Print Assumptions block_phase_zero_iteration.
