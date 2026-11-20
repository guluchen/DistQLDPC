(* The producer may suggest any permutation. Its inverse and both row-space
   conditions are tested before any root is skipped. *)
From Coq Require Import List Bool Arith Lia Sorting.Permutation.
Require Import CCV.CCModel CCV.CCFunctional CCV.CCOrbit CCV.CCQuotientCertificate CCV.CCPCMDetectors
 CCV.CCSeedCoverage CCV.CCPackedWords CCV.CCPackedLayout CCV.CCPackedRoots.
Import ListNotations. Local Open Scope nat_scope.

Definition indices_ok n (p inv:list nat) :=
  (length p=?n) && (length inv=?n) &&
  forallb (fun i=> (nth i p n <? n) && (nth i inv n <? n) &&
    (nth (nth i p n) inv n =? i) && (nth (nth i inv n) p n =? i)) (seq 0 n).

Lemma inverse_checked n p inv : indices_ok n p inv=true ->
  coordinates n p /\ inverse_at n p inv.
Proof.
  unfold indices_ok;rewrite !andb_true_iff,!Nat.eqb_eq,forallb_forall.
  intros [[P Q] All].
  assert (A:forall i,i<n -> nth i p n<n /\nth i inv n<n /\
     nth (nth i p n) inv n=i /\ nth (nth i inv n) p n=i).
  { intros i I;specialize (All i ltac:(apply in_seq;lia)).
    rewrite !andb_true_iff,!Nat.ltb_lt,!Nat.eqb_eq in All;tauto. }
  split;[|intros i I;apply A;assumption].
  apply NoDup_Permutation;[|apply seq_NoDup|].
  - apply (proj2 (NoDup_nth p n));intros i j I J E;rewrite P in I,J.
    pose proof (A i I);pose proof(A j J).
    assert (nth (nth i p n) inv n=nth (nth j p n) inv n) by now rewrite E.
    intuition congruence.
  - intro i;rewrite in_seq;split.
    + intro InP;apply In_nth with (d:=n) in InP as [j [J <-]];rewrite P in J;specialize(A j J);lia.
    + intros [_ I];destruct (A i I) as [_ [J [_ Eq]]]. rewrite <-Eq at 1;apply nth_In;lia.
Qed.

Definition packed_parity n a e := parity n (decode a) e.
Lemma add_parity n a b e : packed_parity n (add_bits a b) e =
  xorb (packed_parity n a e) (packed_parity n b e).
Proof.
  unfold packed_parity. rewrite <- qcert_parity_xor_left.
  rewrite !(qcert_parity_comm n _ e);apply parity_ext;intros i I;apply decode_add.
Qed.
Definition table := list (nat*bits).
Fixpoint reduce (b:table) a :=
  match b with []=>a | (i,r)::tail=>reduce tail (if decode a i then add_bits a r else a) end.
Definition neutral n rows a := forall e,kernel n rows e->packed_parity n a e=false.
Definition basis_ok n rows (b:table) := Forall (fun x=>neutral n rows (snd x)) b.
Lemma reduce_parity n rows b a e : basis_ok n rows b ->kernel n rows e ->
  packed_parity n (reduce b a) e=packed_parity n a e.
Proof.
  intros B K;revert a;induction B as [|[i r] tail R T IH];intro a;[reflexivity|].
  cbn [reduce];rewrite IH;destruct (decode a i);[|reflexivity].
  cbn [snd] in R;rewrite add_parity,(R e K),xorb_false_r;reflexivity.
Qed.

Fixpoint build_basis n (rs:list bits) (b:table) :=
  match rs with []=>b | r::rest=>
    let reduced:=reduce b r in
    match find (decode reduced) (seq 0 n) with
    | None=>build_basis n rest b
    | Some i=>build_basis n rest (b++[(i,reduced)])
    end
  end.
Lemma build_basis_ok n rows rs b : Forall (neutral n rows) rs -> basis_ok n rows b ->
  basis_ok n rows (build_basis n rs b).
