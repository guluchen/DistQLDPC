(* Full bounded search tail: initialize, exhaust canonical roots, clear/EMPTY. *)
Require Import VST.floyd.proofauto.
Require Import CCV.ccv_core CCV.CCSearchSpecs CCV.CCSearchContext CCV.CCSearchFragments
 CCV.CCSearchEntryState CCV.VerifSearchSeedInit CCV.CCSeedLoopState CCV.VerifSeedLoop
 CCV.VerifSearchCleanup CCV.CCSearchExit.
Import ListNotations. Open Scope Z_scope.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
Definition search_bounded_tail:=search_fragment[SeqNext;SeqNext].
Lemma search_bounded_tail_actual:search_bounded_tail=
 Ssequence(Ssequence search_seed_init search_seed_loop)search_cleanup.
Proof. reflexivity. Qed.
Section Proof.
Context{Espec:OracleKind}.
Theorem block_search_bounded_tail:forall sh a p tp rp cap budget rules s0,
 readable_share sh ->legal_model a ->1<=cap<=model_n a ->0<=rules<=63 ->legal_stats budget s0 ->
 semax CCSearchContext.Delta(search_entry_state sh a p tp rp cap budget rules s0)
 search_bounded_tail(function_body_ret_assert tint(search_return sh a p tp rp cap budget s0)).
Proof.
 intros sh a p tp rp cap budget rules s0 SH Legal Cap Rules Stats.
 rewrite search_bounded_tail_actual. apply seq_assoc1.
 eapply semax_seq' with(P':=seed_loop_invariant sh a p tp rp cap budget rules s0).
 - apply block_search_seed_init;assumption.
 - eapply semax_seq with(Q:=seed_loop_finished sh a p tp rp cap budget rules s0).
   + apply block_seed_loop;assumption.
   + apply block_search_cleanup;try assumption;lia.
Qed.
End Proof.
Print Assumptions block_search_bounded_tail.
