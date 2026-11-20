(* Small steps of the verification program replay through the frozen C
   library. Administrative steps can stutter and preserve the complete heap. *)
Require Import VST.floyd.proofauto compcert.cfrontend.Clight compcert.common.Events
 compcert.common.Smallstep CCV.CCReplayEnvironment CCV.CCProgramRelation
 CCV.CCCapGuard CCV.CCBoundedMain CCV.CCSearchFragments CCV.CCReplayFrames
 CCV.CCTerminateMainLoop CCV.CCReplayStep.
Section Replay.
Variables src dst:Clight.genv.
Hypothesis Layout:genv_cenv src=genv_cenv dst.
Hypothesis Symbols:forall i,Genv.find_symbol src i=Genv.find_symbol dst i.
Hypothesis Calls:forall v fd,Genv.find_funct src v=Some fd ->
 exists fd',Genv.find_funct dst v=Some fd' /\ function_pair fd fd'.
Hypothesis External:Senv.equiv src dst.
Lemma block_layout e:blocks_of_env src e=blocks_of_env dst e.
Proof. unfold blocks_of_env,block_of_binding;rewrite Layout;reflexivity. Qed.
Definition advances st t next := exists last,star step2 dst st t last /\ paired_state next last.
Lemma advance_one st t next last:step2 dst st t last ->paired_state next last ->advances st t next.
Proof. intros;exists last;split;[apply star_one|];assumption. Qed.
Lemma advance_zero st next:paired_state next st ->advances st E0 next.
Proof. intro H;exists st;split;[apply star_refl|assumption]. Qed.
Local Ltac silent := eapply star_step with (t1:=E0)(t2:=E0);[| |reflexivity].
Local Ltac pair_basic := eapply ps_stmt;[eassumption|apply pair_atom;reflexivity|eassumption].
Lemma paired_back b f f' n k k' e l m :
 headers f f' ->paired_cont b k k' ->
 advances (State f' Sskip (main_iteration_cont k') e l m) E0 (State f (bounded_main n) k e l m).
Proof.
 intros H K;exists (State f' search_main_loop k' e l m);split;[|eapply ps_stmt;[exact H|apply pair_heads|exact K]].
 unfold main_iteration_cont;rewrite operational_main_layout;silent;[apply step_skip_or_continue_loop1;auto|].
 silent;[apply step_skip_loop2|apply star_refl].
Qed.
Lemma paired_guard b f f' n k k' e l m v yes : headers f f' ->paired_cont b k k' ->
 eval_expr src e l m depth_guard v ->Cop.bool_val v (typeof depth_guard) m=Some yes ->
 advances (State f' search_main_loop k' e l m) E0
 (State f (if yes then Ssequence search_main_iteration (bounded_main n) else Sskip) k e l m).
Proof.
 intros H K Ev T;apply (proj1(replay_evaluations src dst Layout Symbols e l m)) in Ev.
 destruct yes.
 - exists (State f' search_main_iteration (main_iteration_cont k') e l m);split;[|eapply ps_enter;eassumption].
   rewrite operational_main_layout;silent;[apply step_loop|];silent;[apply step_seq|].
   silent;[eapply step_ifthenelse with (b:=true);eauto|];silent;[apply step_skip_seq|apply star_refl].
 - exists (State f' Sskip k' e l m);split;[|pair_basic].
   rewrite operational_main_layout;silent;[apply step_loop|];silent;[apply step_seq|].
   silent;[eapply step_ifthenelse with (b:=false);eauto|].
   silent;[apply step_break_seq|];silent;[apply step_break_loop1|apply star_refl].
Qed.
Lemma atomic_steps b f f' s k k' e l m t next :
 headers f f' ->atomic_control b s=true ->paired_cont b k k' ->
 step2 src (State f s k e l m) t next ->advances (State f' s k' e l m) t next.
