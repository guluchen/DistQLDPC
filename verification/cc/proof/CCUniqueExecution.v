(* A finite internal path to a return forces every maximal execution to
   return at that same state. The argument also rules out an infinite run. *)
Require Import VST.floyd.proofauto VST.veric.Clight_core VST.veric.semax_lemmas.
Require Import compcert.cfrontend.Clight compcert.common.Smallstep CCV.CCInternalPaths.
Section Forcing.
Variable ge:Clight.genv.
Lemma internal_next_unique st t s u s':internal_step ge st t s ->step2 ge st u s' ->s=s'.
Proof.
 intros I A;assert (I':internal_step ge st u s') by (split;[apply (proj1 I)|exact A]).
 pose proof(internal_clight_to_core ge _ _ _ I)as X;pose proof(internal_clight_to_core ge _ _ _ I')as Y.
 pose proof(cl_corestep_fun _ _ _ _ _ _ _ X Y)as E;inversion E.
 rewrite <-(view_state s),<-(view_state s');congruence.
Qed.
Definition terminal_state (st:Clight.state):Prop:=forall t s,~step2 ge st t s.
Lemma returned_terminal v m:terminal_state (Returnstate v Kstop m).
Proof. intros t s A;inversion A. Qed.
Lemma finite_maximal_unique start t last:star internal_step ge start t last ->terminal_state last ->
 forall u fin,star step2 ge start u fin ->terminal_state fin ->fin=last.
Proof.
 intro P;induction P;intros Stop u fin Run End.
 - inversion Run;subst;[reflexivity|exfalso;eapply Stop;eassumption].
 - inversion Run;subst.
   + exfalso;eapply End;apply (proj2 H).
   + match goal with S:step2 ge _ _ _ |- _=>pose proof(internal_next_unique _ _ _ _ _ H S) as Eq end.
     subst;eapply IHP;eassumption.
Qed.
Lemma finite_excludes_forever start t last:star internal_step ge start t last ->terminal_state last ->
 forall T,~forever step2 ge start T.
Proof.
 intro P;induction P;intros Stop T Infinite;inversion Infinite;subst.
 - eapply Stop;eassumption.
 - match goal with S:step2 ge _ _ _ |- _=>pose proof(internal_next_unique _ _ _ _ _ H S) as Eq end.
   subst;eapply IHP;eassumption.
Qed.
End Forcing.
