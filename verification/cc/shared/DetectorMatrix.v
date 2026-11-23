(* SPDX-License-Identifier: GPL-3.0-or-later *)
From Coq Require Import ZArith.
From compcert.lib Require Import Integers.
From mathcomp Require Import all_ssreflect all_algebra.
Require Import PackedDetector.

Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.
Local Open Scope ring_scope.

Definition word_bits (w : int64) :=
  [seq Int64.testbit w (Z.of_nat i) | i : 'I_64].

Lemma word_bits_has w : has id (word_bits w) = lit_word w.
Proof.
rewrite /word_bits has_map; apply/hasP/existsP.
- by move=> [i _ hi]; exists i.
- by move=> [i hi]; exists i; rewrite ?mem_enum.
Qed.

Lemma decoded_has words :
  has id (flatten [seq word_bits w | w <- words]) = packed_detects words.
Proof.
elim: words=> [|w ws IH] //.
by rewrite /= has_cat word_bits_has IH.
Qed.

(* The first k bits are the real detector parities in row order. Every
   remaining stored bit, including the tail of the last word, must be zero. *)
Definition represents j (words : seq int64) (v : 'cV['F_2]_j) :=
  exists pad, flatten [seq word_bits w | w <- words] =
              [seq v i 0 != 0 | i : 'I_j] ++ nseq pad false.

Theorem packed_matrix_nonzero j words (v : 'cV['F_2]_j) :
  represents words v -> packed_detects words = (v != 0).
Proof.
move=> [pad representation].
rewrite -decoded_has representation has_cat has_nseq andbF orbF has_map.
apply/idP/idP.
- move/hasP=> [i _ hi]; apply/eqP=> zero.
  by move: hi; rewrite /= zero mxE eqxx.
- move/eqP=> different; apply/hasP.
  have nz : [exists i, v i 0 != 0].
    case E: [exists i, v i 0 != 0] => //.
    exfalso; apply: different; apply/matrixP=> i z; rewrite (ord1 z) mxE.
    have no : ~~ [exists i, v i 0 != 0] by rewrite E.
    move/existsPn: no => no. by move: (no i); rewrite negbK => /eqP.
  move/existsP: nz=> [i hi]. by exists i; rewrite ?mem_enum.
Qed.

Require Import LeafMatrix.
Section Terminal.
Variables m n k : nat.
Variables (H : 'M['F_2]_(m,n)) (L : 'M['F_2]_(k,n)) (x : 'cV['F_2]_n).

Definition stores_response words := represents words (L *m x).
Definition number_odd := Z.of_nat #|support (H *m x)|.
Definition valid_terminal := (H *m x == 0) && (L *m x != 0).

Lemma zero_syndrome : Z.eqb number_odd 0 = (H *m x == 0).
Proof.
have cv v : Z.eqb (Z.of_nat v) 0 = (v == 0)%N by case: v.
rewrite /number_odd cv cards_eq0.
have empty : support (0 : 'cV['F_2]_m) = set0.
  by apply/setP=> i; rewrite /support !inE mxE eqxx.
by rewrite -empty (inj_eq (@binary_support_inj m)).
Qed.

Theorem terminal_bits_correct words : represents words (L *m x) ->
  (Z.eqb number_odd 0 && packed_detects words) = valid_terminal.
Proof. by move=> rep; rewrite zero_syndrome (packed_matrix_nonzero rep). Qed.
End Terminal.
