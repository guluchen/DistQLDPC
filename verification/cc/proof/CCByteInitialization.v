(* One defined byte store preserves initialized byte reads, including aliases.
   This is sufficient for termination of the primitive in-place XOR loop;
   its functional array relation is the separate existing VST specification. *)
Require Import VST.floyd.proofauto.
Require Import CCV.CCClightStores.
Open Scope Z_scope.
Definition byte_initialized m b ofs:=exists v,Mem.loadv Mint8unsigned m(Vptr b ofs)=Some(Vint v).
Lemma writable_byte_value_store m b ofs value:
 Mem.valid_access m Mint8unsigned b(Ptrofs.unsigned ofs)Writable ->
 exists m',Mem.storev Mint8unsigned m(Vptr b ofs)(Vint value)=Some m'.
Proof. intros Writable;destruct(Mem.valid_access_store m Mint8unsigned b(Ptrofs.unsigned ofs)(Vint value)Writable)as[m' Store];exists m';exact Store. Qed.
Lemma byte_store_keeps_initialized m b ofs value m' b' ofs':
 Mem.storev Mint8unsigned m(Vptr b ofs)(Vint value)=Some m' ->
 byte_initialized m b' ofs' ->byte_initialized m' b' ofs'.
Proof.
 intros Store[v Load];destruct(peq b' b)as[Block|Block].
 - subst b';destruct(Z.eq_dec(Ptrofs.unsigned ofs')(Ptrofs.unsigned ofs))as[Equal|Other].
   + pose proof(f_equal Ptrofs.repr Equal)as Eq;rewrite !Ptrofs.repr_unsigned in Eq;subst ofs'.
     exists(Int.zero_ext 8 value);eapply Mem.load_store_same with(m1:=m)(v:=Vint value);exact Store.
   + exists v;rewrite(storev_keeps_other_load Mint8unsigned m b ofs(Vint value)m' Mint8unsigned b ofs' Store).
     * exact Load.
     * right;cbn[size_chunk];lia.
 - exists v;rewrite(storev_keeps_other_load Mint8unsigned m b ofs(Vint value)m' Mint8unsigned b' ofs' Store).
   + exact Load.
   + left;exact Block.
Qed.
Print Assumptions byte_store_keeps_initialized.
