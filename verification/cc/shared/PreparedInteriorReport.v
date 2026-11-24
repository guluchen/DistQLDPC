(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto.
From mathcomp Require Import all_ssreflect all_algebra.
Require Import LeafMatrix MinimumPrefix LevelSearch PreparedMatrixPath PreparedChildPrefix PreparedObservedWitness
 PreparedPCMLeafVisit PreparedResidualIndex PreparedScanFromPCM PreparedTargetCoverage PreparedOverlapDepth
 PreparedChildMode PreparedDepthSpec PreparedBudgetContract PreparedSiblingScan PreparedRecursiveCall
 OverlapColumnState OverlapChildState OverlapTargetProgress EnabledLoopFacts ChildColumn RowTally IndexRowBridge.
Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.
Local Open Scope ring_scope.
Local Delimit Scope Z_scope with coqZ.

Section Reports.
Variables m n r k:nat.
Variables (H:'M['F_2]_(m,n)) (S:'M['F_2]_(r,n)) (G:'M['F_2]_(k,n)).
Variable admissible_target:seq Integers.int -> 'cV['F_2]_n -> Prop.
(* Polling can interrupt any nonleaf recursive call. EMPTY excludes all
   compatible minima at the active weight. A shorter witness has its
   own length, which must survive arbitrarily many caller frames. *)
Definition recursive_result w st words code tail:Prop:=
 let P:=@prefix_set n words in let F:=@available_now n st in
 (forall x,admissible_target words x -> minimum H G x -> Z.of_nat #|support x|=w -> P \subset support x ->
     support x :\: P \subset F -> code<>0%coqZ) /\
 (code = 1%coqZ -> stored_css_prefix H S w tail) /\
 (code = 3%coqZ -> exists len,(0<len<w)%coqZ /\ stored_css_prefix H S len tail).
Definition recursive_report:budget_report:=fun w _=>recursive_result w.
Variables (root:snapshot) (parent row:seq 'I_n) (check:'I_m) (g:layout) (update:bool).
Let P:=[set q:'I_n | q \in parent].
Let F:=@available_now n root.
Let xs:=map Int.unsigned (free_row (blocked root) (map (@address n) row)).
Hypotheses (nfit:(Z.of_nat n<=Int.max_signed)%coqZ) (size_ok:Zlength (blocked root)=Z.of_nat n)
 (covered:forall q:'I_n,H check q!=0 -> q \in row) (unique:uniq row)
 (odd:(H*m indicator P) check 0!=0).
Hypothesis inherited:forall x (a:'I_n),admissible_target (literal_path parent) x ->
 admissible_target (literal_path parent++[::Int.repr (Z.of_nat a)]) x.
Hypothesis overlap:forall x,admissible_target (literal_path parent) x -> minimum H G x -> P \subset support x -> support x :\: P \subset F ->
 let wanted:=physical_member (support x :\: P) in update=true ->
 forall i,(0<=i<Zlength xs)%coqZ -> wanted (Znth i xs)=true ->
 let st:=sibling_state root xs (i+1)%coqZ in column_bounds g (Znth i xs) st /\
  forall a,wanted a=true -> a<>Znth i xs -> ~List.In a (new_blocks g (Znth i xs) st).

Theorem interior_scan_preserves_weight_and_witness w stop code tail:
 scan_outcome_mode update (recursive_report w) g root xs (literal_path parent) stop code tail ->
 recursive_result w root (literal_path parent) code tail.
Proof.
 move=> scan;split.
 - rewrite (literal_prefix_set parent nfit);move=>x keep best weight inside free.
   have unsigned:(Z.of_nat n<=Int.max_unsigned)%coqZ by move:nfit;change Int.max_signed with 2147483647%coqZ;
     change Int.max_unsigned with 4294967295%coqZ;lia.
   have [/andP[/eqP kernel _] _]:=best.
   apply:(@selected_odd_row_cannot_exhaust m n H (indicator P) x check row root F update (recursive_report w)
      g (literal_path parent) stop code tail unsigned size_ok (@available_in_view n root) covered unique
      _ kernel odd _ _ _ scan);rewrite ?support_indicator //.
   + exact:(overlap keep best inside free).
   + move=>j st path untouched /member_decodes[a [index inres]] result;subst j.
     move:inres;rewrite inE=>/andP[unseen in_x].
     have cat_path:literal_path (rcons parent a)=literal_path parent++[::Int.repr (Z.of_nat a)]
        by rewrite /literal_path map_rcons -cats1.
     have extended:@prefix_set n (literal_path parent++[::Int.repr (Z.of_nat a)])=a |: P.
     { rewrite -cat_path literal_prefix_set //;apply/setP=>b;by rewrite !inE mem_rcons inE. }
     have [child _]:=result;rewrite extended in child.
     apply:(child x (inherited a keep) best weight).
     * by rewrite subUset sub1set in_x inside.
     * apply/subsetP=>b;rewrite inE=>/andP[unmarked within].
       move:unmarked;rewrite inE negb_or=>/andP[other fresh];apply (proj1 (@available_in_view n st b)).
       apply untouched.
       -- apply/member_decodes;exists b;split=> //;by rewrite inE within fresh.
       -- move=>eqn;have E:b=a by apply val_inj;exact:(Nat2Z.inj _ _ eqn).
          by move:other;rewrite E !inE eqxx.
     * reflexivity.
 - have [_ [[_ empty]|[_ [_ [seen [_ [_ [same short]]]]]]]]:=scan.
   + by subst code;split;discriminate.
   + by split.
Qed.
End Reports.
