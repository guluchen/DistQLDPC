(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.zlist.list_solver.
Require Import SeedExemptionState SeedColumnModel SeedBlockModel SeedBlockView SeedPolicyView.
Local Open Scope Z_scope.

(* Outside each seed search, the first exhausted member takes priority
   over the static base order. Inactive rows have no exemption. *)
Definition between_seeds base st:=forall row,0<=row<Zlength base -> 0<=Int.signed (Znth row base) ->
 row<Zlength (exhausted_fallback st) /\ row<Zlength (exempts (live_rows st)) /\
 Znth row (exempts (live_rows st))=
   Int.repr (clear_seed (Int.signed (Znth row base)) (Int.signed (Znth row (exhausted_fallback st)))).
Lemma replaced_row_count limits st row q:0<=row<Zlength (exempts st) ->
 Zlength (exempts (replace_exemption limits st row q))=Zlength (exempts st).
Proof.
 intro pos;unfold replace_exemption;destruct Int.eq;[reflexivity|];destruct Int.eq;
 cbn [exempts];rewrite upd_Znth_Zlength by lia;reflexivity.
Qed.
Lemma remember_at_rest limits base q st word:
 0<=q<=Int.max_signed -> Int.unsigned word<Zlength base -> between_seeds base st ->
 between_seeds base (remember_row limits base q st word).
Proof.
 intros key valid before;unfold remember_row;set (r:=Int.unsigned word) in *.
 assert (positive:0<=r) by (unfold r;apply Int.unsigned_range_2).
 destruct (Z_lt_dec (Int.signed (Znth r base)) 0);[assumption|].
 destruct (Z_lt_dec (Int.signed (Znth r (exhausted_fallback st))) 0);[|assumption].
 pose proof (before r ltac:(lia) ltac:(lia)) as [fb [old _]].
 intros k within active;pose proof (before k within active) as [fpos [cpos chosen]].
 cbn [exhausted_fallback live_rows];rewrite upd_Znth_Zlength,replaced_row_count by lia;split;[lia|];split;[lia|].
 destruct (Z.eq_dec k r) as [->|different].
 - rewrite row_always_selects_current,upd_Znth_same by lia;unfold clear_seed;rewrite Int.signed_repr by rep_lia.
   destruct Z_lt_dec;[lia|reflexivity].
 - rewrite other_exempt_unchanged,upd_Znth_diff by lia;exact chosen.
Qed.
Lemma remember_rows_at_rest limits base q rows st:
 0<=q<=Int.max_signed -> Forall (fun x=> Int.unsigned x<Zlength base) rows -> between_seeds base st ->
 between_seeds base (fold_left (remember_row limits base q) rows st).
Proof.
 intros repr safe;revert st;induction safe;intros st saved;cbn [fold_left];auto.
 apply IHsafe;apply remember_at_rest;assumption.
Qed.
Lemma remember_column_at_rest g limits q st:
 inner_safe g limits q st -> between_seeds (base_order g) st ->
 between_seeds (base_order g) (before_row g limits q st (index_at g (q+1))).
Proof.
 intros [repr [_ [[lo span] [cap safe]]]] saved;unfold before_row,remember_column.
 apply remember_rows_at_rest;try assumption;apply Forall_forall;intros x inside.
 destruct (In_Znth _ _ inside) as [k [pos at_k]];rewrite Zlength_sublist in pos by lia.
 rewrite Znth_sublist in at_k by lia;rewrite <-at_k.
 exact (proj2 (proj1 (safe (k+index_at g q) ltac:(lia)))).
Qed.
Theorem exhausted_orbit_keeps_preference g b limits block st:
 block_safe g b limits block st -> between_seeds (base_order g) st ->
 between_seeds (base_order g) (crossed_block g b limits st (block_at b block) (block_at b (block+1))).
Proof.
 intros [_ [_ [[lo_nonnegative span] [cap safe]]]] saved;set (lo:=block_at b block) in *;set (hi:=block_at b (block+1)) in *.
 assert (all:forall j,lo<=j<=hi -> between_seeds (base_order g) (crossed_block g b limits st lo j)).
 { intros j pos;remember (Z.to_nat (j-lo)) as n eqn:E;revert j pos E;induction n as [|n IH];intros j pos E.
   - assert (j=lo) by lia;subst j;unfold crossed_block;rewrite sublist_nil by lia;exact saved.
   - set (k:=j-1);assert (kpos:lo<=k<hi) by (unfold k;lia).
     replace j with (k+1) by (unfold k;lia);rewrite crossed_next by lia;unfold process_qubit.
     apply remember_column_at_rest;[apply safe;lia|apply IH;unfold k;lia]. }
 apply all;lia.
Qed.
