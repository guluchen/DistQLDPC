(* Link arbitrarily high framed safety and a structurally finite ordinary
   execution. No specification for foreign calls is needed on this path. *)
Require Import VST.floyd.proofauto VST.veric.Clight_core VST.veric.semax_lemmas.
Require Import compcert.common.Smallstep.
Require Import CCV.CCInternalPaths CCV.CCStructuredRuns CCV.CCScanCallees
 CCV.CCInternalEvents CCV.CCFramedInternal.
Section Finish.
Variable ge:Clight.genv.
Definition internal_levels st :=
 forall n,internal_fuel ge n (core_of st) (memory_of st).
Lemma internal_levels_next st t next :
 internal_levels st -> internal_step ge st t next -> internal_levels next.
Proof.
 intros Safe Transition n.
 specialize (Safe (S n));cbn [internal_fuel] in Safe;rewrite ordinary_view in Safe.
 destruct (Safe (proj1 Transition)) as [q [m [Taken Later]]].
 pose proof (internal_clight_to_core ge _ _ _ Transition) as Actual.
 pose proof (cl_corestep_fun _ _ _ _ _ _ _ Taken Actual) as Equal.
 inversion Equal;subst;exact Later.
Qed.
Lemma internal_levels_path st t fin :
 star internal_step ge st t fin -> internal_levels st -> internal_levels fin.
Proof. intros Path;induction Path;intros;auto;eapply IHPath;eapply internal_levels_next;eauto. Qed.
Theorem internal_levels_finish st done :
 internal_levels st -> settles ge st done ->
 exists t fin,star Clight.step2 ge st t fin /\ done fin.
Proof.
 intros Safe [t [fin [Path Exit]]]. exists t,fin;split;[apply internal_path_actual;exact Path|].
 destruct Exit as [Out|[Source Block]];[exact Out|].
 pose proof (internal_levels_path _ _ _ Path Safe 1%nat) as One.
 cbn [internal_fuel] in One;rewrite ordinary_view in One.
 destruct (One Source) as [q [m [Taken _]]].
 destruct (cl_step_equiv ge (core_of fin) (memory_of fin) q m
    (internal_not_external fin Source) Taken) as [u Actual].
 rewrite view_state in Actual;exfalso;eapply Block;exact Actual.
Qed.
Corollary actual_call_finishes fn args k m :
 call_settles ge fn -> Clight.is_call_cont k ->
 internal_levels (Clight.Callstate (Internal fn) args k m) ->
 exists t v m',star Clight.step2 ge (Clight.Callstate (Internal fn) args k m) t
   (Clight.Returnstate v k m').
Proof.
 intros F K Safe. destruct (internal_levels_finish _ _ Safe (F args m k K))
   as [t [fin [Run [v [m' ->]]]]];eauto.
Qed.
End Finish.
Print Assumptions actual_call_finishes.
