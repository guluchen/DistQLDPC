(* SPDX-License-Identifier: GPL-3.0-or-later *)
From Coq Require Import ZArith Lia.
From compcert.lib Require Import Integers.
From mathcomp Require Import all_ssreflect all_algebra.
Require Import LeafMatrix DetectorMatrix ClosureEncoding.
Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.
Local Open Scope ring_scope.
Local Delimit Scope Z_scope with coqZ.

Fixpoint zipxor (a b : seq bool) :=
  if a is x :: xs then
    if b is y :: ys then xorb x y :: zipxor xs ys else [::]
  else [::].

Lemma zipxor_cat a b c d : size a = size b ->
  zipxor (a ++ c) (b ++ d) = zipxor a b ++ zipxor c d.
Proof. by elim: a b=> [|x xs ih] [|y ys] //= /succn_inj/ih ->. Qed.

Lemma zipxor_maps (T : Type) (f g : T -> bool) s :
  zipxor [seq f x | x <- s] [seq g x | x <- s] = [seq xorb (f x) (g x) | x <- s].
Proof. by elim: s=> //= x xs ->. Qed.

Lemma xor_bits a b :
  word_bits (Int64.xor a b) = zipxor (word_bits a) (word_bits b).
Proof.
rewrite /word_bits zipxor_maps; apply: eq_map => i.
apply: Int64.bits_xor; change (0 <= Z.of_nat i < 64)%coqZ.
have ilt : (nat_of_ord i < 64)%coq_nat := elimT ltP (ltn_ord i).
lia.
Qed.

Lemma unpack_xors a b : size a = size b ->
  unpack (xors a b) = zipxor (unpack a) (unpack b).
Proof.
elim: a b=> [|u us ih] [|v vs] //= /succn_inj sz.
rewrite /unpack /= -/(unpack us) -/(unpack vs) -/(unpack (xors us vs)).
by rewrite zipxor_cat ?word_size // xor_bits (ih vs sz).
Qed.

Lemma xor_vecbits k (x y : 'cV['F_2]_k) :
  zipxor (vecbits x) (vecbits y) = vecbits (x+y).
Proof.
rewrite /vecbits zipxor_maps; apply: eq_map => i; rewrite mxE.
have bin (a : 'F_2) : a = 0 \/ a = 1.
  case: a=> a ha; case: a ha=> [|[|a]] ha; [left|right|]; try by apply: val_inj.
  by [].
by case: (bin (x i 0))=> ->; case: (bin (y i 0))=> ->.
Qed.

Theorem xor_represents k a b (x y : 'cV['F_2]_k) :
  represents a x -> represents b y -> size a = size b ->
  represents (xors a b) (x+y).
Proof.
move=> [pa ha] [pb hb] sz; change (unpack a = vecbits x ++ nseq pa false) in ha.
change (unpack b = vecbits y ++ nseq pb false) in hb.
have szu : size (unpack a) = size (unpack b) by rewrite !unpack_size sz.
rewrite ha hb !size_cat !vecbits_size !size_nseq in szu.
have pad := addnI szu.
exists pb; change (unpack (xors a b) = vecbits (x+y) ++ nseq pb false).
rewrite unpack_xors // ha hb zipxor_cat ?vecbits_size // xor_vecbits pad.
congr (_ ++ _); clear ha hb pad szu. by elim: pb=> //= p ->.
Qed.

Theorem packed_flip m n (M : 'M['F_2]_(m,n)) (x : 'cV['F_2]_n) (q : 'I_n) a b :
  represents a (M *m x) -> represents b (col q M) -> size a = size b ->
  represents (xors a b) (M *m (x + delta_mx q 0)).
Proof. by rewrite mulmxDr -colE; exact: xor_represents. Qed.

Theorem packed_rollback a b : size a = size b -> xors (xors a b) b = a.
Proof.
elim: a b=> [|u us ih] [|v vs] //= /succn_inj sz.
rewrite /xors /= -/(xors us vs) -/(xors (xors us vs) vs).
by rewrite Int64.xor_assoc Int64.xor_idem Int64.xor_zero (ih vs sz).
Qed.
