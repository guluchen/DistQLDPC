(* Actual row/next/phase stores restore the complete while invariant, under
   the phase0 caller's odd-row and remaining-room facts. Not all of phase0. *)
Require Import VST.floyd.proofauto.
Require Import CCV.ccv_core CCV.CCSearchSpecs CCV.CCSearchContext CCV.CCSearchMemory
 CCV.CCSearchHeap CCV.CCRowHeap CCV.CCLoopInvariant CCV.CCStackInvariant CCV.CCModel
 CCV.CCFunctional CCV.CCActivateCoverage CCV.CCActivateMemory CCV.CCActivateInvariant
 CCV.CCJournalArray CCV.CCRootArray CCV.CCAPIBridge CCV.VerifActivateFrame CCV.VerifActivateHeap.
Import ListNotations. Open Scope Z_scope.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
Section Proof.
Context{Espec:OracleKind}.
Lemma block_activate_loop:forall sh a p tp rp cap seed budget rules s0 s path prefix g
 log buf xs ys zs pk frames(row:nat),
 legal_model a ->1<=cap<=model_n a ->legal_stats budget s ->stats_monotone s0 s ->
 ghost_phase g=0%nat ->(row<Z.to_nat(model_m a))%nat ->(length path<Z.to_nat cap)%nat ->
 parity(Z.to_nat(model_n a))(nth row(model_h_rows a)zero_vector)
 (prefix_selected path(length prefix))=true ->
 loop_shape a cap seed path(prefix++[g])log buf xs ys zs pk frames ->
 semax CCSearchContext.Delta
 (PROP()LOCAL(temp _p(ptr_problem p);temp _w(ptr_workspace p);temp _out(ptr_out p);
 temp _stats(ptr_stats p);temp _cap(Vint(Int.repr cap));temp _seed(Vint(Int.repr seed));
 temp _budget(Vint(Int.repr budget));temp _rules(Vint(Int.repr rules));
 temp _depth(Vint(Int.repr(Z.of_nat(length path))));temp _finish(Vint Int.zero);
 temp _f(active_frame_address p(model_n a)(Z.of_nat(length path)));
 lvar _top tuint tp;lvar _row tuint rp)
 SEP(row_heap sh a p tp rp(Zlength log)(Z.of_nat row)xs
 (journal_bitmap(root_mask(model_n a)seed)log)ys zs pk buf frames(Zrepeat 0(model_n a))s))%assert
 zero_activate(normal_ret_assert(search_while_invariant sh a p tp rp cap seed budget rules s0)).
Proof.
 intros sh a p tp rp cap seed budget rules s0 s path prefix g log buf xs ys zs pk frames row
 Legal Cap Stats Mono Phase Row Room Odd Whole.
 pose proof(legal_model_ranges a Legal)as[NR[MR[LR[KR[HP Rest]]]]].
 assert(M:0<=model_m a<=Int.max_signed)by(split;[lia|nia]).
 assert(Range:0<=Z.of_nat row<=Int.max_signed).
 { apply Nat2Z.inj_lt in Row;rewrite Z2Nat.id in Row by lia;lia. }
 assert(Geo:stack_geometry(Z.to_nat(model_n a))(Z.to_nat(model_m a))(Z.to_nat cap)
 (model_h_rows a)path(prefix++[g])log)by(unfold loop_shape in Whole;tauto).
 assert(Len:length path=length(prefix++[g]))by(unfold stack_geometry in Geo;tauto).
 assert(Index:Z.of_nat(length path)-1=Z.of_nat(length prefix)).
 { rewrite Len,app_length,Nat2Z.inj_add;cbn;lia. }
 assert(At:0<=Z.of_nat(length prefix)<model_n a).
 { apply Nat2Z.inj_lt in Room;rewrite Z2Nat.id in Room by lia.
   rewrite Len,app_length,Nat2Z.inj_add in Room;cbn in Room;lia. }
 assert(FL:Zlength frames=model_n a).
 { assert(P:physical_stack(Z.to_nat(model_n a))(prefix++[g])frames)by(unfold loop_shape in Whole;tauto).
 unfold physical_stack in P;destruct P as[FL P];rewrite Z2Nat.id in FL by lia;assumption. }
 pose proof(loop_shape_activate a cap seed path prefix g log buf xs ys zs pk frames row
 Cap Phase Row Room Odd Whole)as NewShape.
 unfold active_frame_address;rewrite Index.
 eapply semax_post'.
 2:{ apply(block_activate_heap sh a p tp rp cap seed budget rules(Z.of_nat(length path))
 (Zlength log)(Z.of_nat(length prefix))row xs(journal_bitmap(root_mask(model_n a)seed)log)
 ys zs pk buf frames(Zrepeat 0(model_n a))s);assumption. }
 apply andp_left2;unfold activated_full_heap,search_while_invariant;go_lowerx;normalize.
 Exists path(prefix++[activated_record g row])log buf xs ys zs pk(activate_raw_frames prefix row frames)s.
 unfold activate_raw_frames.
 sep_apply(row_heap_forget sh a p tp rp(Zlength log)(Z.of_nat row)xs
 (journal_bitmap(root_mask(model_n a)seed)log)ys zs pk buf
 (upd_Znth(Z.of_nat(length prefix))frames(activate_raw(Znth(Z.of_nat(length prefix))frames)row))
 (Zrepeat 0(model_n a))s).
 normalize;cancel.
 apply andp_right;[apply prop_right;tauto|cancel].
Qed.
End Proof.
Print Assumptions block_activate_loop.
