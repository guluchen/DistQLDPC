(* Exact finish/rule short circuit for the overlap caller, with full heap. *)
Require Import VST.floyd.proofauto.
Require Import CCV.ccv_core CCV.CCSearchSpecs CCV.CCSearchContext CCV.CCSearchFragments
 CCV.CCSearchMemory CCV.CCSearchHeap CCV.CCRowHeap CCV.CCJournalArray CCV.CCRootArray
 CCV.VerifZeroRemaining.
Import ListNotations. Open Scope Z_scope.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
Definition zero_overlap_conditions:=search_fragment(phase_zero_path++
 [SeqNext;SeqNext;SeqNext;SeqNext;SeqNext;SeqFirst;SeqFirst]).
Definition overlap_condition_result sh a p tp rp cap seed budget rules s path log buf xs ys zs pk frames row:assert:=
 (EX enabled:bool,local(locald_denote(temp _t'3(Vint(Int.repr(if enabled then 1 else 0)))))&&
 zero_row_state sh a p tp rp cap seed budget rules s path log buf xs ys zs pk frames row 0)%logic.
Section Proof.
Context{Espec:OracleKind}.
Lemma block_overlap_conditions:forall sh a p tp rp cap seed budget rules s path log buf xs ys zs pk frames row,
 semax CCSearchContext.Delta
 (zero_row_state sh a p tp rp cap seed budget rules s path log buf xs ys zs pk frames row 0)
 zero_overlap_conditions
 (normal_ret_assert(overlap_condition_result sh a p tp rp cap seed budget rules s path log buf xs ys zs pk frames row)).
Proof.
 intros.
 unfold zero_row_state at 1.
 unfold CCSearchContext.Delta;abbreviate_semax.
 let C:=eval cbv -[Int.repr]in zero_overlap_conditions in
 lazymatch goal with|-semax ?D ?P _ ?R=>change(semax D P C R)end.
 forward_if.
 2:{ contradiction. }
 destruct(Int.eq(Int.repr(Z.land rules 8))(Int.repr 0))eqn:Flag.
 - forward. unfold overlap_condition_result. Exists false.
   unfold zero_row_state;rewrite insert_local;entailer!. rewrite Flag;reflexivity.
 - forward. unfold overlap_condition_result. Exists true.
   unfold zero_row_state;rewrite insert_local;entailer!. rewrite Flag;reflexivity.
Qed.
End Proof.
Print Assumptions block_overlap_conditions.