Proof.
  intro R;revert b;induction R as [|r rs R Rs IH];intros b B;[exact B|].
  cbn [build_basis];destruct (find _ _) as [i|];apply IH;[|exact B].
  apply Forall_app;split;[exact B|];constructor;[|constructor].
  intros e K;cbn [snd];rewrite (reduce_parity _ _ _ _ _ B K);apply R;exact K.
Qed.
Definition packv n r:=encode(tabulate n r).
Lemma packv_parity n r e : n<=189 -> packed_parity n (packv n r) e=parity n r e.
Proof.
  intro N;unfold packed_parity;rewrite !(qcert_parity_comm n _ e);apply parity_ext;intros i I.
  unfold packv;rewrite encode_nth,tabulate_at by (try exact I;unfold tabulate;rewrite map_length,seq_length;lia);reflexivity.
Qed.
Definition images_ok n p rows :=
  let b:=build_basis n (map (packv n) rows) [] in
  forallb (fun r=>is_empty (reduce b (packv n (perm_vector n p r)))) rows.
Lemma images_checked n p rows : n<=189 ->images_ok n p rows=true ->preserves_tests n p rows.
Proof.
  intros N;unfold images_ok;set (b:=build_basis _ _ _).
  assert (B:basis_ok n rows b).
  { unfold b;apply build_basis_ok;[|constructor].
    apply Forall_forall;intros x InX;apply in_map_iff in InX as [r [<- I]];intros e K.
    rewrite packv_parity by exact N;apply K;exact I. }
  rewrite forallb_forall;intros All r InR e K;specialize (All r InR);apply empty_none in All.
  pose proof (reduce_parity n rows b (packv n (perm_vector n p r)) e B K) as E.
  rewrite All,packv_parity in E by exact N.
  rewrite <-E;unfold packed_parity;rewrite qcert_parity_comm.
  rewrite (parity_ext n e (decode none) zero_vector) by (intros;apply decode_none).
  rewrite qcert_parity_comm;apply qcert_zero_dot.
Qed.
Definition checked_skip n hs ls (p inv:list nat) :=
  if indices_ok n p inv && images_ok n inv hs && images_ok n p ls then
    fun i=>nth i inv n <? i
  else fun _=>false.
Theorem checked_skip_sound n hs ls p inv cap : n<=189 ->
  root_skip_ok n hs ls cap (checked_skip n hs ls p inv).
Proof.
  intro N;unfold checked_skip; destruct (_ && _ && _)%bool eqn:C;[|intros i I;discriminate].
  rewrite !andb_true_iff in C;destruct C as [[Index H] L].
  destruct (inverse_checked n p inv Index) as [Perm Inv].
  intros i I Earlier Before;apply Nat.ltb_lt in Earlier.
  assert (Maps:nth (nth i inv n) p n=i).
  { unfold indices_ok in Index;rewrite !andb_true_iff,forallb_forall in Index.
    destruct Index as [_ All];specialize(All i ltac:(apply in_seq;lia)).
    rewrite !andb_true_iff,!Nat.eqb_eq in All;tauto. }
  eapply orbit_seed_advances;[exact Perm|exact Inv|apply images_checked;assumption|
    apply images_checked;assumption|exact Earlier|exact Maps|exact Before].
Qed.

(* Materialize the decisions. Otherwise OCaml extraction eta-expands a
   partial application and repeats both elimination checks at every root. *)
Definition flags n hs ls p inv :=
  if indices_ok n p inv && images_ok n inv hs && images_ok n p ls then
    map (fun i=>nth i inv n <? i) (seq 0 n)
  else repeat false n.
Lemma flag_at n hs ls p inv i : i<n ->
  nth i (flags n hs ls p inv) false=checked_skip n hs ls p inv i.
Proof.
  intros I;unfold flags,checked_skip;destruct (_ && _ && _)%bool.
  - change (nth i (tabulate n (fun j=>nth j inv n <? j)) false = (nth i inv n <? i)).
    exact (tabulate_at n (fun j=>nth j inv n <? j) i I).
  - apply nth_repeat.
Qed.
