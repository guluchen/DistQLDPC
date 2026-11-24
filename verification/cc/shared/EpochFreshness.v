(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.zlist.list_solver.
Definition wiped (tags:list int64) := Zrepeat Int64.zero (Zlength tags).
(* The one-tag counter recycles at MAX. The pair recycles at MAX-2,
   before either of its two issued tags can become zero. *)
Definition recycled (pair:bool) last :=
 if Z_le_dec (Int64.max_unsigned-(if pair then 2 else 0)) last then true else false.
Definition advance_tag (pair:bool) last :=
 if recycled pair last then (if pair then 2 else 1) else last+(if pair then 2 else 1).
Definition after_tags pair last tags := if recycled pair last then wiped tags else tags.

Lemma wiped_length tags : Zlength (wiped tags)=Zlength tags.
Proof. unfold wiped;rewrite Zlength_Zrepeat;[reflexivity|apply Zlength_nonneg]. Qed.
Lemma after_length pair last tags : Zlength (after_tags pair last tags)=Zlength tags.
Proof. unfold after_tags;destruct (recycled pair last);[apply wiped_length|reflexivity]. Qed.
Lemma issued_range pair last : 0<=last<=Int64.max_unsigned ->
  1<=advance_tag pair last<=Int64.max_unsigned-(if pair then 1 else 0).
Proof. intro ok;destruct pair;unfold advance_tag,recycled;destruct Z_le_dec;rep_lia. Qed.
Theorem fresh_slots (pair:bool) last (tags:list int64) : 0<=last<=Int64.max_unsigned ->
 (forall i,0<=i<Zlength tags -> Int64.unsigned (Znth i tags)<=last+(if pair then 1 else 0)) ->
 forall i,0<=i<Zlength tags ->
 Int64.unsigned (Znth i (after_tags pair last tags))<advance_tag pair last.
Proof.
 intros legal prior i live;specialize (prior i live).
 destruct pair;unfold after_tags,advance_tag,recycled;destruct Z_le_dec;
  try (unfold wiped;rewrite Znth_Zrepeat by assumption;change (0<2) || change (0<1));lia.
Qed.

Definition cleared_prefix (xs:list int64) i := Zrepeat Int64.zero i ++ sublist i (Zlength xs) xs.
Lemma prefix_size xs i : 0<=i<=Zlength xs -> Zlength (cleared_prefix xs i)=Zlength xs.
Proof. intro R;unfold cleared_prefix;rewrite Zlength_app,Zlength_Zrepeat,Zlength_sublist by lia;lia. Qed.
Lemma prefix_cell xs i j : 0<=i<=Zlength xs -> 0<=j<Zlength xs ->
 Znth j (cleared_prefix xs i)=if Z_lt_dec j i then Int64.zero else Znth j xs.
Proof.
 intros stop loc;unfold cleared_prefix;destruct Z_lt_dec.
 - rewrite app_Znth1,Znth_Zrepeat;rewrite ?Zlength_Zrepeat by lia;auto;lia.
 - rewrite app_Znth2, Zlength_Zrepeat, Znth_sublist by (rewrite ?Zlength_Zrepeat;lia).
   f_equal;lia.
Qed.
Lemma prefix_step xs i : 0<=i<Zlength xs ->
 upd_Znth i (cleared_prefix xs i) Int64.zero = cleared_prefix xs (i+1).
Proof.
 intro here;apply Znth_eq_ext.
 - rewrite upd_Znth_Zlength,!prefix_size by (rewrite ?prefix_size;lia);reflexivity.
 - intros j J;rewrite upd_Znth_Zlength,prefix_size in J by (rewrite ?prefix_size;lia).
   destruct (Z.eq_dec i j) as [->|diff].
   + rewrite upd_Znth_same,prefix_cell by (rewrite ?prefix_size;lia);destruct Z_lt_dec;[reflexivity|lia].
   + rewrite upd_Znth_diff,!prefix_cell by (rewrite ?prefix_size;lia).
     repeat destruct Z_lt_dec;try reflexivity;lia.
Qed.
