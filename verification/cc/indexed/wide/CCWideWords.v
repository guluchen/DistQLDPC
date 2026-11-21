(* Product of two checked 189-bit values. Every physical coordinate belongs
   to exactly one member of the product. *)
From Coq Require Import List Bool Arith Lia Uint63.
Require CCV.CCPackedWords CCV.CCPackedLayout.
Local Open Scope nat_scope.
Record bits := pair_bits { first_part:CCV.CCPackedWords.bits; second_part:CCV.CCPackedWords.bits }.
Definition none := pair_bits CCV.CCPackedWords.none CCV.CCPackedWords.none.
Definition decode a i := if i <? 189 then CCV.CCPackedWords.decode (first_part a) i
                         else CCV.CCPackedWords.decode (second_part a) (i-189).
Definition comb op a b := pair_bits (op (first_part a) (first_part b)) (op (second_part a) (second_part b)).
Definition add_bits := comb CCV.CCPackedWords.add_bits.
Definition meet := comb CCV.CCPackedWords.meet.
Definition join := comb CCV.CCPackedWords.join.
Definition subtract := comb CCV.CCPackedWords.subtract.
Definition is_empty a := CCV.CCPackedWords.is_empty (first_part a) && CCV.CCPackedWords.is_empty (second_part a).
Definition disjoint a b := CCV.CCPackedWords.disjoint (first_part a) (first_part b) &&
  CCV.CCPackedWords.disjoint (second_part a) (second_part b).
Lemma disjoint_meet a b : disjoint a b=is_empty(meet a b).
Proof. unfold disjoint,is_empty,meet,comb;cbn [first_part second_part].
  now rewrite !CCV.CCPackedWords.disjoint_meet. Qed.
Definition singleton i := if i <? 189 then pair_bits (CCV.CCPackedWords.singleton i) CCV.CCPackedWords.none
                          else pair_bits CCV.CCPackedWords.none (CCV.CCPackedWords.singleton (i-189)).
Lemma decode_none i : decode none i=false.
Proof. unfold decode;destruct (i <? 189);apply CCV.CCPackedWords.decode_none. Qed.
Lemma decode_add a b i : decode(add_bits a b)i=xorb(decode a i)(decode b i).
Proof. unfold decode;destruct (i <? 189);apply CCV.CCPackedWords.decode_add. Qed.
Lemma decode_meet a b i : decode(meet a b)i=andb(decode a i)(decode b i).
Proof. unfold decode;destruct (i <? 189);apply CCV.CCPackedWords.decode_meet. Qed.
Lemma decode_join a b i : decode(join a b)i=orb(decode a i)(decode b i).
Proof. unfold decode;destruct (i <? 189);apply CCV.CCPackedWords.decode_join. Qed.
Lemma decode_subtract a b i : decode(subtract a b)i=andb(decode a i)(negb(decode b i)).
Proof. unfold decode;destruct (i <? 189);apply CCV.CCPackedWords.decode_subtract. Qed.
Lemma empty_none a : is_empty a=true ->a=none.
Proof. destruct a as [u v];unfold is_empty;cbn. rewrite andb_true_iff.
 intros [U V];apply CCV.CCPackedWords.empty_none in U;apply CCV.CCPackedWords.empty_none in V;subst;reflexivity. Qed.
Lemma singleton_bit i j : i<378 ->j<378 ->decode(singleton i)j=Nat.eqb i j.
Proof.
 intros I J;unfold decode,singleton.
 destruct(Nat.ltb_spec0 i 189), (Nat.ltb_spec0 j 189);cbn[first_part second_part];
 rewrite ?CCV.CCPackedWords.decode_none,?CCV.CCPackedWords.singleton_bit by lia;
 destruct (Nat.eqb_spec i j);subst;rewrite ?Nat.eqb_refl;try reflexivity;try lia;
 first [apply Nat.eqb_neq;lia | symmetry;apply Nat.eqb_neq;lia].
Qed.
Lemma bits_ext a b : (forall i, i<378 ->decode a i=decode b i)->a=b.
Proof.
 destruct a as [a0 a1],b as [b0 b1];intro E;f_equal;apply CCV.CCPackedWords.bits_ext;intros i I.
 - specialize(E i ltac:(lia));unfold decode in E;destruct(Nat.ltb_spec0 i 189);[exact E|lia].
 - specialize(E (189+i) ltac:(lia));unfold decode in E;destruct(Nat.ltb_spec0 (189+i) 189);[lia|].
   replace (189+i-189) with i in E by lia;exact E.
Qed.
Lemma outside a i : 378<=i -> decode a i=false.
Proof. intro I;unfold decode;destruct(Nat.ltb_spec0 i 189);[lia|];apply CCV.CCPackedLayout.decode_out;lia. Qed.
