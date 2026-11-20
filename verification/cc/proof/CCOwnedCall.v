(* Finite return for a structurally terminating library entry from the
   caller's VST resources, at every index over the same physical memory.
   Safety and successful return are conclusions, not premises. *)
Require Import VST.veric.juicy_base VST.veric.juicy_mem VST.veric.tycontext
 VST.veric.juicy_extspec VST.veric.semax_prog VST.veric.SequentialClight2.
Require Import VST.veric.ghost_PCM VST.veric.Clight_lemmas VST.veric.Clight_initial_world.
Require Import compcert.common.Smallstep.
Require Import CCV.CCLibraryEntry CCV.CCInternalPaths CCV.CCInternalFinish
 CCV.CCFramedInternal CCV.CCScanCallees.

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

Import Clight Ctypes compcert_rmaps.R.
Section OwnedCall.
Context {E:OracleKind} {CS:compspecs}.
Variables (V:varspecs) (G:funspecs) (prog:Clight.program).
Local Notation tint := (Tint I32 Signed noattr).
Local Notation ge := (Clight.globalenv prog).
Variables (id:ident) (b:block) (fn:Clight.function) (params:list type)
 (args:list val) (A:TypeTree) (z:OK_ty).
Variables (P:forall ts:list Type,dependent_type_functor_rec ts (ArgsTT A) mpred)
 (Q:forall ts:list Type,dependent_type_functor_rec ts (AssertTT A) mpred).
Definition call_world (m:mem) n := exists (own full:juicy_mem) ts a,
 level own=n /\ m_dry full=m /\ mem_sub (m_dry own) m /\
 joins (ghost_of (m_phi full)) (Some (ghost_PCM.ext_ref z,NoneP)::nil) /\
 (exists w,join (m_phi own) w (m_phi full) /\
   (invariants.wsat * invariants.ghost_set invariants.g_en Ensembles.Full_set)%pred w) /\
 app_pred (P ts a (filter_genv ge,args)) (m_phi own) /\
 app_pred (fungassert (nofunc_tycontext V G) (filter_genv ge,args)) (m_phi own) /\
 nth_error (ghost_of (m_phi own)) 0=Some (Some (ext_ghost z,NoneP)).
Theorem owned_library_call_finishes m NEP NEQ :
 library_context E CS V G prog -> postcondition_allows_exit E tint ->
 Genv.find_symbol ge id=Some b ->
 Genv.find_funct_ptr ge b=Some (Internal fn) ->
 initial_world.find_id id G=Some (mk_funspec (params,tint) cc_default A P Q NEP NEQ) ->
 tc_vals params args -> call_settles ge fn -> (forall n,call_world m n) ->
 exists t v m',star Clight.step2 ge (Clight.Callstate (Internal fn) args Kstop m) t
                                    (Clight.Returnstate v Kstop m').
Proof.
 intros Lib Exit Symbol Binding Spec Typed Finite Worlds.
 destruct (framed_function_entry E V G prog b id params args A P Q NEP NEQ 0%nat z
   Exit Lib Symbol Spec Typed) as [q [[fd [Target ->]] [_ Safety]]].
 change (Genv.find_funct_ptr (Genv.globalenv prog) b=Some (Internal fn)) in Binding.
 rewrite Binding in Target;injection Target as Eq;subst fd.
 apply (actual_call_finishes ge fn args Kstop m Finite I);intro n.
 destruct (Worlds n) as [own [full [ts [a [L [M [Sub [Ghost [W [Pre [Fun Ext]]]]]]]]]]].
 specialize (Safety own ts a Pre Fun Ext).
 subst m n. eapply (framed_internal_fuel prog (level own) z own full);eauto.
Qed.
End OwnedCall.
