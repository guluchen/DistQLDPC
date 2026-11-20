(* Concrete greedy candidate packing and its functional CC pruning contract.
   Does not yet verify the imperative C bounds function. *)
From Coq Require Import Bool List Arith Lia.
Require Import CCV.CCModel CCV.CCFunctional.
Import ListNotations.
Definition repair n (h s f:vector) :=filter(fun q=>andb(h q)(andb(negb(s q))(negb(f q)))) (seq 0 n).
Definition completion n e s :=filter(vdiff e s)(seq 0 n).
Definition intersects (used cs:list nat) :=existsb(fun q=>existsb(Nat.eqb q) used) cs.
Lemma intersects_true used cs : intersects used cs=true <->exists q,In q cs /\ In q used.
Proof.
 unfold intersects;rewrite existsb_exists;split.
 - intros [q [Hq E]];apply existsb_exists in E;destruct E as [r [Hr E]].
   apply Nat.eqb_eq in E;subst r;exists q;auto.
 - intros [q [Hq Hu]];exists q;split;[assumption|].
   apply existsb_exists;exists q;split;[assumption|apply Nat.eqb_refl].
Qed.
Lemma intersects_false used cs : intersects used cs=false ->
 forall q,In q cs -> ~In q used.
Proof.
 intros H q Hq Hu;assert(intersects used cs=true) by (apply intersects_true;exists q;auto);congruence.
Qed.
Fixpoint greedy_packing n (row:nat->vector) s f (rows used:list nat) : list nat :=
 match rows with []=>[] | r::tail=>
 if andb (parity n (row r) s) (negb(intersects used (repair n (row r) s f)))
 then r::greedy_packing n row s f tail (repair n (row r) s f++used)
 else greedy_packing n row s f tail used end.
Lemma greedy_in n row s f rows used r : In r (greedy_packing n row s f rows used) -> In r rows.
Proof.
 revert used;induction rows as [|h rows IH];intros used H;simpl in *;[contradiction|].
 destruct(andb _ _) eqn:E;simpl in H.
 - destruct H as [<-|H];[left;reflexivity|right;eapply IH;eassumption].
 - right;eapply IH;eassumption.
Qed.
Lemma greedy_odd n row s f rows used r : In r (greedy_packing n row s f rows used) -> parity n (row r) s=true.
Proof.
 revert used;induction rows as [|h rows IH];intros used H;simpl in *;[contradiction|].
 destruct(andb _ _) eqn:E;simpl in H.
 - destruct H as [<-|H];[apply andb_true_iff in E;tauto|eapply IH;eassumption].
 - eapply IH;eassumption.
Qed.
Lemma greedy_avoids_used n row s f rows used r q :
 In r (greedy_packing n row s f rows used) -> In q (repair n (row r) s f) -> ~In q used.
Proof.
 revert used;induction rows as [|h rows IH];intros used Hr Hq Hu;simpl in Hr;[contradiction|].
 destruct(andb _ _) eqn:E;simpl in Hr.
 - destruct Hr as [<-|Hr].
   + apply andb_true_iff in E;destruct E as [_ E];apply negb_true_iff in E.
     eapply intersects_false;eassumption.
   + eapply IH;[exact Hr|exact Hq|apply in_or_app;right;exact Hu].
 - eapply IH;eassumption.
Qed.
Lemma greedy_nodup n row s f rows : NoDup rows ->forall used,NoDup(greedy_packing n row s f rows used).
Proof.
 intros H;induction H as [|r rows Hnot Hnd IH];intros used;simpl;[constructor|].
 destruct(andb _ _).
 - constructor;[intro Hin;apply Hnot;eapply greedy_in;eassumption|apply IH].
 - apply IH.
