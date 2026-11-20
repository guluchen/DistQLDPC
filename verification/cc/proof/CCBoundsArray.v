(* Numeric array model of the actual C bounds scans.  This is a bridge, not
   the semax_body proof of bounds.  No solver answer is a premise. *)
Require Import VST.floyd.proofauto.
Require Import CCV.CCModel CCV.CCFunctional CCV.CCPacking CCV.CCWord.
Require Import CCV.CCRepresentation CCV.CCRows CCV.CCMatrix CCV.CCValidation.
Import ListNotations.
Open Scope Z_scope.
Definition bitcount t (p:CCModel.vector) :=Z.of_nat(CCModel.weight (Z.to_nat t) p).
Definition free_vec n i h xs fs : CCModel.vector :=
 fun q=>andb (row_vector n i h q) (andb(negb(decode xs q))(negb(decode fs q))).
Definition odd_vec (ys:list Z) : CCModel.vector :=fun r=>negb(Znth(Z.of_nat r) ys=?0).
Definition odd_ids m ys :=filter (odd_vec ys) (seq 0 (Z.to_nat m)).
Definition degree_vec n q h ys : CCModel.vector :=
 fun r=>andb (odd_vec ys r) (row_vector n (Z.of_nat r) h (Z.to_nat q)).
Definition candidate_count t n i h xs fs :=bitcount t (free_vec n i h xs fs).
Definition odd_count t ys :=bitcount t (odd_vec ys).
Definition degree_count t n q h ys :=bitcount t (degree_vec n q h ys).
Lemma bitcount_zero p : bitcount 0 p=0.
Proof. reflexivity. Qed.
Lemma bitcount_step t p : 0<=t ->bitcount (t+1) p=bitcount t p+bitZ(p(Z.to_nat t)).
Proof.
 intros T;unfold bitcount;rewrite Z2Nat.inj_add by lia;simpl.
 rewrite Nat.add_1_r;simpl;rewrite Nat2Z.inj_add.
 destruct(p(Z.to_nat t));reflexivity.
Qed.
Lemma bitcount_bounds t p : 0<=t ->0<=bitcount t p<=t.
Proof.
 intros T;unfold bitcount;assert(B:forall k,(CCModel.weight k p<=k)%nat).
 { induction k;simpl;[lia|destruct(p k);lia]. }
 specialize(B (Z.to_nat t)).
 apply Nat2Z.inj_le in B;rewrite Z2Nat.id in B by assumption;lia.
Qed.
Lemma free_vec_at n m i h xs fs q :
 0<n ->0<=i<m ->0<=q<n ->Zlength h=(m*n)%Z ->
 free_vec n i h xs fs (Z.to_nat q)=
 andb (Znth(i*n+q) h=?1) (andb(negb(Znth q xs=?1))(negb(Znth q fs=?1))).
Proof.
 intros;unfold free_vec;rewrite (row_vector_column n m i h q) by assumption.
 rewrite !decode_at_nat,Z2Nat.id by lia;reflexivity.
Qed.
Lemma free_vec_test n m i h xs fs q :
 0<n ->0<=i<m ->0<=q<n ->Zlength h=(m*n)%Z ->
 Zlength xs=n ->Zlength fs=n ->
 Forall(fun z:Z=>z=0 \/ z=1) h ->Forall(fun z:Z=>z=0 \/ z=1) xs ->Forall(fun z:Z=>z=0 \/ z=1) fs ->
 (free_vec n i h xs fs (Z.to_nat q)=true <->
 Znth(i*n+q) h<>0 /\ Znth q xs=0 /\ Znth q fs=0).
Proof.
 intros N I Q Hlen Xlen Flen Hb Xb Fb;rewrite(free_vec_at n m i h xs fs q) by assumption.
 assert(Hbit:Znth(i*n+q) h=0 \/ Znth(i*n+q) h=1) by(apply Forall_Znth;auto;rewrite Hlen;apply matrix_index;assumption).
 assert(Xbit:Znth q xs=0 \/ Znth q xs=1) by(apply Forall_Znth;auto;lia).
 assert(Fbit:Znth q fs=0 \/ Znth q fs=1) by(apply Forall_Znth;auto;lia).
 destruct Hbit as [-> | ->];destruct Xbit as [-> | ->];destruct Fbit as [-> | ->];simpl;intuition congruence.
Qed.
Lemma count_repair n i h xs fs : 0<=n ->
 candidate_count n n i h xs fs=Z.of_nat(length(repair (Z.to_nat n) (row_vector n i h) (decode xs) (decode fs))).
