(* A compositional termination judgment for actual Clight2 statements.
   On an arbitrary memory, evaluation may reach a stuck state. A separate
   progress proof rules that outcome out for legal callers. *)
Require Import VST.floyd.proofauto Coq.Arith.Wf_nat Coq.Logic.Classical_Prop.
Require Import compcert.lib.Maps compcert.common.Events compcert.common.Smallstep compcert.cfrontend.Clight.
Require Import CCV.CCInternalPaths.
Section Runs.
Variable ge : Clight.genv.
Definition blocked st := forall t next, ~ Clight.step2 ge st t next.
Definition settles st (done:Clight.state->Prop) :=
 exists t fin, star internal_step ge st t fin /\ (done fin \/ (internal_source fin=true /\ blocked fin)).
Lemma settled st done : done st -> settles st done.
Proof. intro H; exists E0,st; split; [apply star_refl|auto]. Qed.
Lemma blocked_settles st done `{Ordinary st} : blocked st -> settles st done.
Proof. intro Stuck; exists E0,st; split; [apply star_refl|right;split;[apply ordinary_source|exact Stuck]]. Qed.
Lemma settles_left st t next done `{Ordinary st} :
 Clight.step2 ge st t next -> settles next done -> settles st done.
Proof.
 intros Transition [u [fin [Path Finished]]]; exists (List.app t u),fin; split; [eapply star_step; [split; [apply ordinary_source|exact Transition]|exact Path|reflexivity]|exact Finished].
