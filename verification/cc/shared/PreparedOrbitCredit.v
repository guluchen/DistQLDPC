(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.zlist.list_solver SeedExemptionState SeedColumnModel
 SeedPolicyView SeedBlockModel SeedBlockView SeedTableSafety BlockTableSafety SeedTransferTrace
 ActualOrbitCommit SeedOrbitStorage SiblingCounters VerifOrbitBlock.
Local Open Scope Z_scope.

(* An exhausted orbit makes two changes to the same block counters.
   First C counts its members, then the seed callback may move an
   exemption as it records a row's earliest exhausted coordinate. *)
Lemma first_fallback_keeps_credit n base limits q st word a:
 valid_seed_tables n base st -> Zlength limits=Zlength base -> n<=Int.max_signed ->
 0<=a<n -> 0<=q<n -> Int.unsigned word<Zlength base ->
 conserved a limits (live_rows (remember_row limits base q st word))=conserved a limits (live_rows st).
Proof.
 intros [_ [shape [size live]]] caps fits pos chosen row;pose proof (Int.unsigned_range_2 word).
 unfold remember_row;destruct Z_lt_dec;[reflexivity|];destruct Z_lt_dec;[|reflexivity];cbn [live_rows].
 apply preserves_credit;try lia.
 specialize (live (Int.unsigned word) ltac:(lia) ltac:(lia));lia.
Qed.

Lemma remember_rows_keeps_credit n base limits q a rows st:
 Zlength limits=Zlength base -> n<=Int.max_signed -> 0<=a<n -> 0<=q<n ->
 Forall (fun row=>Int.unsigned row<Zlength base) rows -> valid_seed_tables n base st ->
 conserved a limits (live_rows (fold_left (remember_row limits base q) rows st))=conserved a limits (live_rows st).
Proof.
 intros size fits pos chosen bounded;revert st;induction bounded;intros st initial;cbn [fold_left];[reflexivity|].
 rewrite IHbounded by (apply remember_valid_row with (n:=n);assumption).
 eapply first_fallback_keeps_credit;eassumption.
Qed.

Lemma visited_members_keep_credit n g limits a ws st:
 Zlength limits=Zlength (base_order g) -> n<=Int.max_signed -> 0<=a<n -> safe_incidence n g ->
 Forall (fun w=>Int.unsigned w<n) ws -> valid_seed_tables n (base_order g) st ->
 conserved a limits (live_rows (fold_left (process_qubit g limits) ws st))=conserved a limits (live_rows st).
Proof.
 intros caps fits pos csr within;revert st;induction within as [|v ws member more IH];intros st good;cbn [fold_left];[reflexivity|].
 pose proof (Int.unsigned_range_2 v).
 rewrite IH by (apply (proj2 (valid_block_column n g limits (Int.unsigned v) st ltac:(lia) fits csr caps good))).
 unfold process_qubit,before_row,remember_column.
 apply (@remember_rows_keeps_credit n);try assumption;try lia.
 destruct (csr (Int.unsigned v) ltac:(lia)) as [key [bounds [available inside]]].
 apply slice_indices;try lia;assumption.
Qed.

Theorem exhausted_seed_changes_only_orbit_members n g b limits i st a:
 Zlength limits=Zlength (base_order g) -> n<=Int.max_signed -> 0<=a<n -> safe_incidence n g ->
 valid_seed_tables n (base_order g) st -> in_array n (raw_members b) ->
 let members:=sublist (block_at b i) (block_at b (i+1)) (raw_members b) in
 conserved a limits (live_rows (after_exhaustion g b limits i st))=
 Int.add (conserved a limits (live_rows st)) (Int.repr (visits members a)).
Proof.
 intros caps fits pos csr good legal members.
 destruct good as [defaults [shape [extent allowed]]].
 assert (width:Zlength (orbit_counts b i st)=n).
 { unfold orbit_counts;rewrite scanned_length;[assumption|rewrite extent;assumption]. }
 assert (changed:valid_seed_tables n (base_order g) (after_counts b i st)).
 { split;[exact defaults|];unfold live_choices,after_counts,replace_counts;cbn [live_rows exempts reference_counts];auto. }
 assert (range:Forall (fun w=>Int.unsigned w<n) (block_members b)).
 { apply Forall_forall;intros x inside;assert (In (Int.unsigned x) (raw_members b)) by (apply in_map;assumption).
   apply (proj1 (Forall_forall _ _)) with (x:=Int.unsigned x) in legal;[lia|assumption]. }
 unfold after_exhaustion,crossed_block;rewrite (@visited_members_keep_credit n g limits a _ _ caps fits pos csr
   (Forall_sublist _ _ _ _ range) changed).
 unfold after_counts,replace_counts,conserved;cbn [live_rows reference_counts exempts].
 unfold orbit_counts,scanned;fold members;rewrite sweep_cell by (try (rewrite extent);try lia;apply Forall_sublist;exact legal).
 rewrite Z.mul_1_l,!Int.add_assoc;f_equal;apply Int.add_commut.
Qed.
