(* SPDX-License-Identifier: GPL-3.0-or-later.
   Logical journal/restoration invariants, not a VST body proof of restore(). *)
From Coq Require Import Bool List Arith Lia.
Require Import CCV.CCModel CCV.CCFunctional.
Import ListNotations.
Definition memberb q (xs:list nat) := existsb (Nat.eqb q) xs.
Definition forbidden (base:vector) journal : vector := fun q=>base q || memberb q journal.
Definition clearbit (v:vector) q : vector := fun i=>if Nat.eqb i q then false else v i.
Lemma memberb_spec q xs : memberb q xs=true <-> In q xs.
Proof.
 unfold memberb;rewrite existsb_exists;split.
 - intros [x [Hin E]];apply Nat.eqb_eq in E;subst;assumption.
 - intros H;exists q;split;[assumption|apply Nat.eqb_refl].
Qed.
Lemma memberb_false q xs : memberb q xs=false <-> ~In q xs.
Proof.
 split.
 - intros H Hin;apply memberb_spec in Hin;congruence.
 - intros H;destruct (memberb q xs) eqn:E;[apply memberb_spec in E;contradiction|reflexivity].
Qed.
Lemma fresh_journal q base journal : forbidden base journal q=false ->
 base q=false /\ ~In q journal.
Proof. unfold forbidden;rewrite orb_false_iff,memberb_false;tauto. Qed.
Lemma push_forbidden_pointwise base journal q i :
 forbidden base (q::journal) i=setbit (forbidden base journal) q i.
Proof.
 unfold forbidden,setbit,memberb;simpl.
 destruct (Nat.eqb i q),(base i),(existsb (Nat.eqb i) journal);reflexivity.
Qed.
Lemma clear_fresh_pointwise base journal q i :
 forbidden base journal q=false ->
 clearbit (forbidden base (q::journal)) q i=forbidden base journal i.
Proof.
 intros Hfresh;unfold clearbit;destruct (Nat.eqb i q) eqn:E.
 - apply Nat.eqb_eq in E;subst;symmetry;assumption.
 - rewrite push_forbidden_pointwise;unfold setbit;rewrite E;reflexivity.
Qed.
Lemma journal_capacity n (base:vector) journal : NoDup journal ->
 (forall q,In q journal -> q<n) -> length journal<=n.
Proof.
 intros Hnd Hrange.
 assert (Hi:incl journal (seq 0 n)) by (intros q Hq;apply in_seq;specialize(Hrange q Hq);lia).
 pose proof (NoDup_incl_length Hnd Hi) as H;rewrite seq_length in H;assumption.
Qed.
Theorem fresh_push_fits n base journal q : NoDup journal ->
 (forall a,In a journal -> a<n) -> q<n -> forbidden base journal q=false ->
 length journal<n /\ NoDup (q::journal).
Proof.
 intros Hnd Hr Hq Hfresh;apply fresh_journal in Hfresh;destruct Hfresh as [_ Hnot].
 assert (Hnd':NoDup(q::journal)) by (constructor;assumption).
 split;[|assumption].
 pose proof (journal_capacity n base (q::journal) Hnd') as Hcap.
 assert (Hrange:forall a,In a (q::journal) -> a<n) by (intros a [<-|Ha];[assumption|apply Hr;assumption]).
 specialize (Hcap Hrange);simpl in Hcap;lia.
Qed.
Fixpoint clear_many (v:vector) (removed:list nat) : vector :=
 match removed with []=>v | q::tail=>clear_many (clearbit v q) tail end.
Lemma clear_many_ext a b removed : (forall i,a i=b i) ->
 forall i,clear_many a removed i=clear_many b removed i.
Proof.
 revert a b;induction removed as [|q tail IH];intros a b H i;simpl;[apply H|].
 apply IH;intros j;unfold clearbit;destruct (Nat.eqb j q);[reflexivity|apply H].
Qed.
Theorem restore_mark_exact base removed entry : NoDup (removed++entry) ->
 (forall q,In q (removed++entry) -> base q=false) ->
 forall i,clear_many (forbidden base (removed++entry)) removed i=forbidden base entry i.
Proof.
 induction removed as [|q tail IH];simpl;intros Hnd Hbase i;[reflexivity|].
 inversion Hnd as [|a xs Hnot Htail];subst.
 assert (Hfresh:forbidden base (tail++entry) q=false).
 { unfold forbidden;apply orb_false_iff;split.
   - apply Hbase;left;reflexivity.
   - apply memberb_false;assumption. }
 rewrite (clear_many_ext _ (forbidden base (tail++entry)) tail).
 - apply IH;[assumption|]. intros a Ha;apply Hbase;right;assumption.
 - intros j;apply clear_fresh_pointwise;assumption.
Qed.
Theorem step_counter_no_wrap steps budget maximum :
 steps<budget -> budget<=maximum -> steps+1<=maximum.
Proof. lia. Qed.
Print Assumptions fresh_push_fits.
Print Assumptions restore_mark_exact.
Print Assumptions step_counter_no_wrap.
