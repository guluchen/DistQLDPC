(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto SeedLoopModel.
Local Open Scope Z_scope.

(* MathComp addresses an orbit by its position, while the C seed vector
   stores representative qubits. Representatives need not equal positions. *)
Definition seed_slots c:=length (seed_order c).
Definition position_empty c (j:nat):=observation c (Z.of_nat j) 0.
Definition reported_stop c i r:=exhausted_before c i /\ stop_at c i r.
Theorem completed_positions c i:
 reported_stop c i 0 -> forall j,(j<seed_slots c)%nat -> position_empty c j.
Proof.
 intros [done [[end_ _]|[_ [nonzero _]]]] j live;[|contradiction].
 apply done;rewrite end_;unfold root_count,seed_slots in *;rewrite Zlength_correct;lia.
Qed.
Lemma interrupted_prefix c i:
 reported_stop c i 2 -> 0<=i<root_count c /\ observation c i 2 /\
  (forall j,0<=j<i -> observation c j 0).
Proof. intros [past [[_ bad]|[within [_ current]]]];[lia|auto]. Qed.
