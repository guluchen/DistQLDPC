(* Internal-state specialization of VST 2.14 veric/Clight_evsem.v,
   cl_evstep_extends. The syntactic source check rules out both external
   cases in the original proof.

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
Require Import VST.veric.Clight_evsem VST.veric.juicy_mem.
Require Import VST.veric.Clight_base VST.veric.Clight_core VST.sepcomp.event_semantics.
Require Import CCV.CCInternalPaths.
Require Import VST.veric.Clight_mem_lessdef VST.veric.mem_lessdef.

Import Ctypes Cop.
Definition ordinary_core (q:CC_core) := internal_source (CC_core_to_CC_state q Mem.empty).
Lemma ordinary_view st : ordinary_core (core_of st)=internal_source st.
Proof. destruct st; reflexivity. Qed.
Lemma internal_event_extends : forall ge c m T c' m' m1
  (Ord:ordinary_core c=true), cl_evstep ge c m T c' m' ->
  mem_sub m m1 -> exists m1', cl_evstep ge c m1 T c' m1' /\ mem_sub m' m1'.
Proof.
  intros until 2.
  revert m1; induction H; intros;
    repeat match goal with
    | H : eval_exprT _ _ _ m _ _ _ |- _ => eapply eval_exprT_sub in H; eauto
    | H : eval_lvalueT _ _ _ m _ _ _ _ _ |- _ => eapply eval_lvalueT_sub in H; eauto
    | H : sem_cast _ _ _ m = _ |- _ => eapply sem_cast_mem_sub in H; eauto
    | H : eval_exprTlist _ _ _ m _ _ _ _ |- _ => eapply eval_exprTlist_sub in H; eauto
    end; try solve [do 2 eexists; [econstructor; eauto|]; eauto].
  - eapply assign_locT_sub in H2 as (? & ? & ?); eauto.
    do 2 eexists; eauto; econstructor; eauto.

  - discriminate.
  - assert (bool_val v1 (typeof a) m1 = Some b).
    { unfold bool_val in *.
      destruct (classify_bool _); auto.
      destruct v1; auto.
      destruct (negb Archi.ptr64); try discriminate; destruct (Mem.weak_valid_pointer m _ _) eqn: Hweak; inv H0;
        erewrite mem_sub_weak_valid_pointer; eauto. }
    do 2 eexists; eauto; econstructor; eauto.
  - eapply free_list_sub in H as (? & ? & ?); eauto.
    do 2 eexists; eauto; econstructor; eauto.
  - eapply free_list_sub in H1 as (? & ? & ?); eauto.
    do 2 eexists; eauto; econstructor; eauto.
  - eapply free_list_sub in H0 as (? & ? & ?); eauto.
    do 2 eexists; eauto; econstructor; eauto.
  - apply alloc_variablesT_elim in H1 as [Helim Hm1].
    eapply ev_elim_sub in Helim as (? & ? & Helim'); eauto.
    apply Hm1 in Helim'.
    do 2 eexists; eauto; econstructor; eauto.
  - discriminate.
Qed.
