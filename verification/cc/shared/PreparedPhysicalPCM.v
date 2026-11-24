(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto.
From mathcomp Require Import all_ssreflect all_algebra.
Require Import VerifClosesBody VerifFlipBody RedundantState SparseSyndrome FlipRoundtrip NativeFlipPayload NativeRootFlip.
Local Delimit Scope Z_scope with coqZ.
Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.

(* The optional redundant syndrome occupies high bits. Both physical
   incidences and these extra rows use the actual, ordered CSR slice. *)
Theorem physical_payload_pair m (inc:seq 'I_m) (active:{set 'I_m}) p keys q payload:
 let v:=words_at payload in
 (0<=q)%coqZ -> uniq inc -> (Z.of_nat m<=Int.modulus)%coqZ ->
 column_list v q=map (@encode m) inc ->
 stores_odd (syndrome v,odd_count payload) active ->
 Forall (fun r=>(Z.of_nat m<=Int.unsigned r)%coqZ) (extra_rows p q) ->
 Forall (fun r=>(Int.unsigned r<64*Zlength (syndrome v))%coqZ) (column_list v q++extra_rows p q) ->
 valid_payload p keys q payload -> valid_payload p keys q (step_support p keys q payload) ->
 pair_safe p keys q payload.
Proof.
move=> v pos unique dim representation odd high all before after.
split;first exact before.
split;first exact after.
have enough := before.
case:enough=> _ [_ [_ [_ [_ [_ [width_ok [room _]]]]]]].
apply:packed_state_roundtrip=> //;first lia.
rewrite representation in all *.
exact:(@native_flip_rolls_back m inc p q unique dim high (syndrome v) (odd_count payload) active odd all).
Qed.
