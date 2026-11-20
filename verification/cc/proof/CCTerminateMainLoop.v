(* Actual main-loop operational composition. CONDITIONAL on finite iteration
   executions with strict rank progress; that contract is NOT discharged by
   this file. In particular this is not whole-search total termination. *)
Require Import VST.floyd.proofauto.
Require Import compcert.lib.Maps compcert.common.Events compcert.common.Smallstep compcert.cfrontend.Clight.
Require Import CCV.CCClightRankedSegments CCV.CCTerminateWeight CCV.CCSearchFragments CCV.ccv_core.
Import ListNotations.
Local Transparent tptr tuchar tuint tint typeconv remove_attributes change_attributes Cop.sem_add.
Definition main_positive_guard:=Ebinop Cop.Ogt(Etempvar _depth tuint)(Econst_int(Int.repr 0)tuint)tint.
Definition main_iteration_cont k:=Kloop1
 (Ssequence(Sifthenelse main_positive_guard Sskip Sbreak)search_main_iteration)Sskip k.
Lemma operational_main_layout:search_main_loop=
 Sloop(Ssequence(Sifthenelse main_positive_guard Sskip Sbreak)search_main_iteration)Sskip.
Proof. reflexivity. Qed.
Lemma main_depth_guard_eval ge e le m d:
 PTree.get _depth le=Some(Vint d) ->
 Clight.eval_expr ge e le m main_positive_guard(Val.of_bool(Int.ltu Int.zero d)).
Proof.
 intros Depth;unfold main_positive_guard.
 eapply Clight.eval_Ebinop with(v1:=Vint d)(v2:=Vint Int.zero).
 - apply Clight.eval_Etempvar;exact Depth.
 - apply Clight.eval_Econst_int.
 - reflexivity.
Qed.
Lemma main_iteration_start_path ge e le m d k:
 PTree.get _depth le=Some(Vint d) ->Int.ltu Int.zero d=true ->
 star Clight.step2 ge(Clight.State f_search search_main_loop k e le m)E0
 (Clight.State f_search search_main_iteration(main_iteration_cont k)e le m).
Proof.
 intros Depth Positive;rewrite operational_main_layout.
 weight_silent_step. apply Clight.step_loop.
 weight_silent_step. apply Clight.step_seq.
 weight_silent_step. { eapply Clight.step_ifthenelse with(v1:=Val.of_bool true)(b:=true).
 - pose proof(main_depth_guard_eval ge e le m d Depth)as Guard;rewrite Positive in Guard;exact Guard.
 - reflexivity. }
 weight_silent_step. apply Clight.step_skip_seq.
 unfold main_iteration_cont;apply star_refl.
Qed.
Lemma main_zero_exit_path ge e le m d k:
 PTree.get _depth le=Some(Vint d) ->Int.ltu Int.zero d=false ->
 star Clight.step2 ge(Clight.State f_search search_main_loop k e le m)E0
 (Clight.State f_search Sskip k e le m).
Proof.
 intros Depth Zero;rewrite operational_main_layout.
 weight_silent_step. apply Clight.step_loop.
 weight_silent_step. apply Clight.step_seq.
 weight_silent_step. { eapply Clight.step_ifthenelse with(v1:=Val.of_bool false)(b:=false).
 - pose proof(main_depth_guard_eval ge e le m d Depth)as Guard;rewrite Zero in Guard;exact Guard.
 - reflexivity. }
 weight_silent_step. apply Clight.step_break_seq.
 weight_silent_step. apply Clight.step_break_loop1.
 apply star_refl.
Qed.
Lemma main_iteration_repeat_path ge e le m k:
 star Clight.step2 ge
 (Clight.State f_search Sskip(main_iteration_cont k)e le m)E0
 (Clight.State f_search search_main_loop k e le m).
Proof.
 unfold main_iteration_cont;rewrite operational_main_layout.
 weight_silent_step. apply Clight.step_skip_or_continue_loop1;left;reflexivity.
 weight_silent_step. apply Clight.step_skip_loop2.
 apply star_refl.
Qed.
Section ConditionalLoopTermination.
Variable ge:Clight.genv.
Variable e:Clight.env.
Variable k:Clight.cont.
Variable Inv:Clight.temp_env->mem->Prop.
Variable rank:Clight.temp_env->mem->nat.
Variable depth_defined:forall le m,Inv le m ->exists d,PTree.get _depth le=Some(Vint d).
Definition finite_iteration_contract:Prop:=forall le m d,
 Inv le m ->PTree.get _depth le=Some(Vint d) ->Int.ltu Int.zero d=true ->
 (exists t v m',star Clight.step2 ge
   (Clight.State f_search search_main_iteration(main_iteration_cont k)e le m)t
   (Clight.Returnstate v(Clight.call_cont k)m')) \/
 (exists t le' m',star Clight.step2 ge
   (Clight.State f_search search_main_iteration(main_iteration_cont k)e le m)t
   (Clight.State f_search Sskip(main_iteration_cont k)e le' m') /\
   Inv le' m' /\(rank le' m'<rank le m)%nat).
Definition main_head_state st:Prop:=exists le m,
 st=Clight.State f_search search_main_loop k e le m /\Inv le m.
Definition main_execution_finished st:Prop:=
 (exists le m,st=Clight.State f_search Sskip k e le m) \/
 (exists v m,st=Clight.Returnstate v(Clight.call_cont k)m).
Definition main_state_rank st:=match st with Clight.State _ _ _ _ le m=>rank le m|_=>0%nat end.
Theorem actual_main_loop_from_finite_iterations:
 finite_iteration_contract ->forall le m,Inv le m ->
 exists t finish,star Clight.step2 ge(Clight.State f_search search_main_loop k e le m)t finish /\
 main_execution_finished finish.
Proof.
 intros Iterations le m Initial.
 apply(ranked_clight_segments_terminate ge main_head_state main_execution_finished main_state_rank).
 - intros st[le0[m0[Eq Valid]]];subst st.
   destruct(depth_defined le0 m0 Valid)as[d Depth].
   destruct(Int.ltu Int.zero d)eqn:Positive.
   + destruct(Iterations le0 m0 d Valid Depth Positive)as [[t[v[m' Return]]]|[t[le'[m'[Body[Next Lower]]]]]].
     * left;exists t,(Clight.Returnstate v(Clight.call_cont k)m');split.
       -- eapply star_trans;[apply(main_iteration_start_path ge e le0 m0 d k Depth Positive)|exact Return|reflexivity].
       -- right;exists v,m';reflexivity.
     * right;exists(List.app t E0),(Clight.State f_search search_main_loop k e le' m');split.
       -- eapply star_trans.
          ++ apply(main_iteration_start_path ge e le0 m0 d k Depth Positive).
          ++ eapply star_trans;[exact Body|apply main_iteration_repeat_path|reflexivity].
          ++ reflexivity.
       -- split;[exists le',m';split;[reflexivity|exact Next]|exact Lower].
   + left;exists E0,(Clight.State f_search Sskip k e le0 m0);split.
     * apply(main_zero_exit_path ge e le0 m0 d k Depth Positive).
     * left;exists le0,m0;reflexivity.
 - exists le,m;split;[reflexivity|exact Initial].
Qed.
End ConditionalLoopTermination.
Print Assumptions actual_main_loop_from_finite_iterations.
