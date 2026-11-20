(* Actual finite clear write packets. A concrete protected-read/permission
   invariant is preserved by every byte store, including between slots. *)
Require Import VST.floyd.proofauto.
Require Import compcert.lib.Maps compcert.common.Events compcert.common.Smallstep compcert.cfrontend.Clight.
Require Import CCV.CCClightReads CCV.CCClightLvalues CCV.CCClightStores
 CCV.CCProtectedByteStores CCV.CCClearControl CCV.CCTerminateWeight CCV.ccv_core.
Import ListNotations. Open Scope Z_scope.
Definition clear_slot_layout ge bw ow bo oout cells areas co delta d:Prop:=
 In(cd_area d)areas /\match cd_field d with
 | Some field=>cd_ptr d<>_p /\cd_ptr d<>_w /\cd_ptr d<>_out /\cd_ptr d<>_i /\
 PTree.get _ccv_workspace(Clight.genv_cenv ge)=Some co /\
 Ctypes.field_offset ge field(co_members co)=Errors.OK(delta field,Full) /\
 In {|cpr_chunk:=Mptr;cpr_block:=bw;cpr_offset:=Ptrofs.add ow(Ptrofs.repr(delta field));
 cpr_value:=Vptr(cpa_block(cd_area d))(cpa_offset(cd_area d))|}cells
 | None=>cd_ptr d=_out /\cpa_block(cd_area d)=bo /\cpa_offset(cd_area d)=oout end.
Theorem clear_slot_terminates ge bp op bw ow bo oout cells areas co delta d le m i k:
 clear_env le bp op bw ow bo oout i ->0<=i<=Int.max_unsigned ->
 clear_slot_layout ge bw ow bo oout cells areas co delta d ->0<=i<cpa_size(cd_area d) ->
 cp_reads m cells ->cp_writables m areas ->cp_separation cells areas ->
 exists le' m',clear_env le' bp op bw ow bo oout i /\cp_reads m' cells /\cp_writables m' areas /\
 star Clight.step2 ge(Clight.State f_clear(clear_slot d)k Clight.empty_env le m)E0
 (Clight.State f_clear Sskip k Clight.empty_env le' m').
