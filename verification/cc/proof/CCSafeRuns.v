(* For internal Clight2 paths, deterministic VST core steps transport
   arbitrarily high finite safety. This excludes the stuck alternative. *)
Require Import VST.floyd.proofauto VST.veric.Clight_core VST.veric.semax_lemmas.
Require Import VST.sepcomp.step_lemmas compcert.common.Smallstep.
Require Import CCV.CCCoreAcyclic CCV.CCInternalPaths CCV.CCStructuredRuns.
Section SafeRuns.
Context {Oracle:Type}.
Variable symb:Clight.genv->extspec.injective_PTree block.
Variable rel:nat->mem->mem->Prop.
Variable spec:extspec.external_specification mem external_function Oracle.
Variable ge:Clight.genv.
Variable z:Oracle.
Definition all_levels st := forall n,
 dry_safe symb rel spec ge n z (core_of st) (memory_of st).
Lemma safe_internal_unfold n st :
 internal_source st=true ->
 dry_safe symb rel spec ge (S n) z (core_of st) (memory_of st) ->
 exists q' m',cl_step ge (core_of st) (memory_of st) q' m' /\
 dry_safe symb rel spec ge n z q' m'.
Proof.
 intros Source Safe;unfold dry_safe in Safe;inversion Safe;subst.
 - eexists;eexists;split;eassumption.
 - pose proof(internal_not_external st Source); cbn in *;congruence.
 - pose proof(internal_not_halted st Source); cbn in *;contradiction.
Qed.
Lemma safe_internal_next st t next :
 all_levels st -> internal_step ge st t next -> all_levels next.
Proof.
 intros Safe Transition n.
 destruct (safe_internal_unfold n st (proj1 Transition) (Safe (S n))) as [q [m [Taken Later]]].
 pose proof (internal_clight_to_core ge _ _ _ Transition) as Actual.
 pose proof (cl_corestep_fun _ _ _ _ _ _ _ Taken Actual) as Equal.
 inversion Equal;subst;exact Later.
Qed.
Lemma safe_internal_path st t fin :
 star internal_step ge st t fin -> all_levels st -> all_levels fin.
Proof. intros Path;induction Path;intros;auto;eapply IHPath;eapply safe_internal_next;eauto. Qed.
Lemma internal_safe_enabled st :
 internal_source st=true -> all_levels st -> exists t next,Clight.step2 ge st t next.
Proof.
 intros Source Safe. destruct (safe_internal_unfold 0 st Source (Safe 1%nat)) as [q [m [Taken _]]].
 destruct (cl_step_equiv ge (core_of st) (memory_of st) q m
   (internal_not_external st Source) Taken) as [t Actual].
 rewrite view_state in Actual; eauto.
Qed.
Theorem safe_runs_finish st done :
 all_levels st -> settles ge st done -> exists t fin,star Clight.step2 ge st t fin /\ done fin.
Proof.
 intros Safe [t [fin [Path Exit]]]. exists t,fin;split;[apply internal_path_actual;exact Path|].
 destruct Exit as [Out|[Source Block]];[exact Out|].
 destruct (internal_safe_enabled _ Source (safe_internal_path _ _ _ Path Safe)) as [u [next Transition]].
 exfalso;exact (Block _ _ Transition).
Qed.
End SafeRuns.
Print Assumptions safe_runs_finish.
