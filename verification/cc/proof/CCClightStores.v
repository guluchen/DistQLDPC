(* Defined actual-Clight assignments and CompCert memory facts needed by
   writeful helper loops. No ownership/whole-loop precondition is inferred. *)
Require Import VST.floyd.proofauto.
Require Import compcert.common.Events compcert.cfrontend.Clight.
Open Scope Z_scope.
Lemma writable_word_store m b ofs word:
 Mem.valid_access m Mint32 b(Ptrofs.unsigned ofs)Writable ->
 exists m',Mem.storev Mint32 m(Vptr b ofs)(Vint word)=Some m' /\
 Mem.loadv Mint32 m'(Vptr b ofs)=Some(Vint word).
Proof.
 intros Writable;destruct(Mem.valid_access_store m Mint32 b(Ptrofs.unsigned ofs)(Vint word)Writable)as[m' Store].
 exists m';split;[exact Store|].
 eapply Mem.load_store_same with(m1:=m)(v:=Vint word);exact Store.
Qed.
Lemma writable_byte_zero_store m b ofs:
 Mem.valid_access m Mint8unsigned b(Ptrofs.unsigned ofs)Writable ->
 exists m',Mem.storev Mint8unsigned m(Vptr b ofs)(Vint Int.zero)=Some m' /\
 Mem.loadv Mint8unsigned m'(Vptr b ofs)=Some(Vint Int.zero).
Proof.
 intros Writable;destruct(Mem.valid_access_store m Mint8unsigned b(Ptrofs.unsigned ofs)(Vint Int.zero)Writable)as[m' Store].
 exists m';split;[exact Store|].
 eapply Mem.load_store_same with(m1:=m)(v:=Vint Int.zero);exact Store.
Qed.
Lemma storev_keeps_other_load chunk m b ofs value m' chunk' b' ofs':
 Mem.storev chunk m(Vptr b ofs)value=Some m' ->
 (b'<>b \/Ptrofs.unsigned ofs'+size_chunk chunk'<=Ptrofs.unsigned ofs \/
  Ptrofs.unsigned ofs+size_chunk chunk<=Ptrofs.unsigned ofs') ->
 Mem.loadv chunk' m'(Vptr b' ofs')=Mem.loadv chunk' m(Vptr b' ofs').
Proof. intros Store Apart;eapply Mem.load_store_other;[exact Store|exact Apart]. Qed.
Lemma storev_keeps_valid_access chunk m b ofs value m' chunk' b' pos perm:
 Mem.storev chunk m(Vptr b ofs)value=Some m' ->
 Mem.valid_access m chunk' b' pos perm ->Mem.valid_access m' chunk' b' pos perm.
Proof. intros Store Valid;eapply Mem.store_valid_access_1;[exact Store|exact Valid]. Qed.
Lemma defined_assignment_step ge f k e le m lhs rhs b ofs chunk value casted m':
 Clight.eval_lvalue ge e le m lhs b ofs Full ->
 Clight.eval_expr ge e le m rhs value ->
 Cop.sem_cast value(typeof rhs)(typeof lhs)m=Some casted ->
 access_mode(typeof lhs)=By_value chunk ->
 Mem.storev chunk m(Vptr b ofs)casted=Some m' ->
 Clight.step2 ge(Clight.State f(Sassign lhs rhs)k e le m)E0
 (Clight.State f Sskip k e le m').
Proof.
 intros Address Value Cast Access Store;unfold Clight.step2.
 eapply Clight.step_assign;[exact Address|exact Value|exact Cast|].
 eapply Clight.assign_loc_value;[exact Access|exact Store].
Qed.
Print Assumptions writable_word_store.
Print Assumptions storev_keeps_other_load.
Print Assumptions defined_assignment_step.
