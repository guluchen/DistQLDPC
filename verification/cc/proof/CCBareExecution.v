(* Erase the proof-only main declaration from a completed solver execution.
   Every machine state, return value and memory block stays the same. *)
Require Import VST.floyd.proofauto compcert.cfrontend.Clight compcert.common.Smallstep.
Require Import CCV.CCOriginalNames CCV.CCOldCalls CCV.CCLinkedProgram CCV.CCVerificationDriver
 CCV.CCReplayEnvironment CCV.CCInternalPaths.
Local Notation src:=(Clight.globalenv driver_prog).
Local Notation dst:=(Clight.globalenv linked_prog).
Fixpoint old_cont k :Prop :=
 match k with Kstop=>True |Kseq s tail=>old_stmt s=true /\ old_cont tail
 |Kloop1 a b tail|Kloop2 a b tail =>old_stmt a=true /\old_stmt b=true /\old_cont tail
 |Kcall _ f e l tail =>words_env e /\old_cont tail|_=>False end.
Lemma old_unwind k:old_cont k ->old_cont (call_cont k).
Proof. induction k;simpl;intuition. Qed.
Definition old_state st:Prop :=
 match st with
 |State _ s k e _ _ => old_stmt s=true /\words_env e /\old_cont k
 |Callstate (Internal f) _ k _=>old_fn f=true /\old_cont k
 |Returnstate _ k _=>old_cont k|_=>False end.
Local Opaque linked_prog.
Lemma bare_layout:genv_cenv src=genv_cenv dst.
Proof. unfold Clight.globalenv;cbn [genv_cenv];unfold driver_prog;reflexivity. Qed.
Lemma bare_blocks e:blocks_of_env src e=blocks_of_env dst e.
Proof. unfold blocks_of_env,block_of_binding;rewrite bare_layout;reflexivity. Qed.
Lemma target_expr a:direct_target a=true ->old_expr a=true.
Proof. destruct a;try discriminate;destruct t;try discriminate;intro H;apply andb_true_iff in H;tauto. Qed.
Section OneStep.
Variables g h:Clight.genv.
Hypothesis Layout:genv_cenv g=genv_cenv h.
Hypothesis Blocks:forall e,blocks_of_env g e=blocks_of_env h e.
Hypothesis Exprs:forall e l m,
 (forall a v,eval_expr g e l m a v ->old_expr a=true ->eval_expr h e l m a v) /\
 (forall a b o bf,eval_lvalue g e l m a b o bf ->old_expr a=true ->eval_lvalue h e l m a b o bf).
Hypothesis Args:forall e l m xs ts vs,eval_exprlist g e l m xs ts vs ->
 forallb old_expr xs=true ->eval_exprlist h e l m xs ts vs.
Hypothesis Target:forall e l m a v fd,words_env e ->direct_target a=true ->eval_expr g e l m a v ->
 Genv.find_funct g v=Some fd ->Genv.find_funct h v=Some fd /\ exists f,fd=Internal f /\old_fn f=true.
Hypothesis Word:forall f args m e l m',old_fn f=true ->function_entry2 g f args m e l m' ->words_env e.
Lemma erase_one st t next:old_state st ->step2 g st t next ->step2 h st t next /\old_state next.
Proof.
 intros Old Run;inversion Run;subst;cbn [old_state old_stmt old_cont] in *;try contradiction;
 repeat match goal with H:_ /\ _ |- _=>destruct H end;
 repeat match goal with H:_ && _=true |- _=>apply andb_true_iff in H as [? ?] end;
 try discriminate;try contradiction.
 - split;[eapply step_assign;[eapply(proj2(Exprs _ _ _));eassumption|
   eapply(proj1(Exprs _ _ _));eassumption|eassumption|rewrite <-Layout;eassumption]|simpl;auto].
 - split;[eapply step_set;eapply(proj1(Exprs _ _ _));eassumption|simpl;auto].
 - match goal with Direct:direct_target ?a=true |- _=>pose proof(target_expr a Direct) as Clean end.
   destruct (Target e le m a vf fd H5 H4 H0 H2) as [Address [fn [Equal Fn]]].
   subst fd.
   split;[eapply step_call;[eassumption|eapply(proj1(Exprs _ _ _));eassumption|eapply Args;eassumption|eassumption|eassumption]|simpl;auto].
 - split;[apply step_seq|simpl;auto].
 - split;[apply step_skip_seq|simpl;auto].
 - split;[apply step_break_seq|simpl;auto].
 - split;[eapply step_ifthenelse;[eapply(proj1(Exprs _ _ _));eassumption|eassumption]|destruct b;simpl;auto].
 - split;[apply step_loop|simpl;auto].
 - split;[apply step_skip_or_continue_loop1;assumption|simpl;auto].
 - split;[apply step_break_loop1|simpl;auto].
 - split;[apply step_skip_loop2|simpl;rewrite andb_true_iff;auto].
 - split;[apply step_break_loop2|simpl;auto].
 - split;[eapply step_return_0;rewrite <-Blocks;eassumption|apply old_unwind;assumption].
 - split;[eapply step_return_1;[eapply(proj1(Exprs _ _ _));eassumption|eassumption|rewrite <-Blocks;eassumption]|apply old_unwind;assumption].
 - split;[eapply step_skip_call;[eassumption|rewrite <-Blocks;eassumption]|simpl;auto].
 - split;[eapply step_internal_function;eapply replay_entry;[apply Layout|apply headers_same|eassumption]|].
   simpl;split;[unfold old_fn in *;rewrite andb_true_iff in *;tauto|split;[eapply Word;eassumption|assumption]].
 - split;[apply step_returnstate|simpl;auto].
Qed.
End OneStep.
Lemma bare_step st t next:old_state st ->step2 src st t next ->step2 dst st t next /\old_state next.
Proof. exact (erase_one src dst bare_layout bare_blocks old_evaluations old_arguments target_resolution word_entry st t next). Qed.
Theorem bare_trace start t finish:star step2 src start t finish ->old_state start ->star step2 dst start t finish.
Proof.
 intros Trace;induction Trace;intros Old;[apply star_refl|].
 destruct(bare_step _ _ _ Old H)as [Hstep Hclean];eapply star_step;[exact Hstep|apply IHTrace;exact Hclean|assumption].
Qed.

Lemma source_is_internal st t next:old_state st ->step2 src st t next ->internal_source st=true.
Proof.
 destruct st as [f s k e l m|fd args k m|v k m];intros Old Run;
 [destruct s;cbn [internal_source];try reflexivity;cbn [old_state old_stmt] in Old;intuition discriminate|
 destruct fd;cbn in *;intuition|destruct k;try reflexivity;inversion Run].
Qed.
Local Opaque driver_prog.
Theorem bare_internal_trace start t finish:star step2 src start t finish ->
 old_state start ->star internal_step dst start t finish.
Proof.
 intro P;induction P;intros Old;[apply star_refl|].
 destruct (bare_step _ _ _ Old H) as [Hstep Hclean].
 pose proof (source_is_internal _ _ _ Old H) as Hinter.
 pose proof (conj Hinter Hstep) as I.
 specialize (IHP Hclean).
 eapply star_step;[exact I|exact IHP|assumption].
Qed.
