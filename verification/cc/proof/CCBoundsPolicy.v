(* Contracts for precisely the three rejection branches of the C bounds scan.
   A numeric array model is checked here; the C loop refinement is separate. *)
Require Import VST.floyd.proofauto.
Require Import CCV.CCModel CCV.CCFunctional CCV.CCWord CCV.CCRepresentation CCV.CCBoundsArray.
Open Scope Z_scope.
Definition degree_upper n m h xs fs ys d :=
 forall q,0<=q<n ->Znth q xs=0 ->Znth q fs=0 ->degree_count m n q h ys<=d.
Definition bounds_policy n m h xs fs ys remaining (Bad:Prop) :=
 (forall i,0<=i<m ->Znth i ys<>0 ->candidate_count n n i h xs fs=0 ->Bad) /\
 (forall rows,packed_family n m h xs fs ys rows ->Z.of_nat(length rows)>remaining ->Bad) /\
 (forall d,0<=d ->degree_upper n m h xs fs ys d ->odd_count m ys>0 ->
   (d=0 \/ (0<d /\ ceil_Z(odd_count m ys) d>remaining)) ->Bad).
Definition target_budget n m h xs fs ys remaining e :=
 indexed_target n m h xs fs ys e /\
 Z.of_nat(CCModel.weight(Z.to_nat n)e)<=Z.of_nat(CCModel.weight(Z.to_nat n)(decode xs))+remaining.
Theorem target_bounds_policy n m h xs fs ys remaining e :
 0<=n ->0<=m ->Zlength xs=n ->Zlength fs=n ->
 Forall(fun z:Z=>z=0 \/ z=1) xs ->Forall(fun z:Z=>z=0 \/ z=1) fs ->
 bounds_policy n m h xs fs ys remaining (~target_budget n m h xs fs ys remaining e).
Proof.
 intros N M Xlen Flen Xb Fb;unfold bounds_policy.
 split.
 - intros i I Odd Empty [Target Budget].
   assert(R:(Z.to_nat i<Z.to_nat m)%nat) by(apply Z2Nat.inj_lt;lia).
   assert(C:candidate_count n n (Z.of_nat(Z.to_nat i)) h xs fs<>0).
   { apply(indexed_empty_reject n m h xs fs ys e (Z.to_nat i));try assumption;rewrite Z2Nat.id by lia;assumption. }
   rewrite Z2Nat.id in C by lia;contradiction.
 - split.
   + intros rows Packed Big [Target Budget].
     pose proof(indexed_packing_bound n m h xs fs ys e rows M Target Packed) as Bound.
     destruct Target as [[Sub Avoid] _].
     pose proof(subset_split (Z.to_nat n)(decode xs)e Sub) as Split.
     apply(f_equal Z.of_nat)in Split;rewrite Nat2Z.inj_add in Split;lia.
   + intros d D Upper Odd Reject [Target Budget].
     pose proof(indexed_charge_bound n m h xs fs ys e d N M D Target Upper Xlen Flen Xb Fb) as Bound.
     destruct Target as [[Sub Avoid] _].
     pose proof(subset_split (Z.to_nat n)(decode xs)e Sub) as Split.
     apply(f_equal Z.of_nat)in Split;rewrite Nat2Z.inj_add in Split.
     destruct Reject as [Dz|[Dp Big]].
     * subst d;nia.
     * assert(Ceil:ceil_Z(odd_count m ys) d<=remaining).
       { apply(proj2(ceil_Z_minimal (odd_count m ys) d remaining ltac:(lia) Dp));nia. }
       lia.
Qed.
Print Assumptions target_bounds_policy.
