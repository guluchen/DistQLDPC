(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto.
From Coq Require Import List Bool Lia.
Import ListNotations.

Definition is_free (blocked:list int) q :=
  Int.eq (Znth (Int.unsigned q) blocked) Int.zero.
Definition has_stamp (marks:list int64) (stamp:int64) q :=
  Int64.eq (Znth (Int.unsigned q) marks) stamp.
Definition flag (condition:bool) := if condition then Int.one else Int.zero.
Definition row_step (blocked:list int) (marks:list int64) (stamp:int64)
  (state:int*int) (q:int) :=
  (Int.add (fst state) (flag (is_free blocked q)),
   Int.or (snd state)
     (Int.and (flag (is_free blocked q)) (flag (has_stamp marks stamp q)))).

Lemma flag_and a b : Int.and (flag a) (flag b)=flag (a && b).
Proof. destruct a,b;reflexivity. Qed.
Lemma flag_or a b : Int.or (flag a) (flag b)=flag (a || b).
Proof. destruct a,b;reflexivity. Qed.

Lemma flag_add count bit : 0<=count<Int.max_unsigned ->
  Int.add (Int.repr count) (flag bit) = Int.repr (count+(if bit then 1 else 0)).
Proof.
  intro R. unfold Int.add; rewrite Int.unsigned_repr by lia.
  destruct bit;reflexivity.
Qed.

Definition free_row (blocked:list int) (row:list int) := filter (is_free blocked) row.
Definition row_clash blocked marks stamp (row:list int) :=
  existsb (fun q=>is_free blocked q && has_stamp marks stamp q) row.

(* Exactly the uint32 count and OR accumulator in the original CSR loop.
   The bound permits a UINT32_MAX-entry row, as do its unsigned endpoints. *)
Theorem row_tally blocked marks stamp row count clash :
  0<=count -> count+Zlength row<=Int.max_unsigned ->
  fold_left (row_step blocked marks stamp) row (Int.repr count,flag clash)=
  (Int.repr (count+Zlength (free_row blocked row)),
   flag (clash || row_clash blocked marks stamp row)).
Proof.
  revert count clash;induction row as [|q rest IH];intros count clash low high.
  - cbn [fold_left free_row filter row_clash existsb].
    rewrite Zlength_nil, Z.add_0_r, Bool.orb_false_r;reflexivity.
  - rewrite Zlength_cons in high. cbn [fold_left].
    unfold row_step at 2; cbn [fst snd].
    rewrite flag_add,flag_and,flag_or by (pose proof (Zlength_nonneg rest);lia).
    rewrite IH by (destruct (is_free blocked q);lia).
    unfold free_row,row_clash; cbn [filter existsb].
    destruct (is_free blocked q), (has_stamp marks stamp q), clash; simpl orb; simpl andb;
      rewrite ?Zlength_cons;f_equal; f_equal;lia.
Qed.

Lemma filtered_length blocked (row:list int) :
  0<=Zlength (free_row blocked row)<=Zlength row.
Proof.
  unfold free_row;induction row as [|q rest IH];[cbn [filter];rewrite !Zlength_nil;lia|].
  rewrite Zlength_cons;cbn [filter];destruct (is_free blocked q);rewrite ?Zlength_cons;lia.
Qed.

Theorem no_candidate_exact blocked marks stamp row :
  Zlength row<=Int.max_unsigned ->
  (fst (fold_left (row_step blocked marks stamp) row (Int.zero,Int.zero))=Int.zero <->
   forall q, In q row -> is_free blocked q=false).
Proof.
  intro bound. change (Int.zero,Int.zero) with (Int.repr 0,flag false).
  rewrite row_tally by lia. cbn [fst]. rewrite Z.add_0_l.
  split.
  - intro value;apply (f_equal Int.unsigned) in value;rewrite Int.unsigned_repr in value
      by (pose proof (filtered_length blocked row);lia).
    change (Zlength (free_row blocked row)=0) in value.
    assert (empty:free_row blocked row=[]) by (destruct (free_row blocked row);
      [reflexivity|rewrite Zlength_cons in value;pose proof (Zlength_nonneg l);lia]).
    intros q member. destruct (is_free blocked q) eqn:free;[|reflexivity].
    assert (In q (free_row blocked row)) by (apply filter_In;auto).
    rewrite empty in H;contradiction.
  - intros none. clear bound. assert (empty:free_row blocked row=[]).
    { unfold free_row; induction row as [|q rs IH];[reflexivity|].
      cbn [filter]; rewrite (none q (or_introl eq_refl)); apply IH.
      intros a inside. apply none; right; exact inside. }
    rewrite empty,Zlength_nil;reflexivity.
Qed.
