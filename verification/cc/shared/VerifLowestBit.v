(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto.
Require Import level_ast VerifDetected LowestWord.
Definition byteval (n:Z) := Vint (Int.repr n).

(* Connect the proof's list to the actual read-only global initializer. *)
Lemma actual_table_initializer :
  gvar_init v_bit_position = map (fun z => Init_int8 (Int.repr z)) positions.
Proof. reflexivity. Qed.

Lemma table_length : Zlength positions=64.
Proof. reflexivity. Qed.

Lemma actual_entry word p : Int64.unsigned word=Z.pos p ->
  0<=index_of (isolated word)<64 /\
  Znth (index_of (isolated word)) positions=trailing p.
Proof.
  intro W; destruct (lowest_bit_correct word p W) as [_ [B [value _]]].
  split;[exact B|]. unfold Znth. destruct (Z_lt_dec _ 0);[lia|].
  erewrite nth_indep;[exact value|].
  change (length positions) with 64%nat;lia.
Qed.

Lemma pointer_index (x:int64) : Ptrofs.unsigned (Ptrofs.of_int64 x)=Int64.unsigned x.
Proof.
  unfold Ptrofs.of_int64;rewrite Ptrofs.unsigned_repr;[reflexivity|].
  change (0<=Int64.unsigned x<=Int64.max_unsigned). apply Int64.unsigned_range_2.
Qed.

Definition lowest_spec : ident * funspec :=
 DECLARE _cc_lowest_bit
 WITH gv : globals, word : int64, p : positive, sh : share
 PRE [tulong] PROP (readable_share sh; Int64.unsigned word=Z.pos p)
   PARAMS (Vlong word) GLOBALS (gv)
   SEP (data_at sh (tarray tuchar 64) (map byteval positions) (gv _bit_position))
 POST [tint] PROP() RETURN (Vint (Int.repr (trailing p)))
   SEP (data_at sh (tarray tuchar 64) (map byteval positions) (gv _bit_position)).

Definition LowGprog : funspecs := ltac:(with_library prog [lowest_spec]).
Theorem body_cc_lowest_bit : semax_body Vprog LowGprog f_cc_lowest_bit lowest_spec.
Proof.
  start_function. destruct (actual_entry word p ltac:(assumption)) as [bounds entry].
  assert (layout: 0<=Ptrofs.unsigned (Ptrofs.of_int64
    (Int64.shru (Int64.mul (isolated word) (Int64.repr 285870213051386505))
      (Int64.repr 58)))<Zlength positions).
  { rewrite pointer_index, table_length. exact bounds. }
  assert (loaded : Znth (Ptrofs.unsigned (Ptrofs.of_int64
    (Int64.shru (Int64.mul (isolated word) (Int64.repr 285870213051386505))
      (Int64.repr 58)))) positions=trailing p) by (rewrite pointer_index;exact entry).
  unfold isolated in loaded; change Int64.zero with (Int64.repr 0) in loaded.
  pose proof (proj1 (lowest_bit_correct word p ltac:(assumption))) as range.
  forward. forward. forward.
  { rewrite loaded; unfold byteval; entailer!; rep_lia. }
  rewrite loaded. unfold byteval. forward.
Qed.