Qed.
Lemma greedy_disjoint n row s f rows : NoDup rows ->forall used r r' q,
 In r (greedy_packing n row s f rows used) -> In r' (greedy_packing n row s f rows used) -> r<>r' ->
 In q (repair n (row r) s f) -> In q (repair n (row r') s f) ->False.
Proof.
 intros Hnd;induction Hnd as [|h rows Hnot Hnd IH];intros used r r' q Hr Hr' Ne Hq Hq';simpl in *;[contradiction|].
 destruct(andb _ _) eqn:E;simpl in Hr,Hr'.
 - destruct Hr as [Er|Hr];destruct Hr' as [Er'|Hr'];subst.
   + contradiction.
   + eapply (greedy_avoids_used n row s f rows (repair n (row r) s f++used) r' q);try eassumption.
     apply in_or_app;left;exact Hq.
   + eapply (greedy_avoids_used n row s f rows (repair n (row r') s f++used) r q);try eassumption.
     apply in_or_app;left;exact Hq'.
   + exact(IH (repair n (row h) s f++used) r r' q Hr Hr' Ne Hq Hq').
 - exact(IH used r r' q Hr Hr' Ne Hq Hq').
Qed.
Lemma repair_member n h s f q : In q (repair n h s f) <->q<n /\ h q=true /\ s q=false /\ f q=false.
Proof.
 unfold repair;rewrite filter_In,in_seq;rewrite !andb_true_iff,!negb_true_iff;simpl;intuition lia.
Qed.
Lemma completion_member n e s q : In q (completion n e s) <->q<n /\ e q=true /\ s q=false.
Proof.
 unfold completion;rewrite filter_In,in_seq;unfold vdiff;rewrite andb_true_iff,negb_true_iff;simpl;intuition lia.
Qed.
Lemma filter_support_weight n e : length(filter e (seq 0 n))=weight n e.
Proof.
 induction n as [|n IH];[reflexivity|].
 replace (S n) with (n+1) at 1 by lia;rewrite seq_app,filter_app,app_length.
 cbn [seq filter length];rewrite IH;cbn [weight];destruct(e n) eqn:E;simpl;rewrite E;simpl;lia.
Qed.
Lemma completion_weight n e s : length(completion n e s)=weight n (vdiff e s).
Proof. unfold completion;apply filter_support_weight. Qed.
Definition row_at (hs:list vector) r :=nth r hs (fun _=>false).
Definition packed_rows n hs s f :=greedy_packing n (row_at hs) s f (seq 0 (length hs)) [].
Theorem packed_rows_bound n hs ls e s f : good n hs ls e -> compatible n e s f ->
 length(packed_rows n hs s f)<=weight n (vdiff e s).
Proof.
 intros [_ [Hker Hlogical]] [Hsub Havoid].
 rewrite <- completion_weight.
 apply (disjoint_odd_row_packing_bound (packed_rows n hs s f) (fun r=>repair n (row_at hs r) s f) (completion n e s)).
 - unfold packed_rows;apply greedy_nodup;apply seq_NoDup.
 - unfold packed_rows;apply greedy_disjoint;apply seq_NoDup.
 - intros r Hr.
   assert(Rin:In r (seq 0 (length hs))) by (unfold packed_rows in Hr;eapply greedy_in;eassumption).
   apply in_seq in Rin.
   assert(Hin:In (row_at hs r) hs) by (unfold row_at;apply nth_In;lia).
   assert(Odd:parity n (row_at hs r) s=true) by (unfold packed_rows in Hr;eapply greedy_odd;eassumption).
   destruct(odd_row_has_target_extension n (row_at hs r) s e Hsub Odd (Hker _ Hin)) as [q [Hq [Hh [He Hs]]]].
   assert(Hf:f q=false).
   { destruct(f q) eqn:F;[pose proof(Havoid q Hq F);congruence|reflexivity]. }
   exists q;split;[apply repair_member|apply completion_member];tauto.
Qed.
Definition packing_prune n hs cap s f :=
 if cap-weight n s <? length(packed_rows n hs s f) then None else Some f.
Theorem packing_prune_contract n hs ls cap : prune_contract n hs ls cap (packing_prune n hs cap).
Proof.
 intros e s f Hmin Hcap Comp;unfold packing_prune.
 pose proof(packed_rows_bound n hs ls e s f (proj1 Hmin) Comp) as Bound.
 pose proof(subset_split n s e (proj1 Comp)) as Split.
 destruct(cap-weight n s <? length(packed_rows n hs s f)) eqn:E.
 - apply Nat.ltb_lt in E;lia.
 - exists f;split;[reflexivity|exact(proj2 Comp)].
Qed.
Theorem packing_distance_found_for_all_inputs n hs ls out :
 code_half_distance n hs ls (packing_prune n hs)=Some out ->minimum n hs ls out.
Proof. apply code_half_distance_found;intros cap;apply packing_prune_contract. Qed.
Theorem packing_distance_none_for_all_inputs n hs ls :
 code_half_distance n hs ls (packing_prune n hs)=None <->~exists e,good n hs ls e.
Proof. apply code_half_distance_none;intros cap;apply packing_prune_contract. Qed.
Print Assumptions packed_rows_bound.
Print Assumptions packing_distance_found_for_all_inputs.
Print Assumptions packing_distance_none_for_all_inputs.
