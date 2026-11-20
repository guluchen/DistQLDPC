(* A register frame for the finite-or-stuck operational calculus.  The
   projection is local to the caller, so memory writes may alias arbitrarily. *)
Require Import VST.floyd.proofauto.
Require Import compcert.lib.Maps compcert.cfrontend.Clight CCV.CCStructuredRuns.
Import ListNotations.
Fixpoint assigned (s:statement) : list ident :=
 match s with
 | Sset id _ | Scall (Some id) _ _ => [id]
 | Ssequence a b | Sifthenelse _ a b | Sloop a b => assigned a ++ assigned b
 | _ => []
 end.
Definition preserves (ws:list ident) (before after:Clight.temp_env) :=
 forall id, ~In id ws -> PTree.get id after=PTree.get id before.
Lemma preserves_self ws l : preserves ws l l.
Proof. red;auto. Qed.
Lemma preserves_both a b l l' l'' :
 preserves a l l' -> preserves b l' l'' -> preserves (a++b) l l''.
Proof. intros A B id Outside; rewrite in_app_iff in Outside. rewrite B,A by tauto. reflexivity. Qed.
Lemma preserves_weaken a b l l' : incl a b -> preserves a l l' -> preserves b l l'.
Proof. unfold incl,preserves;intros;eauto. Qed.
Section Frames.
Variables (ge:Clight.genv) (f:Clight.function) (e:Clight.env).
Definition framed s := forall before, runs ge f e s (fun l _ => l=before)
 (fun l _ => preserves (assigned s) before l)
 (fun l _ => preserves (assigned s) before l).
Lemma framed_skip : framed Sskip.
Proof. intros before l m Eq k done N B R; subst l; apply N; apply preserves_self. Qed.
Lemma framed_break : framed Sbreak.
Proof. intros before l m Eq k done N B R; subst l; apply B; apply preserves_self. Qed.
Lemma framed_return a : framed (Sreturn a).
Proof. intros before;apply runs_return. Qed.
Lemma framed_set id a : framed (Sset id a).
Proof.
 intros before. apply runs_set; intros le m v Eq Value;subst le.
 intros i Left; simpl in Left. rewrite PTree.gso by intuition. reflexivity.
Qed.
Lemma framed_assign x y : framed (Sassign x y).
Proof. intros before;apply runs_assign;intros;subst;apply preserves_self. Qed.
Lemma framed_keep s (Inv:configuration) :
 framed s -> (forall l m l' m',Inv l m -> preserves (assigned s) l l' -> Inv l' m') ->
 runs ge f e s Inv Inv Inv.
Proof.
 intros F Keep l m H k done N B R.
 eapply (F l); [reflexivity| | |exact R]; intros l' m' Frame;
 [apply N|apply B]; eapply Keep;eauto.
Qed.
Lemma framed_seq a b : framed a -> framed b -> framed (Ssequence a b).
Proof.
 intros A B before.
 eapply runs_seq with (M:=fun l _=>preserves (assigned a) before l).
 - eapply runs_consequence; [|exact (A before)| |];intros;try assumption.
   eapply preserves_weaken; [apply incl_appl;apply incl_refl|eassumption].
 - intros l m Frame k done N Br R. eapply (B l); [reflexivity| | |exact R];
   intros l' m' F; [apply N|apply Br];apply (preserves_both _ _ _ _ _ Frame F).
Qed.
Lemma framed_if test a b : framed a -> framed b -> framed (Sifthenelse test a b).
Proof.
 intros A B before;apply runs_if.
 - intros l m [Eq _] k done N Br R;subst l.
   eapply (A before);[reflexivity| | |exact R];
   intros l' m' F;[apply N|apply Br].
   all: eapply preserves_weaken; [apply incl_appl;apply incl_refl | exact F].
 - intros l m [Eq _] k done N Br R;subst l.
   eapply (B before);[reflexivity| | |exact R];
   intros l' m' F;[apply N|apply Br].
   all: eapply preserves_weaken; [apply incl_appr;apply incl_refl | exact F].
Qed.
End Frames.
