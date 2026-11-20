(* Actual non-kernel remaining-capacity gate. A full unfinished prefix closes
   safely; otherwise finish stays zero and positive capacity remains. *)
Require Import VST.floyd.proofauto.
Require Import CCV.ccv_core CCV.CCSearchSpecs CCV.CCSearchContext CCV.CCSearchFragments
 CCV.CCSearchMemory CCV.CCSearchHeap CCV.CCRowHeap CCV.CCLoopInvariant CCV.CCStackInvariant
 CCV.CCModel CCV.CCRepresentation CCV.CCJournalArray CCV.CCRootArray CCV.CCPhaseZeroFacts
 CCV.CCAPIBridge CCV.VerifZeroKernel.
Import ListNotations. Open Scope Z_scope.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
Definition zero_remaining_else:=search_fragment(phase_zero_path++
 [SeqNext;SeqNext;SeqNext;SeqNext;SeqFirst;SeqNext;SeqNext;ElseBranch]).
Lemma zero_remaining_else_layout:zero_remaining_else=
 Sifthenelse(Ebinop Oeq(Etempvar _remaining tuint)(Econst_int(Int.repr 0)tuint)tint)
 (Sset _finish(Econst_int(Int.repr 1)tint))Sskip.
Proof. reflexivity. Qed.
Definition zero_row_state sh a p tp rp cap seed budget rules s(path:list nat)log buf xs ys zs pk frames row finish:assert:=
 (PROP()LOCAL(temp _p(ptr_problem p);temp _w(ptr_workspace p);temp _out(ptr_out p);
 temp _stats(ptr_stats p);temp _cap(Vint(Int.repr cap));temp _seed(Vint(Int.repr seed));
 temp _budget(Vint(Int.repr budget));temp _rules(Vint(Int.repr rules));
 temp _depth(Vint(Int.repr(Z.of_nat(length path))));temp _finish(Vint(Int.repr finish));
 temp _remaining(Vint(Int.repr(cap-Z.of_nat(length path))));
 temp _f(active_frame_address p(model_n a)(Z.of_nat(length path)));
 lvar _top tuint tp;lvar _row tuint rp)
 SEP(row_heap sh a p tp rp(Zlength log)row xs(journal_bitmap(root_mask(model_n a)seed)log)
 ys zs pk buf frames(Zrepeat 0(model_n a))s))%assert.
Definition zero_remaining_result sh a p tp rp cap seed budget rules s path prefix g log buf xs ys zs pk frames row:assert:=
 (EX finish:Z,
 !!((finish=0\/finish=1)/\(finish=1 ->zero_closed_top a cap seed path prefix g log)/\
 (finish=0 ->0<cap-Z.of_nat(length path)))&&
 zero_row_state sh a p tp rp cap seed budget rules s path log buf xs ys zs pk frames row finish)%logic.
Section Proof.
Context{Espec:OracleKind}.
Lemma block_zero_remaining:forall sh a p tp rp cap seed budget rules s path prefix g log buf xs ys zs pk frames row,
 legal_model a ->1<=cap<=model_n a ->ghost_phase g=0%nat ->
 loop_shape a cap seed path(prefix++[g])log buf xs ys zs pk frames ->~model_good a(decode xs) ->
 semax CCSearchContext.Delta
 (zero_row_state sh a p tp rp cap seed budget rules s path log buf xs ys zs pk frames row 0)
 zero_remaining_else
 (normal_ret_assert(zero_remaining_result sh a p tp rp cap seed budget rules s path prefix g log buf xs ys zs pk frames row)).
Proof.
 intros sh a p tp rp cap seed budget rules s path prefix g log buf xs ys zs pk frames row
 Legal Cap Phase Whole Unfinished.
 pose proof(legal_model_ranges a Legal)as[NR More].
 pose proof(phase_zero_path_facts a cap seed path prefix g log buf xs ys zs pk frames Phase Whole)
 as[Nonempty[Weight[Selected Depth]]].
 assert(Rem:0<=cap-Z.of_nat(length path)<=Int.max_unsigned)by rep_lia.
 rewrite zero_remaining_else_layout;unfold zero_row_state at 1.
 unfold CCSearchContext.Delta;abbreviate_semax.
 destruct(Z.eq_dec(cap-Z.of_nat(length path))0)as[RemZero|RemNonzero].
 - assert(Closed:zero_closed_top a cap seed path prefix g log).
   { intros e Min Within;apply(no_room_unfinished_no_critical_top a cap seed path prefix g log
     buf xs ys zs pk frames Phase Whole Unfinished ltac:(lia)e Min Within). }
   rewrite RemZero. forward_if.
   2:{ contradiction. }
   forward.
   unfold zero_remaining_result. Exists 1.
   unfold zero_row_state;rewrite RemZero.
   entailer!;try tauto;try lia;try cancel.
 - assert(Ne:Int.repr(cap-Z.of_nat(length path))<>Int.zero).
   { intro Eq;pose proof(f_equal Int.unsigned Eq)as Bad.
     rewrite Int.unsigned_repr in Bad by rep_lia.
     change(Int.unsigned Int.zero)with 0 in Bad;apply RemNonzero;lia. }
   assert(Positive:0<cap-Z.of_nat(length path))by lia.
   forward_if.
   { contradiction. }
   forward.
   unfold zero_remaining_result. Exists 0.
   unfold zero_row_state;entailer!;try tauto;try lia;try cancel.
Qed.
End Proof.
Print Assumptions block_zero_remaining.
