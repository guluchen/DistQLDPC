(* Termination up to undefined steps for both public entry points, with a
   symbolic body for search. The inclusive distance scan now has a strictly
   decreasing cap rank, even on a malformed raw heap. *)
Require Import VST.floyd.proofauto compcert.lib.Maps compcert.cfrontend.Clight.
Require Import CCV.ccv_core CCV.ccv_primitives CCV.CCFiniteSearch CCV.CCActualScans
 CCV.CCScanCallees CCV.CCScanFrames CCV.CCScanGuard CCV.CCCountedScan CCV.CCExpandedBody
 CCV.CCStructuredRuns CCV.CCCapGuard CCV.CCBodyProgram CCV.CCBoundedMain.
Import ListNotations.
Section Guard.
Variables (ge0:Clight.genv)(f:Clight.function)(e:Clight.env).
Lemma guarded_cap_scan g body :framed ge0 f e g ->framed ge0 f e body ->
 ~In ccv_core._cap (assigned g ++ assigned body) ->
 framed ge0 f e (Sloop (Ssequence (Ssequence g cap_check) body) (increment ccv_core._cap)).
Proof.
 intros G Body Unchanged.
 set (id:=ccv_core._cap) in *.
 assert(Checked:forall initial,
   runs ge0 f e (Ssequence g cap_check) (fun l _=>l=initial)
    (fun l _=>preserves (assigned g) initial l /\ room id l)
    (fun l _=>preserves (assigned g) initial l)).
 { intro initial;eapply runs_seq with (M:=fun l _=>preserves (assigned g) initial l).
   - apply G.
   - unfold cap_check;apply runs_if.
     + intros l m [Fr Take] k done N B R;apply N;split;[exact Fr|].
       exact(uint_test_room ge0 e l m id (Econst_int (Int.repr Int.max_unsigned) tuint) eq_refl Take).
     + intros l m H k done N B R;eapply blocked_settles;[constructor;reflexivity|].
       intros t next Step;eapply cap_dead_stuck;exact Step. }
 intro initial.
 set (ws := assigned (Sloop (Ssequence (Ssequence g cap_check) body) (increment id))).
 set (Inv := fun (l:Clight.temp_env) (_:mem)=>preserves ws initial l).
 eapply runs_consequence with (P':=Inv) (N':=Inv) (B':=Inv).
 - intros l m Eq;subst l;apply preserves_self.
 - eapply runs_loop with (rank:=fun l _=>counter_rank id l)
   (mid:=fun l _ l' m'=>Inv l' m' /\ PTree.get id l'=PTree.get id l /\ room id l').
   + intros l m Inv0;apply runs_seq with
     (M:=fun l' _=>preserves (assigned g) l l' /\ room id l').
     * intros l0 m0 [Eq Em] k done N B R;subst l0 m0.
       eapply (Checked l);[reflexivity|exact N| |exact R].
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
End Guard.
Section Driver.
Variables (p:Clight.program)(search:statement).
Local Notation ge := (Clight.globalenv p).
Local Notation search_f := (with_body f_search search).
Definition driver_bindings:list (ident*Clight.function) :=
 [(ccv_core._stats_init,f_stats_init);(ccv_core._shape,f_shape);(ccv_core._validate,f_validate);
  (ccv_core._clear,f_clear);(ccv_core._search,search_f);(ccv_core._ccv_weight,ccv_primitives.f_ccv_weight)].
Hypothesis Bound:forall i f,In (i,f) driver_bindings ->PTree.get i (AST.prog_defmap p)=Some(Gfun(Internal f)).
Hypothesis helper_ok:helpers_bound p.
Hypothesis search_ok:call_settles ge search_f.
Local Ltac bind := apply Bound;unfold driver_bindings;repeat(first[left;reflexivity|right]).
Local Ltac dispatch id :=
 lazymatch id with
 | ccv_core._stats_init=>constr:(f_stats_init) |ccv_core._shape=>constr:(f_shape)
 | ccv_core._validate=>constr:(f_validate) |ccv_core._clear=>constr:(f_clear)
 | ccv_core._search=>constr:(search_f) |ccv_core._ccv_weight=>constr:(ccv_primitives.f_ccv_weight)
 end.
Lemma finite_stats:call_settles ge f_stats_init. Proof. internal_body f_stats_init. Qed.
Lemma finite_shape_raw:call_settles ge f_shape. Proof. internal_body f_shape. Qed.
Lemma finite_validate_raw:call_settles ge f_validate. Proof. internal_body f_validate. Qed.
Lemma finite_weight_raw:call_settles ge ccv_primitives.f_ccv_weight. Proof. internal_body ccv_primitives.f_ccv_weight. Qed.
Local Ltac driver_walk :=
 lazymatch goal with
 | |- framed _ _ _ (Ssequence _ _) =>apply framed_seq;driver_walk
 | |- framed _ _ _ (Sifthenelse _ _ _) =>apply framed_if;driver_walk
 | |- framed _ _ _ (Scall _ (Evar ?id _) _) =>
   let callee:=dispatch id in eapply (framed_direct_call p id _ callee _ _ _);
   [bind|apply PTree.gempty|
    first[exact search_ok|apply finite_stats|apply finite_shape_raw|apply finite_validate_raw|
          apply finite_clear|apply finite_weight_raw]]
 | |- framed _ _ _ (Sloop (Ssequence (Ssequence ?g cap_check) _) (Sset ?id _)) =>
   apply guarded_cap_scan;[closed_frame|driver_walk|vm_compute;intuition congruence]
 | _ =>closed_frame end.
Theorem finite_decide_raw:call_settles ge f_ccv_decide.
Proof.
 apply structured_function_returns;intros args m e l m' Entry;
 pose proof(empty_call_env _ f_ccv_decide _ _ _ _ _ eq_refl Entry) as Empty;subst e.
 cbn [fn_body f_ccv_decide];driver_walk.
Qed.
Theorem finite_distance_raw:call_settles ge guarded_distance.
Proof.
 apply structured_function_returns;intros args m e l m' Entry;
 pose proof(empty_call_env _ guarded_distance _ _ _ _ _ eq_refl Entry) as Empty;subst e.
 cbn [guarded_distance with_body fn_body f_ccv_distance guard_cap_loops];driver_walk.
Qed.
End Driver.
