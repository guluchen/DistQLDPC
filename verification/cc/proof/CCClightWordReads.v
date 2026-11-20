(* Actual uint-word dereferences and index arithmetic for writeful helpers.
   Read premises remain explicit; no parser/whole-helper claim follows. *)
Require Import VST.floyd.proofauto.
Require Import compcert.lib.Maps compcert.cfrontend.Clight.
Local Transparent tptr tuchar tuint tint typeconv remove_attributes change_attributes Cop.sem_add.
Open Scope Z_scope.
Definition uint_deref_expr ptr:=Ederef(Etempvar ptr(tptr tuint))tuint.
Definition uint_index_expr ptr index:=
 Ederef(Ebinop Oadd(Etempvar ptr(tptr tuint))(Etempvar index tuint)(tptr tuint))tuint.
Lemma eval_uint_deref ge e le m ptr b ofs word:
 PTree.get ptr le=Some(Vptr b ofs) ->Mem.loadv Mint32 m(Vptr b ofs)=Some(Vint word) ->
 Clight.eval_expr ge e le m(uint_deref_expr ptr)(Vint word).
Proof.
 intros Ptr Load;unfold uint_deref_expr.
 eapply Clight.eval_Elvalue with(loc:=b)(ofs:=ofs)(bf:=Full).
 - apply Clight.eval_Ederef;apply Clight.eval_Etempvar;exact Ptr.
 - eapply Clight.deref_loc_value;[reflexivity|exact Load].
Qed.
Lemma eval_uint_index ge e le m ptr index b ofs i v:
 PTree.get ptr le=Some(Vptr b ofs) ->PTree.get index le=Some(Vint(Int.repr i)) ->
 0<=i<=Int.max_unsigned ->
 Mem.loadv Mint32 m(Vptr b(Ptrofs.add ofs(Ptrofs.repr(4*i))))=Some(Vint v) ->
 Clight.eval_expr ge e le m(uint_index_expr ptr index)(Vint v).
Proof.
 intros Ptr Index Range Load;unfold uint_index_expr.
 eapply Clight.eval_Elvalue with(loc:=b)(ofs:=Ptrofs.add ofs(Ptrofs.repr(4*i)))(bf:=Full).
 - apply Clight.eval_Ederef.
   eapply Clight.eval_Ebinop with(v1:=Vptr b ofs)(v2:=Vint(Int.repr i)).
   + apply Clight.eval_Etempvar;exact Ptr.
   + apply Clight.eval_Etempvar;exact Index.
   + cbn[typeof sem_binary_operation].
     unfold Cop.sem_add,Cop.classify_add,Cop.sem_add_ptr_int,Cop.ptrofs_of_int,
       typeconv,tptr,tuint,remove_attributes,change_attributes.
     cbn[Ctypes.sizeof].
     unfold Ptrofs.of_intu,Ptrofs.of_int;rewrite Int.unsigned_repr by exact Range.
     unfold Ptrofs.mul;rewrite !Ptrofs.unsigned_repr by rep_lia;reflexivity.
 - eapply Clight.deref_loc_value;[reflexivity|exact Load].
Qed.
Lemma eval_uint_sub_one ge e le m index i:
 PTree.get index le=Some(Vint(Int.repr i)) ->0<=i<=Int.max_unsigned ->
 Clight.eval_expr ge e le m
 (Ebinop Osub(Etempvar index tuint)(Econst_int(Int.repr 1)tuint)tuint)(Vint(Int.repr(i-1))).
Proof.
 intros Index Range.
 eapply Clight.eval_Ebinop with(v1:=Vint(Int.repr i))(v2:=Vint(Int.repr 1)).
 - apply Clight.eval_Etempvar;exact Index.
 - apply Clight.eval_Econst_int.
 - change(Some(Vint(Int.sub(Int.repr i)(Int.repr 1)))=Some(Vint(Int.repr(i-1)))).
   unfold Int.sub;rewrite !Int.unsigned_repr by rep_lia;reflexivity.
Qed.
Lemma eval_uint_gt ge e le m lhs rhs a b(flag:bool):
 PTree.get lhs le=Some(Vint(Int.repr a)) ->PTree.get rhs le=Some(Vint(Int.repr b)) ->
 0<=a<=Int.max_unsigned ->0<=b<=Int.max_unsigned ->(if flag then b<a else a<=b) ->
 Clight.eval_expr ge e le m(Ebinop Cop.Ogt(Etempvar lhs tuint)(Etempvar rhs tuint)tint)
 (Vint(if flag then Int.one else Int.zero)).
Proof.
 intros Left Right AR BR Order.
 eapply Clight.eval_Ebinop with(v1:=Vint(Int.repr a))(v2:=Vint(Int.repr b)).
 - apply Clight.eval_Etempvar;exact Left.
 - apply Clight.eval_Etempvar;exact Right.
 - change (Some (Val.of_bool (Int.ltu (Int.repr b) (Int.repr a))) =
   Some (Vint (if flag then Int.one else Int.zero))).
   unfold Int.ltu;rewrite !Int.unsigned_repr by assumption.
   destruct flag;destruct(zlt b a);cbn in *;try lia;reflexivity.
Qed.
Print Assumptions eval_uint_index.
Print Assumptions eval_uint_sub_one.
