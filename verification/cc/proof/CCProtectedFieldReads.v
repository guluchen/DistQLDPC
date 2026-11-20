(* A physical metadata-table entry discharges an actual C structure read.
   The table is immutable under the separately proved protected byte stores. *)
Require Import VST.floyd.proofauto.
Require Import compcert.lib.Maps compcert.cfrontend.Clight.
Require Import CCV.CCClightReads CCV.CCProtectedByteStores.
Open Scope Z_scope.
Lemma protected_field_eval ge e le m base sid field ty co delta chunk b ofs v cells:
 PTree.get base le=Some(Vptr b ofs) ->PTree.get sid(Clight.genv_cenv ge)=Some co ->
 Ctypes.field_offset ge field(co_members co)=Errors.OK(delta,Full) ->
 access_mode ty=By_value chunk ->
 In {|cpr_chunk:=chunk;cpr_block:=b;cpr_offset:=Ptrofs.add ofs(Ptrofs.repr delta);cpr_value:=v|}cells ->
 cp_reads m cells ->
 Clight.eval_expr ge e le m(struct_field_expr base sid field ty)v.
Proof.
 intros Ptr Composite Offset Access Member Reads.
 pose proof(cp_load_member m cells
 {|cpr_chunk:=chunk;cpr_block:=b;cpr_offset:=Ptrofs.add ofs(Ptrofs.repr delta);cpr_value:=v|}Reads Member)as Load.
 cbn in Load.
 apply(eval_struct_field ge e le m base sid field ty co delta chunk b ofs v);assumption.
Qed.
Print Assumptions protected_field_eval.
