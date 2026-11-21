(* Product of two checked 378-bit values. Every physical coordinate belongs
   to exactly one member of the product. *)
From Coq Require Import List Bool Arith Lia Uint63.
Require CCWideWords CCWideLayout.
Local Open Scope nat_scope.
Record bits := pair_bits { left_half:CCWideWords.bits; right_half:CCWideWords.bits }.
Definition none := pair_bits CCWideWords.none CCWideWords.none.
Definition decode a i := if i <? 378 then CCWideWords.decode (left_half a) i
                         else CCWideWords.decode (right_half a) (i-378).
Definition comb op a b := pair_bits (op (left_half a) (left_half b)) (op (right_half a) (right_half b)).
Definition add_bits := comb CCWideWords.add_bits.
Definition meet := comb CCWideWords.meet.
Definition join := comb CCWideWords.join.
Definition subtract := comb CCWideWords.subtract.
Definition is_empty a := CCWideWords.is_empty (left_half a) && CCWideWords.is_empty (right_half a).
Definition disjoint a b := CCWideWords.disjoint (left_half a) (left_half b) &&
  CCWideWords.disjoint (right_half a) (right_half b).
Lemma disjoint_meet a b : disjoint a b=is_empty(meet a b).
Proof. unfold disjoint,is_empty,meet,comb;cbn [left_half right_half].
  now rewrite !CCWideWords.disjoint_meet. Qed.
Definition singleton i := if i <? 378 then pair_bits (CCWideWords.singleton i) CCWideWords.none
                          else pair_bits CCWideWords.none (CCWideWords.singleton (i-378)).
Lemma decode_none i : decode none i=false.
Proof. unfold decode;destruct (i <? 378);apply CCWideWords.decode_none. Qed.
Lemma decode_add a b i : decode(add_bits a b)i=xorb(decode a i)(decode b i).
Proof. unfold decode;destruct (i <? 378);apply CCWideWords.decode_add. Qed.
Lemma decode_meet a b i : decode(meet a b)i=andb(decode a i)(decode b i).
Proof. unfold decode;destruct (i <? 378);apply CCWideWords.decode_meet. Qed.
Lemma decode_join a b i : decode(join a b)i=orb(decode a i)(decode b i).
Proof. unfold decode;destruct (i <? 378);apply CCWideWords.decode_join. Qed.
Lemma decode_subtract a b i : decode(subtract a b)i=andb(decode a i)(negb(decode b i)).
Proof. unfold decode;destruct (i <? 378);apply CCWideWords.decode_subtract. Qed.
Lemma empty_none a : is_empty a=true ->a=none.
Proof. destruct a as [u v];unfold is_empty;cbn. rewrite andb_true_iff.
 intros [U V];apply CCWideWords.empty_none in U;apply CCWideWords.empty_none in V;subst;reflexivity. Qed.
Lemma singleton_bit i j : i<756 ->j<756 ->decode(singleton i)j=Nat.eqb i j.
Proof.
 intros I J;unfold decode,singleton.
 destruct(Nat.ltb_spec0 i 378), (Nat.ltb_spec0 j 378);cbn[left_half right_half];
 rewrite ?CCWideWords.decode_none,?CCWideWords.singleton_bit by lia;
 destruct (Nat.eqb_spec i j);subst;rewrite ?Nat.eqb_refl;try reflexivity;try lia;
 first [apply Nat.eqb_neq;lia | symmetry;apply Nat.eqb_neq;lia].
Qed.
Lemma bits_ext a b : (forall i, i<756 ->decode a i=decode b i)->a=b.
Proof.
 destruct a as [a0 a1],b as [b0 b1];intro E;f_equal;apply CCWideWords.bits_ext;intros i I.
 - specialize(E i ltac:(lia));unfold decode in E;destruct(Nat.ltb_spec0 i 378);[exact E|lia].
 - specialize(E (378+i) ltac:(lia));unfold decode in E;destruct(Nat.ltb_spec0 (378+i) 378);[lia|].
   replace (378+i-378) with i in E by lia;exact E.
Qed.
Lemma outside a i : 756<=i -> decode a i=false.
Proof. intro I;unfold decode;destruct(Nat.ltb_spec0 i 378);[lia|];apply CCWideLayout.decode_out;lia. Qed.
