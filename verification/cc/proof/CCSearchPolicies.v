(* Instantiate the generic native pruning contracts for ALL minimum targets.
   Keeps selected/forbidden separation as well as critical-target safety. *)
Require Import VST.floyd.proofauto.
Require Import CCV.CCModel CCV.CCFunctional CCV.CCOverlap CCV.CCOverlapArray
 CCV.CCRepresentation CCV.CCBoundsArray CCV.CCBoundsPolicy CCV.CCMatrixModel.
Open Scope Z_scope.
Definition overlap_rejects_all n hs ls cap xs:=forall e,
 minimum(Z.to_nat n)hs ls e ->Z.of_nat(weight(Z.to_nat n)e)<=cap ->
 ~subset(Z.to_nat n)(decode xs)e.
Definition overlap_allows_all n hs ls cap xs q:=Znth q xs=0 /\forall e,
 minimum(Z.to_nat n)hs ls e ->Z.of_nat(weight(Z.to_nat n)e)<=cap ->
 subset(Z.to_nat n)(decode xs)e ->e(Z.to_nat q)=false.
Theorem universal_overlap_policy n k hs ls xs gs cap:
 0<n ->0<=k ->Zlength xs=n ->Zlength gs=k*n ->
 Forall(fun z:Z=>z=0\/z=1)xs ->Forall(fun z:Z=>z=0\/z=1)gs ->
 (forall i,0<=i<k ->stabilizer_valid(Z.to_nat n)hs ls(CCValidation.row_vector n i gs)) ->
 overlap_policy n k xs gs(overlap_rejects_all n hs ls cap xs)
 (overlap_allows_all n hs ls cap xs).
Proof.
 intros N K Xlen Glen XB GB Valid i I;split.
 - intros Reject e Min Cap.
   pose proof(minimum_implies_overlap_policy n k hs ls xs gs e N K Xlen Glen XB GB Min Valid)as P.
   exact(proj1(P i I)Reject).
 - intros q Q Tight G X;split;[assumption|].
   intros e Min Cap Sub.
   pose proof(minimum_implies_overlap_policy n k hs ls xs gs e N K Xlen Glen XB GB Min Valid)as P.
   exact(proj2(P i I)q Q Tight G X Sub).
Qed.
Definition bounds_rejects_all n m h ls cap xs fs:=forall e,
 minimum(Z.to_nat n)(matrix_vectors n m h)ls e ->
 Z.of_nat(weight(Z.to_nat n)e)<=cap ->
 ~compatible(Z.to_nat n)e(decode xs)(decode fs).
Lemma compatible_minimum_budget n m h ls xs fs ys remaining cap e:
 0<=m ->cached n m xs ys h ->
 Z.of_nat(weight(Z.to_nat n)(decode xs))+remaining=cap ->
 minimum(Z.to_nat n)(matrix_vectors n m h)ls e ->
 Z.of_nat(weight(Z.to_nat n)e)<=cap ->
 compatible(Z.to_nat n)e(decode xs)(decode fs) ->
 target_budget n m h xs fs ys remaining e.
Proof.
 intros M Cache Sum Min Cap Compat;split;[|lia].
 split;[assumption|split;[assumption|]].
 apply matrix_kernel_indexed;[assumption|].
 exact(proj1(proj2(proj1 Min))).
Qed.
Theorem universal_bounds_policy n m h ls xs fs ys remaining cap:
 0<=n ->0<=m ->Zlength xs=n ->Zlength fs=n ->
 Forall(fun z:Z=>z=0\/z=1)xs ->Forall(fun z:Z=>z=0\/z=1)fs ->
 cached n m xs ys h ->Z.of_nat(weight(Z.to_nat n)(decode xs))+remaining=cap ->
 bounds_policy n m h xs fs ys remaining(bounds_rejects_all n m h ls cap xs fs).
Proof.
 intros N M Xlen Flen XB FB Cache Sum;split.
 - intros i I Odd Empty e Min Cap Compat.
   pose proof(target_bounds_policy n m h xs fs ys remaining e N M Xlen Flen XB FB)as P.
   apply(proj1 P i I Odd Empty).
   apply(compatible_minimum_budget n m h ls xs fs ys remaining cap e);assumption.
 - split.
   + intros rows Packed Big e Min Cap Compat.
     pose proof(target_bounds_policy n m h xs fs ys remaining e N M Xlen Flen XB FB)as P.
     apply(proj1(proj2 P)rows Packed Big).
     apply(compatible_minimum_budget n m h ls xs fs ys remaining cap e);assumption.
   + intros d D Upper Odd Reject e Min Cap Compat.
     pose proof(target_bounds_policy n m h xs fs ys remaining e N M Xlen Flen XB FB)as P.
     apply(proj2(proj2 P)d D Upper Odd Reject).
     apply(compatible_minimum_budget n m h ls xs fs ys remaining cap e);assumption.
Qed.
Print Assumptions universal_overlap_policy.
Print Assumptions universal_bounds_policy.
