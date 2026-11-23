(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto.
From Coq Require Import List Lia Logic.Classical_Prop.
Require Import TableFlow.
Import ListNotations.

Section Occupancy.
Variables (ks:list int64) (mask:int64) (cap:Z).
Hypothesis valid_mask : Int64.unsigned mask<cap.
Lemma touched_slot_bound q tab links : history ks mask cap q tab links ->
  exists touched:list Z, Zlength touched=Zlength ks-1-q /\
    forall j, 0<=j<cap -> ~In j touched -> Znth j tab= -1.
Proof.
  intro built;induction built as [|q tab links i earlier IH pos walk final|q tab links i earlier IH pos walk old key].
  - exists [];split;[rewrite Zlength_nil;lia|intros;apply Znth_Zrepeat;assumption].
  - destruct IH as [touched [count empty]]. exists (slot_index i::touched).
    split;[rewrite Zlength_cons;lia|]. intros j range fresh.
    pose proof (@reached_inside ks mask cap valid_mask q tab i walk) as slot.
    pose proof (@slot_count ks cap q tab links (@history_shape ks mask cap valid_mask _ _ _ earlier)) as len.
    rewrite upd_Znth_diff by (try lia;intro eq;apply fresh;left;congruence).
    apply empty;[assumption|intro used;apply fresh;right;exact used].
  - destruct IH as [touched [count empty]]. exists (slot_index i::touched).
    split;[rewrite Zlength_cons;lia|]. intros j range fresh.
    pose proof (@reached_inside ks mask cap valid_mask q tab i walk) as slot.
    pose proof (@slot_count ks cap q tab links (@history_shape ks mask cap valid_mask _ _ _ earlier)) as len.
    rewrite upd_Znth_diff by (try lia;intro eq;apply fresh;left;congruence).
    apply empty;[assumption|intro used;apply fresh;right;exact used].
Qed.

Lemma zmap_nodup ns : NoDup ns -> NoDup (map Z.of_nat ns).
Proof.
  intro unique;induction unique as [|a xs outside _ IH];cbn;constructor;[|assumption].
  intros member;apply in_map_iff in member as [b [eq inside]].
  apply Nat2Z.inj in eq;subst;contradiction.
Qed.
Theorem spare_slot q tab links : history ks mask cap q tab links -> Zlength ks<cap ->
  exists j, 0<=j<cap /\ Znth j tab= -1.
Proof.
  intros built bigger. destruct (touched_slot_bound _ _ _ built) as [xs [count unused]].
  pose proof (@remaining ks cap q tab links (@history_shape ks mask cap valid_mask _ _ _ built)) as Q.
  destruct (classic (exists j, 0<=j<cap /\ ~In j xs)) as [[j [inside fresh]]|none].
  - exists j;split;[assumption|apply unused;assumption].
  - exfalso. set (universe:=map Z.of_nat (seq 0 (Z.to_nat cap))).
    assert (unique:NoDup universe) by (apply zmap_nodup,seq_NoDup).
    assert (covers:incl universe xs).
    { intros j mem. apply NNPP;intro absent. apply none;exists j;split;[|assumption].
      apply in_map_iff in mem as [a [<- present]]. apply in_seq in present;lia. }
    pose proof (NoDup_incl_length unique covers) as too_short.
    unfold universe in too_short;rewrite map_length,seq_length in too_short.
    rewrite Zlength_correct in count;lia.
Qed.
End Occupancy.
