(* A bounded unsigned scan may nest other scans and return early. A normal
   guard establishes headroom; the body must preserve the induction variable. *)
Require Import VST.floyd.proofauto.
Require Import compcert.lib.Maps compcert.cfrontend.Clight.
Require Import CCV.CCStructuredRuns CCV.CCScanFrames CCV.CCScanGuard.
Import ListNotations.
Section Counted.
Variables (ge:Clight.genv) (f:Clight.function) (e:Clight.env).
Definition checked_guard id g := forall l,
 runs ge f e g (fun l0 _=>l0=l)
 (fun l' _=>preserves (assigned g) l l' /\ room id l')
 (fun l' _=>preserves (assigned g) l l').
Lemma simple_guard id bound : typeof bound=tuint ->
 checked_guard id (Sifthenelse (less_guard id bound) Sskip Sbreak).
Proof.
 intros Ty l; apply runs_if.
 - intros l0 m [Eq T] k done N B R; subst l0.
   apply N;split;[apply preserves_self|eapply uint_test_room;eauto].
 - intros l0 m [Eq T] k done N B R;subst l0;apply B;apply preserves_self.
Qed.
Lemma guard_prefix id a g :
 framed ge f e a -> checked_guard id g -> checked_guard id (Ssequence a g).
Proof.
 intros A G l;apply runs_seq with (M:=fun l' _=>preserves (assigned a) l l').
 - intros l0 m Eq k done N B R;subst l0. eapply (A l);[reflexivity|exact N| |exact R].
   intros l' m' F;apply B. eapply preserves_weaken;[apply incl_appl;apply incl_refl|exact F].
 - intros l0 m F k done N B R. eapply (G l0);[reflexivity| | |exact R].
   + intros l' m' [F' Head];apply N;split;[apply(preserves_both _ _ _ _ _ F F')|assumption].
   + intros l' m' F';apply B;apply(preserves_both _ _ _ _ _ F F').
Qed.
Lemma bounded_scan id g body :
 checked_guard id g -> framed ge f e body ->
 ~ In id (assigned g ++ assigned body) ->
 framed ge f e (Sloop (Ssequence g body) (increment id)).
Proof.
 intros G Body Unchanged initial.
 set (ws := assigned (Sloop (Ssequence g body) (increment id))).
 set (Inv := fun (l:Clight.temp_env) (_:mem)=>preserves ws initial l).
 eapply runs_consequence with (P':=Inv) (N':=Inv) (B':=Inv).
 - intros l m Eq;subst l;apply preserves_self.
 - eapply runs_loop with (rank:=fun l _=>counter_rank id l)
   (mid:=fun l _ l' m'=>Inv l' m' /\ PTree.get id l'=PTree.get id l /\ room id l').
   + intros l m Inv0;apply runs_seq with
     (M:=fun l' _=>preserves (assigned g) l l' /\ room id l').
     * intros l0 m0 [Eq Em] k done N B R;subst l0 m0.
       eapply (G l);[reflexivity|exact N| |exact R].
       intros l' m' F;apply B;intros j Outside;rewrite F,Inv0;try reflexivity;intro Member;
       apply Outside;unfold ws;simpl;rewrite !in_app_iff;tauto.
     * intros l0 m0 [F Room] k done N B R;eapply (Body l0); [reflexivity| | |exact R].
       all: intros l' m' F';pose proof (preserves_both _ _ _ _ _ F F') as Both;
         assert (Now:Inv l' m') by
          (intros j Outside;rewrite Both,Inv0;try reflexivity;intro Member;
           apply Outside;unfold ws;simpl;rewrite !in_app_iff in *;tauto).
       -- apply N;split;[exact Now|];split;[apply Both;exact Unchanged|].
          destruct Room as [x [Get Less]];exists x;split;[rewrite F';[exact Get|]|exact Less].
          intro Member;apply Unchanged;apply in_or_app;auto.
       -- apply B;exact Now.
   + intros l m Inv0;apply runs_set;intros l' m' v [Now [Same [x [Get Less]]]] Value.
     rewrite (increment_room _ _ _ _ _ _ _ Get Value).
     split.
     * intros j Outside;rewrite PTree.gso.
       -- apply Now;assumption.
       -- intro Eq;subst j;apply Outside;unfold ws;simpl;rewrite !in_app_iff;simpl;tauto.
     * unfold counter_rank at 2;rewrite <-Same,Get.
       pose proof(increment_decreases id l' x Get Less) as Rk;unfold counter_rank at 2 in Rk;
       rewrite Get in Rk;exact Rk.
 - intros;assumption.
 - intros;assumption.
Qed.
End Counted.
