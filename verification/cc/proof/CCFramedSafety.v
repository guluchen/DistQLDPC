(* Library-state form of the safety transfer in VST 2.14,
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

Lemma framed_library_safety:
   forall {Espec: OracleKind} 
     (dryspec: ext_spec OK_ty)
     (dessicate : forall (ef : external_function) jm,
               ext_spec_type OK_spec ef ->
               ext_spec_type dryspec ef)
     (Jsub: forall ef se lv m t v m' (EFI : ef_inline ef = true) m1
       (EFC : Events.external_call ef se lv m t v m'), mem_sub m m1 ->
       exists m1' (EFC1 : Events.external_call ef se lv m1 t v m1'),
         mem_sub m' m1' /\ proj1_sig (inline_external_call_mem_events _ _ _ _ _ _ _ EFI EFC1) =
         proj1_sig (inline_external_call_mem_events _ _ _ _ _ _ _ EFI EFC))
     (Jframe: extspec_frame OK_spec)
     (JDE: juicy_dry_ext_spec _ (@JE_spec OK_ty OK_spec) dryspec dessicate)
     (DME: ext_spec_mem_evolve _ dryspec)
     (Esub: forall v z m m', ext_spec_exit dryspec v z m -> mem_sub m m' -> ext_spec_exit dryspec v z m')
     (prog : Clight.program) (n : nat) (ora : OK_ty)
     (jm z : juicy_mem) (q : CC_core)
     (H4 : (level jm <= n)%nat)
     (J : joins (ghost_of (m_phi z)) (Some (ghost_PCM.ext_ref ora, NoneP) :: nil))
     (Hwsat : exists w, join (m_phi jm) w (m_phi z) /\
       (invariants.wsat * invariants.ghost_set invariants.g_en Ensembles.Full_set)%pred w)
     (Hmem : mem_sub (m_dry jm) (m_dry z))
     (H6 : semax.jsafeN OK_spec (globalenv prog) ora q jm),
     @dry_safeN _ _ _ OK_ty semax.genv_symb_injective
        (cl_core_sem (globalenv prog)) dryspec (globalenv prog) (level jm) ora q (m_dry z).
Proof.
 intros. unfold semax.jsafeN in H6.
 revert ora jm z q H4 J Hwsat Hmem H6; induction n; intros.
 assert (level jm = 0%nat) by lia. rewrite H; constructor.
 inv H6.
 - rewrite H; constructor.
 - (* in the juicy semantics, we took a step with jm *)
   destruct H as (?&?&Hl&Hg).
   (* so we can take the same step with the full memory z *)
   destruct (CLC_evsem (globalenv prog)) eqn: Hevsem; inv Hevsem.
   destruct (CLC_memsem (globalenv prog)) eqn: Hmemsem; inv Hmemsem.
   simpl in ev_step_ax1, ev_step_ax2.
   apply ev_step_ax2 in H as [T H].
   pose proof (ev_step_elim _ _ _ _ _ H) as Helim.
   eapply cl_evstep_extends in H as (m1' & H & Hmem'); eauto.
   pose proof (ev_step_elim _ _ _ _ _ H) as Helim1; clear ev_step_elim.
   apply ev_step_ax1 in H.
   rewrite Hl; eapply safeN_step.
   + red. red. fold (globalenv prog). eassumption.
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
     apply IHn; eauto. lia.
 -
   unfold extspec_frame in Jframe.
   destruct dryspec as [ty pre post exit].
   destruct JE_spec as [ty' pre' post' exit'].
   change (level (m_phi jm)) with (level jm) in *.
   destruct JDE as [JDE1 [JDE2 JDE3]].
   destruct (level jm) eqn: Hl; [constructor|].
   destruct Hwsat as (w & Jw & Hw).
   edestruct Jframe as (x' & H0' & Hpost); eauto.
   eapply safeN_external.
   { eassumption. }
   { eapply JDE1; eauto. }
   simpl. intros.
   assert (level jm = level z) as Hlz.
   { apply join_level in Jw as []; rewrite <- !level_juice_level_phi in *; lia. }
   (* We need to reconstruct the full jm, then find a sub-memory s.t.
      join sub w jm'. *)
   assert (H20: exists jm', m_dry jm' = m'
                    /\ (level jm' = n')%nat
                    /\ juicy_safety.pures_eq (m_phi z) (m_phi jm')
                    /\ resource_at (m_phi jm') = resource_fmap (approx (level jm')) (approx (level jm')) oo juicy_mem_lemmas.rebuild_juicy_mem_fmap z (m_dry jm')
                    /\ compcert_rmaps.RML.R.ghost_of (m_phi jm') = Some (ghost_PCM.ext_ghost z', compcert_rmaps.RML.R.NoneP) :: ghost_fmap (approx (level jm')) (approx (level jm')) (tl (ghost_of (m_phi z)))). {
     destruct (juicy_mem_lemmas.rebuild_juicy_mem_rmap z m')
          as [phi [? [? ?]]].
     assert (own.ghost_approx phi (Some (ghost_PCM.ext_ghost z', NoneP) :: tl (compcert_rmaps.RML.R.ghost_of phi)) =
        Some (ghost_PCM.ext_ghost z', NoneP) :: tl (compcert_rmaps.RML.R.ghost_of phi)) as Happrox.
     { simpl; f_equal.
        rewrite <- compcert_rmaps.RML.ghost_of_approx at 2.
        destruct (compcert_rmaps.RML.R.ghost_of phi); auto. }
     set (phi1 := initial_world.set_ghost _ _ Happrox).
     assert (level phi1 = level phi /\ resource_at phi1 = resource_at phi) as [Hl1 Hr1].
     { subst phi1; unfold initial_world.set_ghost; rewrite level_make_rmap, resource_at_make_rmap; auto. }
     pose (phi' := age_to.age_to n' phi1).
     assert (mem_rmap_cohere m' phi') as H10. {
       clear - H0' Hr1 Hl1 H8 H7 H5 H2 Hmem DME JDE1.
       eapply JDE1 in H0'; eauto.
       specialize (DME e _ _ _ _ _ _ _ _ _ _ H0' H5).
       subst phi'.
       apply age_to_cohere.
       subst phi1.
       apply set_ghost_cohere.
       eapply mem_evolve_cohere; eauto.
     }
     destruct H10 as [H10 [H11 [H12 H13]]].
     pose (jm' := mkJuicyMem _ _ H10 H11 H12 H13).
     exists jm'.
     assert (n' <= level phi1)%nat by lia.
     split; [ | split3].
     * subst jm'; simpl; auto.
     * subst jm' phi'; simpl. apply age_to.level_age_to; auto.
     * unfold juicy_safety.pures_eq, juicy_safety.pures_sub. subst jm' phi'; simpl.
       split; intros; rewrite age_to_resource_at.age_to_resource_at, Hr1, H7;
         unfold juicy_mem_lemmas.rebuild_juicy_mem_fmap; destruct (m_phi z @ _); simpl; eauto;
         try solve [try (destruct k; auto); if_tac; auto].
       rewrite age_to.level_age_to; auto.
     * subst jm' phi'; simpl. split.
       { extensionality. rewrite age_to_resource_at.age_to_resource_at, Hr1, H7.
         rewrite age_to.level_age_to; auto. }
       rewrite age_to_resource_at.age_to_ghost_of, age_to.level_age_to; auto.
       subst phi1.
       unfold initial_world.set_ghost; rewrite ghost_of_make_rmap, H8; auto.
   }
   destruct H20 as [jm' [H26 [H27 [H28 [H29 Hg']]]]].
   subst m'; eapply JDE2 in H5; eauto 7.
   apply Hpost in H5 as (jm1 & ? & ? & Jw').
   specialize (H1 ret jm1 z' Hargsty Hretty).
   assert (level jm1 = level jm') as Hl1 by (apply join_level in Jw' as []; rewrite <- !level_juice_level_phi in *; lia).
   spec H1.
   { split; [lia|].
     eapply juicy_safety.pures_eq_trans, juicy_safety.pures_eq_trans; [| apply join_sub_pures_eq; eexists; eauto | | eauto |];
       rewrite <- ?level_juice_level_phi; try lia.
     apply pures_eq_sym, join_sub_pures_eq; [|eexists; eauto].
     rewrite <- !level_juice_level_phi; auto. }
   spec H1. assumption.
   destruct H1 as [c' [H2a H2b]]; exists c'; split; auto.
   (* eliminate fupd *)
   assert (app_pred (invariants.wsat * invariants.ghost_set invariants.g_en Ensembles.Full_set)%pred
         (age_to.age_to (level jm1) w)).
   { eapply pred_nec_hereditary, Hw; apply age_to.age_to_necR. }
   edestruct H2b as (x1 & ? & Hz' & Hsafe); eauto.
   { apply join_sub_refl. }
   { rewrite Hg'; eexists; do 2 constructor; simpl.
     instantiate (1 := (_, _)); split; simpl; [apply semax_prog.ext_ref_join | repeat constructor]. }
   assert (level x1 = level jm') as Hl'.
   { destruct Hz' as (? & ? & ?); lia. }
   subst n'; destruct Hsafe as [Hsafe | (m2 & ? & ? & ? & ? & Hsafe)].
   { rewrite <- Hl', Hsafe; constructor. }
   assert (level jm' = level m2) as Hl2 by (apply join_level in H8 as []; rewrite <- !level_juice_level_phi in *; lia).
   rewrite Hl2.
   destruct Hz' as [<- ?].
   apply IHn; eauto. lia.
 - eapply safeN_halted; eauto.
   eapply Esub; eauto.
   apply JDE; auto.
Qed.
Print Assumptions framed_library_safety.
