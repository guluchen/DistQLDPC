(* A checked permutation can move a minimum to an admitted seed. *)
From Coq Require Import List Bool Arith Lia Sorting.Permutation.
Require Import CCV.CCModel CCV.CCFunctional CCV.CCPCMDetectors CCV.CCCSSBridge CCV.CCQuotientCertificate.
Import ListNotations.
Local Open Scope nat_scope.

Definition perm_vector n p (v:vector) : vector := fun i => v (nth i p n).
Definition coordinates n (p:list nat) := Permutation p (seq 0 n).

Lemma perm_length n p : coordinates n p -> length p=n.
Proof. intro P; apply Permutation_length in P; now rewrite seq_length in P. Qed.

Lemma tab_perm n p v : length p=n -> tabulate n (perm_vector n p v) = map v p.
Proof.
  intro Len; apply nth_ext with (d:=false) (d':=false).
  - unfold tabulate; rewrite !map_length,seq_length; lia.
  - intros i Hi. assert (I:i<n) by (unfold tabulate in Hi; rewrite map_length,seq_length in Hi; exact Hi).
    rewrite tabulate_at by exact I. unfold perm_vector.
    rewrite (nth_indep (map v p) false (v n)) by (rewrite map_length; lia).
    rewrite map_nth. reflexivity.
Qed.

Fixpoint count_bits (xs:list bool) :nat :=
  match xs with []=>0 | x::tail=>(if x then 1 else 0)+count_bits tail end.
Lemma count_app xs ys : count_bits (xs++ys) = count_bits xs+count_bits ys.
Proof. induction xs; cbn [count_bits app]; [reflexivity|rewrite IHxs; lia]. Qed.
Lemma count_tab n e : count_bits (tabulate n e)=weight n e.
Proof.
  induction n as [|n IH]; [reflexivity|].
  unfold tabulate in *; rewrite seq_S,map_app,count_app,IH; cbn [map Nat.add count_bits weight].
  destruct (e n); lia.
Qed.
Lemma count_perm a b : Permutation a b -> count_bits a=count_bits b.
Proof. induction 1; cbn [count_bits] in *; lia. Qed.
Lemma orbit_weight n p e : coordinates n p -> weight n (perm_vector n p e)=weight n e.
Proof.
  intro P. rewrite <-!count_tab,tab_perm by (apply perm_length; exact P).
  apply count_perm. unfold tabulate. apply Permutation_map; exact P.
Qed.

Fixpoint xor_bits (xs:list bool) :bool :=
  match xs with []=>false | x::tail=>xorb x (xor_bits tail) end.
Lemma xor_app xs ys : xor_bits (xs++ys)=xorb (xor_bits xs) (xor_bits ys).
Proof. induction xs; cbn [app xor_bits]; [destruct (xor_bits ys);reflexivity|].
  rewrite IHxs; destruct a,(xor_bits xs),(xor_bits ys); reflexivity. Qed.
Lemma xor_dot n a b :
  xor_bits (tabulate n (fun i=>andb (a i) (b i)))=parity n a b.
Proof.
  induction n as [|n IH]; [reflexivity|].
  unfold tabulate in *;rewrite seq_S,map_app,xor_app,IH;cbn [map Nat.add xor_bits parity].
  destruct (a n),(b n),(parity n a b); reflexivity.
Qed.
Lemma xor_perm a b : Permutation a b -> xor_bits a=xor_bits b.
Proof.
  induction 1;cbn [xor_bits];try congruence.
  destruct x,y,(xor_bits l);reflexivity.
Qed.
Lemma orbit_parity n p a b : coordinates n p ->
  parity n (perm_vector n p a) (perm_vector n p b)=parity n a b.
Proof.
  intro P. rewrite <-!xor_dot.
  change (fun i => (perm_vector n p a i && perm_vector n p b i)%bool) with
    (perm_vector n p (fun i=>(a i && b i)%bool)).
  rewrite tab_perm by (apply perm_length;exact P).
  apply xor_perm; unfold tabulate. apply Permutation_map; exact P.
Qed.

Definition inverse_at n p inv := forall i, i<n -> nth (nth i p n) inv n = i.
Definition preserves_tests n p rows := forall r, In r rows -> forall e,
  kernel n rows e -> parity n (perm_vector n p r) e=false.

Lemma span_dot n rows a e : rowspan n rows a -> kernel n rows e -> parity n a e=false.
Proof.
  intros [bs [Len Eq]] K.
  rewrite qcert_parity_comm, (parity_ext n e a (linear_combination rows bs)) by exact Eq.
  rewrite qcert_parity_comm; now apply qcert_lc_zero.
Qed.
Theorem orbit_minimum n hs ls p inv e :
  coordinates n p -> inverse_at n p inv ->
  preserves_tests n inv hs -> preserves_tests n p ls ->
  minimum n hs ls e -> minimum n hs ls (perm_vector n p e).
Proof.
  intros P Inv Hrows Lrows [[Pos [K [l [Lin Odd]]]] Min].
  split; [|rewrite orbit_weight by exact P;exact Min].
  split; [rewrite orbit_weight by exact P;exact Pos|]. split.
  - intros h Hin.
    pose proof (Hrows h Hin e K) as Zero.
    rewrite <- (orbit_parity n p (perm_vector n inv h) e P) in Zero.
    rewrite qcert_parity_comm in Zero |- *.
    erewrite parity_ext in Zero; [exact Zero|].
    intros i I; unfold perm_vector; now rewrite Inv.
  - destruct (existsb (fun r=>parity n r (perm_vector n p e)) ls) eqn:Hit.
    + apply existsb_exists in Hit; exact Hit.
    + exfalso. pose proof (existsb_parity_false n ls _ Hit) as Neutral.
      pose proof (Lrows l Lin _ Neutral) as Z.
      rewrite orbit_parity, Odd in Z by exact P; discriminate.
Qed.

(* Canonical-seed exclusion needs only one earlier coordinate of a transformed
   minimum. The transformation may introduce additional earlier coordinates. *)
Require Import CCV.CCSeedCoverage.
Theorem orbit_seed_advances n hs ls cap seed p inv u :
  coordinates n p -> inverse_at n p inv ->
  preserves_tests n inv hs -> preserves_tests n p ls ->
  u<seed -> nth u p n=seed ->
  seeds_before_clear n hs ls cap seed -> seeds_before_clear n hs ls cap (S seed).
Proof.
  intros P Inv Hrows Lrows Earlier Maps Before.
  apply completed_seed_advances; [exact Before|].
  intros e Min Bound Hit.
  pose proof (orbit_minimum n hs ls p inv e P Inv Hrows Lrows Min) as Rot.
  assert (Bound':weight n (perm_vector n p e)<=cap) by (rewrite orbit_weight by exact P;exact Bound).
  pose proof (Before (perm_vector n p e) Rot Bound' u Earlier) as Zero.
  unfold perm_vector in Zero; rewrite Maps,Hit in Zero;discriminate.
Qed.