Proof.
 intros Env IR Layout Range Reads Writable Apart;pose proof Env as[P[W[Out I]]].
 destruct Layout as[Member Layout].
 destruct(protected_byte_zero_store m cells areas(cd_area d)i Reads Writable Apart Member Range)
 as[m'[Store[Reads' Writable']]].
 destruct d as[ptr[field|]a];cbn in *.
 - destruct Layout as[NotP[NotW[NotOut[NotI[Composite[Offset Cell]]]]]].
   pose proof(cp_load_member m cells
   {|cpr_chunk:=Mptr;cpr_block:=bw;cpr_offset:=Ptrofs.add ow(Ptrofs.repr(delta field));
   cpr_value:=Vptr(cpa_block a)(cpa_offset a)|}Reads Cell)as Load.
   cbn in Load.
   exists(PTree.set ptr(Vptr(cpa_block a)(cpa_offset a))le),m';split.
   + unfold clear_env;rewrite !PTree.gso by congruence;repeat split;assumption.
   + split;[exact Reads'|];split;[exact Writable'|].
     cbn[clear_slot];unfold clear_assignment;cbn[cd_ptr].
     weight_silent_step. apply Clight.step_seq.
     weight_silent_step. eapply Clight.step_set with(v:=Vptr(cpa_block a)(cpa_offset a)).
     { apply(eval_struct_field ge Clight.empty_env le m _w _ccv_workspace field(tptr tuchar)
       co(delta field)Mptr bw ow(Vptr(cpa_block a)(cpa_offset a)));try assumption;reflexivity. }
     weight_silent_step. apply Clight.step_skip_seq.
     weight_silent_step. { apply(defined_assignment_step ge f_clear k Clight.empty_env
       (PTree.set ptr(Vptr(cpa_block a)(cpa_offset a))le)m(uchar_index_expr ptr _i)
       (Econst_int(Int.repr 0)tuint)(cpa_block a)(cp_position a i)Mint8unsigned(Vint Int.zero)(Vint Int.zero)m').
     - apply(lvalue_uchar_index ge Clight.empty_env(PTree.set ptr(Vptr(cpa_block a)(cpa_offset a))le)m
       ptr _i(cpa_block a)(cpa_offset a)i);try assumption.
       + apply PTree.gss.
       + rewrite PTree.gso by congruence;exact I.
     - apply Clight.eval_Econst_int.
     - reflexivity.
     - reflexivity.
     - exact Store. }
     apply star_refl.
 - destruct Layout as[Ptr[Base Offset]].
   exists le,m';split;[exact Env|];split;[exact Reads'|];split;[exact Writable'|].
   cbn[clear_slot];unfold clear_assignment;cbn[cd_ptr].
   weight_silent_step. { apply(defined_assignment_step ge f_clear k Clight.empty_env le m
     (uchar_index_expr ptr _i)(Econst_int(Int.repr 0)tuint)(cpa_block a)(cp_position a i)
     Mint8unsigned(Vint Int.zero)(Vint Int.zero)m').
   - apply(lvalue_uchar_index ge Clight.empty_env le m ptr _i(cpa_block a)(cpa_offset a)i);try assumption.
     rewrite Ptr,Base,Offset;exact Out.
   - apply Clight.eval_Econst_int.
   - reflexivity.
   - reflexivity.
   - exact Store. }
   apply star_refl.
Qed.
Theorem clear_packet_terminates ge bp op bw ow bo oout cells areas co delta ds:
 (forall d,In d ds ->clear_slot_layout ge bw ow bo oout cells areas co delta d) ->
 forall i,0<=i<=Int.max_unsigned ->(forall d,In d ds ->0<=i<cpa_size(cd_area d)) ->
 forall le m k,clear_env le bp op bw ow bo oout i ->
 cp_reads m cells ->cp_writables m areas ->cp_separation cells areas ->
 exists le' m',clear_env le' bp op bw ow bo oout i /\cp_reads m' cells /\cp_writables m' areas /\
 star Clight.step2 ge(Clight.State f_clear(clear_packet ds)k Clight.empty_env le m)E0
 (Clight.State f_clear Sskip k Clight.empty_env le' m').
Proof.
 induction ds as[|d ds IH];intros Layout i IR Bounds le m k Env Reads Writable Apart.
 - exists le,m;split;[exact Env|];split;[exact Reads|];split;[exact Writable|];apply star_refl.
 - destruct(clear_slot_terminates ge bp op bw ow bo oout cells areas co delta d le m i
 (match ds with []=>k|_=>Kseq(clear_packet ds)k end)Env IR(Layout d(or_introl eq_refl))
 (Bounds d(or_introl eq_refl))Reads Writable Apart)as[le1[m1[Env1[Reads1[Writable1 Slot]]]]].
 destruct ds as[|next rest].
 + exists le1,m1;split;[exact Env1|];split;[exact Reads1|];split;[exact Writable1|];exact Slot.
 + destruct(IH ltac:(intros a Member;apply Layout;right;exact Member)i IR
   ltac:(intros a Member;apply Bounds;right;exact Member)le1 m1 k Env1 Reads1 Writable1 Apart)
   as[le2[m2[Env2[Reads2[Writable2 Tail]]]]].
   exists le2,m2;split;[exact Env2|];split;[exact Reads2|];split;[exact Writable2|].
   cbn[clear_packet];fold(clear_slot d).
   weight_silent_step. apply Clight.step_seq.
   eapply star_trans;[exact Slot| |reflexivity].
   weight_silent_step. apply Clight.step_skip_seq.
   exact Tail.
Qed.
Print Assumptions clear_slot_terminates.
Print Assumptions clear_packet_terminates.
