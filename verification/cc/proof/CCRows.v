Require Import VST.floyd.proofauto.
Require Import CCV.VerifDot CCV.CCMatrix.
Open Scope Z_scope.
Definition matrix_row n i (h:list Z) := sublist (i*n) ((i+1)*n) h.
Lemma matrix_row_length n m i h : 0<n -> 0<=i<m -> Zlength h=(m*n)%Z ->
 Zlength(matrix_row n i h)=n.
Proof. intros;unfold matrix_row;rewrite Zlength_sublist by nia;nia. Qed.
Lemma matrix_row_at n m i h q : 0<n -> 0<=i<m -> 0<=q<n -> Zlength h=(m*n)%Z ->
 Znth q (matrix_row n i h)=Znth(i*n+q) h.
Proof. intros;unfold matrix_row;rewrite Znth_sublist by nia;f_equal;lia. Qed.
Lemma matrix_row_bits n i h : Forall(fun z:Z=>z=0 \/ z=1) h ->
 Forall(fun z:Z=>z=0 \/ z=1) (matrix_row n i h).
Proof. intros;unfold matrix_row;apply Forall_sublist;assumption. Qed.
Fixpoint flat_dot_nat (t:nat) n a b (h g:list Z) : int :=
 match t with O=>Int.zero | S k=>Int.xor (flat_dot_nat k n a b h g)
 (Int.and(Int.repr(Znth(a*n+Z.of_nat k) h))(Int.repr(Znth(b*n+Z.of_nat k) g))) end.
Definition flat_dot t n a b h g :=flat_dot_nat (Z.to_nat t) n a b h g.
Lemma flat_dot_step t n a b h g : 0<=t -> flat_dot (t+1) n a b h g=
 Int.xor(flat_dot t n a b h g) (Int.and(Int.repr(Znth(a*n+t) h))(Int.repr(Znth(b*n+t) g))).
Proof.
 intros;unfold flat_dot;rewrite Z2Nat.inj_add by lia;change(Z.to_nat 1) with 1%nat.
 rewrite Nat.add_1_r;cbn [flat_dot_nat];rewrite Z2Nat.id by lia;reflexivity.
Qed.
Lemma flat_dot_rows n m k a b h g t : 0<n -> 0<=a<m -> 0<=b<k ->
 Zlength h=(m*n)%Z -> Zlength g=(k*n)%Z -> (t<=Z.to_nat n)%nat ->
 flat_dot_nat t n a b h g=word_dot_nat t (matrix_row n a h) (matrix_row n b g).
Proof.
 intros Hn Ha Hb Hh Hg Ht;induction t as [|t IH];[reflexivity|].
 cbn [flat_dot_nat word_dot_nat];rewrite IH by lia.
 assert(T:0<=Z.of_nat t<n) by (apply Nat2Z.inj_le in Ht;rewrite Nat2Z.inj_succ,Z2Nat.id in Ht by lia;lia).
 rewrite <- (matrix_row_at n m a h (Z.of_nat t)) by assumption.
 rewrite <- (matrix_row_at n k b g (Z.of_nat t)) by assumption.
 unfold Znth;rewrite !if_false by lia;rewrite !Nat2Z.id;reflexivity.
Qed.
Print Assumptions flat_dot_rows.
