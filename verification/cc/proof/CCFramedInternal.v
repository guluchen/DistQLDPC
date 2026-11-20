(* Internal-path specialization of the safety transfer in VST 2.14,
   veric/SequentialClight2.v, whole_program_sequential_safety.
   The induction below is adapted from that proof. Its initial framed
   world and oracle compatibility are explicit library caller premises.

Verified Software Toolchain OPAM distribution

(c) 2007-2022 Andrew W. Appel et alia

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

- Redistribution of source code must retain the above copyright notice,
this list of conditions and the following disclaimer.

- Redistribution in binary form must reproduce the above copyright notice,
this list of conditions and the following disclaimer in the documentation
and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS "AS IS" AND ANY
EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR THE CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*)
Require Import VST.sepcomp.semantics.

Require Import VST.veric.Clight_base.
Require Import VST.veric.Clight_core.
Require Import VST.veric.Clight_lemmas.
Require Import VST.sepcomp.step_lemmas.
Require Import VST.sepcomp.event_semantics.
Require Import VST.veric.Clight_evsem.
Require Import VST.veric.SeparationLogic.
Require Import VST.veric.juicy_extspec.
Require Import VST.veric.juicy_mem.
(*Require VST.veric.NullExtension. *)
Require Import VST.veric.SeparationLogicSoundness.
Require Import VST.sepcomp.extspec.
Require Import VST.msl.msl_standard.

Import VericSound.
Import VericMinimumSeparationLogic.
Import VericMinimumSeparationLogic.CSHL_Def.
Import VericMinimumSeparationLogic.CSHL_Defs.

Require Import VST.veric.SequentialClight2.
Import VST.veric.compcert_rmaps.R.

Require Import CCV.CCInternalPaths CCV.CCInternalEvents.
Fixpoint internal_fuel (ge:Clight.genv) (n:nat) (q:CC_core) (m:mem) : Prop :=
 match n with
 | O => True
 | S n' => ordinary_core q=true ->
     exists q' m',cl_step ge q m q' m' /\ internal_fuel ge n' q' m'
 end.
Lemma framed_internal_fuel {Espec:OracleKind} (prog:Clight.program) :
 forall n (ora:OK_ty) jm z q (H4:(level jm<=n)%nat)
 (J:joins (ghost_of (m_phi z)) (Some (ghost_PCM.ext_ref ora,NoneP)::nil))
 (Hwsat:exists w, join (m_phi jm) w (m_phi z) /\
     (invariants.wsat * invariants.ghost_set invariants.g_en Ensembles.Full_set)%pred w)
 (Hmem:mem_sub (m_dry jm) (m_dry z))
 (H6:semax.jsafeN OK_spec (globalenv prog) ora q jm),
 internal_fuel (globalenv prog) (level jm) q (m_dry z).
