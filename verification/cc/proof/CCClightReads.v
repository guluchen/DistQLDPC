(* Reusable actual-Clight evaluation of valid array/structure reads. These
   are memory-definedness premises, not claims about the native PCM parser. *)
Require Import VST.floyd.proofauto.
Require Import compcert.lib.Maps compcert.common.Events compcert.cfrontend.Clight.
Local Transparent tptr tuchar tuint tint typeconv remove_attributes change_attributes Cop.sem_add.
Open Scope Z_scope.
Definition uchar_index_expr ptr index:=
 Ederef(Ebinop Oadd(Etempvar ptr(tptr tuchar))(Etempvar index tuint)(tptr tuchar))tuchar.
Lemma eval_uchar_index ge e le m ptr index b ofs i v:
 PTree.get ptr le=Some(Vptr b ofs) ->PTree.get index le=Some(Vint(Int.repr i)) ->
 0<=i<=Int.max_unsigned ->
 Mem.loadv Mint8unsigned m(Vptr b(Ptrofs.add ofs(Ptrofs.repr i)))=Some(Vint v) ->
 Clight.eval_expr ge e le m(uchar_index_expr ptr index)(Vint v).
Proof.
 intros Ptr Index Range Load;unfold uchar_index_expr.
 eapply Clight.eval_Elvalue with(loc:=b)(ofs:=Ptrofs.add ofs(Ptrofs.repr i))(bf:=Full).
 - apply Clight.eval_Ederef.
   eapply Clight.eval_Ebinop with(v1:=Vptr b ofs)(v2:=Vint(Int.repr i)).
   + apply Clight.eval_Etempvar;exact Ptr.
   + apply Clight.eval_Etempvar;exact Index.
   + cbn[typeof sem_binary_operation].
     unfold Cop.sem_add,Cop.classify_add,Cop.sem_add_ptr_int,Cop.ptrofs_of_int,
       typeconv,tptr,tuchar,tuint,remove_attributes,change_attributes.
     cbn[Ctypes.sizeof];rewrite Ptrofs.mul_commut,Ptrofs.mul_one.
     unfold Ptrofs.of_intu,Ptrofs.of_int;rewrite Int.unsigned_repr by exact Range;reflexivity.
 - eapply Clight.deref_loc_value;[reflexivity|exact Load].
Qed.
Definition uint_lt_expr index limit:=Ebinop Olt(Etempvar index tuint)(Etempvar limit tuint)tint.
Lemma eval_uint_lt ge e le m index limit i n(flag:bool):
 PTree.get index le=Some(Vint(Int.repr i)) ->PTree.get limit le=Some(Vint(Int.repr n)) ->
 0<=i<=Int.max_unsigned ->0<=n<=Int.max_unsigned ->(if flag then i<n else n<=i) ->
 Clight.eval_expr ge e le m(uint_lt_expr index limit)(Vint(if flag then Int.one else Int.zero)).
Proof.
 intros Index Limit IR NR Order;unfold uint_lt_expr.
 eapply Clight.eval_Ebinop with(v1:=Vint(Int.repr i))(v2:=Vint(Int.repr n)).
 - apply Clight.eval_Etempvar;exact Index.
 - apply Clight.eval_Etempvar;exact Limit.
 - change (Some (Val.of_bool (Int.ltu (Int.repr i) (Int.repr n))) =
   Some (Vint (if flag then Int.one else Int.zero))).
   unfold Int.ltu;rewrite !Int.unsigned_repr by assumption.
   destruct flag;destruct(zlt i n);cbn in *;try lia;reflexivity.
Qed.
Definition struct_field_expr base sid field ty:=
 Efield(Ederef(Etempvar base(tptr(Tstruct sid noattr)))(Tstruct sid noattr))field ty.
Lemma eval_struct_field ge e le m base sid field ty co delta chunk b ofs v:
 PTree.get base le=Some(Vptr b ofs) ->
 PTree.get sid(Clight.genv_cenv ge)=Some co ->
 Ctypes.field_offset ge field(Ctypes.co_members co)=Errors.OK(delta,Full) ->
 access_mode ty=By_value chunk ->
 Mem.loadv chunk m(Vptr b(Ptrofs.add ofs(Ptrofs.repr delta)))=Some v ->
 Clight.eval_expr ge e le m(struct_field_expr base sid field ty)v.
Proof.
 intros Ptr Composite Offset Access Load;unfold struct_field_expr.
 eapply Clight.eval_Elvalue with(loc:=b)(ofs:=Ptrofs.add ofs(Ptrofs.repr delta))(bf:=Full).
 - eapply Clight.eval_Efield_struct with(id:=sid)(co:=co)(att:=noattr)(delta:=delta).
   + eapply Clight.eval_Elvalue with(loc:=b)(ofs:=ofs)(bf:=Full).
     * apply Clight.eval_Ederef;apply Clight.eval_Etempvar;exact Ptr.
     * apply Clight.deref_loc_copy;reflexivity.
   + reflexivity.
   + exact Composite.
   + exact Offset.
 - eapply Clight.deref_loc_value;[exact Access|exact Load].
Qed.
Print Assumptions eval_uchar_index.
Print Assumptions eval_uint_lt.
Print Assumptions eval_struct_field.
