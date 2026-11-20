(* Actual five-field statistics initialization has finite execution whenever
   the specified layout/word stores are defined. No CLI or allocator claim. *)
Require Import VST.floyd.proofauto.
Require Import compcert.lib.Maps compcert.common.Events compcert.common.Smallstep compcert.cfrontend.Clight.
Require Import CCV.CCClightReads CCV.CCClightStores CCV.CCTerminateWeight CCV.ccv_core.
Import ListNotations. Open Scope Z_scope.
Definition si_lhs field:=struct_field_expr _s _ccv_stats field tuint.
Definition si_assign field:=Sassign(si_lhs field)(Econst_int(Int.repr 0)tuint).
Fixpoint si_stores(fields:list ident):statement:=match fields with
 | []=>Sskip | [field]=>si_assign field | field::rest=>Ssequence(si_assign field)(si_stores rest) end.
Definition si_fields:list ident:=[_steps;_nodes;_pack_prunes;_charge_prunes;_overlap_prunes].
Lemma si_body_actual:fn_body f_stats_init=si_stores si_fields.
Proof. reflexivity. Qed.
Lemma si_field_lvalue ge le m b ofs co delta field:
 PTree.get _s le=Some(Vptr b ofs) ->PTree.get _ccv_stats(Clight.genv_cenv ge)=Some co ->
 Ctypes.field_offset ge field(co_members co)=Errors.OK(delta,Full) ->
 Clight.eval_lvalue ge Clight.empty_env le m(si_lhs field)b(Ptrofs.add ofs(Ptrofs.repr delta))Full.
Proof.
 intros Ptr Composite Offset;unfold si_lhs,struct_field_expr.
 eapply Clight.eval_Efield_struct with(id:=_ccv_stats)(co:=co)(att:=noattr)(delta:=delta).
 - eapply Clight.eval_Elvalue with(loc:=b)(ofs:=ofs)(bf:=Full).
   + apply Clight.eval_Ederef;apply Clight.eval_Etempvar;exact Ptr.
   + apply Clight.deref_loc_copy;reflexivity.
 - reflexivity.
 - exact Composite.
 - exact Offset.
Qed.
Definition si_writable m b ofs delta(fields:list ident):Prop:=forall field,In field fields ->
 Mem.valid_access m Mint32 b(Ptrofs.unsigned(Ptrofs.add ofs(Ptrofs.repr(delta field))))Writable.
Lemma si_store_step ge le m b ofs co delta field k:
 PTree.get _s le=Some(Vptr b ofs) ->PTree.get _ccv_stats(Clight.genv_cenv ge)=Some co ->
 Ctypes.field_offset ge field(co_members co)=Errors.OK(delta field,Full) ->
 si_writable m b ofs delta[field] ->
 exists m',Clight.step2 ge(Clight.State f_stats_init(si_assign field)k Clight.empty_env le m)E0
 (Clight.State f_stats_init Sskip k Clight.empty_env le m') /\
 (forall c b' p perm,Mem.valid_access m c b' p perm ->Mem.valid_access m' c b' p perm).
Proof.
 intros Ptr Composite Offset Writable.
 destruct(writable_word_store m b(Ptrofs.add ofs(Ptrofs.repr(delta field)))Int.zero
 (Writable field(or_introl eq_refl)))as[m'[Store Load]].
 exists m';split.
 - apply(defined_assignment_step ge f_stats_init k Clight.empty_env le m(si_lhs field)
 (Econst_int(Int.repr 0)tuint)b(Ptrofs.add ofs(Ptrofs.repr(delta field)))Mint32(Vint Int.zero)(Vint Int.zero)m').
   + apply(si_field_lvalue ge le m b ofs co(delta field)field);assumption.
   + apply Clight.eval_Econst_int.
   + reflexivity.
   + reflexivity.
   + exact Store.
 - intros c b' p perm Access;eapply storev_keeps_valid_access;[exact Store|exact Access].
Qed.
Theorem si_stores_terminate ge b ofs co delta fields:
 PTree.get _ccv_stats(Clight.genv_cenv ge)=Some co ->
 (forall field,In field fields ->Ctypes.field_offset ge field(co_members co)=Errors.OK(delta field,Full)) ->
 forall le m k,PTree.get _s le=Some(Vptr b ofs) ->si_writable m b ofs delta fields ->
 exists m',star Clight.step2 ge(Clight.State f_stats_init(si_stores fields)k Clight.empty_env le m)E0
 (Clight.State f_stats_init Sskip k Clight.empty_env le m').
Proof.
 intros Composite;induction fields as[|field fields IH];intros Offsets le m k Ptr Writable.
 - exists m;apply star_refl.
 - destruct(si_store_step ge le m b ofs co delta field
   (match fields with []=>k|_=>Kseq(si_stores fields)k end)Ptr Composite
   (Offsets field(or_introl eq_refl))ltac:(intros f Member;destruct Member as[Eq|Bad];[subst f;apply Writable;left;reflexivity|contradiction]))
   as[m1[Assign Keep]].
   destruct fields as[|next rest].
   + exists m1;eapply star_one;exact Assign.
   + destruct(IH ltac:(intros f InTail;apply Offsets;right;exact InTail)le m1 k Ptr
     ltac:(intros f InTail;apply Keep;apply Writable;right;exact InTail))as[m2 Tail].
     exists m2;cbn[si_stores];fold(si_assign field).
     weight_silent_step. apply Clight.step_seq.
     eapply star_step with(t1:=E0)(t2:=E0);[exact Assign| |reflexivity].
     weight_silent_step. apply Clight.step_skip_seq.
     exact Tail.
Qed.
Definition si_arguments b ofs:=PTree.set _s(Vptr b ofs)(Clight.create_undef_temps(fn_temps f_stats_init)).
Lemma si_entry ge b ofs m:
 Clight.function_entry2 ge f_stats_init[Vptr b ofs]m Clight.empty_env(si_arguments b ofs)m.
Proof.
 constructor.
 - constructor.
 - vm_compute;repeat(apply list_norepet_cons;[simpl;intuition congruence|]);apply list_norepet_nil.
 - vm_compute;intros;intuition congruence.
 - constructor.
 - reflexivity.
Qed.
Theorem actual_stats_init_terminates ge b ofs m k co delta:
 Clight.is_call_cont k ->PTree.get _ccv_stats(Clight.genv_cenv ge)=Some co ->
 (forall field,In field si_fields ->Ctypes.field_offset ge field(co_members co)=Errors.OK(delta field,Full)) ->
 si_writable m b ofs delta si_fields ->
 exists m',star Clight.step2 ge(Clight.Callstate(Internal f_stats_init)[Vptr b ofs]k m)E0
 (Clight.Returnstate Vundef k m').
Proof.
 intros Call Composite Offsets Writable.
 destruct(si_stores_terminate ge b ofs co delta si_fields Composite Offsets(si_arguments b ofs)m k
 ltac:(unfold si_arguments;apply PTree.gss)Writable)as[m' Stores].
 exists m';weight_silent_step. apply Clight.step_internal_function;apply si_entry.
 rewrite si_body_actual;eapply star_trans;[exact Stores| |reflexivity].
 weight_silent_step. { apply Clight.step_skip_call;[exact Call|reflexivity]. }
 apply star_refl.
Qed.
Print Assumptions actual_stats_init_terminates.
