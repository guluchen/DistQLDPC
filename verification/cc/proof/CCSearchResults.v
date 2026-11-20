(* Exact return-value bridges for the search loop. These are prerequisites,
   not a claim that the loop implements the specified results. *)
Require Import VST.floyd.proofauto.
Require Import CCV.CCModel CCV.CCCache CCV.CCValidation CCV.CCSearchSpecs CCV.CCMatrixModel CCV.CCFunctional CCV.CCRepresentation CCV.VerifNontrivial.
Import ListNotations.
Open Scope Z_scope.
Lemma no_minimum_in_cap_is_empty a cap :
 (forall e,model_minimum a e ->cap<Z.of_nat(CCModel.weight(Z.to_nat(model_n a))e)) ->
 forall e,model_good a e ->cap<Z.of_nat(CCModel.weight(Z.to_nat(model_n a))e).
Proof.
 intros NoMin e Good.
 destruct(minimum_exists_below_witness (Z.to_nat(model_n a))(model_h_rows a)(model_l_rows a)e Good)as[v[Min Bound]].
 pose proof(NoMin v Min);lia.
Qed.
Lemma zero_cap_empty a :forall e,model_good a e ->0<Z.of_nat(CCModel.weight(Z.to_nat(model_n a))e).
Proof. intros e[Pos Rest];lia. Qed.
Lemma cap_clamp_query_result a cap ret out :
 0<=model_n a ->model_n a<=cap ->
 query_result a(model_n a)ret out ->query_result a cap ret out.
Proof.
 intros N Cap [Unknown|[Empty|Found]].
 - left;assumption.
 - right;left;destruct Empty as[R[O NoGood]];repeat split;try assumption.
   intros e Good;pose proof(NoGood e Good).
   pose proof(vector_weight_bound(Z.to_nat(model_n a))e)as B.
   apply Nat2Z.inj_le in B;rewrite Z2Nat.id in B by assumption;lia.
 - right;right;destruct Found as[R[G Weight]];split;[assumption|split;[assumption|lia]].
Qed.
Lemma cache_zero_is_kernel n m h xs ys :0<=m ->cached n m xs ys h ->
 (forall i,0<=i<m ->Znth i ys=0) ->
 kernel(Z.to_nat n)(matrix_vectors n m h)(decode xs).
Proof.
 intros M Cache Zero;apply matrix_kernel_indexed;[assumption|].
 intros i I;pose proof(Cache i I)as Eq;rewrite Zero in Eq by assumption.
 destruct(CCModel.parity _ _ _);simpl in Eq;[discriminate|reflexivity].
Qed.
Lemma cache_nonzero_is_logical n l lg xs zs :0<=l ->Zlength zs=l ->
 cached n l xs zs lg ->has_nonzero zs=true ->
 CCModel.logical(Z.to_nat n)(matrix_vectors n l lg)(decode xs).
Proof.
 intros L Len Cache Hit;unfold has_nonzero in Hit.
 apply existsb_exists in Hit;destruct Hit as[z[Member NZ]].
 apply negb_true_iff in NZ;apply Z.eqb_neq in NZ.
 destruct(In_nth zs z 0 Member)as[i[Range At]].
 apply matrix_logical_indexed;[assumption|].
 exists(Z.of_nat i);assert(I:0<=Z.of_nat i<l)by(rewrite <-Len,Zlength_correct;lia).
 split;[assumption|].
 pose proof(Cache(Z.of_nat i)I)as Eq.
 rewrite nonnegative_lookup,Nat2Z.id,At in Eq by lia.
 destruct(CCModel.parity _ _ _);simpl in Eq;[reflexivity|congruence].
Qed.
Theorem cached_found_is_good n m l h lg xs ys zs :
 0<=m ->0<=l ->Zlength zs=l ->cached n m xs ys h ->cached n l xs zs lg ->
 (forall i,0<=i<m ->Znth i ys=0) ->has_nonzero zs=true ->
 good(Z.to_nat n)(matrix_vectors n m h)(matrix_vectors n l lg)(decode xs).
Proof.
 intros M L Len HC LC Zero Nonzero.
 pose proof(cache_nonzero_is_logical n l lg xs zs L Len LC Nonzero)as Log.
 split;[apply(logical_positive _ _ _ Log)|split;[apply(cache_zero_is_kernel n m h xs ys);assumption|assumption]].
Qed.
Print Assumptions no_minimum_in_cap_is_empty.
Print Assumptions cached_found_is_good.