Proof.
 intros Header Atom K Act.
 destruct(replay_evaluations src dst Layout Symbols e l m) as [Expr Lval].
 inversion Act;subst;cbn [atomic_control] in Atom;try discriminate.
 - eapply advance_one;[eapply step_assign;[eauto|eauto|eassumption|rewrite <-Layout;eassumption]|pair_basic].
 - eapply advance_one;[eapply step_set;eauto|pair_basic].
 - match goal with A:Genv.find_funct _ _=Some _ |- _=>destruct(Calls _ _ A) as [fd' [Address Pair]] end.
   eapply advance_one;[eapply step_call;[eassumption|eauto|eapply replay_arguments;eassumption|exact Address|rewrite <- (paired_type _ _ Pair);eassumption]|].
   eapply ps_in;[exact Pair|eapply pc_call;eassumption].
 - inversion K;subst.
   + eapply advance_one;[apply step_skip_seq|eapply ps_stmt;eassumption].
   + eapply paired_back;eassumption.
   + apply advance_zero;eapply ps_stmt;[eassumption|apply pair_cap_skip|eassumption].
 - inversion K;subst;try discriminate.
   + eapply advance_one;[apply step_break_seq|eapply ps_stmt;[eassumption|apply pair_atom;first[reflexivity|assumption]|eassumption]].
   + apply advance_zero;eapply ps_stmt;[eassumption|apply pair_atom;first[reflexivity|assumption]|eassumption].
 - inversion K;subst.
   eapply advance_one;[apply step_skip_or_continue_loop1;auto|eapply ps_stmt;[eassumption|eassumption|eapply pc_loop2;eassumption]].
 - inversion K;subst;eapply advance_one;[apply step_break_loop1|pair_basic].
 - inversion K;subst;eapply advance_one;[apply step_skip_loop2|eapply ps_stmt;[eassumption|apply pair_loop;eassumption|eassumption]].
 - inversion K;subst;eapply advance_one;[apply step_break_loop2|pair_basic].
 - eapply advance_one;[eapply step_return_0;rewrite <-block_layout;eassumption|apply ps_out;eapply pc_unwind;eassumption].
 - eapply advance_one;[eapply step_return_1;[eauto|rewrite <-(proj1 Header);eassumption|rewrite <-block_layout;eassumption]|apply ps_out;eapply pc_unwind;eassumption].
 - eapply advance_one;[eapply step_skip_call;[eapply pc_final;eassumption|rewrite <-block_layout;eassumption]|].
   inversion K;subst;simpl in *;try contradiction;apply ps_out;eauto using paired_cont.
 - inversion K.
Qed.
Lemma paired_stmt_step b f f' s s' k k' e l m t next :
 headers f f' ->stmt_pair b s s' ->paired_cont b k k' ->
 step2 src (State f s k e l m) t next ->advances (State f' s' k' e l m) t next.
Proof.
 intros Header Pair K Act;destruct Pair.
 - eapply atomic_steps;eassumption.
 - inversion Act;subst;try solve[intuition discriminate].
   eapply advance_one;[apply step_seq|eapply ps_stmt;[eassumption|eassumption|apply pc_seq;eassumption]].
 - inversion Act;subst;try solve[intuition discriminate].
   eapply advance_one;[eapply step_ifthenelse;[eapply(proj1(replay_evaluations _ _ Layout Symbols _ _ _));eassumption|eassumption]|].
   match goal with h:Cop.bool_val _ _ _=Some ?x |- _=>destruct x end;eapply ps_stmt;eassumption.
 - inversion Act;subst;try solve[intuition discriminate].
   eapply advance_one;[apply step_loop|eapply ps_stmt;[eassumption|eassumption|eapply pc_loop1;eassumption]].
 - destruct n as [|n];[exfalso;eapply unreachable_read_stuck;exact Act|].
   cbn [bounded_main] in Act;inversion Act;subst;try solve[intuition discriminate];eapply paired_guard;eassumption.
 - inversion Act;subst;try solve[intuition discriminate].
   apply advance_zero;eapply ps_stmt;[eassumption|eassumption|apply pc_cap;assumption].
 - inversion Act;subst;try solve[intuition discriminate].
   apply advance_zero;destruct b0;eapply ps_stmt;[eassumption|apply pair_atom;reflexivity|eassumption|eassumption|apply pair_dead_skip|eassumption].
 - exfalso;eapply cap_dead_stuck;exact Act.
Qed.
Lemma paired_transition left right t next:paired_state left right ->step2 src left t next ->advances right t next.
Proof.
 intros Pair Act;destruct Pair.
 - eapply paired_stmt_step;eassumption.
 - inversion Act;subst;try solve[intuition discriminate].
   apply advance_zero;eapply ps_stmt;[eassumption|apply same_statement;exact iteration_closed|eapply pc_back;eassumption].
 - inversion Act;subst;match goal with H:function_pair _ _ |- _=>inversion H;subst end.
   + eapply advance_one;[eapply step_internal_function;eapply replay_entry;eassumption|eapply ps_stmt;eassumption].
   + eapply advance_one;[eapply step_external_function;eapply external_call_symbols_preserved;eassumption|apply ps_out;assumption].
 - inversion Act;subst;match goal with H:paired_cont _ (Kcall _ _ _ _ _) _ |- _=>inversion H;subst end.
   eapply advance_one;[apply step_returnstate|pair_basic].
Qed.
Theorem paired_run left t finish:star step2 src left t finish ->forall right,paired_state left right ->advances right t finish.
Proof.
 intros Run;induction Run;intros right Pair;[apply advance_zero;assumption|].
 destruct(paired_transition _ _ _ _ Pair H) as [mid [A Match]].
 destruct(IHRun _ Match) as [last [B Out]];exists last;split;[eapply star_trans;eauto|exact Out].
Qed.
End Replay.
