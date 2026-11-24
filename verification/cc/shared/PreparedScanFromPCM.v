(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto.
From mathcomp Require Import all_ssreflect all_algebra.
Require Import LeafMatrix MinimumPrefix RowTally IndexRowBridge PreparedResidualIndex
 VerifChildVisit EnabledCall EnabledLoopFacts OverlapChildState OverlapColumnState OverlapTargetProgress ChildColumn
 PreparedRecursiveCall PreparedDepthSpec PreparedSiblingScan PreparedTargetCoverage PreparedPlainCoverage.
Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.
Local Open Scope ring_scope.
Local Delimit Scope Z_scope with coqZ.

Section Physical.
Variables m n:nat.
Variables (H:'M['F_2]_(m,n)) (prefix target:'cV['F_2]_n) (r:'I_m) (ids:seq 'I_n).
Variables (root:snapshot) (allowed:{set 'I_n}).
Let blocks:=blocked root.
Let T:=support target :\: support prefix.
Let wanted:=physical_member T.
Let xs:=map Int.unsigned (free_row blocks (map (@address n) ids)).

Theorem selected_odd_row_cannot_exhaust update (rep:node_report) g path stop code tail:
 (Z.of_nat n<=Int.max_unsigned)%coqZ -> Zlength blocks=Z.of_nat n ->
 (forall q:'I_n,Znth (Z.of_nat q) blocks=Int.zero <-> q \in allowed) ->
 (forall q:'I_n,H r q!=0 -> q \in ids) -> uniq ids ->
 support prefix \subset support target -> H*m target=0 -> (H*m prefix) r 0!=0 -> T \subset allowed ->
 (update=true -> forall i,(0<=i<Zlength xs)%coqZ -> wanted (Znth i xs)=true ->
  let st:=sibling_state root xs (i+1)%coqZ in column_bounds g (Znth i xs) st /\
  forall a,wanted a=true -> a<>Znth i xs -> ~List.In a (new_blocks g (Znth i xs) st)) ->
 (forall q seen returned,residual_free wanted q (blocked seen) ->
    wanted q=true -> ~rep g seen (path++[::Int.repr q]) 0%coqZ returned) ->
 scan_outcome_mode update rep g root xs path stop code tail -> code<>0%coqZ.
Proof.
 move=> cap dim mem incident unique sub closed odd free overlap children evidence.
 have [valid available]:=@emitted_range_and_availability n ids blocks allowed cap dim mem.
 have [admitted touch]:=@residual_inputs_for_scan m n H prefix target r ids blocks allowed cap dim mem
   incident sub closed odd free.
 have no_repeat:=@emitted_unique n ids blocks allowed cap mem unique.
 exact:(@retained_target_with_cached_flag update rep g root xs path stop code tail wanted
  valid no_repeat available admitted touch overlap children evidence).
Qed.
End Physical.
