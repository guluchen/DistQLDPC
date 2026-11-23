(* SPDX-License-Identifier: GPL-3.0-or-later *)
From Coq Require Import ZArith Lia List Bool.
From compcert.lib Require Import Integers.
Import ListNotations.
Open Scope Z_scope.

(* Distance from bit zero to the first one in the usual positive binary
   representation. Factorization also identifies the lower zero positions. *)
Fixpoint trailing (p : positive) : Z :=
  match p with xO t => 1 + trailing t | _ => 0 end.

Lemma trailing_factor p : exists t,
  0 <= trailing p /\ 0 <= t /\ Z.pos p = (2*t+1) * 2^(trailing p).
Proof.
  induction p as [p IH|p IH|].
  - exists (Z.pos p); change (0<=0 /\ 0<=Z.pos p /\ Z.pos (xI p)=(2*Z.pos p+1)*1).
    rewrite Pos2Z.inj_xI;lia.
  - destruct IH as [t [R [T F]]]; exists t.
    change (0<=1+trailing p /\ 0<=t /\ Z.pos (xO p)=(2*t+1)*2^(1+trailing p)).
    split; [lia|split;[lia|]]. rewrite Z.pow_add_r by lia.
    change (2^1) with 2. rewrite Pos2Z.inj_xO, F. ring.
  - exists 0; repeat split; reflexivity.
Qed.

Lemma isolate_odd t : Z.land (2*t+1) (-(2*t+1))=1.
Proof.
  replace (-(2*t+1)) with (2*(Z.lnot t)+1) by (unfold Z.lnot;lia).
  apply Z.bits_inj'; intros i I. rewrite Z.land_spec.
  destruct (Z.eq_dec i 0) as [->|NZ].
  - rewrite !Z.testbit_odd_0;reflexivity.
  - replace i with (Z.succ (i-1)) by lia.
    rewrite !Z.testbit_odd_succ by lia. rewrite Z.lnot_spec by lia.
    assert (H0: Z.testbit 1 (Z.succ (i-1))=false).
    { change (Z.testbit (2^0) (Z.succ (i-1))=false). apply Z.pow2_bits_false;lia. }
    rewrite H0. destruct (Z.testbit t (i-1));reflexivity.
Qed.

Lemma isolate_scaled t r : 0<=r ->
  Z.land ((2*t+1)*2^r) (-((2*t+1)*2^r))=2^r.
Proof.
  intros R. replace (-((2*t+1)*2^r)) with ((-(2*t+1))*2^r) by ring.
  rewrite <- !Z.shiftl_mul_pow2 by lia.
  rewrite <- Z.shiftl_land, isolate_odd, Z.shiftl_mul_pow2 by lia;ring.
Qed.

Definition isolated (word : int64) := Int64.and word (Int64.sub Int64.zero word).

Lemma machine_isolate word : isolated word =
  Int64.repr (Z.land (Int64.unsigned word) (- Int64.unsigned word)).
Proof.
  apply Int64.same_bits_eq; intros i I. unfold isolated.
  rewrite Int64.bits_and, Int64.testbit_repr by exact I. rewrite Z.land_spec.
  unfold Int64.sub. change (Int64.unsigned Int64.zero) with 0.
  rewrite Z.sub_0_l, Int64.testbit_repr by exact I. reflexivity.
Qed.

Definition index_of (w : int64) := Int64.unsigned
  (Int64.shru (Int64.mul w (Int64.repr 285870213051386505)) (Int64.repr 58)).
Definition positions : list Z := [0;1;48;2;57;49;28;3;61;58;50;42;38;29;17;4;
  62;55;59;36;53;51;43;22;45;39;33;30;24;18;12;5;
  63;47;56;27;60;41;37;16;54;35;52;21;44;32;23;11;
  46;26;40;15;34;20;31;10;25;14;19;9;13;8;7;6].

Definition reads_bit (r : nat) :=
  let pos := Z.of_nat r in
  let ix := index_of (Int64.repr (2^pos)) in
  (ix <? 64) && (nth (Z.to_nat ix) positions (-1) =? pos).

Lemma one_hot_table r : 0<=r<64 -> reads_bit (Z.to_nat r)=true.
Proof.
  intros R. assert (all : forallb reads_bit (seq 0 64)=true) by (vm_compute;reflexivity).
  apply forallb_forall with (x:=Z.to_nat r) in all;[assumption|apply in_seq;lia].
Qed.

Theorem lowest_bit_correct word p : Int64.unsigned word=Z.pos p ->
  let r := trailing p in let ix := index_of (isolated word) in
  0<=r<64 /\ 0<=ix<64 /\ nth (Z.to_nat ix) positions (-1)=r /\
  Z.testbit (Int64.unsigned word) r = true /\
  forall i, 0<=i<r -> Z.testbit (Int64.unsigned word) i=false.
Proof.
  cbv zeta; intro W. destruct (trailing_factor p) as [t [R [T F]]].
  pose proof (Int64.unsigned_range word) as B. change Int64.modulus with (2^64) in B.
  assert (P:0<2^(trailing p)) by (apply Z.pow_pos_nonneg;lia).
  assert (K: trailing p<64).
  { destruct (Z_lt_ge_dec (trailing p) 64);auto.
    assert (2^64<=2^(trailing p)) by (apply Z.pow_le_mono_r;lia).
    rewrite W,F in B;nia. }
  rewrite machine_isolate, W,F, isolate_scaled by lia.
  pose proof (one_hot_table _ (conj R K)) as E; unfold reads_bit in E.
  rewrite Z2Nat.id in E by lia. apply andb_true_iff in E as [I E].
  apply Z.ltb_lt in I. apply Z.eqb_eq in E. pose proof (Int64.unsigned_range
    (Int64.shru (Int64.mul (Int64.repr (2^trailing p)) (Int64.repr 285870213051386505))
    (Int64.repr 58))) as U. fold (index_of (Int64.repr (2^trailing p))) in U.
  repeat split;try lia.
  - rewrite Z.mul_pow2_bits, Z.sub_diag by lia. apply Z.testbit_odd_0.
  - intros i Ii; apply Z.mul_pow2_bits_low;lia.
Qed.
