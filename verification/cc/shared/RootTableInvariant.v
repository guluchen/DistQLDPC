(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.zlist.list_solver.
Require Import VerifOrbitBlock SiblingCounters ActiveChildren SeedStorageTransition SeedOrbitStorage
 SeedPolicyView SeedBlockModel SeedBlockView SeedColumnModel SeedExemptionState SeedResume
 StableSeedPreference PCMSeedSafety SeedTableSafety BlockTableSafety ActualOrbitCommit.
Local Open Scope Z_scope.

Definition tables_at_rest n g st:=
 valid_seed_tables n (base_order g) st /\ between_seeds (base_order g) st.

(* These equations are exactly the three assignments made by the half-level
   initializer. The selection may include disabled (negative) base entries. *)
Theorem initialized_tables_at_rest n g fallback counts events :
 Zlength counts=n -> Zlength fallback=Zlength (base_order g) ->
 (forall k,0<=k<Zlength (base_order g) -> Int.signed (Znth k fallback)<0) ->
 (forall k,0<=k<Zlength (base_order g) -> Int.signed (Znth k (base_order g))<n) ->
 tables_at_rest n g (Build_exhausted_state fallback (Build_moving_state (base_order g) counts events)).
Proof.
 intros size len absent bounded;unfold tables_at_rest,valid_seed_tables,usable_defaults,live_choices,between_seeds.
 cbn [exhausted_fallback live_rows exempts reference_counts];split.
 - split.
   + split;[assumption|];intros k pos enabled;pose proof (absent k pos);pose proof (bounded k pos);lia.
   + split;[reflexivity|];split;[assumption|];intros k pos enabled;pose proof (bounded k pos);lia.
 - intros k pos enabled;split;[lia|];split;[lia|];unfold clear_seed;destruct Z_lt_dec;[rewrite Int.repr_signed;reflexivity|].
   pose proof (absent k pos);lia.
Qed.
Lemma restored_tables_at_rest n g st left:
 tables_at_rest n g st -> same_seed_state left (live_rows st) ->
 tables_at_rest n g (Build_exhausted_state (exhausted_fallback st) left).
Proof.
 intros [[defaults choices] rest] same;unfold tables_at_rest,valid_seed_tables;split.
 - split;cbn [exhausted_fallback live_rows];[exact defaults|].
   destruct same as [ex counts];unfold live_choices;rewrite ex,counts;exact choices.
 - apply stable_exemption_after_search;assumption.
Qed.

Theorem orbit_preserves_tables n g b limits i st :
 n<=Int.max_signed -> safe_incidence n g -> Zlength limits=Zlength (base_order g) ->
 0<=i<Int.max_signed -> i+1<Zlength (block_offsets b) ->
 0<=block_at b i<=block_at b (i+1) -> block_at b (i+1)<=Zlength (block_members b) ->
 in_array n (raw_members b) -> tables_at_rest n g st ->
 block_safe g b limits i (after_counts b i st) /\
 tables_at_rest n g (after_exhaustion g b limits i st).
Proof.
 intros cap valid len ix room span slots ids [[defaults choices] stable].
 destruct choices as [rows [size admissible]].
 assert (unchanged:Zlength (orbit_counts b i st)=n).
 { unfold orbit_counts;rewrite scanned_length;[exact size|rewrite size;assumption]. }
 assert (new:valid_seed_tables n (base_order g) (after_counts b i st)).
 { split;[exact defaults|];unfold after_counts,replace_counts,live_choices.
   cbn [live_rows exempts reference_counts];auto. }
 assert (in_range:forall j,block_at b i<=j<block_at b (i+1) ->
  Int.unsigned (Znth j (block_members b))<n).
 { intros j within;unfold in_array in ids;rewrite Forall_forall in ids.
   assert (member:In (Int.unsigned (Znth j (block_members b))) (raw_members b)).
   { unfold raw_members;apply in_map;apply Znth_In;lia. }
   exact (proj2 (ids _ member)). }
 destruct (csr_exhausted_orbit_safe n g b limits i (after_counts b i st)
   cap valid len ix room span slots in_range new) as [safe after].
 split;[exact safe|];split;[exact after|];apply exhausted_orbit_keeps_preference;[exact safe|exact stable].
Qed.
