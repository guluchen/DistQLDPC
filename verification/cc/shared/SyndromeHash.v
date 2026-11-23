(* SPDX-License-Identifier: GPL-3.0-or-later *)
From HB Require Import structures.
From compcert.lib Require Import Integers.
From mathcomp Require Import all_ssreflect.
Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.

Lemma xorA64 : associative Int64.xor.
Proof. by move=> a b c; rewrite Int64.xor_assoc. Qed.
HB.instance Definition _ := Monoid.isComLaw.Build int64 Int64.zero Int64.xor
  xorA64 Int64.xor_commut Int64.xor_zero_l.

Section Signature.
Variable R : finType.
Variable key : R -> int64.
Definition signature (s : {set R}) :=
  \big[Int64.xor/Int64.zero]_(r : R) (if r \in s then key r else Int64.zero).

(* Keys may collide. Equality of physical syndromes implies equality of
   signatures, and toggling a column updates the signature by one XOR. *)
Lemma signature_toggle (s column : {set R}) :
  signature ((s :\: column) :|: (column :\: s)) =
  Int64.xor (signature s) (signature column).
Proof.
rewrite /signature -big_split /=; apply: eq_bigr=> r _; rewrite !inE.
by case: (r \in s); case: (r \in column);
   rewrite ?Int64.xor_idem ?Int64.xor_zero ?Int64.xor_zero_l.
Qed.

Lemma signature_restore s column :
  Int64.xor (Int64.xor (signature s) (signature column)) (signature column) = signature s.
Proof. by rewrite Int64.xor_assoc Int64.xor_idem Int64.xor_zero. Qed.
End Signature.

Section Bucket.
Variables Q R : finType.
Variable free : pred Q.
Variable logical_hit : pred Q.
Variable col : Q -> {set R}.
Variable odd : {set R}.
Variable key : R -> int64.
Variable same_key : Q -> bool.
Hypothesis key_matches : forall q, same_key q = true <-> signature key (col q) = signature key odd.
Definition accepts q := [&& free q, col q == odd & logical_hit q].

(* A bucket contains every qubit with the requested key; its order and the
   number of false positives are arbitrary. A true leaf cannot be lost. *)
Theorem bucket_complete bucket :
  (forall q, (q \in bucket) = same_key q) ->
  has accepts bucket = [exists q, accepts q].
Proof.
move=> members; apply/hasP/existsP=> [[q _ yes]|[q ok]]; first by exists q.
exists q=> //; rewrite members; apply/(key_matches q).
by move: ok=> /and3P[_ /eqP -> _].
Qed.
End Bucket.
