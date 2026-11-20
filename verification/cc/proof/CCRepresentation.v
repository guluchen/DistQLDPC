(* Representation bridge: byte arrays, GF(2) vectors and cached syndromes. *)
Require Import VST.floyd.proofauto.
Require Import CCV.CCModel CCV.CCFunctional CCV.CCCache CCV.CCValidation CCV.CCRows CCV.CCMatrix CCV.VerifToggle.
Open Scope Z_scope.
Definition bitZ (b:bool) : Z :=if b then 1 else 0.
Definition decode (xs:list Z) : CCModel.vector :=fun i=>nth i xs 0=?1.
Lemma nonnegative_lookup i (xs:list Z) : 0<=i -> Znth i xs=nth(Z.to_nat i) xs 0.
Proof. intros;unfold Znth;rewrite if_false by lia;reflexivity. Qed.
Lemma decode_at_nat xs i : decode xs i=(Znth (Z.of_nat i) xs=?1).
Proof. unfold decode;rewrite nonnegative_lookup by lia;rewrite Nat2Z.id;reflexivity. Qed.
Lemma encode_bit x : x=0 \/ x=1 -> bitZ (x=?1)=x.
Proof. intros [H|H];subst;reflexivity. Qed.
Lemma bitZ_xor a b : Z.lxor (bitZ a) (bitZ b)=bitZ(xorb a b).
Proof. destruct a,b;reflexivity. Qed.
Lemma decode_xor_one x : x=0 \/ x=1 -> (Z.lxor x 1=?1)=negb(x=?1).
Proof. intros [H|H];subst;reflexivity. Qed.
Lemma row_vector_column n m i h q : 0<n -> 0<=i<m -> 0<=q<n -> Zlength h=(m*n)%Z ->
 row_vector n i h (Z.to_nat q)=(Znth(i*n+q) h=?1).
Proof.
 intros;unfold row_vector;rewrite <- (nonnegative_lookup q (matrix_row n i h)) by lia.
 rewrite (matrix_row_at n m i h q) by assumption;reflexivity.
Qed.
Theorem decode_toggle xs q : 0<=q<Zlength xs -> Forall(fun z:Z=>z=0 \/ z=1) xs ->
 forall i:nat,(i<Z.to_nat(Zlength xs))%nat ->
 decode (upd_Znth q xs (Z.lxor(Znth q xs) 1)) i=flip (decode xs) (Z.to_nat q) i.
Proof.
 intros Hq Bits i Hi;unfold flip;rewrite !decode_at_nat.
 assert(I:0<=Z.of_nat i<Zlength xs).
 { apply Nat2Z.inj_lt in Hi;rewrite Z2Nat.id in Hi by (apply Zlength_nonneg);lia. }
 destruct(Nat.eqb i (Z.to_nat q)) eqn:E.
 - apply Nat.eqb_eq in E;subst i;rewrite Z2Nat.id by lia.
   rewrite upd_Znth_same by lia;apply decode_xor_one;apply Forall_Znth;auto.
 - assert(Ne:q<>Z.of_nat i).
   { intro X;apply Nat.eqb_neq in E;apply E;rewrite X,Nat2Z.id;reflexivity. }
   rewrite upd_Znth_diff by lia;reflexivity.
Qed.
Lemma xor_vector_bits xs ys : Zlength xs=Zlength ys ->
 Forall(fun z:Z=>z=0 \/ z=1) xs -> Forall(fun z:Z=>z=0 \/ z=1) ys ->
 Forall(fun z:Z=>z=0 \/ z=1) (xor_vector xs ys).
Proof.
 intros Len X Y;apply (proj2 (Forall_Znth _ _));intros i Hi.
 rewrite xor_vector_length in Hi by assumption;rewrite xor_vector_at by assumption.
 assert(Bx:Znth i xs=0 \/ Znth i xs=1) by (apply Forall_Znth;auto).
 assert(By:Znth i ys=0 \/ Znth i ys=1) by (apply Forall_Znth;auto;lia).
 destruct Bx as [Bx|Bx];destruct By as [By|By];rewrite Bx,By;vm_compute;auto.
Qed.
Definition cached n m (xs ys h:list Z) :=forall i:Z,0<=i<m ->
 Znth i ys=bitZ(CCModel.parity (Z.to_nat n) (row_vector n i h) (decode xs)).
Theorem cached_toggle n m xs ys h q :
 0<n -> 0<=m -> 0<=q<n -> Zlength xs=n -> Zlength ys=m -> Zlength h=(m*n)%Z ->
 Forall(fun z:Z=>z=0 \/ z=1) xs -> Forall(fun z:Z=>z=0 \/ z=1) h ->
 cached n m xs ys h ->
 cached n m (upd_Znth q xs (Z.lxor(Znth q xs) 1))
  (xor_vector ys (column n m q h)) h.
Proof.
 intros Hn Hm Hq Hx Hy Hh Bx Bh Cache i Hi.
 rewrite xor_vector_at by (rewrite ?column_length by lia;lia).
 rewrite column_at by assumption;rewrite Cache by assumption.
 assert(B:Znth(i*n+q) h=0 \/ Znth(i*n+q) h=1).
 { apply Forall_Znth;auto;rewrite Hh;apply matrix_index;assumption. }
 rewrite <- (encode_bit _ B),bitZ_xor.
 f_equal.
 rewrite (CCFunctional.parity_ext (Z.to_nat n) (row_vector n i h)
   (decode (upd_Znth q xs (Z.lxor(Znth q xs) 1))) (flip (decode xs) (Z.to_nat q))).
 - rewrite parity_flip by (apply Z2Nat.inj_lt;lia).
   rewrite (row_vector_column n m i h q) by assumption;reflexivity.
 - intros j Hj;apply decode_toggle;try assumption;try lia;rewrite Hx;assumption.
Qed.
Print Assumptions decode_toggle.
Print Assumptions cached_toggle.
