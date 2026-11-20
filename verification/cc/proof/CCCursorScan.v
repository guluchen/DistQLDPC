(* The normalized short-circuit cursor scan increments inside the loop body.
   If the first comparison fails, the compiler writes false to the guard
   temporary, so the increment cannot execute. *)
Require Import VST.floyd.proofauto VST.veric.Clight_lemmas.
Require Import compcert.lib.Maps compcert.cfrontend.Clight.
Require Import CCV.CCStructuredRuns CCV.CCScanFrames CCV.CCScanGuard CCV.CCCountedScan.
Import ListNotations.
Section Cursor.
Variables (ge:Clight.genv) (f:Clight.function) (e:Clight.env).
Lemma zero_not_taken l m flag :
 PTree.get flag l=Some(Vint Int.zero) -> ~takes ge e l m (Etempvar flag tint) true.
Proof.
 intros Get [v [Ev T]].
 assert (Zero:Clight.eval_expr ge e l m (Etempvar flag tint) (Vint Int.zero))
   by (apply Clight.eval_Etempvar;assumption).
 rewrite (eval_expr_fun Ev Zero) in T;discriminate.
Qed.
Definition produces s (P:Clight.temp_env->Prop) := forall before,
 runs ge f e s (fun l _=>l=before)
  (fun l _=>preserves (assigned s) before l /\ P l)
  (fun l _=>preserves (assigned s) before l).
Lemma produce_prefix a b P :
 framed ge f e a -> produces b P -> produces (Ssequence a b) P.
Proof.
 intros Fr G before;apply runs_seq with(M:=fun l _=>preserves (assigned a) before l).
 - intros l m Eq k done N B R; eapply (Fr before);[exact Eq|exact N| |exact R].
   intros l' m' F;apply B;eapply preserves_weaken;[apply incl_appl;apply incl_refl|exact F].
 - intros l m F k done N B R; eapply (G l);[reflexivity| | |exact R].
   + intros l' m' [F' Out];apply N;split;[apply(preserves_both _ _ _ _ _ F F')|exact Out].
   + intros l' m' F';apply B;apply(preserves_both _ _ _ _ _ F F').
Qed.
Lemma short_comparison id flag bound test :
 typeof bound=tuint -> ~In id (assigned test) -> framed ge f e test ->
 produces (Sifthenelse (less_guard id bound) test (Sset flag (Econst_int Int.zero tint)))
 (fun l=>room id l \/ PTree.get flag l=Some(Vint Int.zero)).
Proof.
 intros Ty Fresh Test before;apply runs_if.
 - intros l m [Eq T] k done N B R;subst l.
   eapply (Test before);[reflexivity| | |exact R].
   + intros l' m' Fr;apply N;split.
     * eapply preserves_weaken;[apply incl_appl;apply incl_refl|exact Fr].
     * left;destruct (uint_test_room _ _ _ _ _ _ Ty T) as [x [Get Lt]].
       exists x;split;[rewrite Fr by assumption;exact Get|exact Lt].
   + intros l' m' Fr;apply B;eapply preserves_weaken;[apply incl_appl;apply incl_refl|exact Fr].
 - apply runs_set;intros l m v [Eq _] Ev;subst l;inversion Ev;subst;
   try match goal with L:Clight.eval_lvalue _ _ _ _ (Econst_int _ _) _ _ _ |- _ =>inversion L end.
   split;[|right;apply PTree.gss]. intros j Outside;rewrite PTree.gso;[reflexivity|].
   intro Eq;subst j;apply Outside;simpl;apply in_or_app;simpl;auto.
Qed.
Lemma short_guard id flag prep :
 produces prep (fun l=>room id l \/ PTree.get flag l=Some(Vint Int.zero)) ->
 checked_guard ge f e id (Ssequence prep (Sifthenelse (Etempvar flag tint) Sskip Sbreak)).
Proof.
 intros G before;apply runs_seq with (M:=fun l _=>preserves (assigned prep) before l /\
    (room id l \/ PTree.get flag l=Some(Vint Int.zero))).
 - intros l m Eq k done N B R;eapply (G before);[exact Eq|exact N| |exact R].
   intros l' m' Fr;apply B;eapply preserves_weaken;[apply incl_appl;apply incl_refl|exact Fr].
 - apply runs_if.
   + intros l m [[Fr [Rm|Zero]] T] k done N B R.
     * apply N;split;[eapply preserves_weaken;[apply incl_appl;apply incl_refl|exact Fr]|exact Rm].
     * exfalso;exact (zero_not_taken _ _ _ Zero T).
   + intros l m [[Fr _] _] k done N B R;apply B.
     eapply preserves_weaken;[apply incl_appl;apply incl_refl|exact Fr].
Qed.
Lemma while_increment id g :
 checked_guard ge f e id g -> ~In id (assigned g) ->
 framed ge f e (Sloop (Ssequence g (increment id)) Sskip).
Proof.
 intros Guard Fresh before.
 set (ws:=assigned (Sloop (Ssequence g (increment id)) Sskip)).
 set (I0:=fun (l:Clight.temp_env) (_:mem)=>preserves ws before l).
 eapply runs_consequence with (P':=I0) (N':=I0) (B':=I0).
 - intros l m Eq;subst;apply preserves_self.
 - eapply runs_loop with (rank:=fun l _=>counter_rank id l)
    (mid:=fun l _ l' m'=>I0 l' m' /\ (counter_rank id l'<counter_rank id l)%nat).
   + intros l m Invariant; apply runs_seq with (M:=fun l' _=>preserves (assigned g) l l' /\ room id l').
     * intros l0 m0 [Eq Em] k done N B R;subst.
       eapply (Guard l);[reflexivity|exact N| |exact R]. intros l' m' Fr;apply B.
       intros j Outside;rewrite Fr,Invariant;try reflexivity;intro H;apply Outside;
       unfold ws;simpl;rewrite !in_app_iff;simpl;tauto.
     * apply runs_set;intros l' m' v [Fr [x [Get Less]]] Ev.
       rewrite (increment_room _ _ _ _ _ _ _ Get Ev). split.
       -- intros j Outside;rewrite PTree.gso,Fr,Invariant;try reflexivity;
          intro H;apply Outside;unfold ws;simpl;rewrite !in_app_iff;simpl;intuition congruence.
       -- pose proof(increment_decreases id l' x Get Less) as Strict.
          unfold counter_rank at 2 in Strict;unfold counter_rank at 2;rewrite <- (Fr id Fresh);exact Strict.
   + intros;apply runs_skip.
 - intros;assumption.
 - intros;assumption.
Qed.
End Cursor.
