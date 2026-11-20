(* Every ordinary transition of the unfolded computation has a finite
   trace-preserving replay by the real loop. Register files and heap bytes
   are identical at every synchronized point, including callee returns. *)
Require Import VST.floyd.proofauto compcert.common.Smallstep compcert.common.Events.
Require Import compcert.cfrontend.Clight CCV.CCInternalPaths CCV.CCBoundedMain
 CCV.CCSearchFragments CCV.CCTerminateMainLoop CCV.CCReplayFrames.
Section Replay.
Variable ge:Clight.genv.
Definition follows (from:Clight.state) t (to:Clight.state) :=
 exists next,star Clight.step2 ge from t next /\ replay_state to next.
Lemma follow_one from t to next : Clight.step2 ge from t next ->
 replay_state to next -> follows from t to.
Proof. intros;exists next;split;[apply star_one|];assumption. Qed.
Lemma follow_zero from to : replay_state to from -> follows from E0 to.
Proof. intros;exists from;split;[apply star_refl|assumption]. Qed.
Ltac silent := eapply star_step with (t1:=E0) (t2:=E0);[| |reflexivity].
Lemma follow_test loop f n k k' e le m v yes :
 replay_cont loop k k' ->eval_expr ge e le m depth_guard v ->
 Cop.bool_val v (typeof depth_guard) m=Some yes ->
 follows (State f search_main_loop k' e le m) E0
  (State f (if yes then (Ssequence search_main_iteration (bounded_main n)) else Sskip) k e le m).
Proof.
 intros K Ev T;destruct yes.
 - exists (State f search_main_iteration (main_iteration_cont k') e le m);split;[|econstructor;eauto].
   rewrite operational_main_layout;silent;[apply step_loop|];silent;[apply step_seq|].
   silent;[eapply step_ifthenelse with (b:=true);eauto|].
   silent;[apply step_skip_seq|];apply star_refl.
 - exists (State f Sskip k' e le m);split;[|eapply replay_regular;[reflexivity|exact K]].
   rewrite operational_main_layout;silent;[apply step_loop|];silent;[apply step_seq|].
   silent;[eapply step_ifthenelse with (b:=false);eauto|].
   silent;[apply step_break_seq|];silent;[apply step_break_loop1|];apply star_refl.
Qed.
Lemma follow_back loop f n k k' e le m : replay_cont loop k k' ->
 follows (State f Sskip (main_iteration_cont k') e le m) E0
         (State f (bounded_main n) k e le m).
Proof.
 intros K;exists (State f search_main_loop k' e le m);split;[|econstructor;eauto].
 unfold main_iteration_cont;rewrite operational_main_layout;silent.
 - apply step_skip_or_continue_loop1;auto.
 - silent;[apply step_skip_loop2|apply star_refl].
Qed.
Ltac regular :=
 eapply replay_regular;[|solve[eauto 5 using replay_cont]];first[reflexivity|eassumption].
Lemma follow_regular loop f s k k' e le m t to :
 supported_genv ge -> structured loop s=true -> replay_cont loop k k' ->
 Clight.step2 ge (State f s k e le m) t to ->
 follows (State f s k' e le m) t to.
Proof.
 intros Supported St K Actual;inversion Actual;subst;cbn [structured] in St;try discriminate;
 repeat match goal with A: andb _ _=true |- _ =>apply andb_true_iff in A;destruct A end.
 - eapply follow_one;[eapply step_assign;eassumption|regular].
 - eapply follow_one;[eapply step_set;eassumption|regular].
 - eapply follow_one;[eapply step_call;eassumption|].
   eapply replay_callee;[eapply Supported;eassumption|econstructor;eauto].
 - eapply follow_one;[apply step_seq|regular].
 - inversion K;subst.
   + eapply follow_one;[apply step_skip_seq|regular].
   + eapply follow_back;eauto.
 - inversion K;subst;try discriminate.
   eapply follow_one;[apply step_break_seq|regular].
 - eapply follow_one;[eapply step_ifthenelse;eassumption|].
   destruct b;regular.
 - eapply follow_one;[apply step_loop|regular].
 - inversion K;subst.
   eapply follow_one;[eapply step_skip_or_continue_loop1;eassumption|regular].
 - inversion K;subst.
   eapply follow_one;[apply step_break_loop1|regular].
 - inversion K;subst.
   eapply follow_one;[apply step_skip_loop2|].
   eapply replay_regular;[cbn;apply andb_true_iff;auto|eassumption].
 - inversion K;subst.
   eapply follow_one;[apply step_break_loop2|regular].
 - eapply follow_one;[eapply step_return_0;eassumption|constructor;eapply replay_call_cont;eauto].
 - eapply follow_one;[eapply step_return_1;eassumption|constructor;eapply replay_call_cont;eauto].
 - eapply follow_one;[eapply step_skip_call;[eapply replay_is_call;eauto|eassumption]|].
   eapply replay_result;inversion K;subst;simpl in *;intuition;econstructor;eauto.
 - inversion K.
Qed.
End Replay.
