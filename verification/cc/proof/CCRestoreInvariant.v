(* Concrete restore memory invariant. Read metadata/undo cells and the mutable
   counter/flags are explicitly separated; no allocator or parser is assumed. *)
Require Import VST.floyd.proofauto.
Require Import CCV.CCClightStores CCV.CCRestoreMemory.
Open Scope Z_scope.
Section Layout.
Variable n:Z.
Variables bt bw bf bu:block.
Variables ot ow ofl ou:ptrofs.
Variables df du:Z.
Variable undo:Z->Z.
Definition restore_flag_pos q:=Ptrofs.add ofl(Ptrofs.repr q).
Definition restore_undo_pos j:=Ptrofs.add ou(Ptrofs.repr(4*j)).
Definition restore_field_pos d:=Ptrofs.add ow(Ptrofs.repr d).
Definition restore_read_cell(c:memory_chunk)(b:block)(o:ptrofs):Prop:=
 (c=Mptr /\b=bw /\o=restore_field_pos df) \/
 (c=Mptr /\b=bw /\o=restore_field_pos du) \/
 (exists j,0<=j<n /\c=Mint32 /\b=bu /\o=restore_undo_pos j).
Definition restore_data m:Prop:=
 Mem.loadv Mptr m(Vptr bw(restore_field_pos df))=Some(Vptr bf ofl) /\
 Mem.loadv Mptr m(Vptr bw(restore_field_pos du))=Some(Vptr bu ou) /\
 (forall j,0<=j<n ->Mem.loadv Mint32 m(Vptr bu(restore_undo_pos j))=Some(Vint(Int.repr(undo j)))).
Definition restore_permissions m:Prop:=
 Mem.valid_access m Mint32 bt(Ptrofs.unsigned ot)Writable /\
 (forall q,0<=q<n ->Mem.valid_access m Mint8unsigned bf(Ptrofs.unsigned(restore_flag_pos q))Writable).
Definition restore_memory m top:Prop:=restore_data m /\restore_permissions m /\
 Mem.loadv Mint32 m(Vptr bt ot)=Some(Vint(Int.repr top)).
Definition restore_separation:Prop:=
 (forall q,0<=q<n ->cell_apart Mint32 bt ot Mint8unsigned bf(restore_flag_pos q)) /\
 (forall c b o,restore_read_cell c b o ->cell_apart Mint32 bt ot c b o) /\
 (forall q,0<=q<n ->forall c b o,restore_read_cell c b o ->
 cell_apart Mint8unsigned bf(restore_flag_pos q)c b o).
Lemma restore_data_same m m':
 (forall c b o,restore_read_cell c b o ->Mem.loadv c m'(Vptr b o)=Mem.loadv c m(Vptr b o)) ->
 restore_data m ->restore_data m'.
Proof.
 intros Same[F[U Reads]];unfold restore_data;split.
 - rewrite(Same Mptr bw(restore_field_pos df));[exact F|left;auto].
 - split.
   + rewrite(Same Mptr bw(restore_field_pos du));[exact U|right;left;auto].
   + intros j Range;rewrite(Same Mint32 bu(restore_undo_pos j));[apply Reads;exact Range|].
     right;right;exists j;auto.
Qed.
Lemma restore_permissions_same m m':
 (forall c b p perm,Mem.valid_access m c b p perm ->Mem.valid_access m' c b p perm) ->
 restore_permissions m ->restore_permissions m'.
Proof. intros Keep[Top Flags];split;[apply Keep;exact Top|intros q Range;apply Keep;apply Flags;exact Range]. Qed.
Theorem restore_memory_decrement m top:
 restore_separation ->(forall j,0<=j<n ->0<=undo j<n) ->
 0<top<=n ->restore_memory m top ->
 exists m1 m2,
 Mem.storev Mint32 m(Vptr bt ot)(Vint(Int.repr(top-1)))=Some m1 /\
 Mem.storev Mint8unsigned m1(Vptr bf(restore_flag_pos(undo(top-1))))(Vint Int.zero)=Some m2 /\
 restore_memory m1(top-1) /\restore_memory m2(top-1).
Proof.
 intros[Apart[TopApart FlagApart]] UndoRange Range[Data[Permissions TopLoad]].
 pose proof Permissions as[TopWritable FlagsWritable].
 assert(J:0<=top-1<n)by lia.
 pose proof(UndoRange(top-1)J)as Q.
 destruct(restore_two_stores m bt ot bf(restore_flag_pos(undo(top-1)))
 (Int.repr(top-1))restore_read_cell TopWritable(FlagsWritable _ Q)(Apart _ Q)
 TopApart(FlagApart _ Q))as[m1[m2[Store1[Store2[Top2[Flag2[Same Valid]]]]]]].
 exists m1,m2;split;[exact Store1|];split;[exact Store2|];split.
 - split.
   + eapply restore_data_same;[|exact Data].
     intros c b o Protected;eapply apart_store_load;[apply TopApart;exact Protected|exact Store1].
   + split.
     * eapply restore_permissions_same;[|exact Permissions].
       intros c b p perm Access;eapply storev_keeps_valid_access;[exact Store1|exact Access].
     * eapply Mem.load_store_same with(m1:=m)(v:=Vint(Int.repr(top-1)));exact Store1.
 - split;[eapply restore_data_same;[exact Same|exact Data]|].
   split;[eapply restore_permissions_same;[exact Valid|exact Permissions]|exact Top2].
Qed.
End Layout.
Print Assumptions restore_memory_decrement.
