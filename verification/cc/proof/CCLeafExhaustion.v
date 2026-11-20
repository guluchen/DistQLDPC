(* Numeric leaf exhaustion rules out all compatible minimum targets at unit
   remaining weight. This connects the verified numeric miss contract to CC. *)
Require Import VST.floyd.proofauto.
Require Import CCV.CCModel CCV.CCCache CCV.CCFunctional CCV.CCRepresentation CCV.CCMatrixModel
 CCV.CCLeaf CCV.CCLeafTarget CCV.CCPhaseZero.
Open Scope Z_scope.
Theorem numeric_leaf_exhaustion n m l h lg xs fs ys zs cap e:
 0<n ->0<=m ->0<=l ->Zlength xs=n ->Zlength fs=n ->
 Zlength h=m*n ->Zlength lg=l*n ->
 Forall(fun z:Z=>z=0\/z=1)xs ->Forall(fun z:Z=>z=0\/z=1)fs ->
 Forall(fun z:Z=>z=0\/z=1)h ->Forall(fun z:Z=>z=0\/z=1)lg ->
 cached n m xs ys h ->cached n l xs zs lg ->
 minimum(Z.to_nat n)(matrix_vectors n m h)(matrix_vectors n l lg)e ->
 compatible(Z.to_nat n)e(decode xs)(decode fs) ->
 ~good(Z.to_nat n)(matrix_vectors n m h)(matrix_vectors n l lg)(decode xs) ->
 Z.of_nat(weight(Z.to_nat n)(decode xs))+1=cap ->
 (weight(Z.to_nat n)e<=Z.to_nat cap)%nat ->
 (forall q,0<=q<n ->leaf_candidate n m l xs fs ys zs h lg q=false) ->False.
Proof.
 intros N M L XL FL HL LL XB FB HB LB HC LC Min Compat Unfinished Sum Within Miss.
 assert(Cap:0<=cap)by lia.
 assert(One:(Z.to_nat cap=weight(Z.to_nat n)(decode xs)+1)%nat).
 { apply Nat2Z.inj;rewrite Z2Nat.id by assumption;rewrite Nat2Z.inj_add;cbn;lia. }
 destruct(critical_single_remaining_completes(Z.to_nat n)(matrix_vectors n m h)
 (matrix_vectors n l lg)e(decode xs)(decode fs)(Z.to_nat cap)Min Compat Unfinished Within One)
 as[q[Q[S[F[E[Same Good]]]]]].
 assert(QZ:0<=Z.of_nat q<n).
 { apply Nat2Z.inj_lt in Q;rewrite Z2Nat.id in Q by lia;lia. }
 assert(Sel:Znth(Z.of_nat q)xs=0).
 { rewrite decode_at_nat in S;apply Z.eqb_neq in S.
 assert(Bit:Znth(Z.of_nat q)xs=0\/Znth(Z.of_nat q)xs=1)by(apply Forall_Znth;auto;lia);tauto. }
 assert(Free:Znth(Z.of_nat q)fs=0).
 { rewrite decode_at_nat in F;apply Z.eqb_neq in F.
 assert(Bit:Znth(Z.of_nat q)fs=0\/Znth(Z.of_nat q)fs=1)by(apply Forall_Znth;auto;lia);tauto. }
 destruct(proj1 Min)as[Pos[Ker Log]].
 pose proof(proj1(matrix_kernel_indexed n m h e M)Ker)as KRows.
 pose proof(proj1(matrix_logical_indexed n l lg e L)Log)as LRows.
 assert(SameZ:forall i,(i<Z.to_nat n)%nat ->e i=flip(decode xs)(Z.to_nat(Z.of_nat q))i)
 by(rewrite Nat2Z.id;exact Same).
 pose proof(one_flip_leaf_candidate n m l(Z.of_nat q)xs fs ys zs h lg e
 N M L QZ HL LL HB LB HC LC Sel Free SameZ KRows LRows)as Hit.
 specialize(Miss(Z.of_nat q)QZ);congruence.
Qed.
Print Assumptions numeric_leaf_exhaustion.
