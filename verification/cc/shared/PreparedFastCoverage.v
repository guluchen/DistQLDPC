(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto.
From mathcomp Require Import all_ssreflect all_algebra.
Require Import LeafMatrix MinimumPrefix LevelSearch PCMLeafAPI LeafAPI PackedDetector VerifClosesBody
 VerifFlipBody NativeFlipPayload PreparedMatrixResponse PreparedMatrixPath PreparedPairEvent
 PreparedLeafVisit PreparedLeafMinimum PreparedChildPrefix PreparedPCMLeafVisit PreparedTargetCoverage
 PreparedResidualIndex PreparedScanFromPCM OverlapColumnState OverlapView PreparedDepthSpec
 PreparedBudgetContract PreparedChildMode PreparedSiblingScan RowTally IndexRowBridge.
Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.
Local Open Scope ring_scope.
Local Delimit Scope Z_scope with coqZ.

Section Coverage.
Variables m n k:nat.
Variables (H:'M['F_2]_(m,n)) (G:'M['F_2]_(k,n)).

(* A node reporting EMPTY rules out every minimum logical completion one
   qubit above its current weight. This report names the actual C prefix. *)
Definition one_step_report:budget_report:=fun _ _ st words code _ =>
 let P:=@prefix_set n words in let F:=@available_now n st in
 forall x,minimum H G x -> #|support x|=(#|P|).+1 -> P!=set0 -> P \subset support x ->
     support x :\: P \subset F -> code<>0%coqZ.

Theorem physical_result_covers_minima st words t rowkey depth q cur code tail:
 pcm_response H G rowkey (indicator (@prefix_set n words)) t ->
 pair_observation t (pcm_completion H G (@prefix_set n words) (@available_now n st)) (Z.of_nat n)
   depth q cur code tail ->
 forall w geom,one_step_report w geom st words code tail.
Proof.
 move=> physical [event [branch [-> _]]] w geom;unfold one_step_report;cbn zeta.
 move=>x best size positive sub allowed.
 eapply one_missing_qubit_prevents_empty;[exact best|exact size|exact positive|exact sub|
    exact allowed|exact physical|exact branch].
Qed.

Variables (parent row:seq 'I_n) (root:snapshot) (r:'I_m) (x:'cV['F_2]_n).
Let P:=[set q:'I_n | q \in parent].
Let F:=@available_now n root.
Let cols:=map Int.unsigned (free_row (blocked root) (map (@address n) row)).

Theorem physical_two_move_scan_keeps_minimum w geom stop code tail:
 (Z.of_nat n<=Int.max_signed)%coqZ -> Zlength (blocked root)=Z.of_nat n ->
 (forall q:'I_n,H r q!=0 -> q \in row) -> uniq row ->
 minimum H G x -> #|support x|=(#|P|).+2 ->
 P \subset support x -> (H*m indicator P) r 0!=0 -> support x :\: P \subset F ->
 scan_outcome_mode false (one_step_report w) geom root cols (literal_path parent) stop code tail ->
 code<>0%coqZ.
Proof.
 move=> dim words incident unique best size inside odd allowed recorded.
 have unsigned:(Z.of_nat n<=Int.max_unsigned)%coqZ by move:dim;change Int.max_signed with 2147483647%coqZ;
    change Int.max_unsigned with 4294967295%coqZ;lia.
 have [logical _]:=best;have [/eqP closed _]:=elimT andP logical.
 apply:(@selected_odd_row_cannot_exhaust m n H (indicator P) x r row root F false
  (one_step_report w) geom (literal_path parent) stop code tail unsigned words (@available_in_view n root)
  incident unique _ closed odd _ _ _ recorded);rewrite ?support_indicator //.
 move=>j st out free /member_decodes[a [at_index a_missing]] returned;subst j.
 move:a_missing;rewrite inE=>/andP[fresh in_x].
 have cat_path:literal_path (rcons parent a)=literal_path parent++[::Int.repr (Z.of_nat a)]
   by rewrite /literal_path map_rcons -cats1.
 have extended:@prefix_set n (literal_path parent++[::Int.repr (Z.of_nat a)])=a |: P.
 { rewrite -cat_path literal_prefix_set //;apply/setP=>b;by rewrite !inE mem_rcons inE. }
 unfold one_step_report in returned;rewrite extended in returned.
 apply:(returned x best).
 - by rewrite cardsU1 (negbTE fresh) add1n.
 - apply/set0Pn;exists a;apply/setU1P;by left.
 - by rewrite subUset sub1set in_x inside.
 - apply/subsetP=>b;rewrite inE=>/andP[outside belongs].
   apply (proj1 (@available_in_view n st b)).
   move:outside;rewrite inE negb_or=>/andP[other unstored].
   apply free.
   + apply/member_decodes;exists b;split=> //;by rewrite inE unstored belongs.
   + move=> eqn;have E:b=a by apply val_inj;exact:(Nat2Z.inj _ _ eqn).
     by move:other;rewrite E !inE eqxx.
 - reflexivity.
Qed.
End Coverage.
