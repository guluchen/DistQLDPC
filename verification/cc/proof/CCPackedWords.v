(* Compact sets with explicit indices. All operations use Coq's specified
   63-bit primitive integers; the three lanes cover coordinates 0..188. *)
From Coq Require Import List Bool Arith ZArith Lia Uint63.
Require Import CCV.CCModel CCV.CCFunctional.
Import ListNotations.
Local Open Scope nat_scope.

Record bits := lanes { low:int; middle:int; high:int }.
Definition none := lanes 0%uint63 0%uint63 0%uint63.
Definition index63 n := Uint63.of_Z (Z.of_nat n).
Definition decode (a:bits) (i:nat) : bool :=
  if i <? 63 then Uint63.bit (low a) (index63 i)
  else if i <? 126 then Uint63.bit (middle a) (index63 (i-63))
       else if i <? 189 then Uint63.bit (high a) (index63 (i-126)) else false.
Definition add_bits a b := lanes (Uint63.lxor (low a) (low b))
  (Uint63.lxor (middle a) (middle b)) (Uint63.lxor (high a) (high b)).
Definition meet a b := lanes (Uint63.land (low a) (low b))
  (Uint63.land (middle a) (middle b)) (Uint63.land (high a) (high b)).
Definition join a b := lanes (Uint63.lor (low a) (low b))
  (Uint63.lor (middle a) (middle b)) (Uint63.lor (high a) (high b)).
Definition subtract a b := add_bits a (meet a b).
Definition is_empty a := (Uint63.eqb (low a) 0%uint63 &&
  Uint63.eqb (middle a) 0%uint63 && Uint63.eqb (high a) 0%uint63)%bool.

Ltac lanes_cases i :=
  unfold decode; destruct (i <? 63), (i <? 126), (i <? 189);
  cbn [add_bits meet join none low middle high].
Lemma decode_none i : decode none i = false.
Proof. lanes_cases i; solve [apply Uint63.bit_0|reflexivity]. Qed.
Lemma decode_add a b i : decode (add_bits a b) i=xorb (decode a i) (decode b i).
Proof. lanes_cases i; solve [apply Uint63.lxor_spec|reflexivity]. Qed.
Lemma decode_meet a b i : decode (meet a b) i=andb (decode a i) (decode b i).
Proof. lanes_cases i; solve [apply Uint63.land_spec|reflexivity]. Qed.
Lemma decode_join a b i : decode (join a b) i=orb (decode a i) (decode b i).
Proof. lanes_cases i; solve [apply Uint63.lor_spec|reflexivity]. Qed.
Lemma decode_subtract a b i : decode (subtract a b) i=andb (decode a i) (negb (decode b i)).
Proof. unfold subtract;rewrite decode_add, decode_meet; destruct (decode a i),(decode b i);reflexivity. Qed.
Lemma empty_none a : is_empty a=true -> a=none.
Proof.
  destruct a as [x y z]; unfold is_empty; cbn [low middle high].
  rewrite !andb_true_iff,!Uint63.eqb_spec. intros [[-> ->] ->];reflexivity.
Qed.

Definition one_word i := Uint63.lsl 1%uint63 (index63 i).
Definition singleton i :=
  if i <? 63 then lanes (one_word i) 0%uint63 0%uint63
  else if i <? 126 then lanes 0%uint63 (one_word (i-63)) 0%uint63
       else if i <? 189 then lanes 0%uint63 0%uint63 (one_word (i-126)) else none.

Lemma word_index_small i : i<189 -> Uint63.to_Z (index63 i) = Z.of_nat i.
Proof.
  intro B;unfold index63;rewrite Uint63.of_Z_spec, Z.mod_small;[reflexivity|].
  change (0 <= Z.of_nat i < 9223372036854775808)%Z;lia.
Qed.
Lemma one_word_bit i j : i<63 -> j<63 ->
  Uint63.bit (one_word i) (index63 j) = Nat.eqb i j.
Proof.
  intros I J. unfold one_word; rewrite Uint63.bitE,Uint63.lsl_spec.
  rewrite !word_index_small by lia.
  change (Z.testbit ((1 * 2^ Z.of_nat i) mod 9223372036854775808) (Z.of_nat j) = Nat.eqb i j).
  rewrite Z.mul_1_l,Z.mod_small.
  - rewrite Z.pow2_bits_eqb by lia. destruct (Nat.eqb i j) eqn:E;
      [apply Nat.eqb_eq in E;subst;now rewrite Z.eqb_refl|apply Nat.eqb_neq in E;apply Z.eqb_neq;lia].
  - change (0<=2^Z.of_nat i<2^63)%Z. split;[apply Z.pow_nonneg;lia|apply Z.pow_lt_mono_r;lia].
Qed.

Lemma singleton_bit i j : i<189 -> j<189 -> decode (singleton i) j=Nat.eqb i j.
Proof.
  intros I J. unfold singleton,decode.
  destruct (Nat.ltb_spec0 i 63), (Nat.ltb_spec0 j 63),
           (Nat.ltb_spec0 i 126), (Nat.ltb_spec0 j 126),
           (Nat.ltb_spec0 i 189), (Nat.ltb_spec0 j 189); try lia;
    cbn [low middle high]; rewrite ?Uint63.bit_0,?one_word_bit by lia;
    destruct (Nat.eqb_spec i j); subst; rewrite ?Nat.eqb_refl;
    first [reflexivity|apply Nat.eqb_eq;lia|apply Nat.eqb_neq;lia|lia].
Qed.

Lemma word_ext_small x y :
  (forall i, i<63 -> Uint63.bit x (index63 i)=Uint63.bit y (index63 i)) -> x=y.
Proof.
  intro H;apply Uint63.bit_ext;intro j.
  destruct (Uint63.leb Uint63.digits j) eqn:E.
  - rewrite !Uint63.bit_M by exact E;reflexivity.
  - assert (B:(0<=Uint63.to_Z j<63)%Z).
    { pose proof (Uint63.to_Z_bounded j).
      destruct (Z_lt_ge_dec (Uint63.to_Z j) 63);[lia|].
      assert ((Uint63.digits <=? j)%uint63=true) by (apply Uint63.leb_spec;change (63<=Uint63.to_Z j)%Z;lia).
      congruence. }
    set (k:=Z.to_nat (Uint63.to_Z j)).
    assert (J:index63 k=j) by (unfold k,index63;rewrite Z2Nat.id by lia;apply Uint63.of_to_Z).
    rewrite <- J; apply H;unfold k;lia.
Qed.

Lemma bits_ext a b : (forall i, i<189 -> decode a i=decode b i) -> a=b.
Proof.
  intros H;destruct a as [a0 a1 a2], b as [b0 b1 b2]; f_equal;apply word_ext_small;intros i I.
  - specialize (H i ltac:(lia));unfold decode in H.
    destruct (Nat.ltb_spec0 i 63);[exact H|lia].
  - specialize (H (63+i) ltac:(lia));unfold decode in H.
    destruct (Nat.ltb_spec0 (63+i) 63);[lia|];destruct (Nat.ltb_spec0 (63+i) 126);[|lia].
    replace (63+i-63) with i in H by lia;exact H.
  - specialize (H (126+i) ltac:(lia));unfold decode in H.
    destruct (Nat.ltb_spec0 (126+i) 63);[lia|];destruct (Nat.ltb_spec0 (126+i) 126);[lia|].
    destruct (Nat.ltb_spec0 (126+i) 189);[|lia]. replace (126+i-126) with i in H by lia;exact H.
Qed.
