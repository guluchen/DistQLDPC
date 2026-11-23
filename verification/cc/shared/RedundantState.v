(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto.
From mathcomp Require Import all_ssreflect all_algebra.
Require Import VerifClosesBody VerifToggleBody ClosureWord SparseFlipBits SparseRollback SparseSyndrome VerifFlipBody.
Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.
Local Delimit Scope Z_scope with coqZ.

Definition extra_rows policy q :=
  match policy with
  | WithRedundant _ _ _ os rs => sublist (Znth q os) (Znth (q+1)%coqZ os) rs
  | _ => nil
  end.

Lemma extra_words_independent rs syn odd :
  fold_left extra_step rs syn = fst (fold_left sparse_flip rs (syn,odd)).
Proof.
by elim: rs syn odd=> [|r tail IH] syn odd //=.
Qed.

Lemma policy_words policy q syn :
  after_extra policy q syn = fold_left extra_step (extra_rows policy q) syn.
Proof. by case: policy. Qed.

Theorem extra_bits policy q syn j :
  (0<=j<64*Zlength syn)%coqZ ->
  Forall (fun r=> (Int.unsigned r<64*Zlength syn)%coqZ) (extra_rows policy q) ->
  syndrome_bit (after_extra policy q syn) j =
    xorb (toggled_row j (extra_rows policy q)) (syndrome_bit syn j).
Proof. move=> J bounds; rewrite policy_words (extra_words_independent _ _ 0%coqZ).
exact: (walk_bit _ _ _ _ J bounds). Qed.

Lemma below_extra m (rs:list Integers.int) j : (j<m)%coqZ ->
  Forall (fun r=>(m<=Int.unsigned r)%coqZ) rs -> toggled_row j rs=false.
Proof.
move=> small;elim=> [|r rest top tail IH] //=.
have ne : j<>Int.unsigned r by lia.
by rewrite IH (proj2 (Z.eqb_neq j (Int.unsigned r)) ne).
Qed.

Theorem extra_preserves_physical m (A:{set 'I_m}) policy q syn odd :
  stores_odd (syn,odd) A ->
  Forall (fun r=>(Z.of_nat m<=Int.unsigned r)%coqZ) (extra_rows policy q) ->
  Forall (fun r=>(Int.unsigned r<64*Zlength syn)%coqZ) (extra_rows policy q) ->
  stores_odd (after_extra policy q syn,odd) A.
Proof.
move=> [cap [bits count]] above below; cbn [fst snd] in cap,bits,count.
split; first by rewrite /= policy_words (extra_words_independent _ _ 0%coqZ) walk_length.
split=> // r; cbn [fst].
have jr := elimT ltP (ltn_ord r).
rewrite extra_bits; [|lia|exact below].
have small : (Z.of_nat r<Z.of_nat m)%coqZ by lia.
by rewrite (@below_extra (Z.of_nat m) (extra_rows policy q) (Z.of_nat r) small above) bits.
Qed.

Theorem extra_sweep_rollback policy q syn :
  Forall (fun r=>(Int.unsigned r<64*Zlength syn)%coqZ) (extra_rows policy q) ->
  after_extra policy q (after_extra policy q syn) = syn.
Proof.
move=> bounded;rewrite !policy_words.
set rs := extra_rows policy q in bounded *.
rewrite (extra_words_independent rs syn 0%coqZ).
case pass: (fold_left sparse_flip rs (syn,0%coqZ))=> [middle odd'] /=.
rewrite (extra_words_independent rs middle odd').
have back := @sparse_words_restore rs syn 0%coqZ bounded.
by rewrite pass in back.
Qed.
