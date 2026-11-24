(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto SeedExemptionState SiblingCounters OverlapRollback.
Local Open Scope Z_scope.
Definition directed_move := (Z*Z)%type.
Definition legal_move n (m:directed_move) := 0<=fst m<n /\ 0<=snd m<n.
Definition move_in (dir:bool) (b:list int) (m:directed_move) :=
 if dir then reassign_blocks b (fst m) (snd m) else reassign_blocks b (snd m) (fst m).
Definition moves dir (ms:list directed_move) b := fold_left (move_in dir) ms b.
Definition contribution q (m:directed_move) :=
 (if Z.eq_dec q (fst m) then 1 else 0)-(if Z.eq_dec q (snd m) then 1 else 0).
Definition total_contribution q (ms:list directed_move) := fold_right (fun m z=>contribution q m+z) 0 ms.

Lemma length_adjust b q dx : 0<=q<Zlength b -> Zlength (adjust dx b q)=Zlength b.
Proof. intro pos;unfold adjust;apply upd_Znth_Zlength;assumption. Qed.
Lemma cell_adjust b a q dx : 0<=a<Zlength b -> 0<=q<Zlength b ->
 Znth a (adjust dx b q) =
 Int.add (Znth a b) (Int.repr (if Z.eq_dec a q then dx else 0)).
Proof.
 intros;unfold adjust;destruct Z.eq_dec;[subst;rewrite upd_Znth_same|rewrite upd_Znth_diff,Int.add_zero];try lia;reflexivity.
Qed.
Lemma one_move_len dir b m : legal_move (Zlength b) m -> Zlength (move_in dir b m)=Zlength b.
Proof. intros [A B];destruct dir;unfold move_in,reassign_blocks;rewrite !length_adjust by (rewrite ?length_adjust;lia);reflexivity. Qed.
Lemma one_move_cell dir b m a : legal_move (Zlength b) m -> 0<=a<Zlength b ->
 Znth a (move_in dir b m)=Int.add (Znth a b) (Int.repr ((if dir then 1 else -1)*contribution a m)).
Proof.
 intros [A B] key;destruct dir;unfold move_in,reassign_blocks,contribution;
 rewrite !cell_adjust by (rewrite ?length_adjust;lia);rewrite Int.add_assoc,add_encoded;
 destruct (Z.eq_dec a (fst m)),(Z.eq_dec a (snd m));reflexivity.
Qed.
Lemma moves_length dir ms b : Forall (legal_move (Zlength b)) ms -> Zlength (moves dir ms b)=Zlength b.
Proof.
 revert b;induction ms as [|m ms IH];intros b safe;cbn [moves fold_left];[reflexivity|].
 inversion safe;subst;fold (moves dir ms (move_in dir b m));rewrite IH;rewrite one_move_len by assumption;auto.
Qed.
Lemma moves_cell dir ms b a : Forall (legal_move (Zlength b)) ms -> 0<=a<Zlength b ->
 Znth a (moves dir ms b)=Int.add (Znth a b) (Int.repr ((if dir then 1 else -1)*total_contribution a ms)).
Proof.
 revert b;induction ms as [|m ms IH];intros b safe key.
 - cbn [moves total_contribution fold_left fold_right];rewrite Z.mul_0_r,Int.add_zero;reflexivity.
 - inversion safe as [|? ? current future];subst.
   cbn [moves total_contribution fold_left fold_right];fold (moves dir ms (move_in dir b m)).
   rewrite IH by (rewrite one_move_len by exact current;assumption).
   rewrite one_move_cell by assumption;rewrite Int.add_assoc,add_encoded.
   unfold total_contribution;rewrite Z.mul_add_distr_l;reflexivity.
Qed.
(* Seed exit visits the same CSR rows in forward order. Distinct rows may
   repeatedly move a block to or from the same qubit. *)
Theorem same_order_exemption_rollback ms b :
 Forall (legal_move (Zlength b)) ms -> moves false ms (moves true ms b)=b.
Proof.
 intro safe;pose proof (moves_length true ms b safe) as len.
 apply Znth_eq_ext.
 - rewrite moves_length by (rewrite len;assumption);exact len.
 - intros a key;rewrite moves_length in key by (rewrite len;assumption);rewrite len in key.
   rewrite moves_cell by (rewrite len;assumption).
   rewrite moves_cell by assumption;rewrite Int.add_assoc,add_encoded.
   replace (1*total_contribution a ms + -1*total_contribution a ms) with 0 by ring;apply Int.add_zero.
Qed.
