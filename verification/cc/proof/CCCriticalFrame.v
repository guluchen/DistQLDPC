(* Critical-target coverage for the C stack protocol. Pure mathematics only;
   the complete Clight loop and its spatial invariant remain separate. *)
From Coq Require Import Bool List Arith Lia.
Require Import CCV.CCModel CCV.CCFunctional CCV.CCCache CCV.CCCandidateScan CCV.CCSearchPhases CCV.CCSingleExtension.
Import ListNotations.
Definition critical_frame n h e s f next :=
 compatible n e s f /\ exists target,
 next<=target<n /\ h target=true /\ s target=false /\ f target=false /\ e target=true.
Lemma positive_first_bit n e : 0<weight n e ->
 exists seed,seed<n /\ e seed=true /\ forall q,q<seed ->e q=false.
Proof.
 induction n as [|n IH];intros Pos;[simpl in Pos;lia|].
 destruct(Nat.eq_dec(weight n e)0)as [Zero|Nonzero].
 - assert(Hit:e n=true)by(simpl in Pos;rewrite Zero in Pos;destruct(e n);auto;lia).
   exists n;repeat split;try assumption;try lia.
   intros q Q;apply(zero_weight_support n e Zero q Q).
 - destruct(IH ltac:(lia))as [seed[Seed[Hit First]]].
   exists seed;repeat split;try assumption;lia.
Qed.
Theorem minimum_root_covered n hs ls e : minimum n hs ls e ->
 exists seed,seed<n /\ compatible n e(root_selected seed)(root_forbidden seed).
Proof.
 intros [[Pos Rest] Min];destruct(positive_first_bit n e Pos)as[seed[Q[Hit First]]].
 exists seed;split;[assumption|apply first_target_root_compatible;assumption].
Qed.
Theorem odd_row_starts_critical n h e s f :
 compatible n e s f ->parity n h s=true ->parity n h e=false ->
 critical_frame n h e s f 0.
Proof.
 intros Compat Odd Ker;split;[assumption|].
 destruct Compat as[Sub Avoid].
 destruct(odd_row_has_target_extension n h s e Sub Odd Ker)as[q[Q[Hq[Eq Sq]]]].
 assert(Fq:f q=false)by(destruct(f q)eqn:Fq;[pose proof(Avoid q Q Fq);congruence|reflexivity]).
 exists q;repeat split;try assumption;lia.
Qed.
Theorem proper_minimum_prefix_critical n hs ls e s f :
 minimum n hs ls e ->compatible n e s f ->0<weight n s ->weight n s<weight n e ->
 exists h,In h hs /\critical_frame n h e s f 0.
Proof.
 intros Min Compat Pos Proper.
 destruct(minimum_prefix_has_odd_row n hs ls e s Min (proj1 Compat) Pos Proper)as[h[Hin Odd]].
 exists h;split;[assumption|apply odd_row_starts_critical;try assumption].
 destruct Min as[[_[Ker Log]] Best];apply Ker;assumption.
Qed.
Definition sibling_forbidden (exclude:bool) f q :=if exclude then setbit f q else f.
Theorem critical_scan_transition n h e s f next exclude :
 critical_frame n h e s f next ->
 let chosen:=scan_candidates n next h s f in
 chosen<n /\s chosen=false /\f chosen=false /\
 ((e chosen=true /\compatible n e(setbit s chosen)f) \/
  (e chosen=false /\critical_frame n h e s(sibling_forbidden exclude f chosen)(S chosen))).
Proof.
 intros [Compat[target[Range[H[Sv[Fv E]]]]]];simpl.
 pose proof(scan_target_not_skipped n next h s f e target Range H Sv Fv E)as Scan.
 cbn zeta in Scan;destruct Scan as[Before[Inside[Hc[Sc[Fc Advance]]]]].
 split;[assumption|split;[assumption|split;[assumption|]]].
 destruct(e(scan_candidates n next h s f))eqn:Chosen.
 - left;split;[reflexivity|split].
   + apply setbit_subset;[exact(proj1 Compat)|assumption].
   + exact(proj2 Compat).
 - right;split;[reflexivity|split].
   + split;[exact(proj1 Compat)|].
     unfold sibling_forbidden;destruct exclude;[apply avoids_setbit|];try assumption;exact(proj2 Compat).
   + exists target;split;[pose proof(Advance eq_refl);lia|].
     split;[assumption|split;[assumption|split;[|assumption]]].
     unfold sibling_forbidden;destruct exclude;[|assumption].
     unfold setbit;assert(Ne:Nat.eqb target(scan_candidates n next h s f)=false).
     { apply Nat.eqb_neq;pose proof(Advance eq_refl);lia. }
     rewrite Ne;assumption.
Qed.
Theorem critical_scan_cannot_finish n h e s f next :
 critical_frame n h e s f next ->scan_candidates n next h s f<>n.
Proof.
 intros C;pose proof(critical_scan_transition n h e s f next false C)as T;simpl in T;lia.
Qed.
Theorem chosen_target_child_frame_capacity n depth old path s h e f next :
 phase_path n depth 1 old path s ->critical_frame n h e s f next ->
 depth<n /\phase_path n(depth+1)0 0(path++[scan_candidates n next h s f])
 (flip s(scan_candidates n next h s f)).
Proof.
 intros Phase Critical;pose proof(critical_scan_transition n h e s f next false Critical)as T.
 cbn zeta in T;destruct T as[Q[Free Other]];split.
 - eapply phase_push_frame_capacity;eauto.
 - eapply phase_push;eassumption.
Qed.
Print Assumptions positive_first_bit.
Print Assumptions minimum_root_covered.
Print Assumptions proper_minimum_prefix_critical.
Print Assumptions critical_scan_transition.
Print Assumptions critical_scan_cannot_finish.
Print Assumptions chosen_target_child_frame_capacity.
