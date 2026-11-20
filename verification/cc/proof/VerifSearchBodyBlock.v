(* Actual complete search body under explicit owned stack scratch cells. *)
Require Import VST.floyd.proofauto.
Require Import CCV.ccv_core CCV.CCSearchSpecs CCV.CCSearchContext CCV.CCSearchFragments
 CCV.CCSearchEntryState CCV.VerifSearchEntry CCV.VerifSearchCleanup CCV.CCSearchExit
 CCV.CCSearchHeap CCV.CCRawTopHeap CCV.CCRootInvariant CCV.CCFrameForget CCV.CCAPIBridge CCV.CCSearchResults.
Import ListNotations. Open Scope Z_scope.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
Section Proof.
Context{Espec:OracleKind}.
Theorem block_search_body:forall sh a p tp rp cap budget rules s0,
 readable_share sh ->legal_model a ->0<=cap<=Int.max_unsigned ->0<=rules<=63 ->legal_stats budget s0 ->
 semax CCSearchContext.Delta(search_entry_state sh a p tp rp cap budget rules s0)
 (fn_body f_search)(function_body_ret_assert tint(search_return sh a p tp rp cap budget s0)).
Proof.
 intros sh a p tp rp cap budget rules s0 SH Legal Cap Rules Stats.
 pose proof(legal_model_ranges a Legal)as[NR More].
 assert(Mono:stats_monotone s0 s0)by(unfold stats_monotone;lia).
 rewrite search_full_actual. unfold search_cap_zero,search_fragment,cap_zero_path;cbn[statement_at].
 unfold search_entry_state at 1. unfold CCSearchContext.Delta;abbreviate_semax.
 apply semax_if_seq. forward_if.
 - assert(Zero:cap=0)by(try rewrite !Int.unsigned_repr in * by rep_lia;lia). subst cap.
   assert(Query:query_result a 0 0(Zrepeat 0(model_n a))).
   { right;left;repeat split;try reflexivity. apply zero_cap_empty. }
   eapply semax_pre.
   2:{ eapply semax_seq with(Q:=FF).
       - apply(block_raw_empty_return sh a p tp rp 0 budget Vundef(root_buf(model_n a))
        (Zrepeat(default_frame:frame_value)(model_n a))s0 s0);assumption.
       - apply semax_ff. }
   rewrite <-entry_memory_raw. go_lowerx;normalize;cancel;try(apply andp_right;[apply prop_right;tauto|cancel]).
 - assert(Positive:1<=cap)by(try rewrite !Int.unsigned_repr in * by rep_lia;lia).
   repeat apply -> semax_skip_seq. eapply semax_pre.
   2:{ apply(block_search_positive_tail sh a p tp rp cap budget rules s0);try assumption;lia. }
   unfold search_entry_state;go_lowerx;normalize;cancel;try(apply andp_right;[apply prop_right;tauto|cancel]).
Qed.
End Proof.
Print Assumptions block_search_body.
