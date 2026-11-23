(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto Coq.Logic.ClassicalDescription.
Require Import level_ast VerifDetected VerifPackedDetector VerifClosesBody ClosureWord.
From mathcomp Require Import all_ssreflect all_algebra.
Require Import LeafClosure LeafMatrix DetectorMatrix ClosureEncoding.
Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.
Local Open Scope ring_scope.
Local Delimit Scope Z_scope with coqZ.

Definition col_slice v q := sublist (q * width v)%coqZ ((q+1)*width v)%coqZ (masks v).
Lemma diffs_are_xors v q : differences v q = xors (parities v) (col_slice v q).
Proof.
rewrite /differences -/(col_slice v q) /xors.
elim: (parities v) (col_slice v q) => [|a al ih] [|b bl] //=.
by rewrite ih.
Qed.

Section Layout.
Variables m n k : nat.
Variables (H : 'M['F_2]_(m,n)) (L : 'M['F_2]_(k,n)) (x : 'cV['F_2]_n)
          (q : 'I_n) (physical : seq 'I_m) (v : close_view).
Let qz := Z.of_nat q.
Let lo := Znth qz (offsets v).
Let hi := Znth (qz+1)%coqZ (offsets v).
Let odd := support (H *m x).

(* Row identifiers are the original physical row numbers. The two coverage
   clauses say that exactly this column's rows occur in the CSR slice. *)
Record layout : Prop := {
  rows_once : uniq physical;
  rows_of_q : [set r in physical] = support (col q H);
  row_count : (hi-lo)%coqZ = Z.of_nat (size physical);
  row_bound : (Z.of_nat m <= Int.modulus)%coqZ;
  all_stored : forall r, r \in physical -> exists i, (lo <= i < hi)%coqZ /\
                   Znth i (rows v) = Int.repr (Z.of_nat r);
  all_physical : forall i, (lo <= i < hi)%coqZ -> exists r, r \in physical /\
                   Znth i (rows v) = Int.repr (Z.of_nat r);
  syndrome_bits : forall r : 'I_m, r \in physical ->
      Int64.testbit (Znth (Z.of_nat r / 64)%coqZ (syndrome v)) (Z.of_nat r mod 64)%coqZ =
      (r \in odd);
  stored_logical : represents (parities v) (L *m x);
  stored_column : represents (col_slice v qz) (col q L);
  same_width : size (parities v) = size (col_slice v qz)
}.

Lemma correct_row (rep : layout) (r : 'I_m) i :
  r \in physical -> Znth i (rows v) = Int.repr (Z.of_nat r) ->
  (scan_bit v i <> Int64.zero <-> r \in odd).
Proof.
move=> present addr.
have rn : (nat_of_ord r < m)%coq_nat := elimT ltP (ltn_ord r).
have less : (Z.of_nat r < Z.of_nat m)%coqZ by lia.
have range := row_bound rep.
have wordeq : Int.unsigned (Int.repr (Z.of_nat r)) = Z.of_nat r.
  apply Int.unsigned_repr; unfold Int.max_unsigned; lia.
have dark := scan_bit_dark v i.
cbv zeta in dark; rewrite addr wordeq (syndrome_bits rep present) in dark.
split.
- move=> nz; case hr: (r \in odd) => //.
  exfalso; exact: (nz (proj2 dark hr)).
- move=> hr zero; move: (proj1 dark zero); by rewrite hr.
Qed.

Lemma scan_reads_column (rep : layout) :
  scan_ok v lo hi <-> all (mem odd) physical.
Proof.
split.
- move=> ok; apply/allP=> r present.
  have [i [bounds addr]] := all_stored rep present.
  exact: (proj1 (correct_row rep present addr) (ok i bounds)).
- move/allP=> inside i bounds.
  have [r [present addr]] := all_physical rep bounds.
  exact: (proj2 (correct_row rep present addr) (inside r present)).
Qed.

Theorem closes_value_pcm (rep : layout) :
  close_result v qz (Z.of_nat #|odd|) =
  Vint (if (H *m (x + delta_mx q 0) == 0) && (L *m (x + delta_mx q 0) != 0)
        then Int.one else Int.zero).
Proof.
rewrite -(@leaf_matrix_exact m n k H L x q physical (rows_once rep) (rows_of_q rep)).
rewrite /leaf_test /row_scan (inj_eq (@binary_support_inj k)).
rewrite /close_result -/lo -/hi -/odd.
case: Z.eq_dec => count.
- have eqcount : size physical = #|odd| by apply Nat2Z.inj; rewrite -(row_count rep).
  rewrite eqcount eqxx /=.
  case: excluded_middle_informative => scanned.
  + have -> := proj1 (scan_reads_column rep) scanned.
    rewrite /= detected_return_bits diffs_are_xors.
    by rewrite (packed_column_differs (stored_logical rep) (stored_column rep) (same_width rep)).
  + have -> : all (mem odd) physical = false.
      apply/negbTE/negP=> allset; exact: scanned ((proj2 (scan_reads_column rep)) allset).
    by [].
- have -> : (size physical == #|odd|) = false.
    apply/negbTE/negP=> /eqP size_eq; apply count; by rewrite (row_count rep) size_eq.
  by [].
Qed.
End Layout.
