(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto RawPCMPrimitives RawPCMPackRow SparseFlipBits.
Local Open Scope Z_scope.

Lemma packed_mask_at (v:bool) lane j:0<=lane<64 -> 0<=j<64 ->
 Int64.testbit (Int64.shl' (if v then Int64.one else Int64.zero) (Int.repr lane)) j=
 andb v (Z.eqb j lane).
Proof.
 intros lane_ok addr_ok.
 assert (shift:forall w,Int64.shl' w (Int.repr lane)=Int64.shl w (Int64.repr lane)).
 { intro w;unfold Int64.shl,Int64.shl';rewrite Int.unsigned_repr,Int64.unsigned_repr by rep_lia;reflexivity. }
 rewrite shift;destruct v;simpl.
 - apply one_bit_at;assumption.
 - rewrite Int64.bits_shl by exact addr_ok;rewrite Int64.unsigned_repr by rep_lia.
   destruct zlt;[reflexivity|apply Int64.bits_zero;try (change Int64.zwordsize with 64;lia)].
Qed.

Lemma read_installed_bit xs q j v:
 0<=q<64*Zlength xs -> 0<=j<64*Zlength xs ->
 packed_bit (install_bit xs q v) j=
 orb (packed_bit xs j) (andb v (Z.eqb j q)).
Proof.
 intros q_ok j_ok;unfold packed_bit,install_bit.
 assert (ql:0<=q mod 64<64) by (apply Z.mod_pos_bound;lia).
 assert (jl:0<=j mod 64<64) by (apply Z.mod_pos_bound;lia).
 assert (qw:0<=q/64<Zlength xs) by (split;[apply Z.div_pos|apply Z.div_lt_upper_bound];lia).
 assert (jw:0<=j/64<Zlength xs) by (split;[apply Z.div_pos|apply Z.div_lt_upper_bound];lia).
 destruct (Z.eq_dec (j/64) (q/64)) as [in_word|different].
 - rewrite in_word,upd_Znth_same by exact qw.
   rewrite Int64.bits_or by exact jl;rewrite packed_mask_at by assumption.
   destruct (Z.eqb_spec j q) as [->|neq];[rewrite Z.eqb_refl;reflexivity|].
   assert (lanes:j mod 64<>q mod 64).
   { intro eqn;pose proof (Z.div_mod j 64 ltac:(lia));pose proof (Z.div_mod q 64 ltac:(lia));lia. }
   apply Z.eqb_neq in lanes;rewrite lanes;reflexivity.
 - rewrite upd_Znth_diff by lia. assert (unequal:j<>q) by congruence.
   apply Z.eqb_neq in unequal;rewrite unequal,andb_false_r,orb_false_r;reflexivity.
Qed.

Theorem physical_bytes_after_pack bytes r n nw k j:
 0<=n<=64*nw -> 0<=j<64*nw -> Z.of_nat k<=n ->
 packed_bit (pack_prefix bytes r n (Zrepeat Int64.zero nw) k) j=
 if Z.ltb j (Z.of_nat k) then Znth (r*n+j) bytes else false.
Proof.
 intros dim addr;induction k as [|k IH];intro scanned.
 - cbn [pack_prefix];unfold packed_bit;rewrite Znth_Zrepeat by
     (split;[apply Z.div_pos|apply Z.div_lt_upper_bound];lia).
   rewrite Int64.bits_zero;change (Z.of_nat 0) with 0;destruct (Z.ltb_spec j 0);lia || reflexivity.
 - cbn [pack_prefix];rewrite read_installed_bit;try (rewrite pack_length,Zlength_Zrepeat by lia;lia).
   rewrite IH by lia;rewrite Nat2Z.inj_succ.
   destruct (Z.ltb_spec j (Z.of_nat k)),(Z.eqb_spec j (Z.of_nat k)),
     (Z.ltb_spec j (Z.succ (Z.of_nat k)));try lia;subst;
     rewrite ?andb_false_r,?andb_true_r,?orb_false_r,?orb_false_l;reflexivity.
Qed.

(* The row stored by the actual C substatement can now be read at any
   original physical column, including the last partial 64-bit word. *)
Require Import raw_pcm_ast.
#[local] Existing Instance RawPCMComposites.
Theorem raw_row_is_original_pcm {Espec:OracleKind} a red p buf sh bytes r nr n nw:
 readable_share sh -> 0<=r<nr -> nr<=Int.max_signed -> 0<=n<=Int.max_signed ->
 0<=nw -> n<=64*nw -> Zlength bytes=nr*n ->
 let zero_row:=Zrepeat Int64.zero nw in
 let result:=pack_prefix bytes r n zero_row (Z.to_nat n) in
 let mem:=matrix_bytes sh a buf nr n bytes in let regs:=pack_regs a red p r in
 semax (func_tycontext f_reduce_matrix raw_vars pack_calls [])
   (PROPx [] (LOCALx regs (SEPx [mem;row_storage p nw zero_row]))) pack_row
   (normal_ret_assert (PROPx [] (LOCALx regs (SEPx [mem;row_storage p nw result])))) /\
 forall j,0<=j<n -> packed_bit result j=Znth (r*n+j) bytes.
Proof.
 intros readable row_ok row_cap width words room count zero_row result mem regs.
 assert (len:Zlength zero_row=nw) by (unfold zero_row;rewrite Zlength_Zrepeat;lia).
 split.
 - replace nw with (Zlength zero_row) by lia;apply fill_packed_row;try assumption;lia.
 - intros j at_j;unfold result,zero_row;rewrite physical_bytes_after_pack;try (rewrite ?Z2Nat.id by lia;lia).
   rewrite Z2Nat.id by lia;destruct (Z.ltb_spec j n);lia || reflexivity.
Qed.
