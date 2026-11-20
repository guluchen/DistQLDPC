(* All helper-termination premises for the original complete iteration are
   discharged. Safety of the proof-only depth expansion eliminates blocking. *)
Require Import VST.floyd.proofauto compcert.cfrontend.Clight compcert.common.Smallstep.
Require Import CCV.ccv_core CCV.CCSearchFragments CCV.CCReplayMain CCV.CCReplayFrames
 CCV.CCRestoreSettles CCV.CCStructuredRuns CCV.CCScanFrames CCV.CCIterationScans
 CCV.CCBoundedMain CCV.CCInternalFinish CCV.CCLinkedProgram.
Local Notation ge := (Clight.globalenv linked_prog).
Lemma complete_iteration_framed e : search_locals e -> framed ge f_search e search_main_iteration.
Proof. intro Locals;apply actual_iteration_scans;[assumption|apply restore_settles]. Qed.
Lemma unfolded_framed e n : search_locals e -> framed ge f_search e (bounded_main n).
Proof.
 intro Locals;induction n as [|n IH];cbn [bounded_main];[apply framed_set|].
 apply framed_if;[apply framed_seq;[apply complete_iteration_framed;assumption|exact IH]|apply framed_skip].
Qed.
Theorem original_loop_from_safe_expansion n e l m :
 search_locals e -> internal_levels ge (State f_search (bounded_main n) Kstop e l m) ->
 exists t finish,star Clight.step2 ge (State f_search search_main_loop Kstop e l m) t finish /\
 main_endpoint f_search e finish.
Proof.
 intros Locals Safe.
 assert (Done:settles ge (State f_search (bounded_main n) Kstop e l m) (main_endpoint f_search e)).
 { eapply (unfolded_framed e n Locals l);[reflexivity| | |].
   - intros l' m' _;apply settled;left;eauto.
   - intros l' m' _;eapply blocked_settles;[constructor;reflexivity|].
     intros t next T;inversion T;subst;intuition discriminate.
   - intros v m';apply settled;right;eauto. }
 destruct (internal_levels_finish ge _ _ Safe Done) as [t [finish [Run Out]]].
 exists t,finish;split;[eapply actual_main_replays_unfolding;[apply linked_supported|exact Run|exact Out]|exact Out].
Qed.
