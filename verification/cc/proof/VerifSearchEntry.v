(* Entry cap handling composed with the complete actual two-loop search. *)
Require Import VST.floyd.proofauto.
Require Import CCV.ccv_core CCV.CCSearchSpecs CCV.CCSearchContext CCV.CCSearchFragments
 CCV.CCSearchEntryState CCV.VerifSearchCore CCV.VerifSearchCleanup CCV.CCSearchExit
 CCV.CCRawTopHeap CCV.CCRootInvariant CCV.CCFrameForget CCV.CCAPIBridge CCV.CCSearchResults.
Import ListNotations. Open Scope Z_scope.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
Definition search_positive_tail:=Ssequence search_clamp search_bounded_tail.
Lemma search_full_actual:fn_body f_search=Ssequence search_cap_zero search_positive_tail.
Proof. reflexivity. Qed.
Section Proof.
Context{Espec:OracleKind}.
Theorem block_search_positive_tail:forall sh a p tp rp cap budget rules s0,
 readable_share sh ->legal_model a ->1<=cap<=Int.max_unsigned ->0<=rules<=63 ->legal_stats budget s0 ->
 semax CCSearchContext.Delta(search_entry_state sh a p tp rp cap budget rules s0)
 search_positive_tail(function_body_ret_assert tint(search_return sh a p tp rp cap budget s0)).
Proof.
 intros sh a p tp rp cap budget rules s0 SH Legal Cap Rules Stats.
 pose proof(legal_model_ranges a Legal)as[NR More].
 unfold search_positive_tail,search_clamp,search_fragment,clamp_path;cbn[statement_at].
 unfold search_entry_state at 1;unfold search_entry_memory,problem_repr.
 unfold CCSearchContext.Delta;abbreviate_semax. Intros. apply seq_assoc1. forward.
 apply semax_if_seq. forward_if.
 - assert(Above:model_n a<cap)by(try rewrite !Int.unsigned_repr in * by rep_lia;lia).
   forward.
   eapply semax_post with(R':=function_body_ret_assert tint(search_return sh a p tp rp(model_n a)budget s0)).
   + cbn[RA_normal function_body_ret_assert];normalize.
   + cbn[RA_break function_body_ret_assert];normalize.
   + cbn[RA_continue function_body_ret_assert];normalize.
   + intros vl;cbn[RA_return function_body_ret_assert].
     apply andp_left2. unfold POSTCONDITION,abbreviate.
     change(bind_ret vl tint(search_return sh a p tp rp(model_n a)budget s0) |--
       bind_ret vl tint(search_return sh a p tp rp cap budget s0)).
     unfold bind_ret. destruct vl as[v|].
     * unfold liftx;intro rho;unfold_lift.
       change((!!tc_val tint v && search_return sh a p tp rp(model_n a)budget s0(make_args[ret_temp][v]rho)) |--
       (!!tc_val tint v && search_return sh a p tp rp cap budget s0(make_args[ret_temp][v]rho)))%logic.
       apply andp_derives;[apply derives_refl|]. apply search_return_clamp_cap;lia.
     * apply derives_refl.
   + eapply semax_pre.
     2:{ apply(block_search_bounded_tail sh a p tp rp(model_n a)budget rules s0);try assumption;lia. }
     unfold search_entry_state,search_entry_memory,problem_repr.
     go_lowerx;normalize;cancel;try(apply andp_right;[apply prop_right;tauto|cancel]).
 - assert(Below:cap<=model_n a)by(try rewrite !Int.unsigned_repr in * by rep_lia;lia).
   repeat apply -> semax_skip_seq.
   eapply semax_pre.
   2:{ apply(block_search_bounded_tail sh a p tp rp cap budget rules s0);try assumption;lia. }
   unfold search_entry_state,search_entry_memory,problem_repr.
   go_lowerx;normalize;cancel;try(apply andp_right;[apply prop_right;tauto|cancel]).
Qed.
End Proof.
Print Assumptions block_search_positive_tail.
