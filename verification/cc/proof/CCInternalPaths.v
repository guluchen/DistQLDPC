(* Preserve the source of every transition, so no external or built-in
   behavior can enter the sequential finite-path safety argument. *)
Require Import VST.floyd.proofauto.
Require Import VST.veric.Clight_core VST.veric.semax_lemmas.
Require Import compcert.common.Smallstep compcert.cfrontend.Clight.
Definition internal_source (s:Clight.state) : bool :=
 match s with
 | Clight.State _ (Sbuiltin _ _ _ _) _ _ _ _ => false
 | Clight.Callstate (External _ _ _ _) _ _ _ => false
 | Clight.Returnstate _ Kstop _ => false
 | _ => true end.
Class Ordinary (s:Clight.state) : Prop := { ordinary_source:internal_source s=true }.
#[export] Hint Extern 2 (Ordinary _) => constructor;reflexivity : typeclass_instances.
Definition internal_step ge s t s' := internal_source s=true /\ Clight.step2 ge s t s'.
Lemma internal_path_actual ge s t s' :
 star internal_step ge s t s' -> star Clight.step2 ge s t s'.
Proof.
 intro Path;induction Path;[apply star_refl|].
 destruct H as [_ T];eapply star_step;eauto.
Qed.
Definition core_of s := fst (CC_state_to_CC_core s).
Definition memory_of s := snd (CC_state_to_CC_core s).
Lemma view_state s : CC_core_to_CC_state (core_of s) (memory_of s)=s.
Proof. destruct s;reflexivity. Qed.
Lemma internal_clight_to_core ge s t s' :
 internal_step ge s t s' ->
 cl_step ge (core_of s) (memory_of s) (core_of s') (memory_of s').
Proof.
 intros [Regular T];inversion T;subst;cbn [core_of memory_of CC_state_to_CC_core fst snd internal_source] in *;
 try discriminate; econstructor;eauto.
Qed.
Lemma internal_not_external s : internal_source s=true -> cl_at_external (core_of s)=None.
Proof.
 destruct s as [f a k e le m|fd args k m|v k m];[destruct a|destruct fd|destruct k];
 cbn;intros;try discriminate;reflexivity.
Qed.
Lemma internal_not_halted s : internal_source s=true -> cl_halted (core_of s)=None.
Proof.
 destruct s as [f a k e le m|fd args k m|v k m];[destruct a|destruct fd|destruct k];
 cbn;intros;try discriminate;reflexivity.
Qed.
