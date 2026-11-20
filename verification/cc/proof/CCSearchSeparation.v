(* Selected/forbidden separation and the pending-child capacity obligation.
   These are pure loop-invariant lemmas, not the C while-loop theorem. *)
From Coq Require Import Bool List Arith Lia.
Require Import CCV.CCModel CCV.CCFunctional CCV.CCCache CCV.CCSearchPhases.
Definition separated n selected forbidden:=forall i,
 i<n ->selected i=true ->forbidden i=false.
Lemma separated_flip n s f q:
 separated n s f ->f q=false ->separated n(flip s q)f.
Proof.
 intros Sep Fq i I Hit;unfold flip in Hit.
 destruct(Nat.eqb i q)eqn:E.
 - apply Nat.eqb_eq in E;subst;assumption.
 - apply Sep;assumption.
Qed.
Lemma separated_forbid_unused n s f q:
 separated n s f ->s q=false ->separated n s(setbit f q).
Proof.
 intros Sep Sq i I Hit;unfold setbit;destruct(Nat.eqb i q)eqn:E.
 - apply Nat.eqb_eq in E;subst;congruence.
 - apply Sep;assumption.
Qed.
Lemma separated_resume n s f q (exclude:bool):
 separated n s f ->s q=true ->
 separated n(flip s q)(if exclude then setbit f q else f).
Proof.
 intros Sep Sq.
 assert(Off:flip s q q=false)by(unfold flip;rewrite Nat.eqb_refl,Sq;reflexivity).
 assert(Safe:separated n(flip s q)f).
 { intros i I Hit;unfold flip in Hit;destruct(Nat.eqb i q)eqn:E.
   - apply Nat.eqb_eq in E;subst;rewrite Sq in Hit;discriminate.
   - apply Sep;assumption. }
 destruct exclude;[apply separated_forbid_unused|];assumption.
Qed.
Lemma pending_phase_selected n depth q path selected:
 phase_path n depth 2 q path selected ->q<n /\selected q=true.
Proof.
 intros[ND[Range[Len[Q[Fresh Eq]]]]];split;[assumption|].
 rewrite Eq by assumption;apply path_bits_true.
 apply in_or_app;right;simpl;auto.
Qed.
Print Assumptions separated_resume.
Print Assumptions pending_phase_selected.

Require Import VST.floyd.proofauto.
Require Import CCV.CCRepresentation CCV.CCJournalArray CCV.CCJournalTrace.
Open Scope Z_scope.
Theorem pending_child_has_journal_room n base log buf xs depth path q:
 0<=q<n ->Zlength base=n ->Forall(fun z:Z=>z=0\/z=1)base ->
 journal_trace n base log buf ->
 phase_path(Z.to_nat n)depth 2(Z.to_nat q)path(decode xs) ->
 separated(Z.to_nat n)(decode xs)(decode(journal_bitmap base log)) ->
 Znth q(journal_bitmap base log)=0 /\Zlength log<n.
Proof.
 intros Q Len Bits Trace Phase Sep.
 pose proof(pending_phase_selected _ _ _ _ _ Phase)as[QN Hit].
 pose proof(Sep(Z.to_nat q)QN Hit)as Free.
 rewrite decode_at_nat,Z2Nat.id in Free by lia.
 assert(Range:Forall(fun a:Z=>0<=a<n)log)by(unfold journal_trace in Trace;tauto).
 assert(ND:NoDup(nat_journal log))by(unfold journal_trace in Trace;tauto).
 assert(FLen:Zlength(journal_bitmap base log)=n).
 { apply(journal_bitmap_length n base log);assumption. }
 assert(Binary:Znth q(journal_bitmap base log)=0\/Znth q(journal_bitmap base log)=1).
 { apply Forall_Znth;[apply journal_bitmap_bits;assumption|lia]. }
 assert(Flag:Znth q(journal_bitmap base log)=0).
 { destruct Binary as[B|B];[assumption|rewrite B in Free;discriminate]. }
 split;[assumption|].
 pose proof(journal_fresh_capacity n base log q ltac:(lia)Len Range ND Q Flag)as[Room Rest];assumption.
Qed.
Print Assumptions pending_child_has_journal_room.
