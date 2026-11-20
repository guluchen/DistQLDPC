(* Lift a finite execution of the unfolded search back to the frozen while
   loop. Stuttering for administrative statements preserves the event trace. *)
Require Import VST.floyd.proofauto compcert.common.Smallstep compcert.common.Events.
Require Import compcert.cfrontend.Clight CCV.CCSearchFragments CCV.CCBoundedMain
 CCV.CCReplayFrames CCV.CCReplayStep CCV.CCLinkedProgram CCV.ccv_core.
Section Replay.
Variable ge:Clight.genv.
Lemma replay_transition left right t next :
 supported_genv ge -> replay_state left right -> step2 ge left t next ->
 follows ge right t next.
Proof.
 intros Supported Rel Actual;destruct Rel.
 - eapply follow_regular;eassumption.
 - destruct n as [|n].
   + exfalso;eapply unreachable_read_stuck;exact Actual.
   + cbn [bounded_main] in Actual;inversion Actual;subst;try solve[intuition discriminate].
     eapply follow_test;eassumption.
 - inversion Actual;subst;try solve[intuition discriminate].
   apply follow_zero;eapply replay_regular;[exact iteration_closed|eapply replay_back;eassumption].
 - inversion Actual;subst.
   + eapply follow_one;[eapply step_internal_function;eassumption|eapply replay_regular;eassumption].
   + eapply follow_one;[eapply step_external_function;eassumption|constructor;eassumption].
 - inversion Actual;subst.
   match goal with K:replay_cont _ (Kcall _ _ _ _ _) _ |- _ =>inversion K;subst end.
   eapply follow_one;[apply step_returnstate|eapply replay_regular;[reflexivity|eassumption]].
Qed.
Theorem replay_trace start t finish : supported_genv ge ->
 star Clight.step2 ge start t finish -> forall actual,
 replay_state start actual -> follows ge actual t finish.
Proof.
 intros GE Run;induction Run;intros actual Rel.
 - apply follow_zero;assumption.
 - destruct(replay_transition _ _ _ _ GE Rel H) as [middle [Prefix Match]].
   destruct(IHRun _ Match) as [last [Suffix Out]];exists last;split;[eapply star_trans;eauto|exact Out].
Qed.
End Replay.
Lemma replay_normal_stop f e le m st :
 replay_state (State f Sskip Kstop e le m) st -> st=State f Sskip Kstop e le m.
Proof.
 intros R;inversion R;subst.
 - match goal with K:replay_cont _ Kstop _ |- _=>inversion K;reflexivity end.
 - match goal with H:bounded_main ?n=Sskip |- _=> destruct n;discriminate H end.
Qed.
Definition main_endpoint f e st :=
 (exists le m,st=State f Sskip Kstop e le m) \/ (exists v m,st=Returnstate v Kstop m).
Theorem actual_main_replays_unfolding ge n e le m t finish :
 supported_genv ge ->
 star Clight.step2 ge (State f_search (bounded_main n) Kstop e le m) t finish ->
 main_endpoint f_search e finish ->
 star Clight.step2 ge (State f_search search_main_loop Kstop e le m) t finish.
Proof.
 intros GE Run Outcome.
 destruct (replay_trace ge _ _ _ GE Run _ (replay_head false f_search n Kstop Kstop e le m replay_stop))
 as [actual [Trace Match]].
 destruct Outcome as [[l [mem ->]]|[v [mem ->]]].
 - apply replay_normal_stop in Match;subst;assumption.
 - apply replay_result_stop in Match;subst;assumption.
Qed.
