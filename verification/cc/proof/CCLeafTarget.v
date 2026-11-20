(* Instantiate the checked numeric leaf predicate from a one-bit logical target.
   The C leaf body is checked separately; the C search caller is not yet checked. *)
Require Import VST.floyd.proofauto.
Require Import CCV.CCModel CCV.CCFunctional CCV.CCCache CCV.CCRepresentation CCV.CCValidation CCV.CCMatrix CCV.CCLeaf.
Open Scope Z_scope.
Lemma row_differs_all t n q zs lg : 0<=t ->
 (row_differs t n q zs lg=true <->exists i,0<=i<t /\Znth i zs<>Znth(i*n+q)lg).
Proof.
 intros T;unfold row_differs;remember(Z.to_nat t)as k eqn:E.
 assert(Tk:t=Z.of_nat k)by(subst k;rewrite Z2Nat.id by assumption;reflexivity).
 subst t;clear E T;induction k as [|k IH];cbn[row_differs_nat].
 - split;[discriminate|intros[i[I D]];lia].
 - rewrite orb_true_iff,IH,negb_true_iff,Z.eqb_neq.
   assert(A:nth k zs 0=Znth(Z.of_nat k)zs).
   { rewrite nonnegative_Znth by lia;rewrite Nat2Z.id;reflexivity. }
   rewrite A;split.
   + intros [[i[I D]]|D].
     * exists i;split;[lia|assumption].
     * exists(Z.of_nat k);split;[lia|assumption].
   + intros[i[I D]];destruct(Z.eq_dec i(Z.of_nat k))as[->|Ne].
     * right;assumption.
     * left;exists i;split;[lia|assumption].
Qed.
Theorem one_flip_leaf_candidate n m l q xs fs ys zs h lg e :
 0<n ->0<=m ->0<=l ->0<=q<n ->
 Zlength h=(m*n)%Z ->Zlength lg=(l*n)%Z ->
 Forall(fun z:Z=>z=0 \/z=1)h ->Forall(fun z:Z=>z=0 \/z=1)lg ->
 cached n m xs ys h ->cached n l xs zs lg ->
 Znth q xs=0 ->Znth q fs=0 ->
 (forall j,(j<Z.to_nat n)%nat ->e j=flip(decode xs)(Z.to_nat q)j) ->
 (forall i,0<=i<m ->CCModel.parity(Z.to_nat n)(row_vector n i h)e=false) ->
 (exists i,0<=i<l /\CCModel.parity(Z.to_nat n)(row_vector n i lg)e=true) ->
 leaf_candidate n m l xs fs ys zs h lg q=true.
Proof.
 intros N M L Q Hlen Llen Hbits Lbits HC LC Sel Free Eq Ker Log.
 assert(Qn:(Z.to_nat q<Z.to_nat n)%nat)by(apply Z2Nat.inj_lt;lia).
 assert(PE:forall row,CCModel.parity(Z.to_nat n)row e=
 xorb(CCModel.parity(Z.to_nat n)row(decode xs))(row(Z.to_nat q))).
 { intros row;rewrite(parity_ext (Z.to_nat n)row e(flip(decode xs)(Z.to_nat q))Eq).
   apply parity_flip;assumption. }
 unfold leaf_candidate;apply andb_true_iff;split.
 - unfold free_column;rewrite Sel,Free;reflexivity.
 - apply andb_true_iff;split.
   + apply row_matches_all;[assumption|].
     intros i I;pose proof(Ker i I)as K;rewrite PE in K.
     assert(R:row_vector n i h(Z.to_nat q)=(Znth(i*n+q)h=?1)).
     { apply(row_vector_column n m i h q);assumption. }
     rewrite R in K.
     assert(P:CCModel.parity(Z.to_nat n)(row_vector n i h)(decode xs)=(Znth(i*n+q)h=?1)).
     { destruct(CCModel.parity(Z.to_nat n)(row_vector n i h)(decode xs)),(Znth(i*n+q)h=?1);simpl in K;congruence. }
     rewrite HC by assumption;rewrite P;apply encode_bit.
     apply Forall_Znth;auto;rewrite Hlen;apply matrix_index;assumption.
   + apply row_differs_all;[assumption|].
     destruct Log as[i[I Hit]];exists i;split;[assumption|].
     rewrite PE in Hit.
     assert(R:row_vector n i lg(Z.to_nat q)=(Znth(i*n+q)lg=?1)).
     { apply(row_vector_column n l i lg q);assumption. }
     rewrite R in Hit.
     assert(B:Znth(i*n+q)lg=0 \/Znth(i*n+q)lg=1).
     { apply Forall_Znth;auto;rewrite Llen;apply matrix_index;assumption. }
     intros Same;rewrite LC in Same by assumption.
     rewrite <-(encode_bit _ B)in Same.
     assert(P:CCModel.parity(Z.to_nat n)(row_vector n i lg)(decode xs)=(Znth(i*n+q)lg=?1)).
     { destruct(CCModel.parity(Z.to_nat n)(row_vector n i lg)(decode xs)),(Znth(i*n+q)lg=?1);simpl in Same;congruence. }
     rewrite P in Hit;destruct(Znth(i*n+q)lg=?1);discriminate.
Qed.
Print Assumptions row_differs_all.
Print Assumptions one_flip_leaf_candidate.
