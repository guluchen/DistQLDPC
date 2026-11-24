(* SPDX-License-Identifier: GPL-3.0-or-later *)
From Coq Require Import ZArith Lia.
From mathcomp Require Import all_ssreflect all_algebra.
Require Import compcert.lib.Integers LeafMatrix LevelSearch NativeBoundAlgebra.
Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.
Local Open Scope ring_scope.
Local Delimit Scope Z_scope with coqZ.

(* The preconditions of the two signed C increments follow from the PCM
   distance, including when the parity shortcut skips the next weight. *)
Theorem finite_empty_machine_range m n k (H:'M['F_2]_(m,n)) (L:'M['F_2]_(k,n))
    w (only_even:bool) :
 (Z.of_nat n <= Int.max_signed)%coqZ ->
 (w<=distance_index H L)%N -> w!=distance_index H L -> (distance_index H L<=n)%N ->
 (only_even -> forall q,odd #|support (col q H)|) ->
 (0<=Z.of_nat w<Int.max_signed)%coqZ /\
 (machine_next (Z.of_nat w) only_even<=Z.of_nat (distance_index H L))%coqZ /\
 (machine_next (Z.of_nat w) only_even<=Int.max_signed)%coqZ.
Proof.
move=> cap lower miss finite parity.
have pass:=@justified_next m n k H L w only_even lower miss finite parity.
have below:(w<distance_index H L)%N by rewrite ltn_neqAle miss lower.
rewrite next_encoding.
move/leP:pass=> next;move/leP:finite=> finite;move/ltP:below=> below.
split;[lia|split;lia].
Qed.

(* For a certified physical upper bound, an absent half is neutral to the
   stop test even if the largest signed weight is itself the answer. *)
Definition lower_or_top (present:bool) (value:Z) :=
 if present then value else Int.max_signed.
Theorem exact_when_clipped_smallest
    (x_exists z_exists:bool) (dx dz lx lz up:Z) :
 (lx<=dx)%coqZ -> (lz<=dz)%coqZ ->
 (Z.min (lower_or_top x_exists dx) (lower_or_top z_exists dz)<=up)%coqZ ->
 (up<=Z.min (lower_or_top x_exists lx) (lower_or_top z_exists lz))%coqZ ->
 up=Z.min (lower_or_top x_exists dx) (lower_or_top z_exists dz).
Proof.
case:x_exists;case:z_exists;rewrite /lower_or_top=> /=;lia.
Qed.
