(* Actual row-major byte reads for the core toggle/validation scans. The
   machine index has no wrap under explicit unsigned index/product bounds. *)
Require Import VST.floyd.proofauto.
Require Import compcert.lib.Maps compcert.cfrontend.Clight.
Open Scope Z_scope.
Local Transparent tptr tuchar tuint tint typeconv remove_attributes change_attributes Cop.sem_add.
Definition matrix_index_expr row stride col:=Ebinop Oadd
 (Ebinop Omul(Etempvar row tuint)(Etempvar stride tuint)tuint)(Etempvar col tuint)tuint.
Definition matrix_byte_expr ptr row stride col:=
 Ederef(Ebinop Oadd(Etempvar ptr(tptr tuchar))(matrix_index_expr row stride col)(tptr tuchar))tuchar.
Lemma eval_matrix_index ge e le m row stride col i n q:
 PTree.get row le=Some(Vint(Int.repr i)) ->PTree.get stride le=Some(Vint(Int.repr n)) ->
 PTree.get col le=Some(Vint(Int.repr q)) ->
 0<=i<=Int.max_unsigned ->0<=n<=Int.max_unsigned ->0<=q<=Int.max_unsigned ->
 0<=i*n+q<=Int.max_unsigned ->
 Clight.eval_expr ge e le m(matrix_index_expr row stride col)(Vint(Int.repr(i*n+q))).
Proof.
 intros Row Stride Col IR NR QR Index;unfold matrix_index_expr.
 assert(Mul:Int.mul(Int.repr i)(Int.repr n)=Int.repr(i*n)).
 { unfold Int.mul;rewrite !Int.unsigned_repr by assumption;reflexivity. }
 assert(Add:Int.add(Int.repr(i*n))(Int.repr q)=Int.repr(i*n+q)).
 { unfold Int.add;rewrite !Int.unsigned_repr by nia;reflexivity. }
 eapply Clight.eval_Ebinop with(v1:=Vint(Int.repr(i*n)))(v2:=Vint(Int.repr q)).
 - eapply Clight.eval_Ebinop with(v1:=Vint(Int.repr i))(v2:=Vint(Int.repr n)).
   + apply Clight.eval_Etempvar;exact Row.
   + apply Clight.eval_Etempvar;exact Stride.
   + change(Some(Vint(Int.mul(Int.repr i)(Int.repr n)))=Some(Vint(Int.repr(i*n))));rewrite Mul;reflexivity.
 - apply Clight.eval_Etempvar;exact Col.
 - change(Some(Vint(Int.add(Int.repr(i*n))(Int.repr q)))=Some(Vint(Int.repr(i*n+q))));rewrite Add;reflexivity.
Qed.
Lemma eval_matrix_byte ge e le m ptr row stride col b ofs i n q value:
 PTree.get ptr le=Some(Vptr b ofs) ->PTree.get row le=Some(Vint(Int.repr i)) ->
 PTree.get stride le=Some(Vint(Int.repr n)) ->PTree.get col le=Some(Vint(Int.repr q)) ->
 0<=i<=Int.max_unsigned ->0<=n<=Int.max_unsigned ->0<=q<=Int.max_unsigned ->
 0<=i*n+q<=Int.max_unsigned ->
 Mem.loadv Mint8unsigned m(Vptr b(Ptrofs.add ofs(Ptrofs.repr(i*n+q))))=Some(Vint value) ->
 Clight.eval_expr ge e le m(matrix_byte_expr ptr row stride col)(Vint value).
Proof.
 intros Ptr Row Stride Col IR NR QR Index Load;unfold matrix_byte_expr.
 eapply Clight.eval_Elvalue with(loc:=b)(ofs:=Ptrofs.add ofs(Ptrofs.repr(i*n+q)))(bf:=Full).
 - apply Clight.eval_Ederef.
   eapply Clight.eval_Ebinop with(v1:=Vptr b ofs)(v2:=Vint(Int.repr(i*n+q))).
   + apply Clight.eval_Etempvar;exact Ptr.
   + apply(eval_matrix_index ge e le m row stride col i n q);assumption.
   + cbn[matrix_index_expr typeof sem_binary_operation].
     unfold Cop.sem_add,Cop.classify_add,Cop.sem_add_ptr_int,Cop.ptrofs_of_int,
       typeconv,tptr,tuchar,tuint,remove_attributes,change_attributes.
     cbn[Ctypes.sizeof];rewrite Ptrofs.mul_commut,Ptrofs.mul_one.
     unfold Ptrofs.of_intu,Ptrofs.of_int;rewrite Int.unsigned_repr by exact Index;reflexivity.
 - eapply Clight.deref_loc_value;[reflexivity|exact Load].
Qed.
Lemma matrix_index_in_array rows n i q:
 0<=i<rows ->0<=q<n ->0<=rows*n<=Int.max_unsigned ->
 0<=i*n+q<rows*n /\0<=i*n+q<=Int.max_unsigned.
Proof. intros Row Col Product;split;nia. Qed.
Print Assumptions eval_matrix_byte.
Print Assumptions matrix_index_in_array.
