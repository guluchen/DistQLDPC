(* Defined journal/counter/flag stores for forbid's taken insertion path.
   The protected physical reads are explicit; this is not an allocator proof. *)
Require Import VST.floyd.proofauto.
Require Import CCV.CCClightStores CCV.CCRestoreMemory CCV.CCByteInitialization.
Open Scope Z_scope.
Theorem forbid_three_stores m bt ot bu ou bw ofield bf oflag ofbase top q:
 Mem.loadv Mint32 m(Vptr bt ot)=Some(Vint(Int.repr top)) ->
 Mem.loadv Mptr m(Vptr bw ofield)=Some(Vptr bf ofbase) ->
 Mem.valid_access m Mint32 bu(Ptrofs.unsigned ou)Writable ->
 Mem.valid_access m Mint32 bt(Ptrofs.unsigned ot)Writable ->
 Mem.valid_access m Mint8unsigned bf(Ptrofs.unsigned oflag)Writable ->
 cell_apart Mint32 bu ou Mint32 bt ot ->
 cell_apart Mint32 bu ou Mptr bw ofield ->
 cell_apart Mint32 bt ot Mptr bw ofield ->
 exists m1 m2 m3,
 Mem.storev Mint32 m(Vptr bu ou)(Vint(Int.repr q))=Some m1 /\
 Mem.loadv Mint32 m1(Vptr bt ot)=Some(Vint(Int.repr top)) /\
 Mem.storev Mint32 m1(Vptr bt ot)(Vint(Int.repr(top+1)))=Some m2 /\
 Mem.loadv Mptr m2(Vptr bw ofield)=Some(Vptr bf ofbase) /\
 Mem.storev Mint8unsigned m2(Vptr bf oflag)(Vint Int.one)=Some m3.
Proof.
 intros TopLoad FieldLoad UndoWritable TopWritable FlagWritable ApartUT ApartUF ApartTF.
 destruct(writable_word_store m bu ou(Int.repr q)UndoWritable)as[m1[Store1 Undo1]].
 assert(TopLoad1:Mem.loadv Mint32 m1(Vptr bt ot)=Some(Vint(Int.repr top))).
 { rewrite(apart_store_load Mint32 bu ou Mint32 bt ot m(Vint(Int.repr q))m1 ApartUT Store1);exact TopLoad. }
 assert(FieldLoad1:Mem.loadv Mptr m1(Vptr bw ofield)=Some(Vptr bf ofbase)).
 { rewrite(apart_store_load Mint32 bu ou Mptr bw ofield m(Vint(Int.repr q))m1 ApartUF Store1);exact FieldLoad. }
 assert(TopWritable1:Mem.valid_access m1 Mint32 bt(Ptrofs.unsigned ot)Writable).
 { eapply storev_keeps_valid_access;[exact Store1|exact TopWritable]. }
 destruct(writable_word_store m1 bt ot(Int.repr(top+1))TopWritable1)as[m2[Store2 Top2]].
 assert(FieldLoad2:Mem.loadv Mptr m2(Vptr bw ofield)=Some(Vptr bf ofbase)).
 { rewrite(apart_store_load Mint32 bt ot Mptr bw ofield m1(Vint(Int.repr(top+1)))m2 ApartTF Store2);exact FieldLoad1. }
 assert(FlagWritable2:Mem.valid_access m2 Mint8unsigned bf(Ptrofs.unsigned oflag)Writable).
 { eapply storev_keeps_valid_access;[exact Store2|].
   eapply storev_keeps_valid_access;[exact Store1|exact FlagWritable]. }
 destruct(writable_byte_value_store m2 bf oflag Int.one FlagWritable2)as[m3 Store3].
 exists m1,m2,m3;repeat split;assumption.
Qed.
Print Assumptions forbid_three_stores.
