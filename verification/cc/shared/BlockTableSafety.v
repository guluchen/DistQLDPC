(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.zlist.list_solver.
Require Import SeedColumnModel SeedPolicyView SeedBlockModel SeedBlockView SeedTableSafety.
Local Open Scope Z_scope.

Definition valid_seed_tables n base st :=
 usable_defaults n base (exhausted_fallback st) /\ live_choices n base (live_rows st).
Lemma remember_valid_row n base limits q st word :
 valid_seed_tables n base st -> 0<=q<n -> n<=Int.max_signed ->
 Int.unsigned word<Zlength base -> valid_seed_tables n base (remember_row limits base q st word).
Proof.
 intros initial seed cap bound;pose proof (Int.unsigned_range_2 word);set (r:=Int.unsigned word) in *.
 unfold remember_row;fold r;destruct Z_lt_dec;[assumption|];destruct Z_lt_dec;[|assumption].
 destruct initial as [[len chosen] live];split;cbn [live_rows exhausted_fallback].
 - split;[rewrite upd_Znth_Zlength by lia;assumption|];intros k index enabled.
   destruct (chosen k index enabled) as [base_ok fb_ok];split;[assumption|].
   destruct (Z.eq_dec k r) as [->|diff].
   + rewrite upd_Znth_same by lia;rewrite Int.signed_repr by rep_lia;lia.
   + rewrite upd_Znth_diff by lia;assumption.
 - apply change_live_choice;try assumption;lia.
Qed.

Lemma valid_remember_prefix n base limits q st rows :
 0<=q<n -> n<=Int.max_signed ->
 Forall (fun word=>Int.unsigned word<Zlength base) rows -> valid_seed_tables n base st ->
 valid_seed_tables n base (fold_left (remember_row limits base q) rows st).
Proof.
 intros seed cap checked;revert st;induction checked;intros st good;cbn [fold_left];auto.
 apply IHchecked;apply remember_valid_row;assumption.
Qed.
Definition safe_incidence n g := forall q,0<=q<n ->
 q+1<Zlength (col_starts g) /\ 0<=index_at g q<=index_at g (q+1) /\
 index_at g (q+1)<=Zlength (col_rows g) /\
 forall k,index_at g q<=k<index_at g (q+1) -> Int.unsigned (Znth k (col_rows g))<Zlength (base_order g).

Lemma valid_block_column n g limits q st :
 0<=q<n -> n<=Int.max_signed -> safe_incidence n g ->
 Zlength limits=Zlength (base_order g) -> valid_seed_tables n (base_order g) st ->
 inner_safe g limits q st /\ valid_seed_tables n (base_order g) (before_row g limits q st (index_at g (q+1))).
Proof.
 intros seed cap all lengths initial;destruct (all q seed) as [room [span [end_ok ids]]].
 assert (scan:forall j,index_at g q<=j<=index_at g (q+1) ->
   valid_seed_tables n (base_order g) (before_row g limits q st j)).
 { intros j within;unfold before_row,remember_column;apply valid_remember_prefix;try assumption.
   apply slice_indices;try lia;intros k pos;apply ids;lia. }
 split;[|apply scan;lia].
 split;[lia|];do 3 (split;[assumption|]);intros j within;specialize (ids j within).
 destruct (scan j ltac:(lia)) as [[fallback_length _] [rows [qubits valid]]].
 pose proof (Int.unsigned_range_2 (Znth j (col_rows g))).
 split;[lia|];split;[lia|];intros enabled missing.
 specialize (valid _ (conj (proj1 (Int.unsigned_range_2 _)) ids) enabled);repeat split;lia.
Qed.

Theorem csr_exhausted_orbit_safe n g b limits i st :
 n<=Int.max_signed -> safe_incidence n g -> Zlength limits=Zlength (base_order g) ->
 0<=i<Int.max_signed -> i+1<Zlength (block_offsets b) ->
 0<=block_at b i<=block_at b (i+1) -> block_at b (i+1)<=Zlength (block_members b) ->
 (forall j,block_at b i<=j<block_at b (i+1) -> Int.unsigned (Znth j (block_members b))<n) ->
 valid_seed_tables n (base_order g) st ->
 block_safe g b limits i st /\ valid_seed_tables n (base_order g)
   (crossed_block g b limits st (block_at b i) (block_at b (i+1))).
Proof.
 intros cap valid len ix room span end_ok ids initial;set (lo:=block_at b i) in *;set (hi:=block_at b (i+1)) in *.
 assert (scan:forall j,lo<=j<=hi -> valid_seed_tables n (base_order g) (crossed_block g b limits st lo j)).
 { intros j within;unfold crossed_block.
   pose proof (slice_indices (block_members b) (fun word=>Int.unsigned word<n) lo j
      ltac:(lia) ltac:(lia) ltac:(intros;apply ids;lia)) as legal.
   generalize dependent st;induction legal as [|word words pos legal IH];intros st initial;cbn [fold_left];auto.
   apply IH;unfold process_qubit;pose proof (Int.unsigned_range_2 word).
   exact (proj2 (valid_block_column n g limits (Int.unsigned word) st ltac:(lia) cap valid len initial)). }
 split;[|apply scan;lia];do 4 (split;[assumption|]).
 intros j pos;pose proof (Int.unsigned_range_2 (Znth j (block_members b))).
 exact (proj1 (valid_block_column n g limits (Int.unsigned (Znth j (block_members b))) _
   (conj (proj1 (Int.unsigned_range_2 _)) (ids j pos)) cap valid len (scan j ltac:(lia)))).
Qed.
