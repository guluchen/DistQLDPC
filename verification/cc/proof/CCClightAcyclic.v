(* A strictly decreasing operational rank for loop-free, call-free Clight
   blocks. A progress/safety bridge is still required for total execution. *)
Require Import VST.floyd.proofauto.
Require Import compcert.common.Events compcert.common.Smallstep compcert.cfrontend.Clight.
Require Import CCV.ccv_core CCV.ccv_primitives CCV.CCClightRankedSegments.
Import ListNotations.
Fixpoint acyclic_statement(s:statement):bool:=
 match s with
 |Sskip|Sassign _ _|Sset _ _|Sbreak|Scontinue|Sreturn _=>true
 |Ssequence a b|Sifthenelse _ a b=>acyclic_statement a&&acyclic_statement b
 |Slabel _ a=>acyclic_statement a
 |_=>false end.
Fixpoint acyclic_cont(k:Clight.cont):bool:=
 match k with
 |Kstop|Kcall _ _ _ _ _=>true
 |Kseq s tail=>acyclic_statement s&&acyclic_cont tail
 |_=>false end.
Fixpoint statement_rank(s:statement):nat:=
 match s with
 |Sassign _ _|Sset _ _=>2
 |Ssequence a b=>statement_rank a+statement_rank b+2
 |Sifthenelse _ a b=>Nat.max(statement_rank a)(statement_rank b)+1
 |Slabel _ a=>statement_rank a+1
 |_=>1 end.
Fixpoint continuation_rank(k:Clight.cont):nat:=
 match k with
 |Kseq s tail=>statement_rank s+1+continuation_rank tail
 |_=>0 end.
Definition acyclic_state(st:Clight.state):Prop:=
 match st with
 |Clight.State _ s k _ _ _=>acyclic_statement s=true /\acyclic_cont k=true
 |_=>False end.
Definition returned_state(st:Clight.state):Prop:=
 match st with Clight.Returnstate _ _ _=>True|_=>False end.
Definition control_rank(st:Clight.state):nat:=
 match st with Clight.State _ s k _ _ _=>statement_rank s+continuation_rank k|_=>0 end.
Theorem acyclic_step_decreases ge start trace finish:
 acyclic_state start ->Clight.step2 ge start trace finish ->
 (acyclic_state finish \/returned_state finish) /\(control_rank finish<control_rank start)%nat.
Proof.
 destruct start as[f s k e le m|fd args k m|v k m];cbn[acyclic_state];try contradiction.
 intros [Stmt Cont] Transition;unfold Clight.step2 in Transition;inversion Transition;subst;
 cbn[acyclic_statement acyclic_cont control_rank statement_rank continuation_rank returned_state acyclic_state]in *;
 try discriminate.
 all:repeat match goal with H:andb _ _=true|-_=>rewrite andb_true_iff in H;destruct H end.
 all:repeat match goal with b:bool|-_=>destruct b end.
 all:cbn[acyclic_statement acyclic_cont control_rank statement_rank continuation_rank returned_state acyclic_state]in *.
 all:split.
 all:try solve[repeat match goal with H:?b=true|-_=>progress rewrite H end;cbn;tauto].
 all:lia.
Qed.
Theorem five_actual_helper_bodies_are_acyclic:
 Forall(fun f=>acyclic_statement(fn_body f)=true)
 [ccv_core.f_shape;ccv_core.f_forbid;ccv_core.f_stats_init;
  ccv_primitives.f_ccv_bit_xor;ccv_primitives.f_ccv_ceil_div].
Proof. vm_compute;repeat constructor;reflexivity. Qed.
Print Assumptions acyclic_step_decreases.
Print Assumptions five_actual_helper_bodies_are_acyclic.

Definition progress_until_return ge initial:Prop:=forall t st,
 star Clight.step2 ge initial t st ->~returned_state st ->
 exists u next,Clight.step2 ge st u next.
Theorem acyclic_progress_implies_finite_return ge initial:
 acyclic_state initial ->progress_until_return ge initial ->
 exists t finish,star Clight.step2 ge initial t finish /\returned_state finish.
Proof.
 intros Initial Progress.
 eapply(ranked_clight_segments_terminate ge
  (fun st=>acyclic_state st /\exists t,star Clight.step2 ge initial t st)
  returned_state control_rank).
 - intros st[Valid[t Reach]].
   assert(NotReturned:~returned_state st).
   { destruct st;cbn[acyclic_state returned_state]in *;tauto. }
   destruct(Progress t st Reach NotReturned)as[u[next Transition]].
   destruct(acyclic_step_decreases ge st u next Valid Transition)as[[Next|Final]Lower].
   + right;exists u,next;split;[apply star_one;exact Transition|].
     split;[|exact Lower];split;[exact Next|].
     exists(List.app t u);eapply star_trans;[exact Reach|apply star_one;exact Transition|reflexivity].
   + left;exists u,next;split;[apply star_one;exact Transition|exact Final].
 - split;[exact Initial|exists E0;apply star_refl].
Qed.
Theorem no_infinite_acyclic_execution ge:
 ~exists f:nat->Clight.state,
 (forall n,acyclic_state(f n)) /\
 (forall n,exists t,Clight.step2 ge(f n)t(f(S n))).
Proof.
 intros[f[Valid Steps]].
 assert(Bound:forall n,(control_rank(f n)+n<=control_rank(f 0%nat))%nat).
 { intro n;induction n as[|n IH];[lia|].
   destruct(Steps n)as[t Transition].
   pose proof(proj2(acyclic_step_decreases ge(f n)t(f(S n))(Valid n)Transition));lia. }
 pose proof(Bound(S(control_rank(f 0%nat))));lia.
Qed.
Print Assumptions acyclic_progress_implies_finite_return.
Print Assumptions no_infinite_acyclic_execution.
