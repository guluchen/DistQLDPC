(* Interface between structured statement proofs and direct internal calls.
   A blocked endpoint is explicit and can only be eliminated with safety. *)
Require Import VST.floyd.proofauto VST.veric.Clight_lemmas.
Require Import compcert.lib.Maps compcert.common.Events compcert.common.Smallstep compcert.cfrontend.Clight.
Require Import CCV.CCInternalPaths CCV.CCStructuredRuns CCV.CCScanFrames CCV.CCPrimitiveCalls.
Import ListNotations.
Section Callees.
Variable ge:Clight.genv.
Definition returned_to k st := exists v m, st=Clight.Returnstate v k m.
Definition call_settles callee := forall args m k,Clight.is_call_cont k ->
 settles ge (Clight.Callstate (Internal callee) args k m) (returned_to k).
Lemma bind_settles st done final :
 settles ge st done -> (forall fin,done fin -> settles ge fin final) -> settles ge st final.
Proof.
 intros [t [fin [Prefix [Result|Stuck]]]] K.
 - destruct (K fin Result) as [u [last [Tail Exit]]].
   exists (List.app t u),last;split;[eapply star_trans;eauto|assumption].
 - exists t,fin;split;auto.
Qed.
Lemma structured_function_returns callee :
 (forall args m e le m',Clight.function_entry2 ge callee args m e le m' ->
   framed ge callee e (fn_body callee)) ->
 call_settles callee.
Proof.
 intros Body args m k Call. eapply settles_enabled; [solve [assumption|constructor;reflexivity]|]. intros t next Transition.
 inversion Transition;subst.
 match goal with Entry:Clight.function_entry2 _ _ _ _ _ _ _ |- _ =>
   eapply (Body _ _ _ _ _ Entry _);[reflexivity| | |] end.
 - intros l mem' Frame; eapply settles_enabled;[constructor;reflexivity|];intros t' next Step0.
   destruct k; simpl in Call;try contradiction;inversion Step0;subst;
   try solve [intuition discriminate];apply settled;red;eauto.
 - intros l mem' Frame;eapply blocked_settles;[constructor;reflexivity|];intros t' next Step0.
   destruct k;simpl in Call;try contradiction;inversion Step0;subst;intuition discriminate.
 - intros v mem';apply settled;red;rewrite call_cont_fixed by assumption;eauto.
Qed.
End Callees.
Section Calls.
Variable prog:Clight.program.
Local Notation ge := (Clight.globalenv prog).
Lemma direct_function_value id callee e le m v :
 PTree.get id (AST.prog_defmap prog)=Some (Gfun (Internal callee)) ->
 PTree.get id e=None ->
 Clight.eval_expr ge e le m (Evar id (Clight.type_of_function callee)) v ->
 Genv.find_funct ge v=Some (Internal callee).
Proof.
 intros Binding LocalName E.
 destruct (proj1(Genv.find_def_symbol prog id _) Binding) as [b [Symbol Def]].
 assert (Address:Clight.eval_expr ge e le m (Evar id (Clight.type_of_function callee)) (Vptr b Ptrofs.zero)).
 { eapply Clight.eval_Elvalue with (loc:=b) (ofs:=Ptrofs.zero) (bf:=Full).
   - apply Clight.eval_Evar_global;[exact LocalName|exact Symbol].
   - apply Clight.deref_loc_reference;reflexivity. }
 rewrite (eval_expr_fun E Address).
 rewrite Genv.find_funct_find_funct_ptr;apply Genv.find_funct_ptr_iff;exact Def.
Qed.
Lemma framed_direct_call id caller callee e dst al :
 PTree.get id (AST.prog_defmap prog)=Some (Gfun (Internal callee)) ->
 PTree.get id e=None -> call_settles ge callee ->
 framed ge caller e (Scall dst (Evar id (Clight.type_of_function callee)) al).
Proof.
 intros Binding LocalName Callee before l m Eq k done Normal Br R;subst l.
 eapply settles_enabled;[constructor;reflexivity|];intros t next Transition;inversion Transition;subst;
 try solve[intuition discriminate].
 match goal with Ev:Clight.eval_expr _ _ _ _ (Evar _ _) ?vf,
                 Lookup:Genv.find_funct _ ?vf = Some ?fd |- _ =>
  pose proof(direct_function_value id callee e before m vf Binding LocalName Ev) as Target;
  rewrite Target in Lookup;injection Lookup as <- end.
 eapply bind_settles; [apply Callee;exact I|].
 intros fin [v [m' ->]]. eapply settles_left; [solve [assumption|constructor;reflexivity]|apply Clight.step_returnstate|].
 apply Normal;intros tmp Outside;destruct dst as [d|];simpl in *;auto.
 rewrite PTree.gso by intuition. reflexivity.
Qed.
End Calls.
