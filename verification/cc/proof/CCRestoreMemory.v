(* The two concrete stores used by restore.  Aliasing is excluded explicitly:
   clearing a forbidden byte must not overwrite the decreasing top counter.
   This is a memory lemma, not a total-search theorem or a native parser proof. *)
Require Import VST.floyd.proofauto.
Require Import CCV.CCClightStores.
Open Scope Z_scope.
Definition cell_apart (ca:memory_chunk)(ba:block)(oa:ptrofs)
 (cb:memory_chunk)(bb:block)(ob:ptrofs):Prop:=
 ba<>bb \/Ptrofs.unsigned oa+size_chunk ca<=Ptrofs.unsigned ob \/
 Ptrofs.unsigned ob+size_chunk cb<=Ptrofs.unsigned oa.
Lemma cell_apart_sym ca ba oa cb bb ob:
 cell_apart ca ba oa cb bb ob ->cell_apart cb bb ob ca ba oa.
Proof. unfold cell_apart;intros[A|[A|A]];[left;congruence|right;right;exact A|right;left;exact A]. Qed.
Lemma apart_store_load ca ba oa cb bb ob m v m':
 cell_apart ca ba oa cb bb ob ->
 Mem.storev ca m(Vptr ba oa)v=Some m' ->
 Mem.loadv cb m'(Vptr bb ob)=Mem.loadv cb m(Vptr bb ob).
Proof.
 intros Apart Store;apply(storev_keeps_other_load ca m ba oa v m' cb bb ob Store).
 apply cell_apart_sym;exact Apart.
Qed.
Theorem restore_two_stores m bt ot bf ofl newtop
 (protected:memory_chunk->block->ptrofs->Prop):
 Mem.valid_access m Mint32 bt(Ptrofs.unsigned ot)Writable ->
 Mem.valid_access m Mint8unsigned bf(Ptrofs.unsigned ofl)Writable ->
 cell_apart Mint32 bt ot Mint8unsigned bf ofl ->
 (forall c b o,protected c b o ->cell_apart Mint32 bt ot c b o) ->
 (forall c b o,protected c b o ->cell_apart Mint8unsigned bf ofl c b o) ->
 exists m1 m2,
 Mem.storev Mint32 m(Vptr bt ot)(Vint newtop)=Some m1 /\
 Mem.storev Mint8unsigned m1(Vptr bf ofl)(Vint Int.zero)=Some m2 /\
 Mem.loadv Mint32 m2(Vptr bt ot)=Some(Vint newtop) /\
 Mem.loadv Mint8unsigned m2(Vptr bf ofl)=Some(Vint Int.zero) /\
 (forall c b o,protected c b o ->Mem.loadv c m2(Vptr b o)=Mem.loadv c m(Vptr b o)) /\
 (forall c b p perm,Mem.valid_access m c b p perm ->Mem.valid_access m2 c b p perm).
Proof.
 intros TopWritable FlagWritable Apart TopApart FlagApart.
 destruct(writable_word_store m bt ot newtop TopWritable)as[m1[TopStore TopLoad]].
 assert(FlagWritable1:Mem.valid_access m1 Mint8unsigned bf(Ptrofs.unsigned ofl)Writable).
 { eapply storev_keeps_valid_access;[exact TopStore|exact FlagWritable]. }
 destruct(writable_byte_zero_store m1 bf ofl FlagWritable1)as[m2[FlagStore FlagLoad]].
 exists m1,m2;split;[exact TopStore|];split;[exact FlagStore|].
 split.
 - rewrite(apart_store_load Mint8unsigned bf ofl Mint32 bt ot m1(Vint Int.zero)m2
   (cell_apart_sym _ _ _ _ _ _ Apart)FlagStore);exact TopLoad.
 - split;[exact FlagLoad|];split.
   + intros c b o Protected.
     rewrite(apart_store_load Mint8unsigned bf ofl c b o m1(Vint Int.zero)m2
      (FlagApart c b o Protected)FlagStore).
     apply(apart_store_load Mint32 bt ot c b o m(Vint newtop)m1
      (TopApart c b o Protected)TopStore).
   + intros c b p perm Valid.
     eapply storev_keeps_valid_access;[exact FlagStore|].
     eapply storev_keeps_valid_access;[exact TopStore|exact Valid].
Qed.
Lemma restore_counter_rank_decreases mark top:
 0<=mark<top ->(Z.to_nat((top-1)-mark)<Z.to_nat(top-mark))%nat.
Proof. intros Range;apply Z2Nat.inj_lt;lia. Qed.
Print Assumptions restore_two_stores.
Print Assumptions restore_counter_rank_decreases.
