(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.zlist.list_solver.
Require Import SiblingCounters.
From Coq Require Import List Lia.
Import ListNotations.

Lemma unique_visits xs q : NoDup xs ->
 visits xs q = if in_dec Z.eq_dec q xs then 1 else 0.
Proof.
  intro unique;unfold visits.
  destruct (in_dec Z.eq_dec q xs) as [hit|miss].
  - apply (proj1 (NoDup_count_occ' Z.eq_dec xs)) with (x:=q) in unique;[rewrite unique;reflexivity|assumption].
  - apply (proj1 (count_occ_not_In Z.eq_dec xs q)) in miss;rewrite miss;reflexivity.
Qed.

(* A child list consists of distinct qubits that were free when the row
   was scanned. For each prefix, the machine zero test therefore gives
   exactly the free set minus the siblings already visited, without wrap. *)
Theorem machine_free_after_excluding base xs q :
 in_array (Zlength base) xs -> NoDup xs ->
 Forall (fun a=>Znth a base=Int.zero) xs -> 0<=q<Zlength base ->
 (Znth q (sweep 1 xs base)=Int.zero <-> Znth q base=Int.zero /\ ~In q xs).
Proof.
  intros range distinct available live.
  rewrite sweep_cell by assumption. rewrite unique_visits by assumption.
  destruct (in_dec Z.eq_dec q xs) as [included|absent].
  - apply Forall_forall with (x:=q) in available;[|assumption].
    rewrite available. change (Int.one=Int.zero <-> Int.zero=Int.zero /\ ~In q xs).
    split;[discriminate|intros [_ no];contradiction].
  - rewrite Z.mul_0_r,Int.add_zero. tauto.
Qed.

Lemma fresh_prefix (xs:list Z) i : NoDup xs -> 0<=i<Zlength xs ->
 ~In (Znth i xs) (sublist 0 i xs).
Proof.
  intros distinct live present.
  destruct (In_Znth _ _ present) as [j [bound eqv]].
  rewrite Zlength_sublist in bound by lia.
  rewrite Znth_sublist,?Z.add_0_l,?Z.add_0_r in eqv by lia.
  pose proof (@NoDup_Znth_inj Z _ xs j i distinct ltac:(lia) live eqv);lia.
Qed.
