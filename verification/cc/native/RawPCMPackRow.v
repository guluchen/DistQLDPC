(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.floyd.reassoc_seq ClightSelect raw_pcm_ast RawPCMPrimitives.
#[local] Existing Instance RawPCMComposites.
Local Open Scope Z_scope.

Definition pack_row:statement:=ltac:(native_fragment (counts_on _q) f_reduce_matrix).
Definition install_bit (row:list int64) q (v:bool):=
 let j:=q/64 in let word:=if v then Int64.one else Int64.zero in
 upd_Znth j row (Int64.or (Znth j row) (Int64.shl' word (Int.repr (q mod 64)))).
Fixpoint pack_prefix bytes (r n:Z) initial k:=
 match k with
 | O=>initial
 | S i=>install_bit (pack_prefix bytes r n initial i) (Z.of_nat i) (Znth (r*n+Z.of_nat i) bytes)
 end.
Lemma pack_length bytes r n initial k:Zlength (pack_prefix bytes r n initial k)=Zlength initial.
Proof. induction k;simpl;[reflexivity|unfold install_bit;rewrite Zlength_upd_Znth;assumption]. Qed.
Lemma pack_one_more bytes r n initial q:0<=q ->
 pack_prefix bytes r n initial (Z.to_nat (q+1))=
 install_bit (pack_prefix bytes r n initial (Z.to_nat q)) q (Znth (r*n+q) bytes).
Proof. intros;replace (q+1) with (Z.succ q) by lia;rewrite Z2Nat.inj_succ by lia;cbn;rewrite Z2Nat.id by lia;reflexivity. Qed.

Lemma byte_shift (b:bool) lane:0<=lane<64 ->
 Int64.shl (Int64.repr (Int.unsigned (if b then Int.one else Int.zero)))
    (Int64.repr (Int.unsigned (Int.repr lane)))=
 Int64.shl' (if b then Int64.one else Int64.zero) (Int.repr lane).
Proof.
 intros valid;unfold Int64.shl,Int64.shl';rewrite (Int64.unsigned_repr (Int.unsigned (Int.repr lane))) by
   (pose proof (Int.unsigned_range_2 (Int.repr lane));rep_lia).
 destruct b;reflexivity.
Qed.

Definition pack_regs a red p r:=[temp _a a;temp _r red;temp _row p;temp _i (Vint (Int.repr r))].
Definition pack_calls:funspecs:=ltac:(with_library prog [entry_spec]).
Theorem fill_packed_row {Espec:OracleKind} a red p buf r nr n sh bytes initial:
 readable_share sh -> 0<=r<nr -> nr<=Int.max_signed -> 0<=n<=Int.max_signed ->
 n<=64*Zlength initial -> Zlength bytes=nr*n ->
 let loc:=pack_regs a red p r in
 let store:=matrix_bytes sh a buf nr n bytes in
 semax (func_tycontext f_reduce_matrix raw_vars pack_calls [])
 (PROPx [] (LOCALx loc (SEPx [store;row_storage p (Zlength initial) initial]))) pack_row
 (normal_ret_assert (PROPx [] (LOCALx loc (SEPx [store;
    row_storage p (Zlength initial) (pack_prefix bytes r n initial (Z.to_nat n))])))).
Proof.
 intros readable valid rows dim capacity count loc store;unfold pack_row,loc,pack_regs;abbreviate_semax;forward.
 forward_loop (EX q:Z,PROP(0<=q<=n)
   LOCAL(temp _q (Vint (Int.repr q));temp _a a;temp _r red;temp _row p;temp _i (Vint (Int.repr r)))
   SEP(store;row_storage p (Zlength initial) (pack_prefix bytes r n initial (Z.to_nat q))))
 continue:(EX q:Z,PROP(0<=q<n)
   LOCAL(temp _q (Vint (Int.repr q));temp _a a;temp _r red;temp _row p;temp _i (Vint (Int.repr r)))
   SEP(store;row_storage p (Zlength initial) (pack_prefix bytes r n initial (Z.to_nat (q+1)))))%assert
 break:(PROP() LOCAL(temp _a a;temp _r red;temp _row p;temp _i (Vint (Int.repr r)))
   SEP(store;row_storage p (Zlength initial) (pack_prefix bytes r n initial (Z.to_nat n))))%assert.
 - Exists 0;entailer!;try apply derives_refl.
 - Intros q;unfold store,matrix_bytes,pcm_view_type;Intros;forward;forward_if.
   2:{ assert (q=n) by rep_lia;subst q;forward;unfold store,matrix_bytes,pcm_view_type;entailer!. }
   assert (range:0<=q<n) by rep_lia;fold pcm_view_type.
   forward_call (a,buf,sh,nr,n,bytes,r,q);try solve [unfold matrix_bytes,pcm_view_type;entailer!;cancel;apply derives_refl].
   assert (slot:0<=q/64<Zlength initial) by (split;[apply Z.div_pos|apply Z.div_lt_upper_bound];lia).
   assert (lane:0<=q mod 64<64) by (apply Z.mod_pos_bound;lia).
   assert (di:Int.divs (Int.repr q) (Int.repr 64)=Int.repr (q/64)) by
     (unfold Int.divs;rewrite !Int.signed_repr by rep_lia;rewrite Z.quot_div_nonneg by lia;reflexivity).
   assert (mo:Int.mods (Int.repr q) (Int.repr 64)=Int.repr (q mod 64)) by
     (unfold Int.mods;rewrite !Int.signed_repr by rep_lia;rewrite Z.rem_mod_nonneg by lia;reflexivity).
   assert (index_bound:q/64<=q) by (apply Z.div_le_upper_bound;lia).
   assert (index:Int.signed (Int.divs (Int.repr q) (Int.repr 64))=q/64) by
     (rewrite di,Int.signed_repr by rep_lia;reflexivity).
   assert (live:0<=Int.signed (Int.divs (Int.repr q) (Int.repr 64))<
       Zlength (pack_prefix bytes r n initial (Z.to_nat q))) by (rewrite index,pack_length;exact slot).
   unfold row_storage;forward.
   { entailer!;match goal with h:_ /\ Int.repr 64=Int.mone |- _ =>destruct h as [_ bad];discriminate bad end. }
   forward.
   { unfold cbit;destruct (Znth (r*n+q) bytes);entailer!;
       try rewrite mo,Int.unsigned_repr by rep_lia;
       change (Int.unsigned Int64.iwordsize') with 64;
       repeat split;try lia;intros [_ bad];discriminate bad. }
   Exists q;rewrite pack_one_more by lia;unfold install_bit,store,matrix_bytes,pcm_view_type,row_storage.
   rewrite ?index,?mo,?upd_Znth_map,?Znth_map by (rewrite ?pack_length;lia).
   rewrite byte_shift by exact lane.
   Intros;entailer!;try cancel;try apply derives_refl.
 - Intros q;forward;Exists (q+1);entailer!.
 - apply andp_left2;apply derives_refl.
Qed.
