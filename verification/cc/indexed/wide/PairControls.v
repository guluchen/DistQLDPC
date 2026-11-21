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
