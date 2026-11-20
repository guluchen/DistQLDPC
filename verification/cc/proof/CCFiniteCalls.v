(* A direct internal Clight2 call preserves the saved caller continuation.
   The callee contract can carry its precise return value and heap effects. *)
Require Import VST.floyd.proofauto.
Require Import compcert.lib.Maps compcert.common.Events compcert.common.Smallstep
 compcert.common.Globalenvs compcert.cfrontend.Clight.
Require Import CCV.CCPrimitiveCalls.

Section DirectCall.
Variable prog : Clight.program.
Let ge := Clight.globalenv prog.
Variables (id : ident) (callee caller : Clight.function).
Variables (e : Clight.env) (le : Clight.temp_env) (m : mem).
Variables (dst : option ident) (al : list expr) (args : list val) (k : Clight.cont).
Let call := Scall dst (Evar id (Clight.type_of_function callee)) al.
Let saved := Kcall dst caller e le k.

Hypothesis binding : PTree.get id (AST.prog_defmap prog) = Some (Gfun (Internal callee)).
Hypothesis unshadowed : PTree.get id e = None.
Hypothesis arguments : Clight.eval_exprlist ge e le m al
 (type_of_params (fn_params callee)) args.

Lemma enter_direct_call :
 Clight.step2 ge (Clight.State caller call k e le m) E0
 (Clight.Callstate (Internal callee) args saved m).
Proof.
 destruct (proj1 (Genv.find_def_symbol prog id _) binding) as [b [Symbol Def]].
 eapply Clight.step_call with (vf := Vptr b Ptrofs.zero).
 - reflexivity.
 - eapply Clight.eval_Elvalue with (loc := b) (ofs := Ptrofs.zero) (bf := Full).
   + apply Clight.eval_Evar_global; [exact unshadowed | exact Symbol].
   + apply Clight.deref_loc_reference; reflexivity.
 - exact arguments.
 - rewrite Genv.find_funct_find_funct_ptr. apply Genv.find_funct_ptr_iff. exact Def.
 - reflexivity.
Qed.

Theorem resume_direct_call v m' :
 star Clight.step2 ge (Clight.Callstate (Internal callee) args saved m) E0
                      (Clight.Returnstate v saved m') ->
 star Clight.step2 ge (Clight.State caller call k e le m) E0
   (Clight.State caller Sskip k e (Clight.set_opttemp dst v le) m').
Proof.
 intro Callee.
 eapply star_left; [apply enter_direct_call | | reflexivity].
 eapply star_right; [exact Callee | apply Clight.step_returnstate | reflexivity].
Qed.

Corollary resume_primitive_call :
 primitive_call_pre callee args m ->
 exists v m', star Clight.step2 ge (Clight.State caller call k e le m) E0
   (Clight.State caller Sskip k e (Clight.set_opttemp dst v le) m').
Proof.
 intro Pre.
 destruct (all_primitive_calls_terminate ge callee args m saved Pre I)
   as [v [m' Path]].
 exists v, m'. apply resume_direct_call. exact Path.
Qed.
End DirectCall.
Print Assumptions resume_direct_call.
Print Assumptions resume_primitive_call.
