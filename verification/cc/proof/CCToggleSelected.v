(* Exact selected-bit prefix of core toggle, before either matrix scan. *)
Require Import VST.floyd.proofauto.
Require Import compcert.lib.Maps compcert.common.Events compcert.common.Smallstep compcert.cfrontend.Clight.
Require Import CCV.CCClightReads CCV.CCClightLvalues CCV.CCClightStores
 CCV.CCProtectedByteStores CCV.CCProtectedByteUpdates CCV.CCProtectedFieldReads
 CCV.CCByteXorExpressions CCV.CCToggleControl CCV.CCToggleLayout CCV.CCTerminateWeight CCV.ccv_core.
Import ListNotations. Open Scope Z_scope.
Definition selected_pointer1 le a:=PTree.set _t'15(Vptr(cpa_block a)(cpa_offset a))le.
Definition selected_pointer2 le a:=PTree.set _t'16(Vptr(cpa_block a)(cpa_offset a))(selected_pointer1 le a).
Definition selected_value le a value:=PTree.set _t'17(Vint value)(selected_pointer2 le a).
Ltac selected_registers:=unfold selected_value,selected_pointer2,selected_pointer1;
 repeat(first[rewrite PTree.gss|rewrite PTree.gso by discriminate]);first[assumption|reflexivity].
Theorem actual_toggle_selected ge bp op bw ow q cells areas sources co delta a le m k:
 ts_globals le bp op bw ow q ->PTree.get _ccv_workspace(Clight.genv_cenv ge)=Some co ->
 Ctypes.field_offset ge _selected(co_members co)=Errors.OK(delta,Full) ->
 In {|cpr_chunk:=Mptr;cpr_block:=bw;cpr_offset:=Ptrofs.add ow(Ptrofs.repr delta);
 cpr_value:=Vptr(cpa_block a)(cpa_offset a)|}cells ->
 In a areas ->In a sources ->0<=q<=Int.max_unsigned ->0<=q<cpa_size a ->
 cp_reads m cells ->cp_writables m areas ->cp_initialized m sources ->cp_separation cells areas ->
 exists le' m',ts_globals le' bp op bw ow q /\cp_reads m' cells /\cp_writables m' areas /\cp_initialized m' sources /\
 star Clight.step2 ge(Clight.State f_toggle toggle_selected k Clight.empty_env le m)E0
 (Clight.State f_toggle Sskip k Clight.empty_env le' m').
Proof.
 intros Globals Composite Offset Cell InArea InSource QR Range Reads Writable Initialized Apart;
 pose proof Globals as[P[W Q]].
 destruct(Initialized a InSource q Range)as[value Load].
 destruct(protected_byte_value_store m cells areas sources a q(Int.zero_ext 8(Int.xor value Int.one))
 Reads Writable Initialized Apart InArea Range)as[m'[Store[Reads'[Writable' Initialized']]]].
 exists(selected_value le a value),m';split.
 - unfold ts_globals;repeat split;selected_registers.
 - split;[exact Reads'|];split;[exact Writable'|];split;[exact Initialized'|].
 unfold toggle_selected.
 weight_silent_step. apply Clight.step_seq.
 weight_silent_step. eapply Clight.step_set with(v:=Vptr(cpa_block a)(cpa_offset a)).
 { apply(protected_field_eval ge Clight.empty_env le m _w _ccv_workspace _selected(tptr tuchar)
 co delta Mptr bw ow(Vptr(cpa_block a)(cpa_offset a))cells);try assumption;reflexivity. }
 weight_silent_step. apply Clight.step_skip_seq.
 weight_silent_step. apply Clight.step_seq.
 weight_silent_step. eapply Clight.step_set with(v:=Vptr(cpa_block a)(cpa_offset a)).
 { apply(protected_field_eval ge Clight.empty_env(selected_pointer1 le a)m _w _ccv_workspace _selected(tptr tuchar)
 co delta Mptr bw ow(Vptr(cpa_block a)(cpa_offset a))cells);try assumption;[selected_registers|reflexivity]. }
 weight_silent_step. apply Clight.step_skip_seq.
 weight_silent_step. apply Clight.step_seq.
 weight_silent_step. eapply Clight.step_set with(v:=Vint value).
 { apply(eval_uchar_index ge Clight.empty_env(selected_pointer2 le a)m _t'16 _q(cpa_block a)(cpa_offset a)q value);
 try assumption;selected_registers. }
 weight_silent_step. apply Clight.step_skip_seq.
 weight_silent_step. { apply(defined_assignment_step ge f_toggle k Clight.empty_env(selected_value le a value)m
 (uchar_index_expr _t'15 _q)(byte_flip_expr _t'17)(cpa_block a)(cp_position a q)Mint8unsigned
 (Vint(Int.xor value Int.one))(Vint(Int.zero_ext 8(Int.xor value Int.one)))m').
 - apply(lvalue_uchar_index ge Clight.empty_env(selected_value le a value)m _t'15 _q(cpa_block a)(cpa_offset a)q);
 try assumption;selected_registers.
 - apply(eval_byte_flip ge Clight.empty_env(selected_value le a value)m _t'17 value);selected_registers.
 - reflexivity.
 - reflexivity.
 - exact Store. }
 unfold selected_value,selected_pointer2,selected_pointer1;apply star_refl.
Qed.
Print Assumptions actual_toggle_selected.
