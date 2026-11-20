(* A syntax-preserving template for the three actual clear loops. Descriptor
   areas are ghost information; generated statements equal the frozen AST. *)
Require Import VST.floyd.proofauto.
Require Import compcert.lib.Maps compcert.common.Events compcert.cfrontend.Clight.
Require Import CCV.CCClightReads CCV.CCProtectedByteStores CCV.CCTerminateWeight CCV.ccv_core.
Import ListNotations. Open Scope Z_scope.
Record clear_descriptor:Type:={cd_ptr:ident;cd_field:option ident;cd_area:writable_byte_area}.
Definition clear_assignment d:=Sassign(uchar_index_expr(cd_ptr d)_i)(Econst_int(Int.repr 0)tuint).
Definition clear_slot d:=match cd_field d with
 | Some field=>Ssequence(Sset(cd_ptr d)(struct_field_expr _w _ccv_workspace field(tptr tuchar)))(clear_assignment d)
 | None=>clear_assignment d end.
Fixpoint clear_packet(ds:list clear_descriptor):statement:=match ds with
 | []=>Sskip | [d]=>clear_slot d | d::rest=>Ssequence(clear_slot d)(clear_packet rest) end.
Definition clear_bound(temp:ident)field:=struct_field_expr _p _ccv_problem field tuint.
Definition clear_iteration temp field ds:=Ssequence
 (Ssequence(Sset temp(clear_bound temp field))(Sifthenelse(uint_lt_expr _i temp)Sskip Sbreak))
 (clear_packet ds).
Definition clear_loop temp field ds:=Sloop(clear_iteration temp field ds)weight_increment.
Definition clear_stage temp field ds:=Ssequence(Sset _i(Econst_int(Int.repr 0)tuint))(clear_loop temp field ds).
Definition clear_n_descriptors selected forbidden packed output:list clear_descriptor:=
 [{|cd_ptr:=_t'7;cd_field:=Some _selected;cd_area:=selected|};
  {|cd_ptr:=_t'6;cd_field:=Some _forbidden;cd_area:=forbidden|};
  {|cd_ptr:=_t'5;cd_field:=Some _packed;cd_area:=packed|};
  {|cd_ptr:=_out;cd_field:=None;cd_area:=output|}].
Definition clear_check_descriptors syndrome:list clear_descriptor:=
 [{|cd_ptr:=_t'3;cd_field:=Some _syndrome;cd_area:=syndrome|}].
Definition clear_logical_descriptors logical:list clear_descriptor:=
 [{|cd_ptr:=_t'1;cd_field:=Some _logical_value;cd_area:=logical|}].
Lemma actual_clear_three_stages selected forbidden packed output syndrome logical:
 fn_body f_clear=Ssequence(clear_stage _t'8 _n(clear_n_descriptors selected forbidden packed output))
 (Ssequence(clear_stage _t'4 _checks(clear_check_descriptors syndrome))
 (clear_stage _t'2 _logical_rows(clear_logical_descriptors logical))).
Proof. reflexivity. Qed.
Definition clear_env le bp op bw ow bo oout i:Prop:=
 PTree.get _p le=Some(Vptr bp op) /\PTree.get _w le=Some(Vptr bw ow) /\
 PTree.get _out le=Some(Vptr bo oout) /\PTree.get _i le=Some(Vint(Int.repr i)).
Lemma clear_increment_step ge le m k bp op bw ow bo oout i:
 clear_env le bp op bw ow bo oout i ->0<=i<Int.max_unsigned ->
 Clight.step2 ge(Clight.State f_clear weight_increment k Clight.empty_env le m)E0
 (Clight.State f_clear Sskip k Clight.empty_env(PTree.set _i(Vint(Int.repr(i+1)))le)m).
Proof.
 intros[P[W[Out I]]] Range;unfold Clight.step2,weight_increment.
 eapply Clight.step_set with(v:=Vint(Int.repr(i+1))).
 eapply Clight.eval_Ebinop with(v1:=Vint(Int.repr i))(v2:=Vint(Int.repr 1)).
 - apply Clight.eval_Etempvar;exact I.
 - apply Clight.eval_Econst_int.
 - change(Some(Vint(Int.add(Int.repr i)(Int.repr 1)))=Some(Vint(Int.repr(i+1)))).
   unfold Int.add;rewrite !Int.unsigned_repr by rep_lia;reflexivity.
Qed.
Print Assumptions actual_clear_three_stages.
Print Assumptions clear_increment_step.
