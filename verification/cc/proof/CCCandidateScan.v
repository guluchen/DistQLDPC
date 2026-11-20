(* Exact ascending candidate scan and target-coverage lemmas for phase 1.
   These are mathematics for the C while invariant, not its VST refinement. *)
From Coq Require Import Bool List Arith Lia.
Require Import CCV.CCModel CCV.CCFunctional.
Import ListNotations.
Fixpoint scan_from (fuel start:nat) (available:nat->bool) :nat :=
 match fuel with
 |0=>start
 |S smaller=>if available start then start else scan_from smaller (S start) available end.
Lemma scan_bounds fuel start available :
 start<=scan_from fuel start available<=start+fuel.
Proof.
 revert start;induction fuel as [|fuel IH];intros start;simpl;[lia|].
 destruct(available start);[lia|specialize(IH(S start));lia].
Qed.
Lemma scan_before_false fuel start available q :
 start<=q<scan_from fuel start available ->available q=false.
Proof.
 revert start;induction fuel as [|fuel IH];intros start Q;simpl in *;[lia|].
 destruct(available start)eqn:A;[lia|].
 destruct(Nat.eq_dec q start) as [->|Ne];[assumption|apply(IH(S start));lia].
Qed.
Lemma scan_returns_available fuel start available :
 scan_from fuel start available<start+fuel ->available(scan_from fuel start available)=true.
Proof.
 revert start;induction fuel as [|fuel IH];intros start;simpl;[lia|].
 destruct(available start)eqn:A;[auto|intros Q;apply IH;lia].
Qed.
Lemma scan_precedes_available fuel start available q :
 start<=q<start+fuel ->available q=true ->scan_from fuel start available<=q.
Proof.
 intros Q A;destruct(Nat.le_gt_cases(scan_from fuel start available)q);[assumption|].
 pose proof(scan_before_false fuel start available q ltac:(lia));congruence.
Qed.
Definition scan_candidates n next h s f :=
 scan_from(n-next) next (fun q=>andb(h q)(andb(negb(s q))(negb(f q)))).
Theorem scan_target_not_skipped n next h s f e target :
 next<=target<n ->h target=true ->s target=false ->f target=false ->e target=true ->
 let chosen:=scan_candidates n next h s f in
 next<=chosen<=target /\chosen<n /\h chosen=true /\s chosen=false /\f chosen=false /\
 (e chosen=false ->S chosen<=target).
Proof.
 intros Range H S F E;unfold scan_candidates.
 set(a:=fun q=>andb(h q)(andb(negb(s q))(negb(f q)))).
 assert(A:a target=true)by(unfold a;rewrite H,S,F;reflexivity).
 pose proof(scan_precedes_available (n-next)next a target ltac:(lia) A)as Before.
 pose proof(scan_bounds (n-next)next a)as Bounds.
 assert(Chosen:scan_from(n-next)next a<n)by lia.
 pose proof(scan_returns_available (n-next)next a ltac:(lia))as Hit.
 unfold a in Hit;apply andb_true_iff in Hit;destruct Hit as [Hc Hit].
 apply andb_true_iff in Hit;destruct Hit as [Sc Fc];apply negb_true_iff in Sc,Fc.
 repeat split;try assumption;try lia.
 intros Not;destruct(Nat.eq_dec(scan_from(n-next)next a)target)as [Eq|Ne];[rewrite Eq in Not;congruence|lia].
Qed.
Theorem scanned_non_target_sibling_safe n next h s f e target :
 avoids n e f ->next<=target<n ->h target=true ->s target=false ->f target=false ->e target=true ->
 e(scan_candidates n next h s f)=false ->
 avoids n e(setbit f(scan_candidates n next h s f)) /\
 S(scan_candidates n next h s f)<=target.
Proof.
 intros Avoid Range H S F E Outside;split.
 - apply avoids_setbit;assumption.
 - pose proof(scan_target_not_skipped n next h s f e target Range H S F E)as Cover.
   simpl in Cover;tauto.
Qed.
Definition root_forbidden seed :vector :=fun q=>Nat.ltb q seed.
Definition root_selected seed :vector :=setbit(fun _=>false)seed.
Theorem first_target_root_compatible n e seed :
 seed<n ->e seed=true ->(forall q,q<seed ->e q=false) ->
 compatible n e(root_selected seed)(root_forbidden seed).
Proof.
 intros Q E First;split.
 - unfold subset,root_selected,setbit;intros i I;destruct(Nat.eqb i seed)eqn:T;[apply Nat.eqb_eq in T;subst;auto|discriminate].
 - unfold avoids,root_forbidden;intros i I F;apply Nat.ltb_lt in F;apply First;assumption.
Qed.
Print Assumptions scan_target_not_skipped.
Print Assumptions scanned_non_target_sibling_safe.
Print Assumptions first_target_root_compatible.
