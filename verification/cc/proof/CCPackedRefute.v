(* Refutation of one rooted CC subtree. Hints only choose candidate cuts;
   every successful cut is checked against the current syndrome and geometry. *)
From Coq Require Import List Bool Arith Lia.
Require Import CCV.CCModel CCV.CCFunctional CCV.CCPackedWords CCV.CCPackedBranch.
Import ListNotations. Local Open Scope nat_scope.

Record packed_row := prow { support_mask:bits; neighbors:list column }.
Definition layout n (hs ls:list vector) (row:nat->packed_row) :=
  forall i, i<length hs ->
    (forall q, q<n -> decode (support_mask (row i)) q=nth i hs zero_vector q) /\
    Forall (col_ok n hs ls) (neighbors (row i)) /\
    (forall q,q<n -> nth i hs zero_vector q=true ->
       exists c,In c (neighbors (row i)) /\ position c=q).

Inductive hint := split_row (i:nat) | pack_rows (ids:list nat).
Definition active m sy i := (i <? m) && decode sy i.

Definition active_ok m (test:bits->nat->bool) := forall sy i,test sy i=true ->active m sy i=true.

Fixpoint packing_cut (test:bits->nat->bool) row sy free budget used ids {struct ids} :=
  match ids with
  | []=>false
  | i::tail=>
      if test sy i then
        let can:=meet free (support_mask (row i)) in
        if is_empty (meet used can) then
          match budget with
          | O=>true
          | S k=>packing_cut test row sy free k (join used can) tail
          end
        else false
      else false
  end.

Definition unseen (e s:vector) used : vector :=
  fun i => andb (vdiff e s i) (negb (decode used i)).
Lemma unseen_join n e s used can q :
  q<n -> vdiff e s q=true -> decode used q=false -> decode can q=true ->
  weight n (unseen e s (join used can)) < weight n (unseen e s used).
Proof.
  intros I Q Old New; apply (weight_strict_extra n _ _ q).
  - intros j J;unfold unseen;rewrite decode_join.
    destruct (vdiff e s j),(decode used j),(decode can j);simpl;congruence.
  - exact I.
  - unfold unseen;rewrite decode_join,Q,Old,New;reflexivity.
  - unfold unseen;rewrite Q,Old;reflexivity.
Qed.
Lemma active_target n hs ls row e s sy a i :
  layout n hs ls row -> kernel n hs e -> signature n hs s sy ->
  fits n e s a -> active (length hs) sy i=true ->
  exists q,q<n /\ e q=true /\ s q=false /\ decode (meet a (support_mask (row i))) q=true /\
           nth i hs zero_vector q=true.
Proof.
  intros L K Sig [Sub Fit] A;unfold active in A;apply andb_true_iff in A as [I Odd];apply Nat.ltb_lt in I.
  destruct (L i I) as [Mask _]. rewrite Sig in Odd by exact I.
  destruct (odd_row_has_target_extension n _ s e Sub Odd (K _ (nth_In _ _ I))) as [q [Q [H [E S]]]].
  exists q;rewrite decode_meet,Mask,H,(Fit _ Q E S) by exact Q;auto.
Qed.
Lemma packing_safe n hs ls test row e s sy a used ids rem :
  active_ok (length hs) test -> layout n hs ls row -> kernel n hs e -> signature n hs s sy -> fits n e s a ->
  weight n (unseen e s used)<=rem ->
  packing_cut test row sy a rem used ids=false.
Proof.
  intros Check L K Sig Fit;revert rem used;induction ids as [|i ids IH];intros rem used B;[reflexivity|].
  cbn [packing_cut];destruct (test sy i) eqn:A;[|reflexivity].
  set (can:=meet a (support_mask (row i))). destruct (is_empty (meet used can)) eqn:Z;[|reflexivity].
  destruct (active_target n hs ls row e s sy a i L K Sig Fit (Check _ _ A)) as [q [Q [E [S [Hit H]]]]].
  assert (Unused:decode used q=false).
  { apply empty_none in Z;pose proof (f_equal (fun b=>decode b q) Z) as R;
    cbn beta in R;rewrite decode_none,decode_meet in R;fold can in Hit;
    rewrite Hit, andb_true_r in R;exact R. }
  assert (Residual:vdiff e s q=true) by (unfold vdiff;rewrite E,S;reflexivity).
  pose proof (unseen_join n e s used can q Q Residual Unused Hit).
  destruct rem; [lia|]. apply IH;lia.
Qed.

Fixpoint refute (test:bits->nat->bool) (row:nat->packed_row) (choose:bits->bits->nat->hint)
                (short:nat->bits->bool) (rem:nat) (sy ly a:bits) : bool :=
  if is_empty sy then is_empty ly else
  if short rem sy then true else
  match choose sy a rem with
  | pack_rows ids => packing_cut test row sy a rem none ids
  | split_row i =>
      if test sy i then
        match rem with
        | O=>true
        | S k=>all_branches (refute test row choose short k) sy ly a (neighbors (row i))
        end
      else false
  end.

Definition short_correct n hs (short:nat->bits->bool) :=
  forall rem e s sy, kernel n hs e -> subset n s e ->
  signature n hs s sy -> weight n e<=weight n s+rem -> short rem sy=false.

Theorem refute_safe n hs ls test row choose short rem e s sy ly a :
  active_ok (length hs) test -> layout n hs ls row -> short_correct n hs short -> minimum n hs ls e ->
  fits n e s a -> 0<weight n s -> weight n e<=weight n s+rem ->
  signature n hs s sy -> signature n ls s ly ->
  refute test row choose short rem sy ly a=false.
Proof.
  intros Check L Short Min;revert s sy ly a;induction rem as [|rem IH];
    intros s sy ly a Fit Pos B HS LS; cbn [refute];
    destruct (is_empty sy) eqn:Zero.
  all: try solve [destruct (is_empty ly) eqn:Z; [exfalso;eapply closed_refutes;eauto|reflexivity]].
  all: rewrite (Short _ e s sy (proj1 (proj2 (proj1 Min))) (proj1 Fit) HS B).
  all: destruct (choose sy a _) as [i|ids].
  all: try solve [apply (packing_safe n hs ls test row e s sy a none ids);try assumption;
    [exact (proj1 (proj2 (proj1 Min)))|];
    assert (weight n (unseen e s none)=weight n (vdiff e s)) by
      (apply weight_ext; intros j J; unfold unseen;rewrite decode_none;destruct (vdiff e s j);reflexivity);
    pose proof (subset_split n s e (proj1 Fit));lia].
  all: destruct (test sy i) eqn:A;[|reflexivity].
  all: apply Check in A.
  all: destruct (active_target n hs ls row e s sy a i L (proj1 (proj2 (proj1 Min))) HS Fit A)
     as [q [Q [T [P [Can H]]]]].
  - pose proof (weight_strict_extra n s e q (proj1 Fit) Q P T);lia.
  - unfold active in A;apply andb_true_iff in A as [I _];apply Nat.ltb_lt in I.
    destruct (L i I) as [_ [Cols Whole]].
    apply (branches_refute n hs ls e s sy ly a _ _ Cols HS LS Fit).
    + intros c a' InC E F Next NC NL;rewrite Forall_forall in Cols;specialize (Cols c InC).
      apply (IH (setbit s (position c)));try assumption;
      rewrite setbit_weight by (try exact F;apply Cols);lia.
    + destruct (Whole q Q H) as [c [InC Eq]];exists c;rewrite Eq;auto.
Qed.
