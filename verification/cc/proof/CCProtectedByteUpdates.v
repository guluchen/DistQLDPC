(* Protected metadata + initialized byte regions, preserved by an arbitrary
   defined byte update. Writable/source regions may overlap for definedness. *)
Require Import VST.floyd.proofauto.
Require Import CCV.CCClightStores CCV.CCRestoreMemory CCV.CCByteInitialization CCV.CCProtectedByteStores.
Open Scope Z_scope.
Definition cp_initialized m areas:=forall a,In a areas ->forall i,0<=i<cpa_size a ->
 byte_initialized m(cpa_block a)(cp_position a i).
Theorem protected_byte_value_store m cells areas sources a i value:
 cp_reads m cells ->cp_writables m areas ->cp_initialized m sources ->cp_separation cells areas ->
 In a areas ->0<=i<cpa_size a ->
 exists m',Mem.storev Mint8unsigned m(Vptr(cpa_block a)(cp_position a i))(Vint value)=Some m' /\
 cp_reads m' cells /\cp_writables m' areas /\cp_initialized m' sources.
Proof.
 intros Reads Writable Initialized Apart Member Range.
 destruct(writable_byte_value_store m(cpa_block a)(cp_position a i)value(Writable a Member i Range))as[m' Store].
 exists m';split;[exact Store|];split.
 - unfold cp_reads in *;rewrite Forall_forall in *;intros c InCells.
   rewrite(apart_store_load Mint8unsigned(cpa_block a)(cp_position a i)
    (cpr_chunk c)(cpr_block c)(cpr_offset c)m(Vint value)m'
    (Apart a Member i Range c InCells)Store).
   apply Reads;exact InCells.
 - split.
   + intros a' InAreas j Index;eapply storev_keeps_valid_access;[exact Store|apply Writable;assumption].
   + intros a' InSources j Index;eapply byte_store_keeps_initialized;[exact Store|apply Initialized;assumption].
Qed.
Print Assumptions protected_byte_value_store.
