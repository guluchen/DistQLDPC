From Coq Require Import List.
Require Import CCWideWords CCWideBranch CCWideRefute.
Import ListNotations.
Local Open Scope nat_scope.

Definition union_bits a b := join (singleton a) (singleton b).
Definition rows i := prow (match i with
  | 0=>union_bits 188 260 | 1=>singleton 188 | _=>singleton 188 end) [].
Definition sy := union_bits 0 2.
Definition avail := union_bits 188 260.
Example sum_supplies_extra_odd_check :
  pair_cut 3 (active 3) rows sy avail 1 [2] 0 1=true.
Proof. vm_compute;reflexivity. Qed.
Example even_sum_rejected :
  pair_cut 3 (active 3) rows sy avail 1 [2] 0 2=false.
Proof. vm_compute;reflexivity. Qed.
Example reused_qubit_rejected :
  pair_cut 3 (active 3) rows sy avail 1 [0] 0 1=false.
Proof. vm_compute;reflexivity. Qed.
Example invalid_index_rejected :
  pair_cut 3 (active 3) rows sy avail 1 [2] 0 3=false.
Proof. vm_compute;reflexivity. Qed.

Require Import CCWideLines.
Definition r01 i:bool := orb (Nat.eqb i 0) (Nat.eqb i 1).
Definition r4 i:bool := Nat.ltb i 4.
Example disjoint_logical_bound : coset_bound 5 [r4] [r01] 2 [(0,1);(2,1)]=true.
Proof. vm_compute;reflexivity. Qed.
Example duplicate_logical_support : coset_bound 5 [r4] [r01] 2 [(0,1);(0,1)]=false.
Proof. vm_compute;reflexivity. Qed.
Example missing_coset_equality : coset_bound 5 [] [r01] 2 [(0,1);(2,1)]=false.
Proof. vm_compute;reflexivity. Qed.
Example uncovered_detector : coset_bound 5 [r4] [r01;Nat.eqb 4] 2 [(0,1);(2,1)]=false.
Proof. vm_compute;reflexivity. Qed.

Example valid_linear_cut : linear_cut 3 (active 3) rows sy avail 1 [2] [0;1]=true.
Proof. vm_compute;reflexivity. Qed.
Example repeated_row_cancels : linear_cut 3 (active 3) rows sy avail 1 [2] [0;0]=false.
Proof. vm_compute;reflexivity. Qed.
Example invalid_index_in_sum : linear_cut 3 (active 3) rows sy avail 1 [2] [0;1;4]=false.
Proof. vm_compute;reflexivity. Qed.
Example linear_cut_respects_overlap : linear_cut 3 (active 3) rows sy avail 1 [0] [0;1]=false.
Proof. vm_compute;reflexivity. Qed.

Definition triple_row i:=prow (match i with
 |0=>singleton 0 |1=>singleton 1 |2=>join (union_bits 0 1) (singleton 2)
 |3=>union_bits 0 1 |_=>singleton 3 end) [].
Definition triple_sy:=join (union_bits 0 3) (singleton 4).
Definition triple_free:=join (union_bits 0 1) (union_bits 2 3).
Example three_rows_close_a_saturated_pack :
 linear_cut 5 (active 5) triple_row triple_sy triple_free 2 [3;4] [0;1;2]=true.
Proof. vm_compute;reflexivity. Qed.
Example two_rows_cannot_close_that_pack :
 linear_cut 5 (active 5) triple_row triple_sy triple_free 2 [3;4] [0;2]=false.
Proof. vm_compute;reflexivity. Qed.

Definition r12 i:bool:=orb (Nat.eqb i 1) (Nat.eqb i 2).
Example logicals_of_odd_weight :
 class_limit true 3 [r01;r12] [Nat.eqb 0] 3=2.
Proof. vm_compute;reflexivity. Qed.
Example mixed_parities_kept :
 class_limit true 2 [] [Nat.eqb 0] 3=3.
Proof. vm_compute;reflexivity. Qed.
Example even_kernel_with_redundant_generator :
 class_limit true 4 [r4;r01] [Nat.eqb 0] 4=3.
Proof. vm_compute;reflexivity. Qed.
Example original_parity_without_span_check :
 class_limit false 4 [r4;r01] [Nat.eqb 0] 4=4.
Proof. vm_compute;reflexivity. Qed.

(* Two virtual rows and a physical row require three distinct future flips. *)
Definition separate_rows i:=prow (singleton i) [].
Definition three_bits:=join (union_bits 0 1) (singleton 2).
Example double_disjoint_with_pack :
 double_cut 3 (active 3) separate_rows three_bits three_bits 2 [2] [0] [1]=true.
Proof. vm_compute;reflexivity. Qed.
Example double_repeated_region :
 double_cut 3 (active 3) separate_rows three_bits three_bits 2 [2] [0] [0]=false.
Proof. vm_compute;reflexivity. Qed.
Example double_overlap_with_pack :
 double_cut 3 (active 3) separate_rows three_bits three_bits 2 [0] [0] [1]=false.
Proof. vm_compute;reflexivity. Qed.
Example double_sufficient_budget :
 double_cut 3 (active 3) separate_rows three_bits three_bits 3 [2] [0] [1]=false.
Proof. vm_compute;reflexivity. Qed.
Example double_cancelled_sum :
 double_cut 3 (active 3) separate_rows three_bits three_bits 2 [2] [0] [1;1]=false.
Proof. vm_compute;reflexivity. Qed.
Example double_unknown_row :
 double_cut 3 (active 3) separate_rows three_bits three_bits 2 [2] [0] [1;3]=false.
Proof. vm_compute;reflexivity. Qed.
