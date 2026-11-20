(* Exact overlap rejection counter increment and finish assignment. *)
Require Import VST.floyd.proofauto.
Require Import CCV.ccv_core CCV.CCSearchSpecs CCV.CCSearchContext CCV.CCSearchFragments
 CCV.CCSearchMemory CCV.CCSearchHeap CCV.CCRowHeap CCV.CCJournalArray CCV.CCRootArray
 CCV.CCStatsFields CCV.CCStatsInvariant CCV.VerifZeroRemaining.
Import ListNotations. Open Scope Z_scope.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
Definition zero_overlap_reject:=search_fragment(phase_zero_path++
 [SeqNext;SeqNext;SeqNext;SeqNext;SeqNext;SeqFirst;SeqNext;ThenBranch;SeqNext;SeqNext;ThenBranch]).
Section Proof.
Context{Espec:OracleKind}.
Lemma block_overlap_counter:forall sh a p tp rp cap seed budget rules s path log buf xs ys zs pk frames row,
 legal_stats budget s ->stat_overlap s<stat_nodes s ->
 semax CCSearchContext.Delta
 (zero_row_state sh a p tp rp cap seed budget rules s path log buf xs ys zs pk frames row 0)
 zero_overlap_reject
 (normal_ret_assert(zero_row_state sh a p tp rp cap seed budget rules(overlap_stats s)
 path log buf xs ys zs pk frames row 1)).
Proof.
 intros sh a p tp rp cap seed budget rules s path log buf xs ys zs pk frames row Stats Fresh.
 assert(Add:Int.add(Int.repr(stat_overlap s))(Int.repr 1)=Int.repr(stat_overlap s+1)).
 { unfold Int.add;rewrite !Int.unsigned_repr by(unfold legal_stats in Stats;rep_lia);reflexivity. }
 unfold zero_row_state at 1;unfold row_heap,search_core_heap.
 rewrite stats_repr_fields;unfold stats_fields. Intros.
 unfold CCSearchContext.Delta;abbreviate_semax.
 let C:=eval cbv -[Int.repr]in zero_overlap_reject in
 lazymatch goal with|-semax ?D ?P _ ?R=>change(semax D P C R)end.
 forward. forward. rewrite Add. forward.
 unfold zero_row_state,row_heap,search_core_heap.
 rewrite stats_repr_fields;unfold stats_fields.
 cbn[overlap_stats stat_steps stat_nodes stat_pack stat_charge stat_overlap].
 entailer!;cancel.
Qed.
End Proof.
Print Assumptions block_overlap_counter.
