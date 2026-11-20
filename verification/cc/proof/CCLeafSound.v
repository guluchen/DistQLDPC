(* Soundness bridge from the numeric predicate in the verified C leaf body
   to the GF(2) half problem. The C search caller remains a separate proof. *)
Require Import VST.floyd.proofauto.
Require Import CCV.CCModel CCV.CCFunctional CCV.CCCache CCV.CCRepresentation CCV.CCValidation CCV.CCMatrix CCV.CCMatrixModel CCV.CCLeaf CCV.CCLeafTarget.
Open Scope Z_scope.
Theorem numeric_leaf_sound n m l q xs fs ys zs h lg :
 0<n ->0<=m ->0<=l ->0<=q<n ->Zlength xs=n ->
 Zlength h=(m*n)%Z ->Zlength lg=(l*n)%Z ->
 Forall(fun z:Z=>z=0 \/z=1)xs ->Forall(fun z:Z=>z=0 \/z=1)h ->Forall(fun z:Z=>z=0 \/z=1)lg ->
 cached n m xs ys h ->cached n l xs zs lg ->
 leaf_candidate n m l xs fs ys zs h lg q=true ->
 good(Z.to_nat n)(matrix_vectors n m h)(matrix_vectors n l lg)
 (decode(upd_Znth q xs(Z.lxor(Znth q xs)1))) /\
 weight(Z.to_nat n)(decode(upd_Znth q xs(Z.lxor(Znth q xs)1)))=
 (weight(Z.to_nat n)(decode xs)+1)%nat.
Proof.
 intros N M L Q Xlen Hlen Llen XB HB LB HC LC Hit.
 unfold leaf_candidate in Hit;apply andb_true_iff in Hit;destruct Hit as[Free Hit].
 apply andb_true_iff in Hit;destruct Hit as[Matches Differs].
 pose proof(proj1(row_matches_all m n q ys h M)Matches)as MatchesAll;clear Matches;rename MatchesAll into Matches.
 pose proof(proj1(row_differs_all l n q zs lg L)Differs)as DiffersAll;clear Differs;rename DiffersAll into Differs.
 unfold free_column in Free;apply andb_true_iff in Free;destruct Free as[Sel Forbid].
 apply Z.eqb_eq in Sel,Forbid.
 assert(Qn:(Z.to_nat q<Z.to_nat n)%nat)by(apply Z2Nat.inj_lt;lia).
 assert(Eq:forall i,(i<Z.to_nat n)%nat ->
 decode(upd_Znth q xs(Z.lxor(Znth q xs)1))i=flip(decode xs)(Z.to_nat q)i).
 { rewrite <-Xlen;apply decode_toggle;try assumption;lia. }
 assert(Ker:kernel(Z.to_nat n)(matrix_vectors n m h)(decode(upd_Znth q xs(Z.lxor(Znth q xs)1)))).
 { apply matrix_kernel_indexed;[assumption|];intros i I.
   rewrite(parity_ext _ _ _ _ Eq),parity_flip by assumption.
   rewrite(row_vector_column n m i h q)by assumption.
   pose proof(Matches i I)as Same;rewrite HC in Same by assumption.
   assert(B:Znth(i*n+q)h=0 \/Znth(i*n+q)h=1)by(apply Forall_Znth;auto;rewrite Hlen;apply matrix_index;assumption).
   rewrite <-(encode_bit _ B)in Same.
   assert(P:parity(Z.to_nat n)(row_vector n i h)(decode xs)=(Znth(i*n+q)h=?1)).
   { destruct(parity _ _ _),(Znth(i*n+q)h=?1);simpl in Same;congruence. }
   rewrite P;apply xorb_nilpotent. }
 assert(Log:CCModel.logical(Z.to_nat n)(matrix_vectors n l lg)(decode(upd_Znth q xs(Z.lxor(Znth q xs)1)))).
 { apply matrix_logical_indexed;[assumption|];destruct Differs as[i[I Different]].
   exists i;split;[assumption|].
   rewrite(parity_ext _ _ _ _ Eq),parity_flip by assumption.
   rewrite(row_vector_column n l i lg q)by assumption.
   rewrite LC in Different by assumption.
   assert(B:Znth(i*n+q)lg=0 \/Znth(i*n+q)lg=1)by(apply Forall_Znth;auto;rewrite Llen;apply matrix_index;assumption).
   rewrite <-(encode_bit _ B)in Different.
   destruct(parity _ _ _),(Znth(i*n+q)lg=?1);simpl in *;try contradiction;reflexivity. }
 split.
 - split;[apply(logical_positive _ _ _ Log)|split;assumption].
 - rewrite(weight_ext _ _ _ Eq).
   assert(S:decode xs(Z.to_nat q)=false)by(rewrite decode_at_nat,Z2Nat.id,Sel by lia;reflexivity).
   assert(F:forall i,(i<Z.to_nat n)%nat ->flip(decode xs)(Z.to_nat q)i=setbit(decode xs)(Z.to_nat q)i).
   { intros i I;unfold flip,setbit;destruct(Nat.eqb i(Z.to_nat q))eqn:E;[apply Nat.eqb_eq in E;subst i;rewrite S|];reflexivity. }
   rewrite(weight_ext _ _ _ F);apply setbit_weight;assumption.
Qed.
Print Assumptions numeric_leaf_sound.
