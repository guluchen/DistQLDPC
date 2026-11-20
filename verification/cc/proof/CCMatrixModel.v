(* Exact finite matrix-row representation for the C search specification.
   This does not construct a CSS logical quotient from input PCM. *)
Require Import VST.floyd.proofauto.
Require Import CCV.CCModel CCV.CCFunctional CCV.CCValidation CCV.CCRepresentation CCV.CCOverlap.
Import ListNotations.
Open Scope Z_scope.
Definition matrix_vectors n m h :=map(fun r=>row_vector n(Z.of_nat r)h)(seq 0(Z.to_nat m)).
Lemma matrix_vectors_member n m h row : 0<=m ->
 (In row(matrix_vectors n m h) <->exists i,0<=i<m /\row=row_vector n i h).
Proof.
 intros M;unfold matrix_vectors;rewrite in_map_iff;split.
 - intros[r[Eq Hin]];apply in_seq in Hin;destruct Hin as[Lo Hi].
   simpl in Hi;apply Nat2Z.inj_lt in Hi;rewrite Z2Nat.id in Hi by assumption.
   exists(Z.of_nat r);split;[lia|symmetry;assumption].
 - intros[i[I Eq]];exists(Z.to_nat i);split.
   + rewrite Z2Nat.id by lia;symmetry;assumption.
   + apply in_seq;split;[lia|apply Z2Nat.inj_lt;lia].
Qed.
Theorem matrix_kernel_indexed n m h e : 0<=m ->
 (kernel(Z.to_nat n)(matrix_vectors n m h)e <->
 forall i,0<=i<m ->CCModel.parity(Z.to_nat n)(row_vector n i h)e=false).
Proof.
 intros M;split.
 - intros K i I;apply K;apply(matrix_vectors_member n m h);[assumption|].
   exists i;auto.
 - intros K row Member;apply(matrix_vectors_member n m h row M)in Member.
   destruct Member as[i[I Eq]];subst row;apply K;assumption.
Qed.
Theorem matrix_logical_indexed n l lg e : 0<=l ->
 (CCModel.logical(Z.to_nat n)(matrix_vectors n l lg)e <->
 exists i,0<=i<l /\CCModel.parity(Z.to_nat n)(row_vector n i lg)e=true).
Proof.
 intros L;split.
 - intros[row[Member Hit]];apply(matrix_vectors_member n l lg row L)in Member.
   destruct Member as[i[I Eq]];subst row;exists i;auto.
 - intros[i[I Hit]];exists(row_vector n i lg);split;[|assumption].
   apply(matrix_vectors_member n l lg);[assumption|];exists i;auto.
Qed.
Theorem matrix_stabilizer_valid n m l h lg g : 0<=m ->0<=l ->
 (forall i,0<=i<m ->CCModel.parity(Z.to_nat n)(row_vector n i h)g=false) ->
 (forall i,0<=i<l ->CCModel.parity(Z.to_nat n)(row_vector n i lg)g=false) ->
 stabilizer_valid(Z.to_nat n)(matrix_vectors n m h)(matrix_vectors n l lg)g.
Proof.
 intros M L H LG;split.
 - apply matrix_kernel_indexed;assumption.
 - intros row Member;apply(matrix_vectors_member n l lg row L)in Member.
   destruct Member as[i[I Eq]];subst row;apply LG;assumption.
Qed.
Lemma decode_zero_vector n : forall i,decode(Zrepeat 0 n)i=false.
Proof.
 unfold decode,Zrepeat;generalize(Z.to_nat n)as k;intros k;induction k;intros i;destruct i;cbn[repeat nth Z.eqb];auto.
Qed.
Lemma zero_vector_parity n row : CCModel.parity n row(fun _=>false)=false.
Proof. induction n;simpl;[reflexivity|rewrite andb_false_r;exact IHn]. Qed.
Theorem clear_arrays_cache n m h : 0<=m ->
 cached n m(Zrepeat 0 n)(Zrepeat 0 m)h.
Proof.
 intros M i I;rewrite Znth_Zrepeat by assumption.
 assert(Eq:forall j,(j<Z.to_nat n)%nat ->decode(Zrepeat 0 n)j=false)by(intros;apply decode_zero_vector).
 rewrite(parity_ext (Z.to_nat n)(row_vector n i h)(decode(Zrepeat 0 n))(fun _=>false)Eq).
 rewrite zero_vector_parity;reflexivity.
Qed.
Print Assumptions matrix_kernel_indexed.
Print Assumptions matrix_logical_indexed.
Print Assumptions matrix_stabilizer_valid.
Print Assumptions clear_arrays_cache.
