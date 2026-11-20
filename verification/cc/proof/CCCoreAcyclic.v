(* Bridge from VST's actual dry Clight core and finite safety fuel to a
   finite return of an acyclic block. Juicy-resource/semax instantiation is
   separate and not claimed by this module. *)
Require Import VST.floyd.proofauto.
Require Import VST.veric.Clight_core VST.sepcomp.step_lemmas VST.sepcomp.semantics_lemmas.
Require Import VST.veric.juicy_extspec VST.veric.juicy_mem.
Require Import CCV.CCClightAcyclic.
Open Scope nat_scope.
Definition core_control_rank q m:=control_rank(CC_core_to_CC_state q m).
Definition core_acyclic q m:=acyclic_state(CC_core_to_CC_state q m).
Definition core_returned q m:=returned_state(CC_core_to_CC_state q m).
Lemma acyclic_core_step_decreases ge q m q' m':
 core_acyclic q m ->Clight_core.cl_step ge q m q' m' ->
 (core_acyclic q' m' \/core_returned q' m') /\core_control_rank q' m'<core_control_rank q m.
Proof.
 intros Valid Transition.
 pose proof(cl_corestep_not_at_external ge m q m' q' Transition)as Internal.
 destruct(cl_step_equiv ge q m q' m' Internal Transition)as[t Sim].
 exact(acyclic_step_decreases ge _ t _ Valid Sim).
Qed.
Lemma acyclic_core_not_external q m:core_acyclic q m ->cl_at_external q=None.
Proof. destruct q;cbn[core_acyclic CC_core_to_CC_state acyclic_state]in *;try contradiction;reflexivity. Qed.
Lemma acyclic_core_not_halted q m:core_acyclic q m ->cl_halted q=None.
Proof. destruct q;cbn[core_acyclic CC_core_to_CC_state acyclic_state]in *;try contradiction;reflexivity. Qed.
Section SafetyFuel.
Context{Oracle:Type}.
Variable symb:Clight.genv->extspec.injective_PTree block.
Variable rel:nat->mem->mem->Prop.
Variable spec:extspec.external_specification mem external_function Oracle.
Variable ge:Clight.genv.
Definition dry_safe n z q m:=@safeN_ Clight.genv CC_core mem Oracle symb rel(cl_core_sem ge)spec ge n z q m.
Theorem acyclic_dry_safety_fuel_returns n z q m:
 dry_safe n z q m ->core_acyclic q m ->core_control_rank q m<n ->
 exists count q' m',corestepN(cl_core_sem ge)count q m q' m' /\core_returned q' m'.
Proof.
 revert z q m;induction n as[|n IH];intros z q m Safe Valid Bound;[lia|].
 unfold dry_safe in Safe;inversion Safe;subst.
 - lazymatch goal with
   |T:semantics.corestep(cl_core_sem ge) q m ?next ?memnext,
    HS:@safeN_ _ _ _ _ _ _ _ _ _ n z ?next ?memnext|-_=>
    change(Clight_core.cl_step ge q m next memnext)in T;
    change(dry_safe n z next memnext)in HS;
    destruct(acyclic_core_step_decreases ge q m next memnext Valid T)as[[Next|Final]Lower]
   end.
   + lazymatch goal with HS:dry_safe n z ?next ?memnext|-_=>
     destruct(IH z next memnext HS Next ltac:(lia))as[count[qfinal[mfinal[Path Done]]]];
     exists(S count),qfinal,mfinal;split;[cbn;exists next,memnext;split;[assumption|exact Path]|exact Done]
     end.
   + exists 1%nat,c',m';split;[cbn;exists c',m';split;[assumption|reflexivity]|exact Final].
 - pose proof(acyclic_core_not_external q m Valid);cbn in *;congruence.
 - pose proof(acyclic_core_not_halted q m Valid);cbn in *;contradiction.
Qed.
End SafetyFuel.
Print Assumptions acyclic_core_step_decreases.
Print Assumptions acyclic_dry_safety_fuel_returns.

Lemma core_control_rank_memory_irrelevant q m1 m2:
 core_control_rank q m1=core_control_rank q m2.
Proof. destruct q;reflexivity. Qed.
Lemma core_acyclic_memory_irrelevant q m1 m2:
 core_acyclic q m1 <->core_acyclic q m2.
Proof. destruct q;reflexivity. Qed.
Lemma acyclic_juicy_step_decreases ge q jm q' jm':
 core_acyclic q(m_dry jm) ->juicy_extspec.jstep(cl_core_sem ge)q jm q' jm' ->
 (core_acyclic q'(m_dry jm') \/core_returned q'(m_dry jm')) /\
 core_control_rank q'(m_dry jm')<core_control_rank q(m_dry jm).
Proof.
 intros Valid[Dry Resources].
 apply(acyclic_core_step_decreases ge q(m_dry jm)q'(m_dry jm')Valid Dry).
Qed.
Print Assumptions acyclic_juicy_step_decreases.
