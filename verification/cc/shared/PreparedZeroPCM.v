(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto.
From mathcomp Require Import all_ssreflect all_algebra.
Require Import LeafMatrix DetectorMatrix SparseFlipBits SparseSyndrome SyndromeHash VerifClosesBody
 NativeFlipPayload PreparedMatrixResponse PhysicalPrefixInvariant CSSLevelDistance.
Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.
Local Open Scope ring_scope.
Local Delimit Scope Z_scope with coqZ.

Lemma constant_bit_list (A:Type) (words:seq A) (bit:A->bool):
 (forall a,bit a=false) -> map bit words=nseq (size words) false.
Proof. move=> constant;elim:words=>[|a words ih] //=;by rewrite constant ih. Qed.
Lemma decoded_zero_words words:
 Forall (fun w=>w=Int64.zero) words ->
 flatten [seq word_bits w | w <- words]=nseq (64 * size words)%N false.
Proof.
 move=> zeroed;elim:zeroed=>[|word more -> all_zero ih];first reflexivity.
 change (word_bits Int64.zero ++ flatten [seq word_bits w | w <- more]=nseq (64 * (size more).+1)%N false).
 have zeros:word_bits Int64.zero=nseq 64 false.
 { transitivity (nseq (size (enum 'I_64)) false);last by rewrite size_enum_ord.
   apply constant_bit_list=>i;apply Int64.bits_zero. }
 by rewrite zeros ih -nseqD mulnS.
Qed.

(* The C++ level setup clears the allocated syndrome, detector, count
   and checksum fields. Only dimensions and padding are needed to relate
   those initial bytes to the zero GF(2) column vector. *)
Theorem zeroed_level_represents_pcm m n k (H:'M['F_2]_(m,n)) (G:'M['F_2]_(k,n)) rowkey t:
 let v:=words_at t in Forall (fun w=>w=Int64.zero) (syndrome v) ->
 Forall (fun w=>w=Int64.zero) (parities v) ->
 (Z.of_nat m<=64*Zlength (syndrome v))%coqZ -> (k<=64*size (parities v))%N ->
 odd_count t=0%coqZ -> checksum t=Int64.zero ->
 pcm_response H G rowkey (0:'cV['F_2]_n) t.
Proof.
 move=>v checks det room words count hash;rewrite /pcm_response !mulmx0 support_zero.
 split.
 - split;first exact room.
   split;last by rewrite cards0.
   move=>i;rewrite inE /syndrome_bit.
   have valid:(0<=Z.of_nat i/64<Zlength (syndrome v))%coqZ.
   { have lt:=elimT ltP (ltn_ord i);split;[apply Z.div_pos;lia|apply Z.div_lt_upper_bound;lia]. }
   have member:=@Znth_In int64 _ (Z.of_nat i/64)%coqZ (syndrome v) valid.
   have zero_word:=proj1 (Forall_forall _ _) checks _ (member _).
   rewrite zero_word;exact:Int64.bits_zero.
 - split.
   + exists (64 * size (parities v)-k)%N;rewrite (decoded_zero_words det).
     have bits:forall i:'I_k,((0:'cV['F_2]_k) i 0!=0)=false by move=>i;rewrite mxE eqxx.
     have pad:[seq ((0:'cV['F_2]_k) i 0!=0) | i:'I_k]=nseq k false.
     { transitivity (nseq (size (enum 'I_k)) false);last by rewrite size_enum_ord.
       apply constant_bit_list;exact bits. }
     by rewrite pad -nseqD subnKC.
   + rewrite hash /signature;apply esym;apply big1=>i _;by rewrite inE.
Qed.
