(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VerifDetected VerifChildVisit SiblingCounters EnabledCall EnabledLoopFacts OverlapChildState
 OverlapColumnState OverlapTargetProgress ChildColumn PreparedRecursiveCall PreparedDepthSpec PreparedSiblingScan.
Local Open Scope Z_scope.

Definition residual_free (target:Z->bool) (chosen:Z) (blocked_words:list int):=
 forall a,target a=true -> a<>chosen -> Znth a blocked_words=Int.zero.

(* A deadline can legitimately interrupt the first surviving child. Only an
   EMPTY result asserts that no target completion existed. *)
Theorem physical_target_prevents_empty (rep:node_report) g root xs prefix stop r tail (target:Z->bool):
 in_array (Zlength (blocked root)) xs -> NoDup xs ->
 Forall (fun q=>Znth q (blocked root)=Int.zero) xs ->
 (forall q,target q=true -> 0<=q<Zlength (blocked root) /\ Znth q (blocked root)=Int.zero) ->
 (exists q,In q xs /\ target q=true) ->
 (forall i,0<=i<Zlength xs -> target (Znth i xs)=true -> let st:=sibling_state root xs (i+1) in
   column_bounds g (Znth i xs) st /\ forall a,target a=true -> a<>Znth i xs -> ~In a (new_blocks g (Znth i xs) st)) ->
 (forall q seen returned,residual_free target q (blocked seen) ->
    target q=true -> ~rep g seen (prefix++[Int.repr q]) 0 returned) ->
 scan_outcome rep g root xs prefix stop r tail -> r<>0.
Proof.
 intros bounds unique usable admitted touches overlap child [prior [[complete empty]|[within [nonzero record]]]];[|assumption].
 destruct (physical_first_target g root xs target bounds unique usable admitted touches overlap) as [i [index [wanted free]]].
 subst stop;destruct (prior i index) as [out [seen [[S B] returned]]].
 exfalso;eapply (child _ seen out);[unfold residual_free;rewrite B;exact free|exact wanted|exact returned].
Qed.
