(* Defined uint-array lvalue for journal writes; the byte offset matches the
   frozen64-bit ABI. Access permissions/aliasing remain separate premises. *)
Require Import VST.floyd.proofauto.
Require Import compcert.lib.Maps compcert.cfrontend.Clight.
Require Import CCV.CCClightWordReads.
Local Transparent tptr tuchar tuint tint typeconv remove_attributes change_attributes Cop.sem_add.
Open Scope Z_scope.
Lemma lvalue_uint_index ge e le m ptr index b ofs i:
 PTree.get ptr le=Some(Vptr b ofs) ->PTree.get index le=Some(Vint(Int.repr i)) ->
 0<=i<=Int.max_unsigned ->
 Clight.eval_lvalue ge e le m(uint_index_expr ptr index)b(Ptrofs.add ofs(Ptrofs.repr(4*i)))Full.
Proof.
 intros Ptr Index Range;unfold uint_index_expr;apply Clight.eval_Ederef.
 eapply Clight.eval_Ebinop with(v1:=Vptr b ofs)(v2:=Vint(Int.repr i)).
 - apply Clight.eval_Etempvar;exact Ptr.
 - apply Clight.eval_Etempvar;exact Index.
 - cbn[typeof sem_binary_operation].
   unfold Cop.sem_add,Cop.classify_add,Cop.sem_add_ptr_int,Cop.ptrofs_of_int,
     typeconv,tptr,tuint,remove_attributes,change_attributes.
   cbn[Ctypes.sizeof];unfold Ptrofs.of_intu,Ptrofs.of_int;rewrite Int.unsigned_repr by exact Range.
   unfold Ptrofs.mul;rewrite !Ptrofs.unsigned_repr by rep_lia;reflexivity.
Qed.
Print Assumptions lvalue_uint_index.
