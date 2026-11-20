(* Relate the continuation that queues a finite unfolding to the real loop
   back edge. An iteration cannot send an uncaught break into this hole. *)
Require Import VST.floyd.proofauto compcert.common.Smallstep compcert.common.Events.
Require Import compcert.cfrontend.Clight CCV.CCBoundedMain CCV.CCSearchFragments
 CCV.CCTerminateMainLoop CCV.CCLinkedProgram CCV.CCVerificationDriver.
Import ListNotations.
Fixpoint structured (loop:bool) (s:statement) : bool :=
 match s with
 | Sbreak => loop
 | Sskip | Sreturn _ | Sassign _ _ | Sset _ _ | Scall _ _ _ => true
 | Ssequence a b | Sifthenelse _ a b => structured loop a && structured loop b
 | Sloop a b => structured true a && structured true b
 | _ => false
 end.
Definition supported_fd (fd:Clight.fundef) : bool :=
 match fd with Internal f => structured false (fn_body f) | _=>true end.
Definition checked_definition (d:ident * globdef Clight.fundef type) :=
 match snd d with Gfun fd => supported_fd fd | _=>true end.
Definition supported_genv (ge:Clight.genv) := forall v fd,
 Genv.find_funct ge v=Some fd -> supported_fd fd=true.
Lemma checked_genv p : forallb checked_definition (prog_defs p)=true ->
 supported_genv (Clight.globalenv p).
Proof.
 intros All v fd Found. apply Genv.find_funct_inversion in Found as [id H].
 rewrite forallb_forall in All. exact (All (id,Gfun fd) H).
Qed.
Lemma linked_supported : supported_genv (Clight.globalenv linked_prog).
Proof. apply checked_genv;vm_compute;reflexivity. Qed.
Lemma driver_supported : supported_genv (Clight.globalenv driver_prog).
Proof. apply checked_genv;vm_compute;reflexivity. Qed.
Lemma iteration_closed : structured false search_main_iteration=true.
Proof. vm_compute;reflexivity. Qed.
Inductive replay_cont : bool -> cont -> cont -> Prop :=
 | replay_stop : replay_cont false Kstop Kstop
 | replay_seq : forall loop a k k',structured loop a=true ->replay_cont loop k k' ->
   replay_cont loop (Kseq a k) (Kseq a k')
 | replay_loop1 : forall loop a b k k',structured true a=true ->structured true b=true ->
   replay_cont loop k k' -> replay_cont true (Kloop1 a b k) (Kloop1 a b k')
 | replay_loop2 : forall loop a b k k',structured true a=true ->structured true b=true ->
   replay_cont loop k k' -> replay_cont true (Kloop2 a b k) (Kloop2 a b k')
 | replay_call : forall loop dst f e le k k',replay_cont loop k k' ->
   replay_cont false (Kcall dst f e le k) (Kcall dst f e le k')
 | replay_back : forall loop n k k',replay_cont loop k k' ->
   replay_cont false (Kseq (bounded_main n) k) (main_iteration_cont k').
Lemma replay_call_cont b k k' : replay_cont b k k' ->
 replay_cont false (call_cont k) (call_cont k').
Proof. induction 1;simpl;try assumption;eauto using replay_cont. Qed.
Lemma replay_is_call b k k' : replay_cont b k k' -> is_call_cont k -> is_call_cont k'.
Proof. destruct 1;simpl;auto. Qed.
Inductive replay_state : Clight.state -> Clight.state -> Prop :=
 | replay_regular : forall loop f s k k' e le m,structured loop s=true ->replay_cont loop k k' ->
   replay_state (State f s k e le m) (State f s k' e le m)
 | replay_head : forall loop f n k k' e le m,replay_cont loop k k' ->
   replay_state (State f (bounded_main n) k e le m) (State f search_main_loop k' e le m)
 | replay_enter : forall loop f n k k' e le m,replay_cont loop k k' ->
   replay_state (State f (Ssequence search_main_iteration (bounded_main n)) k e le m)
    (State f search_main_iteration (main_iteration_cont k') e le m)
 | replay_callee : forall fd args k k' m,supported_fd fd=true ->replay_cont false k k' ->
   replay_state (Callstate fd args k m) (Callstate fd args k' m)
 | replay_result : forall v k k' m,replay_cont false k k' ->
   replay_state (Returnstate v k m) (Returnstate v k' m).
Lemma replay_result_stop v m st :
 replay_state (Returnstate v Kstop m) st -> st=Returnstate v Kstop m.
Proof. inversion 1;subst;match goal with H:replay_cont _ Kstop _ |- _=>inversion H;reflexivity end. Qed.
