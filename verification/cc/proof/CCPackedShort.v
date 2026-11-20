(* A checked membership table may overapproximate short syndromes. An absent
   entry alone is enough to exclude all completions of the specified weight. *)
From Coq Require Import List Bool Arith Lia.
Require Import CCV.CCModel CCV.CCFunctional CCV.CCPCMDetectors CCV.CCPacking
 CCV.CCQuotientCertificate CCV.CCOrbit CCV.CCPackedWords CCV.CCPackedBranch CCV.CCPackedRefute.
Import ListNotations. Local Open Scope nat_scope.

Fixpoint verify_sums (present:bits->bool) (cs:list column) k acc {struct cs} :=
  match k,cs with
  | O,_ | _,[]=>present acc
  | S smaller,c::tail =>
      verify_sums present tail k acc &&
      verify_sums present tail smaller (add_bits acc (check_delta c))
  end.

Fixpoint chosen_sum (e:vector) acc cs :=
  match cs with
  | []=>acc
  | c::tail=>chosen_sum e (if e (position c) then add_bits acc (check_delta c) else acc) tail
  end.
Definition chosen_count (e:vector) cs := length (filter (fun c=>e (position c)) cs).
Lemma zero_chosen e cs acc : chosen_count e cs=0 -> chosen_sum e acc cs=acc.
Proof.
  revert acc;induction cs as [|c cs IH];intro acc;[reflexivity|].
  unfold chosen_count;cbn [filter chosen_sum];destruct (e (position c));[discriminate|apply IH].
Qed.
Lemma verified_sums_cover present cs k acc e : verify_sums present cs k acc=true ->
  chosen_count e cs<=k -> present (chosen_sum e acc cs)=true.
Proof.
  revert k acc;induction cs as [|c cs IH];intros [|k] acc H Count;
    try solve [cbn [verify_sums chosen_sum] in *;assumption].
  - rewrite zero_chosen by lia;exact H.
  - cbn [verify_sums] in H;apply andb_true_iff in H as [Skip Pick].
    cbn [chosen_sum];unfold chosen_count in Count;cbn [filter] in Count.
    destruct (e (position c)) eqn:E.
    + eapply IH;[exact Pick|]. unfold chosen_count;cbn [length] in Count;lia.
    + eapply IH;[exact Skip|exact Count].
Qed.

Lemma chosen_count_positions n cs e : map position cs=seq 0 n ->
  chosen_count e cs=weight n e.
Proof.
  intro Eq;rewrite <- filter_support_weight,<-Eq;unfold chosen_count.
  rewrite <- (map_length position (filter (fun c=>e (position c)) cs)).
  f_equal. clear Eq;induction cs as [|c cs IH];[reflexivity|].
  cbn [map filter];destruct (e (position c));cbn [map];rewrite IH;reflexivity.
Qed.

Lemma decode_chosen e cs acc i : decode (chosen_sum e acc cs) i =
  xorb (decode acc i) (xor_bits (map (fun c=>andb (decode (check_delta c) i) (e (position c))) cs)).
Proof.
  revert acc;induction cs as [|c cs IH];intro acc;cbn [chosen_sum map xor_bits].
  - destruct (decode acc i);reflexivity.
  - destruct (e (position c));rewrite IH,?decode_add;
      destruct (decode acc i),(decode (check_delta c) i),
        (xor_bits (map (fun c=>andb (decode (check_delta c) i) (e (position c))) cs));reflexivity.
Qed.
Lemma chosen_signature n hs cs e : map position cs=seq 0 n ->
  Forall (fun c=>column_signature hs (position c) (check_delta c)) cs ->
  signature n hs e (chosen_sum e none cs).
Proof.
  intros Pos Col i. rewrite decode_chosen, decode_none;cbn [xorb].
  rewrite <-xor_dot;unfold tabulate; rewrite <-Pos,map_map.
  f_equal;apply map_ext_in;intros c Hin.
  rewrite Forall_forall in Col. rewrite (Col c Hin i);reflexivity.
Qed.

Lemma residual_sum n hs e s sy cs : map position cs=seq 0 n ->
  Forall (fun c=>column_signature hs (position c) (check_delta c)) cs ->
  kernel n hs e -> subset n s e -> signature n hs s sy ->
  sy=chosen_sum (vdiff e s) none cs.
Proof.
  intros Pos Col K Sub Sig;apply bits_ext;intros i I.
  rewrite Sig,(chosen_signature n hs cs (vdiff e s) Pos Col).
  set (h:=nth i hs zero_vector). assert (H:parity n h e=false).
  { unfold h;destruct (lt_dec i (length hs)).
    - apply K;apply nth_In;assumption.
    - rewrite nth_overflow by lia;apply qcert_zero_dot. }
  pose proof (parity_split n h s e Sub) as P;rewrite H in P.
  destruct (parity n h s),(parity n h (vdiff e s));cbn in P;congruence.
Qed.
Definition short_table k (present:bits->bool) rem sy :=
  if rem <=? k then negb (present sy) else false.
Theorem validated_table_sound n hs cs k present :
  map position cs=seq 0 n ->
  Forall (fun c=>column_signature hs (position c) (check_delta c)) cs ->
  verify_sums present cs k none=true -> short_correct n hs (short_table k present).
Proof.
  intros Seq Col OK rem e s sy K Sub Sig Bound;unfold short_table.
  destruct (rem <=? k) eqn:R;[|reflexivity]. apply Nat.leb_le in R.
  rewrite (residual_sum n hs e s sy cs Seq Col K Sub Sig).
  rewrite (verified_sums_cover present cs k none (vdiff e s) OK);
    [reflexivity|rewrite (chosen_count_positions n cs _ Seq);pose proof (subset_split n s e Sub);lia].
Qed.
