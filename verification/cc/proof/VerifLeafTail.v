(* Exact final phase0 tail and shared finish. Both leaf hit/miss and the
   disabled-rule path meet the same full loop invariant or valid return. *)
Require Import VST.floyd.proofauto.
Require Import CCV.ccv_core CCV.CCSearchSpecs CCV.CCSearchContext CCV.CCSearchFragments
 CCV.CCSearchMemory CCV.CCSearchHeap CCV.CCRowHeap CCV.CCLoopInvariant CCV.CCStackInvariant
 CCV.CCModel CCV.CCFunctional CCV.CCRepresentation CCV.CCJournalArray CCV.CCRootArray
 CCV.CCSearchExit CCV.CCPhaseZeroFacts CCV.CCAPIBridge CCV.CCBlockReturn
 CCV.VerifZeroKernel CCV.VerifZeroRemaining CCV.VerifLeafConditions CCV.VerifLeafConditionHeap
 CCV.VerifLeafEnabled CCV.VerifZeroClosedSuffix CCV.VerifZeroActivateIteration.
Import ListNotations. Open Scope Z_scope.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
Lemma zero_leaf_suffix_layout:zero_phase_suffix 7=
 Ssequence(Ssequence zero_leaf_conditions(Sifthenelse(Etempvar _t'8 tint)zero_leaf_enabled Sskip))
 zero_activate_guard.
Proof. reflexivity. Qed.
Section Proof.
Context{Espec:OracleKind}.
Lemma block_leaf_tail:forall sh a p tp rp cap seed budget rules s0 s path prefix g log buf xs ys zs pk frames(row:nat),
 readable_share sh ->legal_model a ->1<=cap<=model_n a ->0<=seed<=model_n a ->
 legal_stats budget s ->stats_monotone s0 s ->ghost_phase g=0%nat ->
 (row<Z.to_nat(model_m a))%nat ->(length path<Z.to_nat cap)%nat ->
 parity(Z.to_nat(model_n a))(nth row(model_h_rows a)zero_vector)(prefix_selected path(length prefix))=true ->
 loop_shape a cap seed path(prefix++[g])log buf xs ys zs pk frames ->~model_good a(decode xs) ->
 semax CCSearchContext.Delta
 (zero_row_state sh a p tp rp cap seed budget rules s path log buf xs ys zs pk frames(Z.of_nat row)0)
 (Ssequence(zero_phase_suffix 7)search_finish)
 (overridePost(search_while_invariant sh a p tp rp cap seed budget rules s0)
 (function_body_ret_assert tint(search_return sh a p tp rp cap budget s0))).
Proof.
 intros sh a p tp rp cap seed budget rules s0 s path prefix g log buf xs ys zs pk frames row
 SH Legal Cap Seed Stats Mono Phase Row Room Odd Whole Unfinished.
 pose proof(legal_model_ranges a Legal)as[NR More].
 assert(Rem:0<=cap-Z.of_nat(length path)<=Int.max_unsigned).
 { apply Nat2Z.inj_lt in Room;rewrite Z2Nat.id in Room by lia;rep_lia. }
 rewrite zero_leaf_suffix_layout;apply seq_assoc1;apply seq_assoc1.
 eapply semax_seq' with(P':=leaf_condition_state_result sh a p tp rp cap seed budget rules s
 path log buf xs ys zs pk frames(Z.of_nat row)).
 - apply block_leaf_condition_heap;assumption.
 - unfold leaf_condition_state_result;Intros enabled;destruct enabled.
   + unfold zero_row_state at 1;rewrite andp_assoc,insert_local,insert_prop;Intros.
     assert(One:cap-Z.of_nat(length path)=1)by auto.
     unfold CCSearchContext.Delta;abbreviate_semax.
     apply semax_if_seq. forward_if.
     2:{ match goal with H:Int.repr 1=Int.zero|-_=>
          let Bad:=fresh"Bad"in pose proof(f_equal Int.unsigned H)as Bad;
          change(1=0)%Z in Bad;discriminate end. }
     eapply semax_seq with(Q:=zero_leaf_closed sh a p tp rp cap seed budget rules s
     path prefix g log buf xs ys zs pk frames(Z.of_nat row)).
     * eapply semax_pre.
       2:{ apply(block_leaf_enabled sh a p tp rp cap seed budget rules s0 s path prefix g log buf xs ys zs pk frames(Z.of_nat row));assumption. }
       unfold zero_row_state;go_lowerx;normalize;cancel;try(apply andp_right;[apply prop_right;tauto|cancel]).
     * unfold zero_leaf_closed. apply semax_extract_prop;intro Closed.
       apply normal_block_enclosing_return.
       change zero_activate_guard with(zero_phase_suffix 8).
       apply(block_zero_closed_suffix_iteration 8 sh a p tp rp cap seed budget rules s0 s
       path prefix g log buf xs ys zs pk frames(Z.of_nat row));try assumption;lia.
   + unfold zero_row_state at 1;rewrite andp_assoc,insert_local,insert_prop;Intros.
     unfold CCSearchContext.Delta;abbreviate_semax.
     apply semax_if_seq. forward_if.
     { contradiction. }
     eapply semax_pre.
     2:{ apply normal_block_enclosing_return.
       apply(block_zero_activate_iteration sh a p tp rp cap seed budget rules s0 s path prefix g log buf xs ys zs pk frames row);
       assumption. }
     unfold zero_row_state;go_lowerx;normalize;cancel;try(apply andp_right;[apply prop_right;tauto|cancel]).
Qed.
End Proof.
Print Assumptions block_leaf_tail.
