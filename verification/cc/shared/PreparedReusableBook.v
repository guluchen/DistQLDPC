(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto.
From mathcomp Require Import all_ssreflect all_algebra.
Require Import VerifDetected VerifClosesBody VerifLookup HashLookup BuiltLookup
 VerifFlipBody NativeFlipPayload LeafMatrix LevelSearch PreparedMatrixResponse PreparedLeafAtPath.
Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.
Local Open Scope ring_scope.
Local Delimit Scope Z_scope with coqZ.

(* Changing the key and block values leaves the table or CSR addresses
   unchanged. The number of odd checks may change at every flip. *)
Theorem same_book_after_flip keys mask initial_hash current_hash slots links before after (old v:close_view)
 previous_odd odd_count:
 book_safe (table_book keys mask initial_hash slots links before) old previous_odd ->
 same_lookup_geometry v old -> Zlength after=Zlength before ->
 (0<=odd_count<=Int.max_signed)%coqZ ->
 book_safe (table_book keys mask current_hash slots links after) v odd_count.
Proof.
 move=> [mask_range n next block heads chain columns] [off row wid msk syn] dim counted.
 constructor;cbn [table_book HashLookup.slots HashLookup.keys HashLookup.links HashLookup.blocked HashLookup.mask] in *;
 try assumption;try by rewrite dim.
 move=> q range;have bounds:=columns q range.
 unfold close_safe in bounds |- *;rewrite off row wid msk syn;tauto.
Qed.

Lemma count_at_leaf m n k (H:'M['F_2]_(m,n)) (G:'M['F_2]_(k,n)) (x:'cV['F_2]_n)
 rowkey t:
 (Z.of_nat m<=Int.max_signed)%coqZ -> pcm_response H G rowkey x t ->
 (0<=odd_count t<=Int.max_signed)%coqZ.
Proof.
 move=> max [[_ [_ count]] _].
 have le:=max_card (support (H*m x));rewrite card_ord in le;have dim:=elimT leP le.
 change (odd_count t=Z.of_nat #|support (H*m x)|) in count;lia.
Qed.
