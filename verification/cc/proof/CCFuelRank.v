(* A well-founded budget rank for normally continuing search iterations.
   No claim of total operational Clight termination is made here. *)
Require Import VST.floyd.proofauto.
Require Import Coq.Arith.Wf_nat.
Require Import CCV.CCSearchSpecs CCV.CCStatsInvariant.
Open Scope Z_scope.
Definition fuel_rank budget s:nat:=Z.to_nat(budget-stat_steps s).
Definition continuing_step budget before after:Prop:=
 legal_stats budget before /\legal_stats budget after /\
 stats_monotone(step_stats before)after.
Lemma continuing_step_strict budget before after:
 continuing_step budget before after ->stat_steps before<stat_steps after.
Proof. unfold continuing_step,stats_monotone,step_stats;cbn;intros;lia. Qed.
Lemma continuing_step_rank budget before after:
 continuing_step budget before after ->(fuel_rank budget after<fuel_rank budget before)%nat.
Proof.
 intros H;pose proof(continuing_step_strict _ _ _ H)as Strict.
 unfold continuing_step,legal_stats in H;unfold fuel_rank.
 apply Z2Nat.inj_lt;lia.
Qed.
Theorem continuing_step_well_founded budget:
 well_founded(fun after before=>continuing_step budget before after).
Proof.
 apply(well_founded_lt_compat stats_model(fuel_rank budget)).
 intros after before H;apply continuing_step_rank;exact H.
Qed.
Theorem no_infinite_continuing_steps budget:
 ~exists f:nat->stats_model,forall n,continuing_step budget(f n)(f(S n)).
Proof.
 intros[f Steps].
 assert(Lower:forall n,Z.of_nat n<=stat_steps(f n)).
 { intro n;induction n as[|n IH].
   - pose proof(Steps 0%nat)as H;unfold continuing_step,legal_stats in H;cbn;lia.
   - pose proof(continuing_step_strict _ _ _ (Steps n))as Strict.
     rewrite Nat2Z.inj_succ;lia. }
 pose proof(Steps 0%nat)as Initial.
 assert(Budget:0<=budget)by(unfold continuing_step,legal_stats in Initial;lia).
 pose proof(Lower(S(Z.to_nat budget)))as TooMany.
 pose proof(Steps(S(Z.to_nat budget)))as Last.
 unfold continuing_step,legal_stats in Last.
 rewrite Nat2Z.inj_succ,Z2Nat.id in TooMany by lia;lia.
Qed.
(* This trace counts only normally continuing iterations; early function
   returns are separate and do not add fictitious transitions. *)
Inductive fuel_chain budget:stats_model->stats_model->nat->Prop:=
 |fuel_chain_zero:forall s,fuel_chain budget s s 0
 |fuel_chain_next:forall first next last count,
   continuing_step budget first next ->fuel_chain budget next last count ->
   fuel_chain budget first last(S count).
Lemma fuel_chain_counter budget first last count:
 fuel_chain budget first last count ->
 stat_steps first+Z.of_nat count<=stat_steps last.
Proof.
 intros Chain;induction Chain.
 - cbn;lia.
 - pose proof(continuing_step_strict _ _ _ H)as Strict.
   rewrite Nat2Z.inj_succ;lia.
Qed.
Theorem fuel_chain_length_bound budget first last count:
 legal_stats budget last ->fuel_chain budget first last count ->
 Z.of_nat count<=budget-stat_steps first.
Proof.
 intros Legal Chain;pose proof(fuel_chain_counter _ _ _ _ Chain).
 unfold legal_stats in Legal;lia.
Qed.
(* A nondecreasing counter alone cannot establish progress. *)
Definition zero_stats:stats_model:=
 {|stat_steps:=0;stat_nodes:=0;stat_pack:=0;stat_charge:=0;stat_overlap:=0|}.
Example monotonicity_only_mutant_is_not_progress:
 legal_stats 1 zero_stats /\stats_monotone zero_stats zero_stats /\
 ~continuing_step 1 zero_stats zero_stats.
Proof. vm_compute;intuition congruence. Qed.
Print Assumptions continuing_step_rank.
Print Assumptions continuing_step_well_founded.
Print Assumptions no_infinite_continuing_steps.
Print Assumptions fuel_chain_length_bound.
