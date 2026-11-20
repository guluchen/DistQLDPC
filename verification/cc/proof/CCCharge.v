(* Concrete free-column degree bound; functional correctness, not C refinement. *)
From Coq Require Import Bool List Arith Lia.
Require Import CCV.CCModel CCV.CCFunctional CCV.CCPacking CCV.CCOverlap CCV.CCEmpty.
Import ListNotations.
Definition odd_rows n hs s :=filter(fun r=>parity n (row_at hs r) s) (seq 0 (length hs)).
Definition free_columns n (s f:vector) :=filter(fun q=>andb(negb(s q))(negb(f q))) (seq 0 n).
Definition column_degree n hs s q :=sumover (odd_rows n hs s) (fun r=>if row_at hs r q then 1 else 0).
Definition max_degree n hs s f :=fold_right Nat.max 0 (map (column_degree n hs s) (free_columns n s f)).
Lemma maximum_member (xs:list nat) x : In x xs -> x<=fold_right Nat.max 0 xs.
Proof.
 induction xs as [|a xs IH];simpl;intros H;[contradiction|].
 destruct H as [<-|H];[apply Nat.le_max_l|eapply Nat.le_trans;[apply IH;assumption|apply Nat.le_max_r]].
Qed.
Lemma odd_row_member n hs s r : In r (odd_rows n hs s) ->
 In (row_at hs r) hs /\ parity n (row_at hs r) s=true.
Proof.
 unfold odd_rows;rewrite filter_In;intros [Hr Odd];split;[|assumption].
 apply in_seq in Hr;unfold row_at;apply nth_In;lia.
Qed.
Lemma free_column_member n s f q : In q (free_columns n s f) <->q<n /\ s q=false /\ f q=false.
Proof.
 unfold free_columns;rewrite filter_In,in_seq,andb_true_iff,!negb_true_iff;simpl;intuition lia.
Qed.
Lemma completion_is_free n e s f q : compatible n e s f -> In q (completion n e s) -> In q (free_columns n s f).
Proof.
 intros [Sub Avoid] Hq;apply completion_member in Hq;destruct Hq as [Q [E S]].
 apply free_column_member;repeat split;try assumption.
 destruct(f q) eqn:F;[pose proof(Avoid q Q F);congruence|reflexivity].
Qed.
Theorem concrete_charge_bound n hs ls e s f : good n hs ls e -> compatible n e s f ->
 length(odd_rows n hs s)<=weight n (vdiff e s)*max_degree n hs s f.
Proof.
 intros [_ [Ker Log]] Comp;rewrite <-completion_weight.
 apply (uniform_charge_bound (odd_rows n hs s) (completion n e s) (fun r q=>row_at hs r q) (max_degree n hs s f)).
 - intros r Hr;destruct(odd_row_member n hs s r Hr) as [InRow Odd].
   destruct(odd_row_has_target_extension n (row_at hs r) s e (proj1 Comp) Odd (Ker _ InRow))
    as [q [Q [Hq [E S]]]].
   exists q;split;[apply completion_member;tauto|assumption].
 - intros q Hq;unfold max_degree;apply maximum_member.
   change (In (column_degree n hs s q) (map (column_degree n hs s) (free_columns n s f))).
   apply in_map;apply (completion_is_free n e s f q Comp Hq).
Qed.
Definition charge_prune n hs cap s f :=
 let odd:=length(odd_rows n hs s) in let degree:=max_degree n hs s f in
 if odd=?0 then Some f else if degree=?0 then None
 else if cap-weight n s <? ceil_nat odd degree then None else Some f.
