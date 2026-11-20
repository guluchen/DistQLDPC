(* Actual node/remaining/row-init prefix composed with the actual syndrome
   scan. Exact frozen substatements; the rest of phase0 remains unproved. *)
Require Import VST.floyd.proofauto.
Require Import CCV.ccv_core CCV.CCSearchFragments CCV.CCSearchSpecs CCV.CCSearchContext CCV.CCSearchHeap
 CCV.CCRowHeap CCV.CCPhaseZeroStats CCV.CCAPIBridge CCV.VerifPhaseZeroEnter
 CCV.VerifRowScanHeap CCV.VerifSearchRow.
Import ListNotations. Open Scope Z_scope.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
Definition zero_prefix:=Ssequence zero_enter row_scan.
Definition zero_after_row:=search_fragment(phase_zero_path++[SeqNext;SeqNext;SeqNext;SeqNext]).
Lemma zero_prefix_source_layout:search_phase_zero=Ssequence zero_node
 (Ssequence zero_remaining(Ssequence zero_row_init(Ssequence row_scan zero_after_row))).
Proof. reflexivity. Qed.
Section Proof.
Context{Espec:OracleKind}.
Lemma block_phase_zero_prefix:forall sh a p tp rp fp cap seed budget rules depth top
 xs fs ys zs pk buf frames out s,
 readable_share sh ->legal_model a ->legal_stats budget s ->stat_nodes s<stat_steps s ->
 0<=depth<=cap ->cap<=model_n a ->Zlength ys=model_m a ->Forall(fun z:Z=>z=0\/z=1)ys ->
 semax CCSearchContext.Delta
 (PROP()LOCAL(temp _p(ptr_problem p);temp _w(ptr_workspace p);temp _f fp;
 temp _depth(Vint(Int.repr depth));temp _finish(Vint Int.zero);
 temp _cap(Vint(Int.repr cap));temp _seed(Vint(Int.repr seed));temp _budget(Vint(Int.repr budget));
 temp _rules(Vint(Int.repr rules));temp _out(ptr_out p);temp _stats(ptr_stats p);
 lvar _top tuint tp;lvar _row tuint rp)
 SEP(search_heap sh a p tp rp top xs fs ys zs pk buf frames out s))%assert
 zero_prefix
 (normal_ret_assert(row_scan_heap_result sh a p tp rp fp cap seed budget rules depth top(cap-depth)
 xs fs ys zs pk buf frames out(node_only_stats s))).
Proof.
 intros sh a p tp rp fp cap seed budget rules depth top xs fs ys zs pk buf frames out s
 SH Legal Stats Room Depth Cap YL YB.
 pose proof(legal_model_ranges a Legal)as[NR[MR[LR[KR[HP Rest]]]]].
 assert(M:0<=model_m a<=Int.max_signed)by(split;[lia|nia]).
 unfold zero_prefix.
 eapply semax_seq' with(P':=
 (PROP()LOCAL(temp _p(ptr_problem p);temp _w(ptr_workspace p);temp _f fp;
 temp _depth(Vint(Int.repr depth));temp _finish(Vint Int.zero);
 temp _remaining(Vint(Int.repr(cap-depth)));
 temp _cap(Vint(Int.repr cap));temp _seed(Vint(Int.repr seed));temp _budget(Vint(Int.repr budget));
 temp _rules(Vint(Int.repr rules));temp _out(ptr_out p);temp _stats(ptr_stats p);
 lvar _top tuint tp;lvar _row tuint rp)
 SEP(row_heap sh a p tp rp top(model_m a)xs fs ys zs pk buf frames out(node_only_stats s)))%assert).
 - apply block_phase_zero_enter;assumption.
 - eapply semax_pre.
   2: exact(block_row_scan_heap sh a p tp rp fp cap seed budget rules depth top(cap-depth)
 xs fs ys zs pk buf frames out(node_only_stats s) SH M YL YB).
   go_lowerx;normalize;cancel.
Qed.
End Proof.
Print Assumptions block_phase_zero_prefix.
