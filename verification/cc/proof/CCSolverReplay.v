(* Discharge every environmental replay assumption for the linked solver
   with its VST verification entry. This lemma is about actual C steps. *)
Require Import VST.floyd.proofauto compcert.cfrontend.Clight compcert.common.Smallstep.
Require Import CCV.ccv_core CCV.CCBoundedMain CCV.CCExpandedBody CCV.CCCapGuard
 CCV.CCBodyProgram CCV.CCProgramRelation CCV.CCProgramSteps CCV.CCProgramBindings
 CCV.CCVerificationDriver CCV.CCReplayEnvironment.
Section Transfer.
Variable n:nat.
Local Notation q := (proof_driver (body_with (bounded_main n)) (fn_body guarded_distance)).
Local Notation g := (Clight.globalenv driver_prog).
Theorem original_return_replay fn fn' args m t v m':
 function_pair (Internal fn)(Internal fn') ->
 star step2 (Clight.globalenv q) (Callstate (Internal fn) args Kstop m) t (Returnstate v Kstop m') ->
 star step2 g (Callstate (Internal fn') args Kstop m) t (Returnstate v Kstop m').
Proof.
 intros F Run.
 assert (Pair:paired_state (Callstate (Internal fn) args Kstop m)(Callstate (Internal fn') args Kstop m))
 by (apply ps_in;[exact F|apply pc_stop]).
 eapply (paired_run _ _ (body_layout _ _ _) (body_addresses _ _ _)
  (all_targets driver_prog driver_search_decl driver_distance_decl all_driver_code_supported n)
  (external_environment driver_prog driver_search_decl driver_distance_decl all_driver_code_supported n))
 in Run;[|exact Pair].
 destruct Run as [actual [Steps Out]]. apply ps_stop in Out;subst;assumption.
Qed.
End Transfer.
