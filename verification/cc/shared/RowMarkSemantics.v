(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VerifMarkRow.
From Coq Require Import List.
Import ListNotations.

Theorem mark_cells t (ms:list int64) xs j :
 Forall (fun q=>Int.unsigned q<Zlength ms) xs -> 0<=j<Zlength ms ->
 Znth j (fold_left (mark_word t) xs ms)=
 if in_dec Z.eq_dec j (map Int.unsigned xs) then t else Znth j ms.
Proof.
 revert ms;induction xs as [|q xs IH];intros ms ok bound;[reflexivity|].
 inversion ok as [|? ? qok rest];subst. cbn [fold_left map].
 pose proof (Int.unsigned_range q) as qnn.
 pose proof (upd_Znth_Zlength (Int.unsigned q) ms t ltac:(lia)) as length_ok.
 rewrite IH by (unfold mark_word;rewrite length_ok;assumption).
 destruct (in_dec Z.eq_dec j (map Int.unsigned xs)) as [intail|outside];
 destruct (in_dec Z.eq_dec j (Int.unsigned q::map Int.unsigned xs)) as [included|missing];
 try reflexivity;try (exfalso;apply missing;right;assumption).
 - destruct included as [first|later];[subst j|contradiction].
   unfold mark_word;rewrite upd_Znth_same by lia;reflexivity.
 - assert (j<>Int.unsigned q) by (intro same;apply missing;left;congruence).
   unfold mark_word;rewrite upd_Znth_diff by lia;reflexivity.
Qed.

(* Logical marking is union with the incidence set. Unavailable qubits
   may be marked as well, since only free qubits are counted as clashes. *)
Corollary mark_set_union t ms xs j :
 Forall (fun q=>Int.unsigned q<Zlength ms) xs -> 0<=j<Zlength ms ->
 (Znth j (fold_left (mark_word t) xs ms)=t <->
  In j (map Int.unsigned xs) \/ Znth j ms=t).
Proof. intros;rewrite mark_cells by assumption;destruct in_dec;intuition. Qed.
