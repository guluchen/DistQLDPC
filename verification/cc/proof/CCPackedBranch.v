(* Range-checked column descriptions and the completeness of sibling exclusion. *)
From Coq Require Import List Bool Arith Lia.
Require Import CCV.CCModel CCV.CCFunctional CCV.CCCache CCV.CCPackedWords.
Import ListNotations.
Local Open Scope nat_scope.

Record column := col { position:nat; mark:bits; check_delta:bits; logical_delta:bits }.
Definition signature n (rows:list vector) s a :=
  forall i, decode a i = parity n (nth i rows zero_vector) s.
Definition column_signature rows q delta :=
  forall i, decode delta i = nth i rows zero_vector q.
Definition col_ok n hs ls c :=
  position c<n /\ (forall i,i<n -> decode (mark c) i=Nat.eqb i (position c)) /\
  column_signature hs (position c) (check_delta c) /\
  column_signature ls (position c) (logical_delta c).
Definition fits n (target prefix:vector) free :=
  subset n prefix target /\
  forall i, i<n -> target i=true -> prefix i=false -> decode free i=true.

Lemma parity_set n s q h : q<n -> s q=false ->
  parity n h (setbit s q)=xorb (parity n h s) (h q).
Proof.
  intros I Q;rewrite <- parity_flip by exact I; apply parity_ext.
  intros i J;unfold setbit,flip;destruct (Nat.eqb i q) eqn:E;[apply Nat.eqb_eq in E;subst;rewrite Q|];reflexivity.
Qed.
Lemma advance_signature n rows s a q delta :
  q<n -> s q=false -> signature n rows s a -> column_signature rows q delta ->
  signature n rows (setbit s q) (add_bits a delta).
Proof.
  intros Q Free S D i;rewrite decode_add, S, D, parity_set by assumption; reflexivity.
Qed.
Lemma neutral_signature n rows s a :
  signature n rows s a -> is_empty a=true -> kernel n rows s.
Proof.
  intros E Zero h Hin; apply empty_none in Zero;subst a.
  apply In_nth with (d:=zero_vector) in Hin as [i [I Eq]];subst h.
  specialize (E i);rewrite decode_none in E;symmetry;exact E.
Qed.
Lemma closed_refutes n hs ls e s available sy ly :
  minimum n hs ls e -> fits n e s available -> 0<weight n s ->
  signature n hs s sy -> signature n ls s ly ->
  is_empty sy=true -> is_empty ly=true -> False.
Proof.
  intros Min [Sub Fit] Pos HS LS A B.
  pose proof (neutral_signature _ _ _ _ HS A) as H.
  pose proof (neutral_signature _ _ _ _ LS B) as L.
  pose proof (subset_split n s e Sub) as Split.
  destruct (Nat.eq_dec (weight n s) (weight n e)) as [Eq|Diff].
  - destruct (good_subset_equal_weight n hs ls e s (proj1 Min) Sub Eq) as [_ [_ [l [InL Odd]]]].
    rewrite (L _ InL) in Odd;discriminate.
  - destruct (minimum_prefix_has_odd_row n hs ls e s Min Sub Pos ltac:(lia)) as [h [InH Odd]].
    rewrite (H _ InH) in Odd;discriminate.
Qed.

Definition available free c := negb (is_empty (meet free (mark c))).
Lemma available_hit n hs ls c e s a : col_ok n hs ls c -> fits n e s a ->
  e (position c)=true -> s (position c)=false -> available a c=true.
Proof.
  intros [I [M _]] [_ F] T P. unfold available.
  destruct (is_empty (meet a (mark c))) eqn:Z;[|reflexivity].
  apply empty_none in Z. pose proof (f_equal (fun b=>decode b (position c)) Z) as K.
  cbn beta in K;rewrite decode_none,decode_meet,M,Nat.eqb_refl,(F _ I T P) in K by exact I.
  discriminate.
Qed.
Lemma fits_pick n hs ls c e s a : col_ok n hs ls c -> fits n e s a ->
  e (position c)=true -> fits n e (setbit s (position c)) (subtract a (mark c)).
Proof.
  intros [I [M _]] [Sub F] E. split; [apply setbit_subset;assumption|].
  intros i J T Zero;unfold setbit in Zero;destruct (Nat.eqb i (position c)) eqn:Ne;[discriminate|].
  rewrite decode_subtract,M,Ne,(F _ J T Zero) by exact J;reflexivity.
Qed.
Lemma fits_skip n hs ls c e s a : col_ok n hs ls c -> fits n e s a ->
  ~(e (position c)=true /\ s (position c)=false) -> fits n e s (subtract a (mark c)).
Proof.
  intros [I [M _]] [Sub F] Miss;split;[exact Sub|].
  intros i J T Zero;rewrite decode_subtract,M,(F _ J T Zero) by exact J.
  destruct (Nat.eqb i (position c)) eqn:E;[|reflexivity].
  apply Nat.eqb_eq in E;subst i;exfalso; auto.
Qed.

Fixpoint all_branches (child:bits->bits->bits->bool) sy ly a cs :=
  match cs with
  | []=>true
  | c::tail=>
      if available a c then
        let rest:=subtract a (mark c) in
        child (add_bits sy (check_delta c)) (add_bits ly (logical_delta c)) rest &&
        all_branches child sy ly rest tail
      else all_branches child sy ly a tail
  end.

Lemma branches_refute n hs ls target s sy ly a cs child :
  Forall (col_ok n hs ls) cs -> signature n hs s sy -> signature n ls s ly ->
  fits n target s a ->
  (forall c a', In c cs -> target (position c)=true -> s (position c)=false ->
    fits n target (setbit s (position c)) a' ->
    signature n hs (setbit s (position c)) (add_bits sy (check_delta c)) ->
    signature n ls (setbit s (position c)) (add_bits ly (logical_delta c)) ->
    child (add_bits sy (check_delta c)) (add_bits ly (logical_delta c)) a'=false) ->
  (exists c, In c cs /\ target (position c)=true /\ s (position c)=false) ->
  all_branches child sy ly a cs=false.
Proof.
  intros Ok HS LS;revert a;induction Ok as [|c cs Ok Rest IH]; intros a Fit Child Hit.
  - destruct Hit as [? [[] _]].
  - cbn [all_branches].
    destruct (andb (target (position c)) (negb (s (position c)))) eqn:Head.
    + apply andb_true_iff in Head as [T P];apply negb_true_iff in P.
      rewrite (available_hit n hs ls c target s a Ok Fit T P).
      rewrite Child; [reflexivity|left;reflexivity|exact T|exact P|eapply fits_pick;eauto| |].
      * destruct Ok as [Q [_ [D _]]];apply advance_signature;assumption.
      * destruct Ok as [Q [_ [_ D]]];apply advance_signature;assumption.
    + assert (Miss:~(target (position c)=true /\ s (position c)=false)).
      { intros [T P];rewrite T,P in Head;discriminate. }
      assert (Tail:exists c0, In c0 cs /\ target (position c0)=true /\ s (position c0)=false).
      { destruct Hit as [u [[Eq|I] [T P]]];[subst u;exfalso;auto|eauto]. }
      destruct (available a c).
      * apply andb_false_iff;right;apply IH.
        -- eapply fits_skip; eauto.
        -- intros;eapply Child; eauto using in_cons.
        -- exact Tail.
      * apply IH; [exact Fit| |exact Tail]. intros;eapply Child;eauto using in_cons.
Qed.
