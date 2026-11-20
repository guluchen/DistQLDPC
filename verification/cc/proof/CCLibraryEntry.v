(* Generalized from VST 2.14 veric/semax_prog.v, semax_prog_entry_point.
   A library caller supplies its argument and specification resources.
   Only the linked function library, layout and global declarations are used.

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
Require Import VST.veric.juicy_base.
Require Import VST.veric.juicy_mem VST.veric.juicy_mem_lemmas VST.veric.juicy_mem_ops.
Require Import VST.veric.res_predicates.
Require Import VST.veric.extend_tc.
Require Import VST.veric.Clight_seplog.
Require Import VST.veric.Clight_assert_lemmas.
Require Import VST.veric.Clight_core.
Require Import VST.sepcomp.extspec.
Require Import VST.sepcomp.step_lemmas.
Require Import VST.veric.juicy_extspec.
Require Import VST.veric.tycontext.
Require Import VST.veric.expr2.
Require Import VST.veric.expr_lemmas.
Require Import VST.veric.semax.
Require Import VST.veric.semax_lemmas.
Require Import VST.veric.Clight_lemmas.
Require Import VST.veric.initial_world.
Require Import VST.msl.normalize.
Require Import VST.veric.semax_call.
Require Import VST.veric.semax_conseq.
Require Import VST.veric.Clight_initial_world.
Require Import VST.veric.initialize.
Require Import VST.veric.coqlib4.
Require Import Coq.Logic.JMeq.

Require Import Coq.Logic.JMeq.
Require Import VST.veric.ghost_PCM.

Import compcert.lib.Maps.

Import Ctypes Clight.

Local Open Scope pred.


Require Import VST.veric.semax_prog.
Section LibraryEntry.
Context (Espec:OracleKind).
Record library_context (CS:compspecs) V G (prog:Clight.program) : Prop := {
 lib_nodup : compute_list_norepet (prog_defs_names prog)=true;
 lib_cenv : PTree.elements (@cenv_cs CS) = PTree.elements (prog_comp_env prog);
 lib_functions : @semax_prog.semax_func Espec V G CS (Genv.globalenv prog) (prog_funct prog) G;
 lib_globals : match_globvars (prog_vars prog) V=true
}.
Lemma framed_function_entry {CS: compspecs} V G prog b id_fun params args A
   (P: forall ts : list Type, (dependent_type_functor_rec ts (ArgsTT A)) mpred)
   (Q: forall ts : list Type, (dependent_type_functor_rec ts (AssertTT A)) mpred)
  NEP NEQ h z:
  let retty := tint in
  postcondition_allows_exit Espec retty ->
  library_context CS V G prog ->
  Genv.find_symbol (globalenv prog) id_fun = Some b ->
  find_id id_fun G =
     Some (mk_funspec (params, retty) cc_default A P Q NEP NEQ) ->
  tc_vals params args ->
  let gargs := (filter_genv (globalenv prog), args) in
  { q : CC_core | (exists fd, Genv.find_funct_ptr (Genv.globalenv prog) b = Some fd /\ q=Clight_core.Callstate fd args Kstop) /\
 (   (forall jm,
     Forall (fun v => Val.inject (Mem.flat_inj (nextblock (m_dry jm))) v v)  args->
     inject_neutral (nextblock (m_dry jm)) (m_dry jm) /\
     Coqlib.Ple (Genv.genv_next (Genv.globalenv prog)) (nextblock (m_dry jm)) ->
    exists jm', semantics.initial_core
    (juicy_core_sem (cl_core_sem (globalenv prog))) h
    jm q jm' (Vptr b Ptrofs.zero) args) /\

  forall (jm : juicy_mem) ts (a: (dependent_type_functor_rec ts A) mpred),
    app_pred (P ts a gargs) (m_phi jm) ->
    app_pred (fungassert (nofunc_tycontext V G) gargs ) (m_phi jm) ->
    nth_error (ghost_of (m_phi jm)) 0 = Some (Some (ext_ghost z, NoneP)) ->
    jsafeN (@OK_spec Espec) (globalenv prog) z q jm) }.
Proof.
intro retty.
intros EXIT SP Findb id_in_G arg_p.
rewrite <-find_id_maketycontext_s in id_in_G.
pose proof (lib_cenv _ _ _ _ SP) as CSEQ.
destruct (lib_functions _ _ _ _ SP) as [MatchFdecs [Gcontains Believe]].
specialize (Believe (globalenv prog)).
spec Believe; [ intros; apply sub_option_refl |].
spec Believe; [ intros; apply sub_option_refl |].
specialize (Believe 0%nat).
apply believe_cs_ext with (ge2 :=
  {| genv_genv := genv_genv (globalenv prog);
     genv_cenv := prog_comp_env prog |}) in Believe; auto.
replace  {|
               genv_genv := genv_genv (globalenv prog);
               genv_cenv := prog_comp_env prog |}
 with (globalenv prog) in Believe
  by (unfold globalenv; f_equal; auto).
unfold nofunc_tycontext in *.
destruct (believe_exists_fundef Findb Believe id_in_G) as [f [Eb Ef]].
clear Believe.
exists (Clight_core.Callstate f args Kstop). split; [exists f;auto|].
simpl semantics.initial_core.
unfold j_initial_core.
simpl semantics.initial_core.
fold fundef in *.
split.
intros; exists jm; split; auto.
rewrite if_true by auto.
change (Genv.globalenv (program_of_program prog))
  with (genv_genv (globalenv prog)).
rewrite Eb; auto.
intros jm ts a m_sat_Pa m_funassert.
intros HZ.
set (psi := globalenv prog) in *.
destruct SP as [H0 _ [H2 [GC H3]] GV].
set (fspec := mk_funspec (params, retty) cc_default A P Q NEP NEQ) in *.
specialize (H3 (genv_genv psi)).
spec H3. intros; apply sub_option_refl.
spec H3. intros; apply sub_option_refl.
specialize (H3 (S (level jm))).
apply believe_cs_ext with (ge2 :=
  {| genv_genv := genv_genv (globalenv prog);
     genv_cenv := prog_comp_env prog |}) in H3; auto.
 fold psi in H3.
replace  {|
               genv_genv := genv_genv psi;
               genv_cenv := prog_comp_env prog |}
 with psi in *
  by (subst psi; unfold globalenv; f_equal; auto).
rename H3 into Prog_OK. assert (H3 := I).

rename z into ora.
assert (Hora: ext_compat ora (m_phi jm)). {
 pose proof (ext_ref_join ora).
 exists ((Some (ext_both ora, NoneP)) :: tl (ghost_of (m_phi jm))).
 destruct (ghost_of (m_phi jm)). inv HZ.
 simpl in HZ. inv HZ.
 constructor; auto.
 constructor.
 constructor; [auto|]. simpl. constructor; auto.
 simpl.
 apply ghost_join_nil_r.
}
clear HZ.
set (Delta := nofunc_tycontext V G) in *.
change (make_tycontext_s G)
   with (glob_specs Delta) in id_in_G.
change (make_tycontext nil nil nil Tvoid V G nil)
  with Delta in m_funassert.
assert  (TC5: typecheck_glob_environ (filter_genv psi) (glob_types Delta)). {
     eapply tc_ge_denote_initial; try eassumption.
     apply compute_list_norepet_e; auto.
}

clearbody Delta.
forget cc_default as cc.
change (prog_comp_env prog) with (genv_cenv psi) in *.


assert (HGG: cenv_sub (@cenv_cs CS) (globalenv prog)).
 { clear - CSEQ. forget (@cenv_cs CS) as cs1.
   subst psi. forget (genv_cenv (globalenv prog)) as cs2.
   hnf; intros; hnf.
   destruct (cs1 ! i) eqn:?H; auto.
   apply PTree.elements_correct in H.
   apply PTree.elements_complete. congruence.
 }

(***  cut here ****)

assert (H5 := Prog_OK).
specialize (H5 (Vptr b Ptrofs.zero)).
specialize (H5 (typesig_of_funspec fspec)
   (callingconvention_of_funspec fspec)).
specialize (H5 A P Q _ _ (necR_refl _) (ext_refl _)).
spec H5. { clear H5.
 exists id_fun. exists NEP. exists NEQ.
 split.
  rewrite id_in_G. reflexivity.
  exists b; split; auto.
}
destruct H5 as [H5|H5].
-
 simpl in H5.
 unfold believe_external in H5.
 change (Genv.find_funct (genv_genv psi)
           (Vptr b Ptrofs.zero))
   with (Genv.find_funct_ptr (genv_genv psi) b) in H5.
  rewrite Eb in H5.
  destruct f; try contradiction.
 destruct H5 as [[[? [? [? Hinline]]] ?] ?].
 destruct Hinline as [Hinline|Hempty].
 2:{ exfalso; clear - a Hempty. eapply Hempty; eauto. }
 subst c.
 simpl in H4.
 injection H; clear H; intros.
 subst t0.
 change (level (m_phi jm)) with (level jm) in H6.
 specialize (H5 psi ts a (level jm)).
 spec H5. constructor. reflexivity.
 specialize (H5 TT (typlist_of_typelist (typelist_of_type_list params)) args).
 specialize (H5 jm (Nat.le_refl _) _ _ (necR_refl _) (ext_refl _)).
 rewrite TTL2 in *.
 spec H5. { clear H5.
 split. simpl.
 rewrite H4; simpl.
 clear - arg_p.
 revert args arg_p; induction params; destruct args; simpl; intros; try discriminate; try contradiction;  auto.
 destruct arg_p;  split; auto.
 apply tc_val_has_type; auto.
 simpl fst.
 clear H3 H6.
 eapply sepcon_derives.
 apply derives_refl.
 instantiate (1:=emp); auto.
 rewrite sepcon_emp.
 auto.
}
 destruct (level jm) eqn:?H.
 constructor; auto.
 destruct H5 as [x' [? H9]].
 clear H1 H3 m_funassert m_sat_Pa Ef Eb.
 eapply jsafeN_external.
 simpl. rewrite Hinline.
 reflexivity.
 rewrite H4. simpl.
 apply H5.
 apply Hora.
 simpl.
 intros.
 rewrite H4 in *. simpl sig_res in *. simpl sig_args in *.
 assert (tc_option_val retty ret). {
  specialize (H9 (sig_res (ef_sig e)) ret z' m').
  spec H9. destruct H1 as [? ?];  lia.
  change (genv_symb_injective (Genv.globalenv prog))
   with (genv_symb_injective psi) in H3.
  rewrite H4 in H9.
  specialize (H9 _ _ (necR_refl _) (ext_refl _) H3).
  specialize (H6 ts a ret).
  destruct H9 as [? [? [? [? _]]]].
  specialize (H6 x).
  spec H6.  simpl. unfold natLevel. destruct H1 as [? ?].
  change (level (m_phi ?a)) with (level a).
  apply join_level in H7. destruct H7.
  change (level (m_phi ?a)) with (level a) in H7.
  lia.
  specialize (H6 _ _ (necR_refl _) (ext_refl _)).
  spec H6. split; auto.
  auto.
 }
 clear H6.
 eexists. split. reflexivity.
 apply jm_fupd_intro_strong'; intros.
 hnf in H9.
 unfold retty in H7. destruct ret; try contradiction H7.
 destruct v; try contradiction H7.
 eapply jsafeN_halted with i.
 simpl. congruence.
 apply (EXIT (Some (Vint i)) z' m'); auto.
-
(* internal case *)
hnf in H5.
destruct H5 as [b' [f' [[H5 [H9 H10]] H11]]].
symmetry in H5; inv H5.
inversion2 Eb H9. rename f' into f.
rename Eb into H7.

specialize (H11 Delta CS _ _ (necR_refl _) (ext_refl _)).

spec H11. { intro; apply tycontext_sub_refl. }
specialize (H11 _ _ (necR_refl _) (ext_refl _) cenv_sub_refl ts a).
red in H11.
specialize (H11 (level jm)).
spec H11. apply later_nat; clear; lia.
  rewrite semax_fold_unfold in H11.

specialize (H11 psi (func_tycontext' f Delta) CS _ _ (necR_refl _) (ext_refl _)
     (conj (tycontext_sub_refl _) (conj cenv_sub_refl HGG))
      _ _ (necR_refl _) (ext_refl _)).
  spec H11.
  eapply pred_nec_hereditary; try apply Prog_OK.
  apply nec_nat; lia.
  clear Prog_OK H3.
  specialize (H11 Kstop (fun _ => TT) f _ _ (necR_refl _) (ext_refl _)).
  simpl in Ef.
  assert (Hret: fn_return f = retty) by (destruct f; inv Ef; auto).
  spec H11. { clear H11.
   split. hnf; intros; reflexivity.
red. red. red. intros ek vl te ve.
set (rhox := construct_rho (filter_genv psi) ve te).
cbv zeta.
cut ((!! guard_environ (func_tycontext' f Delta) f rhox &&
 (stackframe_of' cenv_cs f rhox *
  bind_ret vl (fn_return f) (Q ts a) rhox *
  TT) && funassert (func_tycontext' f Delta) rhox >=>
 assert_safe Espec psi f ve te (exit_cont EK_return vl Kstop) rhox)
  (level jm)). {
  clearbody rhox; clear.
  evar (j: mpred).
  replace (proj_ret_assert
   (frame_ret_assert
      (frame_ret_assert (function_body_ret_assert (fn_return f) (Q ts a))
         (stackframe_of' cenv_cs f)) (fun _ : environ => TT)) ek vl rhox)
    with j.
  subst j.
  apply guard_fallthrough_return; auto.
  subst j.
  destruct ek; simpl; normalize.
  destruct (fn_return f); simpl; normalize;
  f_equal; pull_left (stackframe_of' cenv_cs f rhox); auto.
  pull_left (stackframe_of' cenv_cs f rhox); auto.
}
  subst rhox.
   intros y H3 ? a' H5 Hext [[H8 H9] H11].
   clear ek.
   simpl exit_cont.
   unfold proj_ret_assert, frame_ret_assert,
   function_body_ret_assert, RA_return in H9.
     rewrite predicates_sl.sepcon_assoc in H9.
    rewrite predicates_sl.sepcon_comm in H9.
   rewrite Hret in *.
   hnf; intros.
   destruct (can_free_list Delta TT f jm0
                       psi ve te)
     as [m2 ?].
  - destruct H10 as [_ [_ [? _]]]; auto.
  - destruct H10; auto.
  - auto.
  - apply H8.
  -
    subst a'.
     eapply predicates_sl.sepcon_derives; try apply H9; auto.
  -
     set (rho' := construct_rho (filter_genv psi)
            ve te) in *.
     destruct H10 as [COMPLETE [_ [H17' _]]].
  assert (H10:=I).
 assert (SFFB := stackframe_of_freeable_blocks Delta f rho' (globalenv prog) ve
     HGG COMPLETE H17'  (eq_refl _) H8).
  subst a'.
  exploit (@predicates_sl.sepcon_derives rmap _ _ _ _); [ | | apply H9 |].
   2:  apply SFFB.  apply predicates_hered.derives_refl.  clear H9.
  pull_left (freeable_blocks (blocks_of_env (globalenv prog) ve)).
 intro H13.
  rewrite predicates_sl.sepcon_assoc in H13.
  destruct (free_list_juicy_mem_i _ _ _ _ H6 H13) as [jm2 [? [? ?]]].
  destruct (age1 jm0) as [jm0' | ] eqn:?.
  2: apply age1_level0 in Heqo; destruct vl; intros; constructor; auto.
   destruct (age_twin' _ _ _ H12 Heqo)
       as [jm2' [? ?]].
   subst m2.
 assert (resource_decay (nextblock (m_dry jm0)) (m_phi jm0) (m_phi jm2') /\
            level jm0 = S (level jm2') /\
            ghost_of (m_phi jm2') =
            ghost_fmap (approx (level jm2')) (approx (level jm2'))
                  (ghost_of (m_phi jm0))). {
   split3.
  eapply resource_decay_trans.
  2: eapply free_list_resource_decay; eassumption.
  2: eapply age1_resource_decay; eassumption.
  rewrite (mem_lemmas.nextblock_freelist _ _ _ H6).
  apply Pos.le_refl.
  rewrite <- H14.
  apply age_level; auto.
  erewrite age1_ghost_of by (eapply age_jm_phi; eauto).
  f_equal.
  eapply free_list_juicy_mem_ghost; eauto.
 }
 assert ((ext_compat ora0) (m_phi jm2)). {
   pose proof (free_list_juicy_mem_ghost _ _ _ H4).
   clear - H16 H.
   hnf in H|-*. rewrite H16; auto.
 }
 eapply free_list_juicy_mem_lem in H4;[ | eassumption].
 apply (pred_nec_hereditary _ _ _ (laterR_necR (age_laterR (age_jm_phi H15)))) in H4.
 unfold ext_compat in H16. eapply ext_join_approx in H16. rewrite <- (age1_ghost_of _ _ (age_jm_phi H15)) in H16.
 move EXIT after H4.
 specialize (EXIT vl ora0 jm2').
 assert (tc_option_val retty vl). {
  clear - H13.
  rewrite predicates_sl.sepcon_comm in H13.
  rewrite !predicates_sl.sepcon_assoc in H13.
  destruct H13 as [? [? [? [? _]]]].
  subst retty.  destruct vl; simpl in H0; try contradiction.
  destruct H0 as [? _]. destruct v; try contradiction. eauto.
 }
 specialize (EXIT H17 H16).
 destruct vl; try contradiction.
 destruct v; try contradiction.
 clear H17.
 intros; eapply jsafeN_step; try instantiate (1:=jm2').
 split; auto; rewrite <- (age_jm_dry H15); econstructor; eauto.
 apply jm_fupd_intro'; eapply jsafeN_halted.
 instantiate (1:=i).
 simpl. clear; congruence.
 apply EXIT.
}

remember (alloc_juicy_variables psi empty_env jm (fn_vars f)) eqn:AJV.
destruct p as [ve' jm']; symmetry in AJV.
destruct (alloc_juicy_variables_e _ _ _ _ _ _ AJV) as [H15 [H20' CORE]].
assert (MATCH := alloc_juicy_variables_match_venv _ _ _ _ _ AJV).
assert (H20 := alloc_juicy_variables_resource_decay _ _ _ _ _ _ AJV).
destruct (build_call_temp_env f args)
as [te' H21]; auto.
  { clear - H10 arg_p. subst fspec; simpl in H10.
    destruct f; simpl in *.
    assert (Datatypes.length (map snd fn_params) =
                Datatypes.length params). assert (params = map snd fn_params) by apply H10. subst; trivial.
   rewrite !map_length in H. rewrite H.
   clear - arg_p. apply tc_vals_length; trivial.
}

(*** split here ****)
destruct (level jm) eqn:H2'; [constructor; auto |].

destruct (levelS_age1 _ _ H2') as [jm2 H13]. change (age jm jm2) in H13.
rewrite <- H2' in *. clear H2'.
pose proof (age_twin' _ _ _ H20' H13) as [jm'' [_ H20x]].
destruct H10 as [COMPLETE [H17 [H17' [Hvars H18]]]].

eapply jsafeN_step
  with (c' := Clight_core.State f (f.(fn_body)) Kstop ve' te')
       (m' := jm''); auto.
split; auto.
apply Clight_core.step_internal_function.
apply list_norepet_append_inv in H17; destruct H17 as [H17 [H22 H23]]; constructor; auto.
rewrite <- (age_jm_dry H20x); auto.
split.
 destruct H20;  apply resource_decay_trans with (nextblock (m_dry jm')) (m_phi jm'); auto.
 apply age1_resource_decay; auto.
 split.
 rewrite H20'; apply age_level; auto.
 erewrite <- (alloc_juicy_variables_ghost _ _ _ jm), AJV; simpl.
 apply age1_ghost_of, age_jm_phi; auto.
assert (H22: (level jm2 >= level jm'')%nat)
  by (apply age_level in H13; apply age_level in H20x; lia).
assert (H23: app_pred (fungassert Delta (filter_genv psi, args)) (m_phi jm'')).
{ apply (resource_decay_fungassert _ _ (nextblock (m_dry jm)) _ (m_phi jm'')) in m_funassert.
  2: apply laterR_necR; apply age_laterR; auto.
  apply m_funassert.
  rewrite CORE. apply age_core. apply age_jm_phi; auto.
  destruct H20;  apply resource_decay_trans with (nextblock (m_dry jm')) (m_phi jm'); auto.
  apply age1_resource_decay; auto.
}
  apply (pred_nec_hereditary  _ _ _ (necR_level' (laterR_necR (age_laterR H13))))
    in H11.
  specialize (H11 te' ve' _ H22 _ _ (necR_refl _) (ext_refl _)).
  spec H11; [clear H11|]. {
  split; [split |]; auto.
  split; [ | simpl; split; [ | reflexivity]; apply MATCH ].
 -
  rewrite (age_jm_dry H20x) in H15.
  clear m_sat_Pa m_funassert.
  eapply semax_call_typecheck_environ
   with (jm := jm2); try eassumption.
 +
  erewrite <- age_jm_dry by apply H13;  eassumption.
 + destruct H23 as [H _].
    intros. specialize (H b0 b1 _ _ H1 H3 H4).
    destruct H as [b2 [? ?]]; exists b2; split; auto.
 + rewrite snd_split. subst fspec; simpl in H18. destruct H18; subst. trivial.
-
 normalize.
 split; auto. unfold construct_rho.
 rewrite <- sepcon_assoc.
 apply (pred_nec_hereditary  _ _ _ (laterR_necR (age_laterR (age_jm_phi H20x)))).
 unfold bind_args.
 unfold tc_formals.
 normalize.
 simpl fst in H18; simpl snd in H18.
 split.
 +
 hnf.
 destruct H18 as [H18 [H18b H18']].
 clear m_funassert.
 destruct fspec; simpl in *.
 destruct f; inv Ef; simpl in *.
 clear - arg_p H21 H17.
 simpl in *.
 match goal with H: tc_vals _ ?A |- tc_vals _ ?B => replace B with A; auto end.
 rewrite list_norepet_app in H17. destruct H17 as [H17 [_ _]].
 clear - H17 H21.
 forget (create_undef_temps fn_temps) as te.
 revert  args te te' H21 H17.
 induction fn_params as [|[??]]; destruct args; intros; auto; try discriminate.
 inv H17.
 simpl. f_equal. unfold eval_id, construct_rho; simpl.
  inv H21.
 erewrite pass_params_ni; try eassumption.
  rewrite PTree.gss. reflexivity.
 eapply IHfn_params; try eassumption.
+
 rewrite predicates_sl.sepcon_assoc.
 eapply predicates_sl.sepcon_derives.
 instantiate (1:=emp); intro; simpl; auto. apply predicates_hered.derives_refl.
 setoid_rewrite emp_sepcon.
 destruct H18 as [H18a [_ H18c]]. subst params.
 assert (list_norepet (map fst (fn_params f))).
 { apply list_norepet_app in H17. apply H17. }
 eapply sepcon_derives.
 assert (VUNDEF:= tc_vals_Vundef arg_p).
 eapply make_args_close_precondition; eauto.
 apply derives_refl.
 eapply alloc_juicy_variables_lem2; eauto.
 unfold var_sizes_ok in Hvars;
 rewrite Forall_forall in Hvars, COMPLETE |- *.
 intros.
 specialize (COMPLETE x H1).
 specialize (Hvars x H1).
 rewrite (cenv_sub_sizeof HGG); auto.
}
apply assert_safe_jsafe.
apply H11.
Qed.
End LibraryEntry.
Print Assumptions framed_function_entry.
