(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto.
Require Import SeedColumnModel SeedPolicyView SeedColumnRestore.
Local Open Scope Z_scope.

Definition same_seed_state s t := exempts s=exempts t /\ reference_counts s=reference_counts t.
Lemma same_seed_move limits a b r q:
 same_seed_state a b -> same_seed_state (replace_exemption limits a r q) (replace_exemption limits b r q).
Proof.
 intros [ex ref];unfold same_seed_state,replace_exemption;rewrite ex,ref.
 destruct (Int.eq (Znth r (exempts b)) (Int.repr q));[auto|].
 destruct (Int.eq (Znth r limits) Int.zero);cbn [exempts reference_counts];auto.
Qed.
Lemma same_seed_row limits base prior seed enter a b word:
 same_seed_state a b ->
 same_seed_state (visit_seed_row limits base prior seed enter a word)
                 (visit_seed_row limits base prior seed enter b word).
Proof. intro saved;unfold visit_seed_row;destruct Z_lt_dec;[assumption|apply same_seed_move;assumption]. Qed.
Lemma same_seed_prefix g limits enter seed a b j:
 same_seed_state a b -> same_seed_state (prefix g limits enter seed a j) (prefix g limits enter seed b j).
Proof.
 unfold prefix,visited_seed_rows;generalize (sublist (index_at g seed) j (col_rows g)).
 intros rows;revert a b;induction rows;intros a0 b0 saved;cbn [fold_left];auto.
 apply IHrows;apply same_seed_row;assumption.
Qed.
Lemma same_seed_precondition g limits enter seed a b :
 same_seed_state a b -> column_safe g limits enter seed a -> column_safe g limits enter seed b.
Proof.
 intros same [qo [room [span [cap scan]]]];unfold column_safe;do 4 (split;[assumption|]).
 intros j pos;pose proof (same_seed_prefix g limits enter seed a b j same) as [ex ref].
 specialize (scan j pos);destruct scan as [base_ok [fb_ok visit]];split;[exact base_ok|];split;[exact fb_ok|].
 intro active;rewrite <-ex,<-ref;apply visit;assumption.
Qed.

Theorem restored_after_root_visit g limits q initial resumed :
 let entered:=full_column g limits true q initial in
 column_safe g limits true q initial -> column_safe g limits false q entered ->
 0<Zlength (reference_counts initial) -> same_seed_state entered resumed ->
 (forall k,0<=k<Zlength (exempts initial) -> touched g q (index_at g (q+1)) k=true ->
    Znth k (exempts initial)=Int.repr (seed_choice (base_order g) (first_block g) k q false)) ->
 same_seed_state (full_column g limits false q resumed) initial.
Proof.
 intros entered on exit width saved preference.
 eapply native_seed_roundtrip;try eassumption;try apply eq_sym;
   try solve [apply (proj1 saved)|apply (proj2 saved)].
 eapply same_seed_precondition;[exact saved|exact exit].
Qed.
