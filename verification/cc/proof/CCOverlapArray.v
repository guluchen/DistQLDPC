(* Numeric row loops and their domain-specific overlap safety policy. *)
Require Import VST.floyd.proofauto.
Require Import CCV.CCModel CCV.CCFunctional CCV.CCOverlap CCV.CCValidation CCV.CCMatrix CCV.CCRepresentation.
Open Scope Z_scope.
Definition stab_weight t n i gs :=Z.of_nat(weight (Z.to_nat t) (row_vector n i gs)).
Definition stab_overlap t n i xs gs :=Z.of_nat(weight (Z.to_nat t) (vinter (decode xs) (row_vector n i gs))).
Lemma stab_weight_step t n k i gs : 0<n ->0<=i<k ->0<=t<n ->Zlength gs=(k*n)%Z ->
 Forall(fun z:Z=>z=0 \/ z=1) gs ->
 stab_weight (t+1) n i gs=stab_weight t n i gs+Znth(i*n+t) gs.
Proof.
 intros N I T Len B;unfold stab_weight;rewrite Z2Nat.inj_add by lia;change(Z.to_nat 1) with 1%nat.
 rewrite Nat.add_1_r;cbn [weight];rewrite Nat2Z.inj_add.
 rewrite (row_vector_column n k i gs t) by assumption.
 assert(G:Znth(i*n+t) gs=0 \/ Znth(i*n+t) gs=1) by (apply Forall_Znth;auto;rewrite Len;apply matrix_index;assumption).
 destruct G as [G|G];rewrite G;reflexivity.
Qed.
Lemma stab_overlap_step t n k i xs gs : 0<n ->0<=i<k ->0<=t<n ->Zlength xs=n ->Zlength gs=(k*n)%Z ->
 Forall(fun z:Z=>z=0 \/ z=1) xs ->Forall(fun z:Z=>z=0 \/ z=1) gs ->
 stab_overlap (t+1) n i xs gs=stab_overlap t n i xs gs+Z.land (Znth(i*n+t) gs) (Znth t xs).
Proof.
 intros N I T Lx Lg Bx Bg;unfold stab_overlap;rewrite Z2Nat.inj_add by lia;change(Z.to_nat 1) with 1%nat.
 rewrite Nat.add_1_r;cbn [weight];rewrite Nat2Z.inj_add;unfold vinter.
 rewrite (row_vector_column n k i gs t) by assumption.
 rewrite decode_at_nat,Z2Nat.id by lia.
 assert(G:Znth(i*n+t) gs=0 \/ Znth(i*n+t) gs=1) by (apply Forall_Znth;auto;rewrite Lg;apply matrix_index;assumption).
 assert(X:Znth t xs=0 \/ Znth t xs=1) by (apply Forall_Znth;auto;lia).
 destruct G as [G|G];destruct X as [X|X];rewrite G,X;reflexivity.
Qed.
Lemma stab_counts_bounds t n i xs gs : 0<=t ->
 0<=stab_weight t n i gs<=t /\ 0<=stab_overlap t n i xs gs<=stab_weight t n i gs.
Proof.
 intros T;unfold stab_weight,stab_overlap.
 pose proof(vector_weight_bound (Z.to_nat t) (row_vector n i gs)) as W.
 assert(Sub:subset (Z.to_nat t) (vinter (decode xs) (row_vector n i gs)) (row_vector n i gs)).
 { intros j Hj H;unfold vinter in H;apply andb_true_iff in H;tauto. }
 pose proof(subset_split _ _ _ Sub) as Split.
 assert(B:(weight (Z.to_nat t) (vinter (decode xs) (row_vector n i gs))<=weight (Z.to_nat t) (row_vector n i gs))%nat) by lia.
 apply Nat2Z.inj_le in W;apply Nat2Z.inj_le in B;rewrite Z2Nat.id in W by assumption;lia.
Qed.
Lemma half_floor_Z w : 0<=w ->w<2*(w/2+1).
Proof. intros W;pose proof(Z.div_mod w 2 ltac:(lia));pose proof(Z.mod_pos_bound w 2 ltac:(lia));nia. Qed.
Definition overlap_policy n k xs gs (Bad:Prop) (Allowed:Z->Prop) :=
 forall i:Z,0<=i<k ->
 (stab_overlap n n i xs gs>stab_weight n n i gs/2 ->Bad) /\
 (forall q:Z,0<=q<n ->stab_overlap n n i xs gs=stab_weight n n i gs/2 ->
   Znth(i*n+q) gs<>0 ->Znth q xs=0 ->Allowed q).
Theorem minimum_implies_overlap_policy n k hs ls xs gs e :
 0<n ->0<=k ->Zlength xs=n ->Zlength gs=(k*n)%Z ->
 Forall(fun z:Z=>z=0 \/ z=1) xs ->Forall(fun z:Z=>z=0 \/ z=1) gs ->
 minimum (Z.to_nat n) hs ls e ->
 (forall i:Z,0<=i<k ->stabilizer_valid (Z.to_nat n) hs ls (row_vector n i gs)) ->
 overlap_policy n k xs gs (~subset (Z.to_nat n) (decode xs) e)
  (fun q=>subset (Z.to_nat n) (decode xs) e ->e(Z.to_nat q)=false).
Proof.
 intros N K Lx Lg Bx Bg Min Valid i I;destruct(Valid i I) as [Ker Log];split.
 - intros Bad Sub.
   assert(Round:=half_floor_Z (stab_weight n n i gs) ltac:(unfold stab_weight;lia)).
   eapply (overlap_prune_preserves_minimum (Z.to_nat n) hs ls e (row_vector n i gs) (decode xs));try eassumption.
   unfold stab_weight,stab_overlap in *;rewrite Nat2Z.inj_lt;nia.
 - intros q Q Tight G S Sub.
   eapply (tight_overlap_forbid (Z.to_nat n) hs ls e (row_vector n i gs) (decode xs)
     (weight (Z.to_nat n) (vinter (decode xs) (row_vector n i gs))) (Z.to_nat q));try eassumption.
   + reflexivity.
   + pose proof(half_floor_Z (stab_weight n n i gs) ltac:(unfold stab_weight;lia)) as Round.
     unfold stab_weight,stab_overlap in *;rewrite Nat2Z.inj_lt;nia.
   + apply Z2Nat.inj_lt;lia.
   + rewrite (row_vector_column n k i gs q) by assumption.
     assert(Bit:Znth(i*n+q) gs=0 \/ Znth(i*n+q) gs=1) by (apply Forall_Znth;auto;rewrite Lg;apply matrix_index;assumption).
     destruct Bit;[contradiction|apply Z.eqb_eq;assumption].
   + rewrite decode_at_nat,Z2Nat.id by lia;rewrite S;reflexivity.
Qed.
Print Assumptions stab_counts_bounds.
Print Assumptions minimum_implies_overlap_policy.

Lemma uint_repr_equal a b : 0<=a<=Int.max_unsigned ->0<=b<=Int.max_unsigned ->Int.repr a=Int.repr b ->a=b.
Proof. intros A B E;apply (f_equal Int.unsigned) in E;rewrite !Int.unsigned_repr in E by assumption;assumption. Qed.
