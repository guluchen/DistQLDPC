(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto.
From mathcomp Require Import all_ssreflect all_algebra.
Require Import VerifClosesBody VerifToggleBody SparseFlipBits ClosureWord LeafMatrix.
Require Import DetectorMatrix ClosureMatrix ToggleModel SyndromeHash MinimumOverlap.
Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.
Local Open Scope ring_scope.
Local Delimit Scope Z_scope with coqZ.

Section Physical.
Variable m : nat.
Definition flip_row (r : 'I_m) (A : {set 'I_m}) :=
  if r \in A then A :\ r else r |: A.
Definition stores_odd (st : list int64 * Z) (A : {set 'I_m}) : Prop :=
  (Z.of_nat m <= 64 * Zlength st.1)%coqZ /\
  (forall r : 'I_m, syndrome_bit st.1 (Z.of_nat r) = (r \in A)) /\
  st.2 = Z.of_nat #|A|.

Lemma flipped_membership (A : {set 'I_m}) r j :
  (j \in flip_row r A) = xorb (j == r) (j \in A).
Proof.
rewrite /flip_row; case: ifP => hr; rewrite !inE; case: eqP=> [->|neq];
  by rewrite ?hr //=; case: (j \in A).
Qed.

Lemma flipped_count (A : {set 'I_m}) r :
  Z.of_nat #|flip_row r A| =
    (if r \in A then Z.of_nat #|A| - 1 else Z.of_nat #|A| + 1)%coqZ.
Proof.
rewrite /flip_row; case h: (r \in A).
- have := cardsD1 r A; rewrite h add1n => ->; lia.
- rewrite cardsU1 h add1n; lia.
Qed.

Theorem sparse_step_correct syn odd (r : 'I_m) A :
  (Z.of_nat m <= Int.modulus)%coqZ -> stores_odd (syn,odd) A ->
  stores_odd (sparse_flip (syn,odd) (Int.repr (Z.of_nat r))) (flip_row r A).
Proof.
move=> dim [capacity [bits count]]. cbn [fst snd] in capacity, bits, count.
have inside (j : 'I_m) : (0 <= Z.of_nat j < Z.of_nat m)%coqZ.
  have := elimT ltP (ltn_ord j); lia.
have addr : Int.unsigned (Int.repr (Z.of_nat r)) = Z.of_nat r.
  apply Int.unsigned_repr; have := inside r; unfold Int.max_unsigned; lia.
split.
- cbn [sparse_flip fst]. rewrite upd_Znth_Zlength; first exact capacity.
  rewrite csr_word_index addr. have := inside r; split; [apply Z.div_pos | apply Z.div_lt_upper_bound]; lia.
split.
- move=> j. rewrite sparse_flip_bits; [|have := inside j; lia |rewrite addr; have := inside r; lia].
  rewrite addr flipped_membership bits; case: Z.eq_dec=> test.
  + have jr : j = r by apply val_inj; apply Nat2Z.inj.
    by rewrite jr eqxx; case: (r \in A).
  + have ne : j != r by apply/eqP=> same; apply test; rewrite same.
    by rewrite (negbTE ne).
- by rewrite sparse_flip_count addr bits count flipped_count.
Qed.

Lemma trace_correct (rs : seq 'I_m) st A :
  (Z.of_nat m <= Int.modulus)%coqZ -> stores_odd st A ->
  stores_odd (fold_left sparse_flip [seq Int.repr (Z.of_nat (nat_of_ord r)) | r <- rs] st)
             (foldl (fun B r => flip_row r B) A rs).
Proof.
move=> dim; elim: rs st A=> [|r rs ih] [syn odd] A rep; first exact: rep.
apply: ih; exact: (@sparse_step_correct syn odd r A dim rep).
Qed.
End Physical.

Lemma flip_unique m (rs : seq 'I_m) A j :
  uniq rs ->
  (j \in foldl (fun B r => flip_row r B) A rs) = xorb (j \in rs) (j \in A).
Proof.
elim: rs A=> [|r rs ih] A //= /andP[fresh tail].
rewrite ih // flipped_membership inE; case jr: (j == r).
- move/eqP: jr=> ->; by rewrite (negbTE fresh); case: (r \in A).
- by case: (j \in rs); case: (j \in A).
Qed.

Lemma sum_support_bit m (a b : 'cV['F_2]_m) j :
  (j \in support (a+b)) = xorb (j \in support a) (j \in support b).
Proof.
rewrite /support !inE mxE.
have binary (u : 'F_2) : u = 0 \/ u = 1.
  case: u=> u hu; case: u hu=> [|[|u]] hu; [left|right|]; try by apply: val_inj.
  by [].
by case: (binary (a j 0))=> ->; case: (binary (b j 0))=> ->.
Qed.

Section Column.
Variables m n : nat.
Variables (H : 'M['F_2]_(m,n)) (x : 'cV['F_2]_n) (q : 'I_n)
          (v : close_view) (physical : seq 'I_m).
Let qz := Z.of_nat q.
Let lo := Znth qz (offsets v).
Let hi := Znth (qz+1)%coqZ (offsets v).

Theorem flipped_pcm odd :
  (Z.of_nat m <= Int.modulus)%coqZ -> uniq physical ->
  [set r in physical] = support (col q H) ->
  sublist lo hi (rows v) = [seq Int.repr (Z.of_nat (nat_of_ord r)) | r <- physical] ->
  stores_odd (syndrome v,odd) (support (H *m x)) ->
  stores_odd (flipped v qz odd hi) (support (H *m (x + delta_mx q 0))).
Proof.
move=> dim distinct column layout rep; rewrite /flipped -/lo layout mulmxDr -colE.
have same : foldl (fun B r => flip_row r B) (support (H *m x)) physical =
            support (H *m x + col q H).
  apply/setP=> j; rewrite flip_unique // sum_support_bit -column inE.
  by case: (j \in physical); case: (j \in support (H *m x)).
rewrite -same; exact: trace_correct dim rep.
Qed.
End Column.

Section NativeToggle.
Variables m n k : nat.
Variables (H : 'M['F_2]_(m,n)) (L : 'M['F_2]_(k,n)) (x : 'cV['F_2]_n)
  (q : 'I_n) (v : close_view) (physical : seq 'I_m) (rowkey : 'I_m -> int64).
Let qz := Z.of_nat q.
Let lo := Znth qz (offsets v).
Let hi := Znth (qz+1)%coqZ (offsets v).
Let x' := x + delta_mx q 0.

(* All four mathematical components of body_toggle's concrete postcondition. *)
Theorem toggle_pcm odd hash keys :
  (Z.of_nat m <= Int.modulus)%coqZ -> uniq physical ->
  [set r in physical] = support (col q H) ->
  sublist lo hi (rows v) = [seq Int.repr (Z.of_nat (nat_of_ord r)) | r <- physical] ->
  stores_odd (syndrome v,odd) (support (H *m x)) ->
  represents (parities v) (L *m x) -> represents (col_slice v qz) (col q L) ->
  size (parities v) = size (col_slice v qz) ->
  hash = signature rowkey (support (H *m x)) ->
  Znth qz keys = signature rowkey (support (col q H)) ->
  stores_odd (flipped v qz odd hi) (support (H *m x')) /\
  represents (differences v qz) (L *m x') /\
  Int64.xor hash (Znth qz keys) = signature rowkey (support (H *m x')).
Proof.
move=> dim distinct column layout start logical colrep width_eq -> ->.
split; first exact: (flipped_pcm dim distinct column layout start).
split.
- rewrite diffs_are_xors; exact: (packed_flip logical colrep width_eq).
- by rewrite /x' mulmxDr -colE support_sum signature_toggle.
Qed.
End NativeToggle.