Proof. intros;unfold candidate_count,bitcount,free_vec,repair;rewrite filter_support_weight;reflexivity. Qed.
Lemma odd_count_length m ys : 0<=m ->odd_count m ys=Z.of_nat(length(odd_ids m ys)).
Proof. intros;unfold odd_count,bitcount,odd_ids;rewrite filter_support_weight;reflexivity. Qed.
Lemma odd_ids_member m ys r : In r (odd_ids m ys) <->
 (r<Z.to_nat m)%nat /\ Znth(Z.of_nat r) ys<>0.
Proof.
 unfold odd_ids;rewrite filter_In,in_seq;unfold odd_vec;rewrite negb_true_iff,Z.eqb_neq.
 intuition lia.
Qed.
Lemma sumover_filter_bool (rows:list nat) (p f:CCModel.vector) :
 sumover(filter p rows)(fun r=>if f r then 1%nat else 0%nat)=
 sumover rows(fun r=>if andb(p r)(f r) then 1%nat else 0%nat).
Proof. induction rows as [|r rows IH];simpl;[reflexivity|];destruct(p r);simpl;rewrite IH;reflexivity. Qed.
Lemma sumover_indicator n (p:CCModel.vector) : sumover(seq 0 n)(fun r=>if p r then 1%nat else 0%nat)=CCModel.weight n p.
Proof.
 induction n as [|n IH];[reflexivity|].
 replace (S n) with (n+1)%nat at 1 by lia;rewrite seq_app.
 assert(App:forall a b f,sumover(a++b) f=(sumover a f+sumover b f)%nat).
 { intros a;induction a as [|x a IHapp];intros b f;simpl;[reflexivity|rewrite IHapp;lia]. }
 rewrite App;simpl;rewrite IH;cbn[CCModel.weight];lia.
Qed.
Lemma degree_count_sum m n q h ys : 0<=m ->
 degree_count m n q h ys=Z.of_nat(sumover(odd_ids m ys)
 (fun r=>if row_vector n (Z.of_nat r) h (Z.to_nat q) then 1%nat else 0%nat)).
Proof.
 intros;unfold degree_count,bitcount,degree_vec,odd_ids.
 rewrite sumover_filter_bool,sumover_indicator;reflexivity.