Theorem charge_prune_contract n hs ls cap : prune_contract n hs ls cap (charge_prune n hs cap).
Proof.
 intros e s f Hmin Hcap Comp;unfold charge_prune.
 pose proof(concrete_charge_bound n hs ls e s f (proj1 Hmin) Comp) as Bound.
 pose proof(subset_split n s e (proj1 Comp)) as Split.
 destruct(length(odd_rows n hs s)=?0) eqn:O.
 - exists f;split;[reflexivity|exact(proj2 Comp)].
 - apply Nat.eqb_neq in O.
   destruct(max_degree n hs s f=?0) eqn:D.
   + apply Nat.eqb_eq in D;rewrite D,Nat.mul_0_r in Bound;lia.
   + apply Nat.eqb_neq in D.
     assert(Ceil:ceil_nat (length(odd_rows n hs s)) (max_degree n hs s f)<=cap-weight n s).
     { apply (proj2 (ceil_nat_minimal (length(odd_rows n hs s)) (max_degree n hs s f) (cap-weight n s) ltac:(lia)));nia. }
     destruct(cap-weight n s <? ceil_nat (length(odd_rows n hs s)) (max_degree n hs s f)) eqn:C.
     * apply Nat.ltb_lt in C;lia.
     * exists f;split;[reflexivity|exact(proj2 Comp)].
Qed.
Definition compose_prune (p q:vector->vector->option vector) s f :=
 match p s f with None=>None | Some f'=>q s f' end.
Lemma compose_prune_contract n hs ls cap p q :
 prune_contract n hs ls cap p ->prune_contract n hs ls cap q ->
 prune_contract n hs ls cap (compose_prune p q).
Proof.
 intros P Q e s f Min Cap Comp.
 destruct(P e s f Min Cap Comp) as [f1 [Run Safe]];unfold compose_prune;rewrite Run.
 apply (Q e s f1 Min Cap);split;[exact(proj1 Comp)|assumption].
Qed.
Definition optional_prune (enabled:bool) (p:vector->vector->option vector) :=if enabled then p else no_prune.
Lemma optional_prune_contract n hs ls cap enabled p :
 prune_contract n hs ls cap p ->prune_contract n hs ls cap (optional_prune enabled p).
Proof. intros H;destruct enabled;simpl;[assumption|apply no_prune_contract]. Qed.
Definition optimized_prune n hs gs cap overlap pack charge :=
 compose_prune (optional_prune overlap (overlap_rules n gs))
 (compose_prune (empty_prune n hs) (compose_prune (optional_prune pack (packing_prune n hs cap)) (optional_prune charge (charge_prune n hs cap)))).
Theorem optimized_prune_contract n hs ls gs cap overlap pack charge :
 (forall g,In g gs ->stabilizer_valid n hs ls g) ->
 prune_contract n hs ls cap (optimized_prune n hs gs cap overlap pack charge).
Proof.
 intros Valid;unfold optimized_prune;apply compose_prune_contract.
 - apply optional_prune_contract;apply overlap_prune_contract;assumption.
 - apply compose_prune_contract;[apply empty_prune_contract|].
   apply compose_prune_contract;apply optional_prune_contract;
   [apply packing_prune_contract|apply charge_prune_contract].
Qed.
Theorem optimized_distance_found_for_all_inputs n hs ls gs overlap pack charge out :
 (forall g,In g gs ->stabilizer_valid n hs ls g) ->
 code_half_distance n hs ls (fun cap=>optimized_prune n hs gs cap overlap pack charge)=Some out ->minimum n hs ls out.
Proof.
 intros Valid Run;apply (code_half_distance_found n hs ls (fun cap=>optimized_prune n hs gs cap overlap pack charge) out);[intros cap;apply optimized_prune_contract;assumption|assumption].
Qed.
Theorem optimized_distance_none_for_all_inputs n hs ls gs overlap pack charge :
 (forall g,In g gs ->stabilizer_valid n hs ls g) ->
 (code_half_distance n hs ls (fun cap=>optimized_prune n hs gs cap overlap pack charge)=None <->~exists e,good n hs ls e).
Proof.
 intros Valid;apply code_half_distance_none;intros cap;apply optimized_prune_contract;assumption.
Qed.
Print Assumptions concrete_charge_bound.
Print Assumptions optimized_distance_found_for_all_inputs.
Print Assumptions optimized_distance_none_for_all_inputs.
