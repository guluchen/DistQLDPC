(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VerifDetected VerifChildVisit SiblingCounters EnabledCall EnabledLoopFacts
 OverlapChildState OverlapColumnState OverlapTargetProgress ChildColumn SiblingSearchCoverage
 PreparedRecursiveCall PreparedDepthSpec PreparedChildMode PreparedSiblingScan PreparedTargetCoverage.
Local Open Scope Z_scope.

(* With the overlap callback skipped, the only block writes on this edge
   come from selecting a qubit and excluding earlier siblings. *)
Theorem retained_target_with_cached_flag (update:bool) (rep:node_report) g root xs prefix stop r tail (target:Z->bool):
 in_array (Zlength (blocked root)) xs -> NoDup xs ->
 Forall (fun q=>Znth q (blocked root)=Int.zero) xs ->
 (forall q,target q=true -> 0<=q<Zlength (blocked root) /\ Znth q (blocked root)=Int.zero) ->
 (exists q,In q xs /\ target q=true) ->
 (update=true -> forall i,0<=i<Zlength xs -> target (Znth i xs)=true ->
  let st:=sibling_state root xs (i+1) in column_bounds g (Znth i xs) st /\
   forall a,target a=true -> a<>Znth i xs -> ~In a (new_blocks g (Znth i xs) st)) ->
 (forall q seen returned,residual_free target q (blocked seen) ->
    target q=true -> ~rep g seen (prefix++[Int.repr q]) 0 returned) ->
 scan_outcome_mode update rep g root xs prefix stop r tail -> r<>0.
Proof.
 intros bounds unique usable admitted touches overlap child;destruct update.
 - apply physical_target_prevents_empty with (target:=target);auto.
 - intros [prior [[complete empty]|[within [nonzero record]]]];[|assumption].
   destruct (first_entered_child target xs (blocked root) bounds unique usable admitted touches)
    as [i [pos [hit [one free]]]].
   subst stop;destruct (prior i pos) as [out [seen [[S B] returned]]].
   exfalso;eapply (child _ seen out);[unfold residual_free;rewrite B;exact free|exact hit|exact returned].
Qed.
