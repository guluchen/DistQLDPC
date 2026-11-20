(* Total finite return at all three public/search entries, for a caller owning
   the specification resources at all indices over the same concrete heap.
   The return value and final heap are those of the frozen Clight functions. *)
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
Require Import CCV.ccv_core CCV.CCSearchContext CCV.CCSearchSpecs CCV.CCBoundedMain CCV.CCExpandedBody
 CCV.CCExpandedEntry CCV.CCSearchExpansion CCV.CCCapGuard CCV.CCGuardedDistanceEntry
 CCV.CCBodyProgram CCV.CCBodyLibrary CCV.CCSolverFinite CCV.CCSolverReplay CCV.CCOwnedCall
 CCV.CCCallerTransport CCV.CCDriverContext CCV.CCProgramRelation CCV.CCReplayEnvironment CCV.CCVerificationDriver CCV.CCReplayFrames.
Inductive solver_entry:=SearchEntry|DecideEntry|DistanceEntry.
Definition entry_name x:=match x with SearchEntry=>_search|DecideEntry=>_ccv_decide|DistanceEntry=>_ccv_distance end.
Definition entry_function x:=match x with SearchEntry=>f_search|DecideEntry=>f_ccv_decide|DistanceEntry=>f_ccv_distance end.
Definition entry_image c d x:=match x with SearchEntry=>with_body f_search c|DecideEntry=>f_ccv_decide|DistanceEntry=>with_body f_ccv_distance d end.
Lemma entry_definition c d x:PTree.get (entry_name x)(AST.prog_defmap (proof_driver c d))=Some(Gfun(Internal(entry_image c d x))).
Proof. destruct x;reflexivity. Qed.
Section Solver.
Context {E:OracleKind}.
Variable z:OK_ty.
Local Notation tint:=(Tint I32 Signed noattr).
Local Notation c:=(body_with (bounded_main word_heads)).
Local Notation d:=(fn_body guarded_distance).
Local Notation p:=(proof_driver c d).
Local Notation V:=CCSearchContext.Vprog.
Local Notation G:=(body_specs c d z).
Variables (x:solver_entry)(params:list type)(args:list val)(A:TypeTree).
Variables (P:forall ts:list Type,dependent_type_functor_rec ts (ArgsTT A) mpred)
 (Q:forall ts:list Type,dependent_type_functor_rec ts (AssertTT A) mpred).
Theorem frozen_solver_returns m NEP NEQ:
 postcondition_allows_exit E tint ->
 initial_world.find_id (entry_name x) (driver_specs z)=Some(mk_funspec (params,tint) cc_default A P Q NEP NEQ) ->
 tc_vals params args -> (forall n,@call_world E V (driver_specs z) driver_prog args A z P m n) ->
 exists t v m',star Clight.step2 (Clight.globalenv driver_prog)
  (Callstate (Internal(entry_function x)) args Kstop m) t (Returnstate v Kstop m').
Proof.
 intros Exit Spec Typed Worlds.
 rewrite <-(same_driver_specs c d z) in Spec.
 assert (Resources:forall n,@call_world E V G p args A z P m n).
 { intro n;unfold call_world;rewrite same_driver_specs,driver_world_symbols;apply Worlds. }
 destruct (proj1 (Genv.find_def_symbol p _ _) (entry_definition c d x)) as [b [Sym Def]].
 assert (Binding:Genv.find_funct_ptr (Genv.globalenv p) b=Some (Internal (entry_image c d x)))
 by (apply Genv.find_funct_ptr_iff;exact Def).
 assert (C:library_context E CCSearchSpecs.CompSpecs V G p) by
  (apply replacement_context;[apply expanded_search_entry|apply guarded_distance_entry]).
 assert (Fin:call_settles (Clight.globalenv p) (entry_image c d x)) by
  (destruct x;[apply proof_search_finite|apply proof_decide_finite|apply proof_distance_finite]).
 destruct (owned_library_call_finishes V G p (entry_name x) b (entry_image c d x) params args A z P Q m NEP NEQ
     C Exit Sym Binding Spec Typed Fin Resources) as [t [v [m' Run]]].
 exists t,v,m';eapply original_return_replay;[|exact Run].
 destruct x.
 - apply paired_fn;[apply headers_body|apply search_code_pair].
 - apply same_fd;reflexivity.
 - apply paired_fn;[apply headers_body|apply distance_code_pair].
Qed.
End Solver.
Print Assumptions frozen_solver_returns.

Definition entry_contract x: funspec := snd (match x with
 | SearchEntry=>search_spec |DecideEntry=>decide_spec |DistanceEntry=>distance_spec end).
Lemma public_contract_lookup {E:OracleKind} (z:OK_ty) x :
 initial_world.find_id (entry_name x) (driver_specs z)=Some(entry_contract x).
Proof. destruct x;reflexivity. Qed.
Section Interface.
Context {E:OracleKind} (z:OK_ty).
Local Notation tint:=(Tint I32 Signed noattr).
Definition owns_entry x args m:Prop :=
 match entry_contract x with
 | mk_funspec (params,_) _ A P _ _ _ =>
 tc_vals params args /\ forall n,@call_world E CCSearchContext.Vprog (driver_specs z) driver_prog args A z P m n
 end.
Theorem every_owned_entry_returns x args m :postcondition_allows_exit E tint ->
 owns_entry x args m ->exists t v m',star Clight.step2 (Clight.globalenv driver_prog)
  (Callstate (Internal(entry_function x)) args Kstop m) t (Returnstate v Kstop m').
Proof.
 intro Exit;unfold owns_entry.
 pose proof (public_contract_lookup z x) as Lookup.

 destruct (entry_contract x) as [[params result] cc A P Q NP NQ] eqn:FS.
 assert(R:result=tint) by (destruct x;inversion FS;reflexivity). subst result.
 assert(CC:cc=cc_default).
 { destruct x;cbv [entry_contract] in FS;inversion FS;reflexivity. }
 subst cc;intros [Typed Worlds];eapply frozen_solver_returns;eassumption.
Qed.
End Interface.
