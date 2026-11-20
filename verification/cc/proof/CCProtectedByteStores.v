(* Shared memory invariant for clear's byte-writing loops. Metadata loads are
   protected explicitly; mutable byte arrays may alias for definedness alone. *)
Require Import VST.floyd.proofauto.
Require Import CCV.CCClightStores CCV.CCRestoreMemory.
Open Scope Z_scope.
Record protected_read_cell:Type:={
 cpr_chunk:memory_chunk;cpr_block:block;cpr_offset:ptrofs;cpr_value:val}.
Record writable_byte_area:Type:={cpa_block:block;cpa_offset:ptrofs;cpa_size:Z}.
Definition cp_position a i:=Ptrofs.add(cpa_offset a)(Ptrofs.repr i).
Definition cp_reads m cells:=Forall(fun c=>Mem.loadv(cpr_chunk c)m
 (Vptr(cpr_block c)(cpr_offset c))=Some(cpr_value c))cells.
Definition cp_writables m areas:=forall a,In a areas ->forall i,0<=i<cpa_size a ->
 Mem.valid_access m Mint8unsigned(cpa_block a)(Ptrofs.unsigned(cp_position a i))Writable.
Definition cp_separation cells areas:=forall a,In a areas ->forall i,0<=i<cpa_size a ->
 forall c,In c cells ->cell_apart Mint8unsigned(cpa_block a)(cp_position a i)
 (cpr_chunk c)(cpr_block c)(cpr_offset c).
Lemma cp_load_member m cells c:cp_reads m cells ->In c cells ->
 Mem.loadv(cpr_chunk c)m(Vptr(cpr_block c)(cpr_offset c))=Some(cpr_value c).
Proof. unfold cp_reads;rewrite Forall_forall;auto. Qed.
Theorem protected_byte_zero_store m cells areas a i:
 cp_reads m cells ->cp_writables m areas ->cp_separation cells areas ->
 In a areas ->0<=i<cpa_size a ->
 exists m',Mem.storev Mint8unsigned m(Vptr(cpa_block a)(cp_position a i))(Vint Int.zero)=Some m' /\
 cp_reads m' cells /\cp_writables m' areas.
Proof.
 intros Reads Writable Apart Member Range.
 destruct(writable_byte_zero_store m(cpa_block a)(cp_position a i)(Writable a Member i Range))as[m'[Store Load]].
 exists m';split;[exact Store|];split.
 - unfold cp_reads in *;rewrite Forall_forall in *;intros c InCells.
   rewrite(apart_store_load Mint8unsigned(cpa_block a)(cp_position a i)
    (cpr_chunk c)(cpr_block c)(cpr_offset c)m(Vint Int.zero)m'
    (Apart a Member i Range c InCells)Store).
   apply Reads;exact InCells.
 - intros a' InAreas j Index;eapply storev_keeps_valid_access;[exact Store|apply Writable;assumption].
Qed.
Print Assumptions protected_byte_zero_store.
