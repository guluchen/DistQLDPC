(* Full finite execution of actual clear, by its three concrete protected-
   metadata loops. Layout/read/permission premises are explicit; the existing
   VST body supplies functional zeroing, separately from this termination. *)
Require Import VST.floyd.proofauto.
Require Import compcert.lib.Maps compcert.common.Events compcert.common.Smallstep compcert.cfrontend.Clight.
Require Import CCV.CCProtectedByteStores CCV.CCClearControl CCV.CCClearPackets
 CCV.CCClearLoop CCV.CCTerminateWeight CCV.ccv_core.
Import ListNotations. Open Scope Z_scope.
Definition clear_arguments bp op bw ow bo oout:=PTree.set _out(Vptr bo oout)
 (PTree.set _w(Vptr bw ow)(PTree.set _p(Vptr bp op)(Clight.create_undef_temps(fn_temps f_clear)))).
Lemma clear_function_entry ge bp op bw ow bo oout m:
 Clight.function_entry2 ge f_clear[Vptr bp op;Vptr bw ow;Vptr bo oout]m
 Clight.empty_env(clear_arguments bp op bw ow bo oout)m.
Proof.
 constructor.
 - constructor.
 - vm_compute;repeat(apply list_norepet_cons;[simpl;intuition congruence|]);apply list_norepet_nil.
 - vm_compute;intros;intuition congruence.
 - constructor.
 - reflexivity.
Qed.
Lemma clear_arguments_globals bp op bw ow bo oout:
 clear_globals(clear_arguments bp op bw ow bo oout)bp op bw ow bo oout.
Proof.
 unfold clear_globals,clear_arguments;
 repeat(first[rewrite PTree.gss|rewrite PTree.gso by discriminate]);repeat split;reflexivity.
Qed.
Theorem actual_clear_terminates ge bp op bw ow bo oout cells areas cp dp cw dw
 n checks logical selected forbidden packed output syndrome logvalues m k:
 Clight.is_call_cont k ->
 clear_bound_layout ge bp op cells cp(dp _n)_t'8 _n n ->
 clear_bound_layout ge bp op cells cp(dp _checks)_t'4 _checks checks ->
 clear_bound_layout ge bp op cells cp(dp _logical_rows)_t'2 _logical_rows logical ->
 (forall d,In d(clear_n_descriptors selected forbidden packed output) ->
 clear_slot_layout ge bw ow bo oout cells areas cw dw d) ->
 (forall d,In d(clear_check_descriptors syndrome) ->clear_slot_layout ge bw ow bo oout cells areas cw dw d) ->
 (forall d,In d(clear_logical_descriptors logvalues) ->clear_slot_layout ge bw ow bo oout cells areas cw dw d) ->
 (forall d,In d(clear_n_descriptors selected forbidden packed output) ->n<=cpa_size(cd_area d)) ->
 (forall d,In d(clear_check_descriptors syndrome) ->checks<=cpa_size(cd_area d)) ->
 (forall d,In d(clear_logical_descriptors logvalues) ->logical<=cpa_size(cd_area d)) ->
 0<=n<=Int.max_unsigned ->0<=checks<=Int.max_unsigned ->0<=logical<=Int.max_unsigned ->
 cp_reads m cells ->cp_writables m areas ->cp_separation cells areas ->
 exists m',cp_reads m' cells /\cp_writables m' areas /\
 star Clight.step2 ge
 (Clight.Callstate(Internal f_clear)[Vptr bp op;Vptr bw ow;Vptr bo oout]k m)E0
 (Clight.Returnstate Vundef k m').
Proof.
 intros Call BoundN BoundC BoundL SlotsN SlotsC SlotsL SizesN SizesC SizesL NR CR LR Reads Writable Apart.
 set(dsN:=clear_n_descriptors selected forbidden packed output).
 set(dsC:=clear_check_descriptors syndrome).
 set(dsL:=clear_logical_descriptors logvalues).
 set(stageC:=clear_stage _t'4 _checks dsC).
 set(stageL:=clear_stage _t'2 _logical_rows dsL).
 destruct(clear_stage_terminates ge bp op bw ow bo oout cells areas cp(dp _n)cw dw _t'8 _n n dsN
 (clear_arguments bp op bw ow bo oout)m(Kseq(Ssequence stageC stageL)k)
 BoundN SlotsN SizesN NR(clear_arguments_globals bp op bw ow bo oout)Reads Writable Apart)
 as[le1[m1[Env1[Reads1[Writable1 StageN]]]]].
 destruct(clear_stage_terminates ge bp op bw ow bo oout cells areas cp(dp _checks)cw dw _t'4 _checks checks dsC
 le1 m1(Kseq stageL k)BoundC SlotsC SizesC CR(clear_env_globals le1 bp op bw ow bo oout n Env1)
 Reads1 Writable1 Apart)as[le2[m2[Env2[Reads2[Writable2 StageC]]]]].
 destruct(clear_stage_terminates ge bp op bw ow bo oout cells areas cp(dp _logical_rows)cw dw _t'2 _logical_rows logical dsL
 le2 m2 k BoundL SlotsL SizesL LR(clear_env_globals le2 bp op bw ow bo oout checks Env2)
 Reads2 Writable2 Apart)as[le3[m3[Env3[Reads3[Writable3 StageL]]]]].
 exists m3;split;[exact Reads3|];split;[exact Writable3|].
 weight_silent_step. apply Clight.step_internal_function;apply clear_function_entry.
 rewrite(actual_clear_three_stages selected forbidden packed output syndrome logvalues).
 weight_silent_step. apply Clight.step_seq.
 eapply star_trans;[exact StageN| |reflexivity].
 weight_silent_step. apply Clight.step_skip_seq.
 weight_silent_step. apply Clight.step_seq.
 eapply star_trans;[exact StageC| |reflexivity].
 weight_silent_step. apply Clight.step_skip_seq.
 eapply star_trans;[exact StageL| |reflexivity].
 weight_silent_step. { apply Clight.step_skip_call;[exact Call|reflexivity]. }
 apply star_refl.
Qed.
Print Assumptions actual_clear_terminates.
