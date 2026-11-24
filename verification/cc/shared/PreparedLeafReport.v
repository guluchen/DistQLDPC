(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto.
From mathcomp Require Import all_ssreflect all_algebra.
Require Import LeafMatrix MinimumPrefix LevelSearch VerifClosesBody VerifFlipBody VerifOneLeft NativeFlipPayload
 PCMLeafAPI PreparedLeafVisit PreparedChildPrefix PreparedFastCoverage PreparedObservedWitness
 PreparedDepthSpec PreparedChildMode PreparedRecursiveCall PreparedSiblingScan PreparedBudgetContract
 PreparedPairEvent PreparedPCMLeafVisit PreparedMatrixResponse PreparedMatrixPath
 OverlapColumnState OverlapView RowTally IndexRowBridge.
Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.
Local Open Scope ring_scope.
Local Delimit Scope Z_scope with coqZ.

Section PhysicalReport.
Variables m n r k:nat.
Variables (H:'M['F_2]_(m,n)) (S:'M['F_2]_(r,n)) (G:'M['F_2]_(k,n)).
Definition reported_len w code:=if Z.eq_dec code 3 then (w-1)%coqZ else w.
Definition leaf_report:budget_report:=fun w g st words code tail=>
 one_step_report H G w g st words code tail /\
 (code=0%coqZ \/ witness_status code) /\
 (witness_status code -> stored_css_prefix H S (reported_len w code) tail).

Theorem prepared_leaf_evidence (ids:seq 'I_n) st t rowkey depth q cur code tail g:
 H*m S^T=0 -> G*m S^T=0 -> (\rank (col_mx H G)+\rank S=n)%N ->
 (Z.of_nat n<=Int.max_signed)%coqZ -> uniq ids ->
 (1<=depth)%coqZ -> (depth+1<Zlength cur)%coqZ -> (depth+1)%coqZ=Z.of_nat (size ids) ->
 let node:=PreparedChildCall.append_qubit cur depth q in node=literal_path ids ->
 let P:=@prefix_set n node in pcm_response H G rowkey (indicator P) t ->
 pair_observation t (pcm_completion H G P (@available_now n st)) (Z.of_nat n) depth q cur code tail ->
 leaf_report (depth+2)%coqZ g st node code tail.
Proof.
 move=> orth det rank_ok dim unique fit room count node trace P live result.
 split;first exact:(physical_result_covers_minima live result).
 split.
 - have [e [_ [-> _]]]:=result;case:e=>[z|];rewrite /pair_code /witness_status.
   + by rewrite /final_pick;case:(Z_lt_dec z 0);auto.
   + by case: (PackedDetector.packed_detects _);auto.
 - move=>found;have members:P=[set a:'I_n | a \in ids] by rewrite /P trace literal_prefix_set.
   rewrite members in result live.
   have record:=@observed_witness_has_valid_length m n k r H S G ids (@available_now n st) rowkey t
      depth q cur code tail orth det rank_ok dim unique fit room count trace live result found.
   unfold reported_len;destruct (Z.eq_dec code 3);[replace (depth+2-1)%coqZ with (depth+1)%coqZ by lia|];exact record.
Qed.

Theorem conclude_leaf_scan w g root (parent row:seq 'I_n) stop code tail:
 let cols:=map Int.unsigned (free_row (blocked root) (map (@address n) row)) in
 scan_outcome_mode false (leaf_report w) g root cols (literal_path parent) stop code tail ->
 scan_outcome_mode false (one_step_report H G w) g root cols (literal_path parent) stop code tail /\
 (code=0%coqZ \/ (witness_status code /\ stored_css_prefix H S (reported_len w code) tail)).
Proof.
 move=> cols [prior last].
 have weaken:forall i out path,child_evidence_mode false (leaf_report w) g root cols (literal_path parent) i out path ->
      child_evidence_mode false (one_step_report H G w) g root cols (literal_path parent) i out path.
 { move=>i out path [seen [same [valid _]]];by exists seen. }
 split.
 - split.
   + move=>i live;have [cells evidence]:=prior i live;exists cells;exact:(weaken _ _ _ evidence).
   + case:last=>[empty|[live [nonzero evidence]]];[by left|right;split=> //;split=> //;exact:(weaken _ _ _ evidence)].
 - case:last=>[[_ ->]|[_ [nonzero [seen [_ [_ [[empty|found] valid]]]]]]];auto;try contradiction.
Qed.
End PhysicalReport.
