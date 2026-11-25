(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.zlist.list_solver RowTally RowGather PreparedGatherCandidates.
From mathcomp Require Import all_ssreflect all_algebra.
Require Import LeafMatrix MinimumPrefix LevelSearch IndexRowBridge.
Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.
Local Delimit Scope Z_scope with coqZ.

(* The constructor appends the sorted row at the offset equal to the
   number of entries in preceding rows. Empty rows occupy zero slots. *)
Lemma row_between_offsets (prefix row suffix:seq Integers.int):
 sublist (Zlength prefix) (Zlength prefix+Zlength row) (prefix++row++suffix)=row.
Proof.
 pose proof (Zlength_nonneg prefix);pose proof (Zlength_nonneg row);pose proof (Zlength_nonneg suffix).
 rewrite sublist_app2;try lia.
 rewrite Z.sub_diag;replace (Zlength prefix+Zlength row-Zlength prefix)%coqZ with (Zlength row) by lia.
 rewrite sublist_app1;try lia;rewrite sublist_same;auto;lia.
Qed.

Section Row.
Variables n:nat.
Variables (previous following:seq (seq 'I_n)) (row:seq 'I_n) (F:{set 'I_n}) (blocks:seq Integers.int).
Hypotheses (fits:(Z.of_nat n<=Int.max_unsigned)%coqZ)
 (available:forall a:'I_n,Znth (Z.of_nat a) blocks=Int.zero <-> a \in F).
Let words (rs:seq (seq 'I_n)):=List.concat (map (map (@address n)) rs).
Let begin:=Zlength (words previous).
Let after_row:=(begin+Zlength (map (@address n) row))%coqZ.

Theorem constructed_row_candidates:
 gathered blocks (words (previous++row::following)) begin after_row =
 map (@address n) [seq a <- row | a \in F].
Proof.
 unfold gathered,words,begin,after_row;rewrite map_cat List.concat_app;cbn [map List.concat].
 rewrite row_between_offsets;exact:(@physical_free_row n F blocks fits available row).
Qed.
End Row.

Local Open Scope ring_scope.
Section ChosenCheck.
Variables m checks n:nat.
Variables (H:'M['F_2]_(m,n)) (combine:'M['F_2]_(checks,m)) (check:'I_checks).
Let valid_checks:=combine*m H.
Variables (row:seq 'I_n) (previous following:seq (seq 'I_n)) (x y:'cV['F_2]_n)
 (F:{set 'I_n}) (blocks:seq Integers.int).
Let addresses:=map (@address n).
Let acc rs:=List.concat (map addresses rs).
Let lo:=Zlength (acc previous).
Let hi:=(lo+Zlength (addresses row))%coqZ.

(* Both original rows and pair-XOR rows are linear combinations of H.
   A choice from either CSR table preserves a path to every still
   available completion whenever the chosen check really is odd. *)
Theorem selected_table_row_hits_residual:
 (Z.of_nat n<=Int.max_unsigned)%coqZ ->
 (forall q:'I_n,Znth (Z.of_nat q) blocks=Int.zero <-> q \in F) ->
 (forall q:'I_n,valid_checks check q!=0 -> q \in row) ->
 H*m y=0 -> (valid_checks*m x) check 0!=0 ->
 support x \subset support y -> support y :\: support x \subset F ->
 exists q, q \in support y :\: support x /\
   List.In (address q) (gathered blocks (acc (previous++row::following)) lo hi).
Proof.
 move=> fits available covers closed odd inside free.
 have kernel:valid_checks*m y=0 by rewrite /valid_checks -mulmxA closed mulmx0.
 have [q [need incident]]:=@odd_row_hits_residual checks n valid_checks x y check inside kernel odd.
 exists q;split=> //.
 rewrite (@constructed_row_candidates n previous following row F blocks fits available).
 apply List.in_map.
 have to_list (ls:seq 'I_n):q \in ls -> List.In q ls.
 { elim:ls=>[|a ls ih] //=;rewrite inE=> /orP[/eqP ->|later];[by left|right;exact:ih later]. }
 apply to_list;by rewrite mem_filter (subsetP free q need) (covers q incident).
Qed.
End ChosenCheck.

Require VerifDetected VerifChildVisit PreparedCandidateArena OverlapRowSpecs OverlapView.
#[local] Instance GatherLevelLayout:change_composite_env CandidateSpecs VerifDetected.CompSpecs.
 make_cs_preserve CandidateSpecs VerifDetected.CompSpecs.
Qed.
#[local] Instance GatherBlockLayout:change_composite_env CandidateSpecs OverlapRowSpecs.OverlapSpecs.
 make_cs_preserve CandidateSpecs OverlapRowSpecs.OverlapSpecs.
Qed.

(* The real C++ chooser and the C stack use the same blocked words and
   candidate buffer. There is no copy or new allocation at either boundary. *)
Lemma gather_reads_level_blocks bs bp:(0<Zlength bs)%coqZ ->
 @data_at CandidateSpecs Tsh (tarray tuint (Zlength bs)) (map Vint bs) bp=
 OverlapRowSpecs.array32 bs bp.
Proof.
 move=>positive;rewrite OverlapRowSpecs.stored_array //.
 erewrite (@data_at_change_composite CandidateSpecs OverlapRowSpecs.OverlapSpecs _ Tsh
   (tarray tuint (Zlength bs)) (map Vint bs) (map Vint bs));[reflexivity|apply JMeq_refl|reflexivity].
Qed.

Lemma selector_hands_row_to_dfs (bs row:seq Integers.int) (old:seq Values.val) ptr:
 let picks:=free_row bs row in let xs:=map Int.unsigned picks in let stride:=Zlength old in
 (Zlength picks<=stride)%coqZ ->
 @data_at CandidateSpecs Tsh (tarray tuint stride) (written_values (map Vint picks) old) ptr |--
 (VerifChildVisit.child_array ptr xs * PreparedCandidateArena.spare_words ptr stride xs)%logic.
Proof.
 move=>picks xs stride fits.
 erewrite (@data_at_change_composite CandidateSpecs VerifDetected.CompSpecs _ Tsh (tarray tuint stride)
  (written_values (map Vint picks) old) (written_values (map Vint picks) old));[|apply JMeq_refl|reflexivity].
 have repr_words (ls:seq Integers.int):List.map (fun q=>Vint (Int.repr q)) (map Int.unsigned ls)=map Vint ls.
 { elim:ls=>[|a rest ih] //=;by rewrite Int.repr_unsigned ih. }
 unfold VerifChildVisit.child_array,PreparedCandidateArena.spare_words,written_values,xs;rewrite repr_words !Zlength_map.
 rewrite (@split2_data_at_Tarray_app VerifDetected.CompSpecs (Zlength picks) stride Tsh tuint
    (map Vint picks) (sublist (Zlength picks) (Zlength old) old) ptr).
 - apply sepcon_derives;[apply derives_refl|apply data_at_data_at_].
 - apply Zlength_map.
 - change (Zlength picks<=Zlength old)%coqZ in fits.
   pose proof (Zlength_nonneg picks).
   rewrite Zlength_sublist;try lia;reflexivity.
Qed.
