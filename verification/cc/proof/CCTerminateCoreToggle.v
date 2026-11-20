(* Complete actual core toggle: selected bit, syndrome matrix scan, logical
   matrix scan and return. Concrete metadata/array premises remain explicit. *)
Require Import VST.floyd.proofauto.
Require Import compcert.lib.Maps compcert.common.Events compcert.common.Smallstep compcert.cfrontend.Clight.
Require Import CCV.CCProtectedByteStores CCV.CCProtectedByteUpdates CCV.CCToggleControl
 CCV.CCToggleLayout CCV.CCToggleSelected CCV.CCToggleLoop CCV.CCTerminateWeight CCV.ccv_core.
Import ListNotations. Open Scope Z_scope.
Definition core_toggle_arguments bp op bw ow q:=PTree.set _q(Vint(Int.repr q))
 (PTree.set _w(Vptr bw ow)(PTree.set _p(Vptr bp op)(Clight.create_undef_temps(fn_temps f_toggle)))).
Lemma core_toggle_entry ge bp op bw ow q m:
 Clight.function_entry2 ge f_toggle[Vptr bp op;Vptr bw ow;Vint(Int.repr q)]m
 Clight.empty_env(core_toggle_arguments bp op bw ow q)m.
Proof.
 constructor.
 - constructor.
 - vm_compute;repeat(apply list_norepet_cons;[simpl;intuition congruence|]);apply list_norepet_nil.
 - vm_compute;intros;intuition congruence.
 - constructor.
 - reflexivity.
Qed.
Lemma core_toggle_argument_globals bp op bw ow q:
 ts_globals(core_toggle_arguments bp op bw ow q)bp op bw ow q.
Proof.
 unfold ts_globals,core_toggle_arguments;
 repeat(first[rewrite PTree.gss|rewrite PTree.gso by discriminate]);repeat split;reflexivity.
Qed.
Theorem actual_core_toggle_terminates ge bp op bw ow cells areas sources coP coW dp dw
 n checks logical selected syndrome logvalues hmatrix lmatrix q m k:
 Clight.is_call_cont k ->
 ts_data_layout ge bp op bw ow cells coP coW dp dw syndrome_scan checks n syndrome hmatrix ->
 ts_data_layout ge bp op bw ow cells coP coW dp dw logical_scan logical n logvalues lmatrix ->
 Ctypes.field_offset ge _selected(co_members coW)=Errors.OK(dw _selected,Full) ->
 In {|cpr_chunk:=Mptr;cpr_block:=bw;cpr_offset:=Ptrofs.add ow(Ptrofs.repr(dw _selected));
 cpr_value:=Vptr(cpa_block selected)(cpa_offset selected)|}cells ->
 In selected areas ->In selected sources ->0<=q<cpa_size selected ->
 0<=n<=Int.max_unsigned ->0<=checks<=Int.max_unsigned ->0<=logical<=Int.max_unsigned ->0<=q<n ->
 0<=checks*n<=Int.max_unsigned ->0<=logical*n<=Int.max_unsigned ->
 checks<=cpa_size syndrome ->checks*n<=cpa_size hmatrix ->
 logical<=cpa_size logvalues ->logical*n<=cpa_size lmatrix ->
 In syndrome areas ->In syndrome sources ->In hmatrix sources ->
 In logvalues areas ->In logvalues sources ->In lmatrix sources ->
 cp_reads m cells ->cp_writables m areas ->cp_initialized m sources ->cp_separation cells areas ->
 exists m',cp_reads m' cells /\cp_writables m' areas /\cp_initialized m' sources /\
 star Clight.step2 ge(Clight.Callstate(Internal f_toggle)[Vptr bp op;Vptr bw ow;Vint(Int.repr q)]k m)E0
 (Clight.Returnstate Vundef k m').
Proof.
 intros Call LayoutS LayoutL SelectedOffset SelectedCell SelectedWrite SelectedRead SelectedRange
 NR CR LR QR HC LC SyndromeSize HSize LogicalSize LSize SyndromeWrite SyndromeRead HRead
 LogicalWrite LogicalRead LRead Reads Writable Initialized Apart.
 pose proof LayoutS as[CompP CompW Rest].
 destruct(actual_toggle_selected ge bp op bw ow q cells areas sources coW(dw _selected)selected
 (core_toggle_arguments bp op bw ow q)m(Kseq(Ssequence(ts_stage syndrome_scan)(ts_stage logical_scan))k)
 (core_toggle_argument_globals bp op bw ow q)CompW SelectedOffset SelectedCell SelectedWrite SelectedRead
 ltac:(lia)SelectedRange Reads Writable Initialized Apart)
 as[le0[m0[Globals0[Reads0[Writable0[Initialized0 Selected]]]]]].
 destruct(ts_stage_terminates ge bp op bw ow cells areas sources coP coW dp dw syndrome_scan checks n syndrome hmatrix q
 le0 m0(Kseq(ts_stage logical_scan)k)ltac:(left;reflexivity)LayoutS NR CR QR HC SyndromeSize HSize
 SyndromeWrite SyndromeRead HRead Globals0 Reads0 Writable0 Initialized0 Apart)
 as[le1[m1[Env1[Reads1[Writable1[Initialized1 Syndrome]]]]]].
 destruct(ts_stage_terminates ge bp op bw ow cells areas sources coP coW dp dw logical_scan logical n logvalues lmatrix q
 le1 m1 k ltac:(right;reflexivity)LayoutL NR LR QR LC LogicalSize LSize LogicalWrite LogicalRead LRead
 (ts_env_globals le1 bp op bw ow q checks Env1)Reads1 Writable1 Initialized1 Apart)
 as[le2[m2[Env2[Reads2[Writable2[Initialized2 Logical]]]]]].
 exists m2;split;[exact Reads2|];split;[exact Writable2|];split;[exact Initialized2|].
 weight_silent_step. apply Clight.step_internal_function;apply core_toggle_entry.
 rewrite actual_toggle_two_scans.
 weight_silent_step. apply Clight.step_seq.
 eapply star_trans;[exact Selected| |reflexivity].
 weight_silent_step. apply Clight.step_skip_seq.
 weight_silent_step. apply Clight.step_seq.
 eapply star_trans;[exact Syndrome| |reflexivity].
 weight_silent_step. apply Clight.step_skip_seq.
 eapply star_trans;[exact Logical| |reflexivity].
 weight_silent_step. { apply Clight.step_skip_call;[exact Call|reflexivity]. }
 apply star_refl.
Qed.
Print Assumptions actual_core_toggle_terminates.