Qed.
Definition packed_family n m h xs fs ys (rows:list nat) :=
 NoDup rows /\ Forall(fun r=>(r<Z.to_nat m)%nat /\ Znth(Z.of_nat r) ys<>0) rows /\
 (forall r r' q,In r rows ->In r' rows ->r<>r' ->
 In q(repair(Z.to_nat n)(row_vector n (Z.of_nat r) h)(decode xs)(decode fs)) ->
 In q(repair(Z.to_nat n)(row_vector n (Z.of_nat r') h)(decode xs)(decode fs)) ->False).
Definition indexed_target n m h xs fs ys e :=
 compatible(Z.to_nat n) e (decode xs)(decode fs) /\ cached n m xs ys h /\
 (forall i,0<=i<m ->CCModel.parity(Z.to_nat n)(row_vector n i h)e=false).
Lemma indexed_odd_extension n m h xs fs ys e r :
 0<=m ->indexed_target n m h xs fs ys e ->
 (r<Z.to_nat m)%nat ->Znth(Z.of_nat r) ys<>0 ->
 exists q,In q(repair(Z.to_nat n)(row_vector n(Z.of_nat r) h)(decode xs)(decode fs)) /\
 In q(completion(Z.to_nat n) e (decode xs)).
Proof.
 intros M [[Sub Avoid] [Cache Ker]] R Odd.
 assert(Rz:0<=Z.of_nat r<m) by (apply Nat2Z.inj_lt in R;rewrite Z2Nat.id in R by lia;lia).
 assert(P:CCModel.parity(Z.to_nat n)(row_vector n(Z.of_nat r) h)(decode xs)=true).
 { specialize(Cache (Z.of_nat r) Rz);destruct(CCModel.parity _ _ _) eqn:E;[reflexivity|simpl in Cache;congruence]. }
 destruct(odd_row_has_target_extension (Z.to_nat n)(row_vector n(Z.of_nat r) h)(decode xs)e Sub P (Ker _ Rz)) as [q [Q [Hq [Eq Sq]]]].
 assert(Fq:decode fs q=false).
 { destruct(decode fs q) eqn:F;[pose proof(Avoid q Q F);congruence|reflexivity]. }
 exists q;split;[apply repair_member|apply completion_member];tauto.
Qed.
Theorem indexed_empty_reject n m h xs fs ys e r :
 0<=n ->0<=m ->indexed_target n m h xs fs ys e ->
 (r<Z.to_nat m)%nat ->Znth(Z.of_nat r) ys<>0 ->
 candidate_count n n (Z.of_nat r) h xs fs<>0.
Proof.
 intros N M Target R Odd Count.
 destruct(indexed_odd_extension n m h xs fs ys e r M Target R Odd) as [q [Hin _]].
 rewrite count_repair in Count by assumption.
 destruct(repair _ _ _ _) as [|a tail];simpl in *;[contradiction|lia].
Qed.
Theorem indexed_packing_bound n m h xs fs ys e rows :
 0<=m ->indexed_target n m h xs fs ys e ->packed_family n m h xs fs ys rows ->
 Z.of_nat(length rows)<=Z.of_nat(CCModel.weight(Z.to_nat n)(vdiff e (decode xs))).
Proof.
 intros M Target [ND [Rows Disjoint]].
 apply Nat2Z.inj_le;rewrite <-completion_weight.
 apply(disjoint_odd_row_packing_bound rows
 (fun r=>repair(Z.to_nat n)(row_vector n(Z.of_nat r)h)(decode xs)(decode fs))
 (completion(Z.to_nat n)e(decode xs)));try assumption.
 intros r Hin;apply Forall_forall with(x:=r) in Rows;[|assumption].
 destruct Rows as [R Odd];apply(indexed_odd_extension n m h xs fs ys e r);assumption.
Qed.
Theorem indexed_charge_bound n m h xs fs ys e d :
 0<=n ->0<=m ->0<=d ->indexed_target n m h xs fs ys e ->
 (forall q,0<=q<n ->Znth q xs=0 ->Znth q fs=0 ->degree_count m n q h ys<=d) ->
 Zlength xs=n ->Zlength fs=n ->Forall(fun z:Z=>z=0 \/ z=1) xs ->Forall(fun z:Z=>z=0 \/ z=1) fs ->
 odd_count m ys<=Z.of_nat(CCModel.weight(Z.to_nat n)(vdiff e(decode xs)))*d.
Proof.
 intros N M D Target Deg Xlen Flen Xbits Fbits.
 assert(B:(length(odd_ids m ys)<=length(completion(Z.to_nat n)e(decode xs))*Z.to_nat d)%nat).
 { apply(uniform_charge_bound (odd_ids m ys)(completion(Z.to_nat n)e(decode xs))
   (fun r q=>row_vector n(Z.of_nat r)h q)(Z.to_nat d)).
   - intros r Hin;apply odd_ids_member in Hin;destruct Hin as [R Odd].
     destruct(indexed_odd_extension n m h xs fs ys e r M Target R Odd) as [q [Hr Hc]].
     exists q;split;[assumption|apply repair_member in Hr;tauto].
   - intros q Hq;apply completion_member in Hq;destruct Hq as [Q [Eq Sq]].
     assert(Qz:0<=Z.of_nat q<n) by(apply Nat2Z.inj_lt in Q;rewrite Z2Nat.id in Q by lia;lia).
     assert(Fq:decode fs q=false).
     { destruct Target as [[Sub Avoid] _];destruct(decode fs q) eqn:F;[pose proof(Avoid q Q F);congruence|reflexivity]. }
     assert(X:Znth(Z.of_nat q) xs=0).
     { rewrite decode_at_nat in Sq;assert(Bx:Znth(Z.of_nat q) xs=0 \/ Znth(Z.of_nat q) xs=1) by(apply Forall_Znth;auto;lia);destruct Bx as [Bx|Bx];[assumption|rewrite Bx in Sq;discriminate]. }
     assert(F:Znth(Z.of_nat q) fs=0).
     { rewrite decode_at_nat in Fq;assert(Bf:Znth(Z.of_nat q) fs=0 \/ Znth(Z.of_nat q) fs=1) by(apply Forall_Znth;auto;lia);destruct Bf as [Bf|Bf];[assumption|rewrite Bf in Fq;discriminate]. }
     specialize(Deg (Z.of_nat q) Qz X F);rewrite degree_count_sum in Deg by assumption.
     rewrite Nat2Z.id in Deg;lia. }
 rewrite odd_count_length by assumption;rewrite completion_weight in B.
 apply Nat2Z.inj_le in B;rewrite Nat2Z.inj_mul,Z2Nat.id in B by assumption;assumption.
Qed.
Print Assumptions indexed_empty_reject.
Print Assumptions indexed_packing_bound.
Print Assumptions indexed_charge_bound.
