(* Clearing one byte can only decrease a previously stored unsigned counter,
   even when a malformed scratch pointer aliases that counter. *)
Require Import VST.floyd.proofauto compcert.common.Memdata compcert.lib.Maps.
Import ListNotations. Open Scope Z_scope.
Fixpoint zero_at (start pos:Z) (bs:list byte) : list byte :=
 match bs with
 | []=>[] | b::tl=>(if zeq start pos then Byte.zero else b)::zero_at (start+1) pos tl end.
Lemma zero_at_length start pos bs : length (zero_at start pos bs)=length bs.
Proof. revert start;induction bs;intros;simpl;auto. Qed.
Lemma zero_at_le start pos bs : int_of_bytes (zero_at start pos bs)<=int_of_bytes bs.
Proof.
 revert start;induction bs;intro start;cbn [zero_at int_of_bytes];[lia|].
 specialize (IHbs (start+1));destruct(zeq start pos);[rewrite Byte.unsigned_zero|];
 pose proof(Byte.unsigned_range a);lia.
Qed.
Lemma zero_at_nonnegative bs : 0<=int_of_bytes bs.
Proof. pose proof(int_of_bytes_range bs);lia. Qed.
Lemma getN_zero_at bs start pos contents :
 Mem.getN (length bs) start contents=inj_bytes bs ->
 Mem.getN (length bs) start (ZMap.set pos (Byte Byte.zero) contents)=inj_bytes (zero_at start pos bs).
Proof.
 revert start;induction bs as [|b tl IH];intro start;[reflexivity|].
 cbn [length Mem.getN inj_bytes map zero_at].
 intro E;injection E as First Rest;f_equal.
 - destruct(zeq start pos) as [->|Different];[rewrite ZMap.gss|rewrite ZMap.gso by auto];auto.
 - apply IH;assumption.
Qed.
Lemma decode_cleared_counter start pos w :
 let bs:=encode_int 4 (Int.unsigned w) in
 exists w',decode_val Mint32 (inj_bytes(zero_at start pos bs))=Vint w' /\
 Int.unsigned w'<=Int.unsigned w.
Proof.
 intros bs;unfold decode_val;rewrite proj_inj_bytes.
 eexists;split;[reflexivity|].
 assert (Len:length bs=4%nat) by apply encode_int_length.
 assert (Old:int_of_bytes bs=Int.unsigned w).
 { change (decode_int (encode_int 4 (Int.unsigned w))=Int.unsigned w).
   rewrite decode_encode_int;change (Int.unsigned w mod Int.modulus=Int.unsigned w);apply Z.mod_small;apply Int.unsigned_range. }
 change (Int.unsigned (Int.repr (int_of_bytes (zero_at start pos bs)))<=Int.unsigned w).
 rewrite Int.unsigned_repr;pose proof(zero_at_le start pos bs);pose proof(zero_at_nonnegative (zero_at start pos bs));
 pose proof(Int.unsigned_range_2 w);lia.
Qed.

Local Transparent Mem.load Mem.loadbytes.
Lemma store_word_then_zero m m1 m2 bt start bf pos w :
 Mem.store Mint32 m bt start (Vint w)=Some m1 ->
 Mem.store Mint8unsigned m1 bf pos (Vint Int.zero)=Some m2 ->
 exists w',Mem.load Mint32 m2 bt start=Some(Vint w') /\ Int.unsigned w'<=Int.unsigned w.
Proof.
 intros Word Zero. pose proof(Mem.load_store_same _ _ _ _ _ _ Word) as Exact.
 destruct(peq bt bf) as [Eq|Diff].
 2:{ exists w;split;[rewrite(Mem.load_store_other _ _ _ _ _ _ Zero) by auto;exact Exact|lia]. }
 subst bf. set (bs:=encode_int 4 (Int.unsigned w)).
 pose proof (Mem.loadbytes_store_same _ _ _ _ _ _ Word) as Bytes.
 unfold Mem.loadbytes in Bytes;destruct Mem.range_perm_dec in Bytes;[|discriminate].
 apply (f_equal (fun x=>match x with Some a=>a|None=>nil end)) in Bytes. change (Mem.getN 4 start (PMap.get bt (Mem.mem_contents m1))=inj_bytes bs) in Bytes.
 assert (L:length bs=4%nat) by apply encode_int_length.
 assert (Valid:Mem.valid_access m2 Mint32 bt start Readable).
 { eapply Mem.store_valid_access_1;[exact Zero|]. eapply Mem.load_valid_access;exact Exact. }
 destruct (decode_cleared_counter start pos w) as [w' [Decode Le]].
 exists w';split;[|exact Le]. unfold Mem.load;rewrite pred_dec_true by exact Valid.
 rewrite (Mem.store_mem_contents _ _ _ _ _ _ Zero),PMap.gss.
 change (Some (decode_val Mint32 (Mem.getN 4 start (ZMap.set pos (Byte Byte.zero) (PMap.get bt (Mem.mem_contents m1)))))=Some(Vint w')).
 rewrite <-L in Bytes|-*. rewrite (getN_zero_at bs start pos _ Bytes);f_equal;exact Decode.
Qed.
