(* Whole-half lower bound from checked roots. The per-coordinate skip
   predicate is justified separately by a validated permutation. *)
From Coq Require Import List Bool Arith Lia.
Require Import CCV.CCModel CCV.CCFunctional CCV.CCCache CCV.CCSeedCoverage
 CCV.CCPackedWords CCV.CCPackedBranch CCV.CCPackedRefute.
Import ListNotations. Local Open Scope nat_scope.

Fixpoint all_roots (run:bits->bits->bits->bool) skip free cs :=
  match cs with []=>true | c::tail=>
    let next:=subtract free (mark c) in
    (skip (position c) || run (check_delta c) (logical_delta c) next) &&
    all_roots run skip next tail
  end.
Definition root_skip_ok n hs ls cap skip :=
  forall i, i<n ->skip i=true ->seeds_before_clear n hs ls cap i ->
  seeds_before_clear n hs ls cap (S i).
Lemma unit_signature n q rows a : q<n ->column_signature rows q a ->
  signature n rows (unit_vector q) a.
Proof. intros Q D i;rewrite parity_unit_inside by exact Q;apply D. Qed.
Lemma unit_weight n q : q<n -> weight n (unit_vector q)=1.
Proof.
  intro Q. replace (weight n (unit_vector q)) with (weight n (setbit zero_vector q)).
  - rewrite setbit_weight,zero_weight by (try exact Q;reflexivity);reflexivity.
  - apply weight_ext;intros i I;unfold unit_vector,setbit,zero_vector;destruct (i=?q);reflexivity.
Qed.
Lemma roots_advance n hs ls test row choose short rest skip cs seed free :
  active_ok (length hs) test -> layout n hs ls row -> short_correct n hs short ->root_skip_ok n hs ls (S rest) skip ->
  Forall (col_ok n hs ls) cs -> map position cs=seq seed (length cs) ->
  (forall j,seed<=j<n ->decode free j=true) ->
  seeds_before_clear n hs ls (S rest) seed ->
  all_roots (refute test row choose short rest) skip free cs=true ->
  seeds_before_clear n hs ls (S rest) (seed+length cs).
Proof.
  intros Check Layout Short Skip Col;revert seed free;induction Col as [|c tail C CT IH];
    intros seed free Pos Free Before R;[now rewrite Nat.add_0_r|].
  cbn [map seq length] in Pos;injection Pos as Id Seq.
  cbn [all_roots] in R;apply andb_true_iff in R as [Head Tail].
  destruct C as [Q [M [D E]]].
  assert (Later:forall j,S seed<=j<n ->decode (subtract free (mark c)) j=true).
  { intros j J; rewrite decode_subtract,M,Free,Id by lia.
    destruct (Nat.eqb_spec j seed);[lia|reflexivity]. }
  assert (Next:seeds_before_clear n hs ls (S rest) (S seed)).
  { apply orb_true_iff in Head as [Sk|Done].
    - apply Skip;try lia;[now rewrite <-Id|exact Before].
    - apply completed_seed_advances;[exact Before|]. intros e Min Cap Hit.
      pose proof (unit_weight n (position c) Q) as W.
      assert (Fit:fits n e (unit_vector (position c)) (subtract free (mark c))).
      { split.
        + intros j J U;unfold unit_vector in U;apply Nat.eqb_eq in U;rewrite U,Id;exact Hit.
        + intros j J T Z. apply Later;split;[|exact J].
          unfold unit_vector in Z;apply Nat.eqb_neq in Z.
          destruct (lt_dec j seed);[specialize(Before e Min Cap j l);congruence|lia]. }
      pose proof (refute_safe n hs ls test row choose short rest e _ _ _ _ Check Layout Short Min Fit
        ltac:(lia) ltac:(lia) (unit_signature n _ hs _ Q D) (unit_signature n _ ls _ Q E)).
      congruence. }
  replace (seed+length(c::tail)) with (S seed+length tail) by (simpl;lia).
  eapply IH; eauto.
Qed.

Theorem packed_lower_bound n hs ls test row choose short cap skip cs free :
  active_ok (length hs) test -> layout n hs ls row ->short_correct n hs short ->root_skip_ok n hs ls (S cap) skip ->
  Forall (col_ok n hs ls) cs -> map position cs=seq 0 n ->
  (forall j,j<n->decode free j=true) ->
  all_roots (refute test row choose short cap) skip free cs=true ->
  forall e, good n hs ls e -> S cap<weight n e.
Proof.
  intros Check L T Sk Col Seq F OK. assert (Len:length cs=n).
  { pose proof(f_equal (@length nat) Seq) as Eq;rewrite map_length,seq_length in Eq;exact Eq. }
  pose proof (roots_advance n hs ls test row choose short cap skip cs 0 free Check L T Sk Col
    ltac:(now rewrite Len) ltac:(intros;apply F;lia) (seeds_initial n hs ls (S cap)) OK) as All.
  cbn [Nat.add] in All. rewrite Len in All. apply all_seeds_empty_no_good;exact All.
Qed.
