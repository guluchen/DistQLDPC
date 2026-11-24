(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.zlist.list_solver.
Require Import RowTally.

Definition gathered blocks cols lo i := free_row blocks (sublist lo i cols).
Definition filled (picks old:list int) := picks ++ sublist (Zlength picks) (Zlength old) old.
Lemma filled_len picks old : Zlength picks<=Zlength old -> Zlength (filled picks old)=Zlength old.
Proof.
 intro room;unfold filled;rewrite Zlength_app,Zlength_sublist by (pose proof (Zlength_nonneg picks);lia);lia.
Qed.
Lemma filled_at picks old i : Zlength picks<=Zlength old -> 0<=i<Zlength old ->
 Znth i (filled picks old) = if Z_lt_dec i (Zlength picks) then Znth i picks else Znth i old.
Proof.
 intros room live;unfold filled;destruct Z_lt_dec.
 - rewrite app_Znth1 by lia;reflexivity.
 - rewrite app_Znth2 by lia;rewrite Znth_sublist by (rewrite ?Zlength_sublist;try lia;apply Zlength_nonneg).
   f_equal;lia.
Qed.
Lemma fill_one picks old q : Zlength picks<Zlength old ->
 upd_Znth (Zlength picks) (filled picks old) q=filled (picks++[q]) old.
Proof.
 intro room;assert (plus:Zlength (picks++[q])=Zlength picks+1) by (rewrite Zlength_app;reflexivity).
 pose proof (Zlength_nonneg picks) as nn. apply Znth_eq_ext.
 - rewrite upd_Znth_Zlength,!filled_len by (rewrite ?plus,?filled_len;lia);reflexivity.
 - intros i I;rewrite upd_Znth_Zlength,filled_len in I by (rewrite ?filled_len;lia).
   destruct (Z.eq_dec i (Zlength picks)) as [->|elsewhere].
   + rewrite upd_Znth_same,filled_at by (rewrite ?plus,?filled_len;lia).
     rewrite plus;destruct Z_lt_dec;[rewrite app_Znth2 by lia;rewrite Z.sub_diag;reflexivity|lia].
   + rewrite upd_Znth_diff,!filled_at by (rewrite ?plus,?filled_len;lia).
     rewrite plus;repeat destruct Z_lt_dec;try lia;try reflexivity.
     rewrite app_Znth1 by lia;reflexivity.
Qed.
Lemma gather_step blocks cols lo i : 0<=lo<=i -> i<Zlength cols ->
 gathered blocks cols lo (i+1) =
  if is_free blocks (Znth i cols) then gathered blocks cols lo i++[Znth i cols]
  else gathered blocks cols lo i.
Proof.
 intros bounds live;unfold gathered,free_row.
 rewrite (sublist_split lo i (i+1)),(sublist_one i),filter_app by lia.
 simpl filter;destruct (is_free blocks (Znth i cols));rewrite ?app_nil_r;reflexivity.
Qed.
Lemma gather_size blocks cols lo i : 0<=lo<=i -> i<=Zlength cols ->
  0<=Zlength (gathered blocks cols lo i)<=i-lo.
Proof.
 intros;unfold gathered;pose proof (filtered_length blocks (sublist lo i cols)) as bound.
 rewrite Zlength_sublist in bound by lia;exact bound.
Qed.
