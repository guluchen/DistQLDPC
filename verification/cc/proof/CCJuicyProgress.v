(* First-step bridge from VST2.14's actual juicy safety judgment.  Its fancy
   update continuation is not replaced by ordinary dry safety; this proves
   positive-level internal progress only, not a finite whole execution. *)
Require Import VST.floyd.proofauto VST.msl.ageable.
Require Import VST.veric.Clight_core VST.veric.juicy_mem VST.veric.juicy_extspec.
Require Import CCV.CCClightAcyclic CCV.CCCoreAcyclic.
Open Scope nat_scope.
Section ActualJuicySafety.
Context{Oracle:Type}.
Variable symb:Clight.genv->extspec.injective_PTree block.
Variable spec:juicy_ext_spec Oracle.
Variable ge:Clight.genv.
Definition actual_juicy_safe z q jm:=
 @jsafeN_ Clight.genv CC_core Oracle symb(cl_core_sem ge)spec ge z q jm.
Theorem positive_internal_juicy_progress z q jm:
 actual_juicy_safe z q jm ->0<level jm ->cl_at_external q=None ->cl_halted q=None ->
 exists q' jm',juicy_extspec.jstep(cl_core_sem ge)q jm q' jm'.
Proof.
 intros Safe Positive Internal NotHalted;unfold actual_juicy_safe in Safe;inversion Safe;subst.
 - lia.
 - eexists;eexists;eassumption.
 - unfold j_at_external in *;cbn in *;congruence.
 - cbn in *;contradiction.
Qed.
Theorem acyclic_positive_juicy_progress z q jm:
 actual_juicy_safe z q jm ->0<level jm ->core_acyclic q(m_dry jm) ->
 exists q' jm',juicy_extspec.jstep(cl_core_sem ge)q jm q' jm' /\
 (core_acyclic q'(m_dry jm') \/core_returned q'(m_dry jm')) /\
 core_control_rank q'(m_dry jm')<core_control_rank q(m_dry jm).
Proof.
 intros Safe Positive Acyclic.
 destruct(positive_internal_juicy_progress z q jm Safe Positive
 (acyclic_core_not_external q(m_dry jm)Acyclic)
 (acyclic_core_not_halted q(m_dry jm)Acyclic))as[q'[jm' Transition]].
 exists q',jm';split;[exact Transition|].
 apply(acyclic_juicy_step_decreases ge q jm q' jm' Acyclic Transition).
Qed.
End ActualJuicySafety.
Print Assumptions positive_internal_juicy_progress.
Print Assumptions acyclic_positive_juicy_progress.
