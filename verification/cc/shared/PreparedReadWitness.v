(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto.
From mathcomp Require Import all_ssreflect all_algebra.
Require Import LeafMatrix LevelSearch LeafAPI PCMLeafAPI PackedDetector VerifClosesBody VerifOneLeft
 NativeFlipPayload PreparedMatrixResponse PreparedMatrixPath PreparedChildCall PreparedRecursiveCall PreparedPairEvent
 PreparedLeafVisit PreparedObservedWitness.
Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.
Local Open Scope ring_scope.
Local Delimit Scope Z_scope with coqZ.

Section Reader.
Variables m n r k:nat.
Variables (H:'M['F_2]_(m,n)) (S:'M['F_2]_(r,n)) (G:'M['F_2]_(k,n)).

(* The two-mode fast path writes the precise length that the C++
   caller passes to record_witness. Decode that signed C word and
   check the corresponding entries of cur, including an early close. *)
Theorem pair_register_indexes_checked_witness (ids:seq 'I_n) (F:{set 'I_n}) rowkey t depth q cur old event:
 H*m S^T=0 -> G*m S^T=0 -> (\rank (col_mx H G)+\rank S=n)%N ->
 (Z.of_nat n<=Int.max_signed)%coqZ -> uniq ids ->
 (1<=depth<=Int.max_signed-2)%coqZ -> (depth+1<Zlength cur)%coqZ -> (depth+1)%coqZ=Z.of_nat (size ids) ->
 append_qubit cur depth q=literal_path ids ->
 let P:=[set b:'I_n | b \in ids] in pcm_response H G rowkey (indicator P) t ->
 scanned_leaf (odd_count t) (pcm_completion H G P F) (Z.of_nat n) event ->
 let seen:=packed_detects (parities (words_at t)) in let code:=pair_code seen event in
 let reg:=pair_size depth old seen event in let tail:=pair_path depth (upd_Znth depth cur (Int.repr q)) event in
 (witness_status code -> stored_css_prefix H S (Int.signed reg) tail) /\
 (code=0%coqZ -> reg=old).
Proof.
 move=>orth det rank_ok nfit uniq_ids bounds room size_eq path P physical answer seen code reg tail.
 have obs:pair_observation t (pcm_completion H G P F) (Z.of_nat n) depth q cur code tail by exists event.
 split.
 - move=>hit;have css:=@observed_witness_has_valid_length m n k r H S G ids F rowkey t depth q cur
     code tail orth det rank_ok nfit uniq_ids (proj1 bounds) room size_eq path physical obs hit.
   suff ->:Int.signed reg=(if Z.eq_dec code 3 then depth+1 else depth+2)%coqZ by exact css.
   unfold reg,code in *;destruct event as [z|];cbn [pair_code pair_size] in *.
   + unfold final_pick,last_size,witness_status in *;destruct (Z_lt_dec z 0);[lia|].
     change (Int.signed (Int.repr (depth+2)%coqZ)=(depth+2)%coqZ);apply Int.signed_repr;rep_lia.
   + destruct seen.
     * change (Int.signed (Int.repr (depth+1)%coqZ)=(depth+1)%coqZ);apply Int.signed_repr.
       change Int.min_signed with (-2147483648)%coqZ;lia.
     * change (0 = 1 \/ 0 = 3)%coqZ in hit;intuition discriminate.
 - unfold code,reg;destruct event as [z|];cbn [pair_code pair_size].
   + unfold final_pick,last_size;by destruct (Z_lt_dec z 0).
   + by destruct seen.
Qed.
End Reader.
