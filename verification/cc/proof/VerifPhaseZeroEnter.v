(* Actual phase0 node increment, remaining-capacity subtraction and row scratch
   initialization. Does not prove the rest of phase0 or the complete search. *)
Require Import VST.floyd.proofauto.
Require Import CCV.ccv_core CCV.CCSearchSpecs CCV.CCSearchContext CCV.CCSearchFragments
 CCV.CCSearchHeap CCV.CCRowHeap CCV.CCPhaseZeroStats CCV.CCStatsFields CCV.CCAPIBridge.
Import ListNotations. Open Scope Z_scope.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
Definition zero_node:=search_fragment(phase_zero_path++[SeqFirst]).
Definition zero_remaining:=search_fragment(phase_zero_path++[SeqNext;SeqFirst]).
Definition zero_row_init:=search_fragment(phase_zero_path++[SeqNext;SeqNext;SeqFirst]).
Definition zero_enter_rest:=search_fragment(phase_zero_path++[SeqNext;SeqNext;SeqNext]).
Definition zero_enter:=Ssequence zero_node(Ssequence zero_remaining zero_row_init).
Lemma zero_enter_actual_layout:search_phase_zero=Ssequence zero_node
 (Ssequence zero_remaining(Ssequence zero_row_init zero_enter_rest)).
Proof. reflexivity. Qed.
Section Proof.
Context{Espec:OracleKind}.
Lemma block_phase_zero_enter:forall sh a p tp rp fp cap seed budget rules depth top
 xs fs ys zs pk buf frames out s,
 readable_share sh ->legal_model a ->legal_stats budget s ->stat_nodes s<stat_steps s ->
 0<=depth<=cap ->cap<=model_n a ->
 semax CCSearchContext.Delta
 (PROP()LOCAL(temp _p(ptr_problem p);temp _w(ptr_workspace p);temp _f fp;
 temp _depth(Vint(Int.repr depth));temp _finish(Vint Int.zero);
 temp _cap(Vint(Int.repr cap));temp _seed(Vint(Int.repr seed));temp _budget(Vint(Int.repr budget));
 temp _rules(Vint(Int.repr rules));temp _out(ptr_out p);temp _stats(ptr_stats p);
 lvar _top tuint tp;lvar _row tuint rp)
 SEP(search_heap sh a p tp rp top xs fs ys zs pk buf frames out s))%assert
 zero_enter
 (normal_ret_assert
 (PROP()LOCAL(temp _p(ptr_problem p);temp _w(ptr_workspace p);temp _f fp;
 temp _depth(Vint(Int.repr depth));temp _finish(Vint Int.zero);
 temp _remaining(Vint(Int.repr(cap-depth)));
 temp _cap(Vint(Int.repr cap));temp _seed(Vint(Int.repr seed));temp _budget(Vint(Int.repr budget));
 temp _rules(Vint(Int.repr rules));temp _out(ptr_out p);temp _stats(ptr_stats p);
 lvar _top tuint tp;lvar _row tuint rp)
 SEP(row_heap sh a p tp rp top(model_m a)xs fs ys zs pk buf frames out(node_only_stats s)))%assert).
Proof.
 intros sh a p tp rp fp cap seed budget rules depth top xs fs ys zs pk buf frames out s
 SH Legal Stats Room Depth Cap.
 pose proof(legal_model_ranges a Legal)as[NR[MR[LR[KR Rest]]]].
 pose proof Stats as Counts;unfold legal_stats in Counts.
 assert(Add:Int.add(Int.repr(stat_nodes s))(Int.repr 1)=Int.repr(stat_nodes s+1)).
 { unfold Int.add;rewrite !Int.unsigned_repr by rep_lia;reflexivity. }
 assert(Sub:Int.sub(Int.repr cap)(Int.repr depth)=Int.repr(cap-depth)).
 { unfold Int.sub;rewrite !Int.unsigned_repr by rep_lia;reflexivity. }
 unfold CCSearchContext.Delta;abbreviate_semax.
 let C:=eval cbv -[Int.repr]in zero_enter in
 lazymatch goal with|-semax ?D ?P _ ?R=>change(semax D P C R)end.
 unfold search_heap,problem_repr. rewrite stats_repr_fields;unfold stats_fields. Intros.
 forward. forward. rewrite Add.
 forward. rewrite Sub.
 forward. forward.
 unfold row_heap,search_core_heap,problem_repr.
 rewrite stats_repr_fields. cbn[node_only_stats stat_steps stat_nodes stat_pack stat_charge stat_overlap].
 unfold stats_fields;entailer!;cancel.
Qed.
End Proof.
Print Assumptions block_phase_zero_enter.