Proof.
 induction n;intros.
 { assert (level jm=0%nat) by lia;rewrite H;exact I. }
 unfold semax.jsafeN in H6;inv H6.
 - rewrite H;exact I.
 - (* in the juicy semantics, we took a step with jm *)
   destruct H as (?&?&Hl&Hg).
   rewrite Hl;cbn [internal_fuel];intro Source.
   (* so we can take the same step with the full memory z *)
   destruct (CLC_evsem (globalenv prog)) eqn: Hevsem; inv Hevsem.
   destruct (CLC_memsem (globalenv prog)) eqn: Hmemsem; inv Hmemsem.
   simpl in ev_step_ax1, ev_step_ax2.
   apply ev_step_ax2 in H as [T H].
   pose proof (ev_step_elim _ _ _ _ _ H) as Helim.
   eapply internal_event_extends in H as (m1' & H & Hmem'); eauto.
   pose proof (ev_step_elim _ _ _ _ _ H) as Helim1; clear ev_step_elim.
   apply ev_step_ax1 in H.
   exists c',m1';split.
   + exact H.
   + destruct Hwsat as (w & Jw & Hw).
     (* the new full memory can be broken into the memory we got from the step,
        and the memory we left in the invariant *)
     assert (exists z', join (m_phi m') (age_to.age_to (level m') w) (m_phi z') /\ m_dry z' = m1') as (z' & J' & ?); subst.
     { apply corestep_mem, mem_step_evolve in H.
       destruct (juicy_mem_lemmas.rebuild_juicy_mem_rmap z m1') as (? & ? & Hr' & Hg').
       eapply mem_evolve_cohere in H; [|eauto].
       apply (age_to_cohere _ _ (level m')) in H as (A & B & C & D).
       exists (mkJuicyMem _ _ A B C D); split; auto; simpl.
       apply compcert_rmaps.RML.resource_at_join2; auto.
       * apply join_level in Jw as []. rewrite !level_juice_level_phi in *. rewrite age_to.level_age_to; auto; lia.
       * apply join_level in Jw as []. rewrite !level_juice_level_phi in *. rewrite !age_to.level_age_to; auto; lia.
       * intros; rewrite !age_to_resource_at.age_to_resource_at, Hr'.
         eapply join_ev_elim_commut; eauto.
       * rewrite !age_to_resource_at.age_to_ghost_of, Hg, Hg'.
         rewrite <- level_juice_level_phi; apply compcert_rmaps.RML.ghost_fmap_join, compcert_rmaps.RML.ghost_of_join; auto. }
     assert ((invariants.wsat * invariants.ghost_set invariants.g_en Ensembles.Full_set)%pred
       (age_to.age_to (level m') w)).
     { eapply pred_nec_hereditary, Hw; apply age_to.age_to_necR. }
     assert (joins (compcert_rmaps.RML.R.ghost_of (m_phi z'))
       (compcert_rmaps.RML.R.ghost_fmap
         (compcert_rmaps.RML.R.approx (level z'))
         (compcert_rmaps.RML.R.approx (level z'))
        (Some (ghost_PCM.ext_ref ora, compcert_rmaps.RML.R.NoneP) :: nil))).
     { assert (join (ghost_of (m_phi m')) (ghost_of (age_to.age_to (level m') w))
         (ghost_of (age_to.age_to (level m') (m_phi z)))) as J1.
       { rewrite Hg, !age_to_resource_at.age_to_ghost_of.
         apply compcert_rmaps.RML.ghost_fmap_join, compcert_rmaps.RML.ghost_of_join; auto. }
       eapply join_eq in J1; [|apply compcert_rmaps.RML.ghost_of_join; eauto].
       rewrite J1. rewrite age_to_resource_at.age_to_ghost_of.
       destruct J as [? J]; eapply compcert_rmaps.RML.ghost_fmap_join in J; simpl in *; eexists; apply J. }
     edestruct H0 as (? & ? & Hz' & Hsafe); eauto.
     { apply join_sub_refl. }
     assert (level x = level m') as Hl'.
     { destruct Hz' as (? & ? & ?); apply join_level in J' as [];
         rewrite <- !level_juice_level_phi in *; lia. }
     destruct Hsafe as [Hsafe | (m2 & ? & ? & ? & ? & Hsafe)].
     { rewrite <- Hl', Hsafe; constructor. }
     (* after accessing invariants, we have a new sub-memory m2, which
        completes to the same full memory *)
     assert (level m' = level m2) as Hl2 by (apply join_level in H6 as []; rewrite <- !level_juice_level_phi in *; lia).
     rewrite Hl2.
     destruct Hz' as [<- ?].
     eapply (IHn ora); eauto. lia.
 - destruct (level jm); cbn [internal_fuel]; [exact I|intro Source].
   pose proof (internal_not_external (CC_core_to_CC_state q Mem.empty) Source) as No.
   destruct q;cbn in *;congruence.
 - destruct (level jm); cbn [internal_fuel]; [exact I|intro Source].
   pose proof (internal_not_halted (CC_core_to_CC_state q Mem.empty) Source) as No.
   destruct q;cbn in *;congruence.
Qed.
Print Assumptions framed_internal_fuel.