Qed.
Lemma settles_enabled st done `{Ordinary st} :
 (forall t next, Clight.step2 ge st t next -> settles next done) -> settles st done.
Proof.
 intro K. destruct (classic (exists t next, Clight.step2 ge st t next)) as [[t [next Transition]]|NoTransition].
 - eapply settles_left; [solve [assumption|constructor;reflexivity]|exact Transition|eauto].
 - eapply blocked_settles;[assumption|]. intros t next Transition; apply NoTransition; eauto.
Qed.
Definition configuration := Clight.temp_env -> mem -> Prop.
Definition runs f e s (P N B:configuration) :=
 forall le m, P le m -> forall k done,
 (forall le' m', N le' m' -> settles (Clight.State f Sskip k e le' m') done) ->
 (forall le' m', B le' m' -> settles (Clight.State f Sbreak k e le' m') done) ->
 (forall v m', settles (Clight.Returnstate v (Clight.call_cont k) m') done) ->
 settles (Clight.State f s k e le m) done.
Lemma runs_consequence f e s (P P' N N' B B':configuration) :
 (forall l m, P l m -> P' l m) -> runs f e s P' N' B' ->
 (forall l m, N' l m -> N l m) -> (forall l m, B' l m -> B l m) -> runs f e s P N B.
Proof.
 intros Pre Body Post Br le m H k done Nend Bend Rend.
 apply (Body le m (Pre le m H) k done); [intros;apply Nend;apply Post;assumption|
 intros;apply Bend;apply Br;assumption|exact Rend].
Qed.
Lemma runs_skip f e (P B:configuration) : runs f e Sskip P P B.
Proof. unfold runs; auto. Qed.
Lemma runs_break f e (P N:configuration) : runs f e Sbreak P N P.
Proof. unfold runs; auto. Qed.
Lemma runs_set f e id a (P N B:configuration) :
 (forall le m v, P le m -> Clight.eval_expr ge e le m a v -> N (PTree.set id v le) m) ->
 runs f e (Sset id a) P N B.
Proof.
 intros Update le m H k done Normal OnBreak OnReturn. eapply settles_enabled; [solve [assumption|constructor;reflexivity]|].
 intros t next Transition; inversion Transition; subst; try solve [intuition discriminate]. apply Normal; eauto.
Qed.
Lemma runs_assign f e lhs rhs (P N B:configuration) :
 (forall le m m' t k, P le m ->
  Clight.step2 ge (Clight.State f (Sassign lhs rhs) k e le m) t (Clight.State f Sskip k e le m') ->
  N le m') -> runs f e (Sassign lhs rhs) P N B.
Proof.
 intros Update le m H k done Normal OnBreak OnReturn. eapply settles_enabled; [solve [assumption|constructor;reflexivity]|].
 intros t next Transition; inversion Transition; subst; try solve [intuition discriminate]. apply Normal; eauto.
Qed.
Lemma runs_return f e a (P N B:configuration) : runs f e (Sreturn a) P N B.
Proof.
 intros le m H k done Normal OnBreak OnReturn. eapply settles_enabled; [solve [assumption|constructor;reflexivity]|].
 intros t next Transition; inversion Transition; subst; try solve [intuition discriminate]; apply OnReturn.
Qed.
Lemma runs_seq f e a b (P M N B:configuration) :
 runs f e a P M B -> runs f e b M N B -> runs f e (Ssequence a b) P N B.
Proof.
 intros A Bdy le m H k done Normal OnBreak OnReturn.
 eapply settles_left; [solve [assumption|constructor;reflexivity]|apply Clight.step_seq|].
 eapply A; [exact H| | |exact OnReturn].
 - intros l m' Mid. eapply settles_left; [solve [assumption|constructor;reflexivity]|apply Clight.step_skip_seq|].
   exact (Bdy l m' Mid k done Normal OnBreak OnReturn).
 - intros l m' Brk. eapply settles_left; [solve [assumption|constructor;reflexivity]|apply Clight.step_break_seq|]. auto.
Qed.
Definition takes e le m a b :=
 exists v, Clight.eval_expr ge e le m a v /\ Cop.bool_val v (typeof a) m = Some b.
Lemma runs_if f e a yes no (P N B:configuration) :
 runs f e yes (fun l m => P l m /\ takes e l m a true) N B ->
 runs f e no (fun l m => P l m /\ takes e l m a false) N B ->
 runs f e (Sifthenelse a yes no) P N B.
Proof.
 intros Y No le m H k done Normal OnBreak OnReturn.
 eapply settles_enabled; [constructor;reflexivity|]; intros t next Transition; inversion Transition; subst; try solve [intuition discriminate].
 destruct b; [eapply Y|eapply No]; try eassumption; split; try assumption; unfold takes; eauto.
Qed.
Lemma runs_loop f e body incr (Inv N B:configuration)
 (rank:Clight.temp_env -> mem -> nat)
 (mid:Clight.temp_env -> mem -> configuration) :
 (forall l m, Inv l m ->
  runs f e body (fun l0 m0 => l0=l /\ m0=m) (mid l m) N) ->
 (forall l m, Inv l m ->
  runs f e incr (mid l m) (fun l' m' => Inv l' m' /\ (rank l' m'<rank l m)%nat) N) ->
 runs f e (Sloop body incr) Inv N B.
Proof.
 intros Body Incr le m H k done Normal OnBreak OnReturn.
 remember (rank le m) as fuel eqn:Bound;revert le m H Bound.
 induction fuel as [fuel IH] using lt_wf_ind;intros le m H Bound.
 eapply settles_left; [solve [assumption|constructor;reflexivity]|apply Clight.step_loop|].
 eapply (Body le m H); [split;reflexivity| | |exact OnReturn].
 - intros l m1 Mid. eapply settles_left; [solve [assumption|constructor;reflexivity]|apply Clight.step_skip_or_continue_loop1;auto|].
   eapply (Incr le m H); [exact Mid| | |exact OnReturn].
   + intros l2 m2 [Next Less]. eapply settles_left; [solve [assumption|constructor;reflexivity]|apply Clight.step_skip_loop2|].
     apply (IH (rank l2 m2) ltac:(lia) l2 m2 Next eq_refl).
   + intros l2 m2 Exit. eapply settles_left; [solve [assumption|constructor;reflexivity]|apply Clight.step_break_loop2|auto].
 - intros l m1 Exit. eapply settles_left; [solve [assumption|constructor;reflexivity]|apply Clight.step_break_loop1|auto].
Qed.
Lemma safe_settling_returns st done :
 settles st done ->
 (forall t fin, star Clight.step2 ge st t fin -> ~done fin -> exists u next,Clight.step2 ge fin u next) ->
 exists t fin,star Clight.step2 ge st t fin /\ done fin.
Proof.
 intros [t [fin [Path Result]]] Safe; apply internal_path_actual in Path.
 exists t,fin; split; [exact Path|]. destruct Result as [Finished|[_ NoStep]]; [exact Finished|].
 destruct (classic (done fin)); auto. destruct (Safe t fin Path H) as [u [next Transition]].
 exfalso; exact (NoStep _ _ Transition).
Qed.
End Runs.
