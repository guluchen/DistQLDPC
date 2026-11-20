(* Once finish=1, the actual remaining phase0 guards skip all mutating calls
   and frame writes. This proves that early safe closure reaches shared finish. *)
Require Import VST.floyd.proofauto.
Require Import CCV.ccv_core CCV.CCSearchSpecs CCV.CCSearchContext CCV.CCSearchFragments
 CCV.CCRowHeap CCV.CCSearchMemory CCV.CCJournalArray CCV.CCRootArray CCV.CCBlockFrame
 CCV.VerifZeroRemaining.
Import ListNotations. Open Scope Z_scope.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
Definition zero_phase_tail:=search_fragment(phase_zero_path++
 [SeqNext;SeqNext;SeqNext;SeqNext;SeqNext]).
Lemma zero_phase_tail_not_skip:zero_phase_tail<>Sskip.
Proof. discriminate. Qed.
Definition finish_one_frame:assert:=(PROP()LOCAL(temp _finish(Vint(Int.repr 1)))SEP())%assert.
Ltac closed_guard_false :=
 first[solve[contradiction]|solve[congruence]|
 match goal with H:Int.repr 1=Int.zero|-_=>
   let Bad:=fresh "Bad" in pose proof(f_equal Int.unsigned H)as Bad;
   change(1=0)%Z in Bad;discriminate end].
Section Proof.
Context{Espec:OracleKind}.
Lemma block_zero_tail_closed_empty:
 semax CCSearchContext.Delta finish_one_frame zero_phase_tail(normal_ret_assert finish_one_frame).
Proof.
 unfold CCSearchContext.Delta;abbreviate_semax.
 unfold finish_one_frame.
 let C:=eval cbv -[Int.repr]in zero_phase_tail in
 lazymatch goal with|-semax ?D ?P _ ?R=>change(semax D P C R)end.
 repeat first[closed_guard_false|progress(apply seq_assoc1)|progress forward|progress(apply semax_if_seq)|progress forward_if].
 all:unfold finish_one_frame;entailer!.
Qed.
End Proof.
Definition zero_tail_rest sh a p tp rp cap seed budget rules s(path:list nat)log buf xs ys zs pk frames row:assert:=
 (PROP()LOCAL(temp _p(ptr_problem p);temp _w(ptr_workspace p);temp _out(ptr_out p);
 temp _stats(ptr_stats p);temp _cap(Vint(Int.repr cap));temp _seed(Vint(Int.repr seed));
 temp _budget(Vint(Int.repr budget));temp _rules(Vint(Int.repr rules));
 temp _depth(Vint(Int.repr(Z.of_nat(length path))));
 temp _remaining(Vint(Int.repr(cap-Z.of_nat(length path))));
 temp _f(active_frame_address p(model_n a)(Z.of_nat(length path)));
 lvar _top tuint tp;lvar _row tuint rp)
 SEP(row_heap sh a p tp rp(Zlength log)row xs(journal_bitmap(root_mask(model_n a)seed)log)
 ys zs pk buf frames(Zrepeat 0(model_n a))s))%assert.
Lemma zero_tail_closed_intro sh a p tp rp cap seed budget rules s path log buf xs ys zs pk frames row:
 zero_row_state sh a p tp rp cap seed budget rules s path log buf xs ys zs pk frames row 1 |--
 (finish_one_frame*zero_tail_rest sh a p tp rp cap seed budget rules s path log buf xs ys zs pk frames row)%logic.
Proof.
 unfold zero_row_state,finish_one_frame,zero_tail_rest;go_lowerx;normalize;cancel;
 try(apply andp_right;[apply prop_right;tauto|cancel]).
Qed.
Lemma zero_tail_closed_elim sh a p tp rp cap seed budget rules s path log buf xs ys zs pk frames row:
 (finish_one_frame*zero_tail_rest sh a p tp rp cap seed budget rules s path log buf xs ys zs pk frames row)%logic |--
 zero_row_state sh a p tp rp cap seed budget rules s path log buf xs ys zs pk frames row 1.
Proof.
 unfold zero_row_state,finish_one_frame,zero_tail_rest;go_lowerx;normalize;cancel;
 try(apply andp_right;[apply prop_right;tauto|cancel]).
Qed.
Section Heap.
Context{Espec:OracleKind}.
Lemma block_zero_tail_closed:forall sh a p tp rp cap seed budget rules s path log buf xs ys zs pk frames row,
 semax CCSearchContext.Delta
 (zero_row_state sh a p tp rp cap seed budget rules s path log buf xs ys zs pk frames row 1)
 zero_phase_tail
 (normal_ret_assert(zero_row_state sh a p tp rp cap seed budget rules s path log buf xs ys zs pk frames row 1)).
Proof.
 intros.
 eapply semax_post' with(R':=(finish_one_frame*zero_tail_rest sh a p tp rp cap seed budget rules s
 path log buf xs ys zs pk frames row)%logic).
 - apply andp_left2;apply zero_tail_closed_elim.
 - eapply semax_pre;[apply andp_left2;apply zero_tail_closed_intro|].
   apply semax_normal_block_frame.
   + unfold zero_tail_rest,zero_phase_tail;auto 50 with closed.
   + apply block_zero_tail_closed_empty.
Qed.
End Heap.
Print Assumptions block_zero_tail_closed.
