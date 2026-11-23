(* SPDX-License-Identifier: GPL-3.0-or-later *)
From Coq Require Import ZArith Lia List.
From compcert.lib Require Import Integers.
Require Import LowestWord.
Import ListNotations.
Open Scope Z_scope.

Definition clear word := Int64.and word (Int64.sub word Int64.one).

Lemma clear_smaller word : 0<Int64.unsigned word ->
  Int64.unsigned (clear word)<Int64.unsigned word.
Proof.
  intro P. unfold clear. rewrite Int64.and_commut.
  eapply Z.le_lt_trans; [apply Int64.and_le|].
  unfold Int64.sub; change (Int64.unsigned Int64.one) with 1.
  rewrite Int64.unsigned_repr; pose proof (Int64.unsigned_range_2 word);lia.
Qed.

Lemma clears_one word p i : Int64.unsigned word=Z.pos p -> 0<=i<64 ->
  Int64.testbit (clear word) i =
    (Int64.testbit word i && negb (Z.eqb (trailing p) i))%bool.
Proof.
  intros W I. destruct (trailing_factor p) as [t [R [T F]]].
  assert (A:isolated word=Int64.repr (2^trailing p)).
  { rewrite machine_isolate,W,F,isolate_scaled by lia;reflexivity. }
  apply (f_equal (fun w=> Int64.testbit w i)) in A.
  cbn beta in A. rewrite Int64.testbit_repr, Z.pow2_bits_eqb in A by (try exact I; lia).
  unfold isolated in A; rewrite Int64.bits_and in A by exact I.
  unfold Int64.sub in A;change (Int64.unsigned Int64.zero) with 0 in A.
  rewrite Z.sub_0_l, Int64.testbit_repr in A by exact I.
  unfold clear;rewrite Int64.bits_and by exact I.
  unfold Int64.sub;change (Int64.unsigned Int64.one) with 1.
  rewrite Int64.testbit_repr by exact I.
  replace (Int64.unsigned word-1) with (Z.lnot (-Int64.unsigned word))
    by (unfold Z.lnot;lia).
  rewrite Z.lnot_spec by lia. rewrite <- A.
  destruct (Int64.testbit word i), (Z.testbit (-Int64.unsigned word) i);reflexivity.
Qed.

(* This relation follows the nonzero word loop in index_children. *)
Inductive scan_word : int64 -> list Z -> Prop :=
| word_done w : Int64.unsigned w=0 -> scan_word w []
| word_step w p tail : Int64.unsigned w=Z.pos p ->
    scan_word (clear w) tail -> scan_word w (trailing p :: tail).

Lemma scan_finite w : exists rs, scan_word w rs.
Proof.
  remember (Z.to_nat (Int64.unsigned w)) as n eqn:E. revert w E.
  induction n using lt_wf_ind;intros w E.
  destruct (Int64.unsigned w) as [|p|p] eqn:W.
  - exists [];constructor;assumption.
  - destruct (H (Z.to_nat (Int64.unsigned (clear w))) ltac:(pose proof
      (clear_smaller w ltac:(lia)); rewrite W in *;lia) (clear w) eq_refl) as [rs tail].
    exists (trailing p::rs);econstructor;eassumption.
  - pose proof (Int64.unsigned_range w);lia.
Qed.

Lemma scan_members w rs : scan_word w rs -> forall i, 0<=i<64 ->
  (In i rs <-> Int64.testbit w i=true).
Proof.
  induction 1 as [w zero|w p tail W path IH]; intros i I.
  - unfold Int64.testbit;rewrite zero, Z.testbit_0_l; simpl;intuition discriminate.
  - destruct (lowest_bit_correct w p W) as [bound [_ [_ [one lower]]]].
    cbn [In]. rewrite IH, (clears_one w p i W I) by assumption.
    destruct (Z.eq_dec (trailing p) i) as [same|ne].
    + subst i. unfold Int64.testbit;rewrite one;intuition.
    + rewrite (proj2 (Z.eqb_neq _ _) ne), Bool.andb_true_r;simpl;tauto.
Qed.

Theorem scan_exact w rs : scan_word w rs -> NoDup rs /\
  Forall (fun i=>0<=i<64) rs /\
  forall i, 0<=i<64 -> (In i rs <-> Int64.testbit w i=true).
Proof.
  intro path; split;[|split;[|exact (scan_members _ _ path)]].
  - induction path as [w zero|w p tail W path IH];constructor;auto.
    destruct (lowest_bit_correct w p W) as [R _].
    rewrite (scan_members _ _ path _ R), (clears_one _ _ _ W R), Z.eqb_refl,
      Bool.andb_false_r;discriminate.
  - induction path as [w zero|w p tail W path IH];constructor;auto.
    exact (proj1 (lowest_bit_correct w p W)).
Qed.
