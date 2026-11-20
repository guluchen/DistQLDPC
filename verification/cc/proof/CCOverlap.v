(* Concrete overlap pruning, instantiated in the complete functional CC model.
   This is not yet the VST proof of the C overlap loop/journal. *)
From Coq Require Import Bool List Arith Lia.
Require Import CCV.CCModel CCV.CCFunctional.
Import ListNotations.
Definition tight_mask n (s g:vector) : vector :=fun q=>
 andb (Nat.eqb (weight n (vinter s g)) (weight n g/2)) (andb (g q) (negb(s q))).
Definition overlap_one n (s f g:vector) : option vector :=
 if weight n g/2 <? weight n (vinter s g) then None
 else Some(fun q=>orb(f q)(tight_mask n s g q)).
Fixpoint overlap_rules n (gs:list vector) s f : option vector :=
 match gs with []=>Some f | g::tail=>match overlap_one n s f g with
    None=>None | Some f'=>overlap_rules n tail s f' end end.
Definition stabilizer_valid n hs ls g :=kernel n hs g /\ forall l,In l ls ->parity n l g=false.
Lemma half_round w : w<2*(w/2+1).
Proof.
 pose proof(Nat.div_mod w 2 ltac:(lia));pose proof(Nat.mod_upper_bound w 2 ltac:(lia));nia.
Qed.
Theorem overlap_one_keeps_minimum n hs ls e s f g :
 minimum n hs ls e -> stabilizer_valid n hs ls g -> compatible n e s f ->
 exists f',overlap_one n s f g=Some f' /\ avoids n e f'.
Proof.
 intros Hmin [Hg Hl] [Hsub Havoid];unfold overlap_one.
 destruct(weight n g/2 <? weight n (vinter s g)) eqn:Bad.
 - apply Nat.ltb_lt in Bad;exfalso.
   eapply (overlap_prune_preserves_minimum n hs ls e g s);try eassumption.
   pose proof(half_round (weight n g));nia.
 - eexists;split;[reflexivity|].
   intros q Hq Hf;apply orb_true_iff in Hf;destruct Hf as [Hf|Ht].
   + apply Havoid;assumption.
   + unfold tight_mask in Ht;apply andb_true_iff in Ht;destruct Ht as [Heq Ht].
     apply Nat.eqb_eq in Heq;apply andb_true_iff in Ht;destruct Ht as [Hgq Hsq].
     apply negb_true_iff in Hsq.
     eapply (tight_overlap_forbid n hs ls e g s (weight n g/2) q);try eassumption.
     apply half_round.
Qed.
Theorem overlap_rules_keep_minimum n hs ls e gs :
 minimum n hs ls e -> (forall g,In g gs -> stabilizer_valid n hs ls g) ->
 forall s f,compatible n e s f ->
 exists f',overlap_rules n gs s f=Some f' /\ avoids n e f'.
Proof.
 intros Hmin;induction gs as [|g gs IH];intros Valid s f Comp;simpl.
 - exists f;split;[reflexivity|exact (proj2 Comp)].
 - destruct(overlap_one_keeps_minimum n hs ls e s f g Hmin (Valid g (or_introl eq_refl)) Comp)
    as [f1 [Run Safe]];rewrite Run.
   apply IH.
   + intros g' Hin;apply Valid;right;assumption.
   + split;[exact(proj1 Comp)|assumption].
Qed.
Theorem overlap_prune_contract n hs ls gs cap :
 (forall g,In g gs ->stabilizer_valid n hs ls g) ->
 prune_contract n hs ls cap (overlap_rules n gs).
Proof.
 intros Valid e s f Hmin Hcap Comp;apply (overlap_rules_keep_minimum n hs ls e gs);assumption.
Qed.
Theorem overlap_distance_found_for_all_inputs n hs ls gs out :
 (forall g,In g gs ->stabilizer_valid n hs ls g) ->
 code_half_distance n hs ls (fun _=>overlap_rules n gs)=Some out -> minimum n hs ls out.
Proof.
 intros Valid Run;apply (code_half_distance_found n hs ls (fun _=>overlap_rules n gs) out);
 [intros cap;apply overlap_prune_contract;assumption|assumption].
Qed.
Theorem overlap_distance_none_for_all_inputs n hs ls gs :
 (forall g,In g gs ->stabilizer_valid n hs ls g) ->
 (code_half_distance n hs ls (fun _=>overlap_rules n gs)=None <-> ~exists e,good n hs ls e).
Proof.
 intros Valid;apply code_half_distance_none;intros cap;apply overlap_prune_contract;assumption.
Qed.
Print Assumptions overlap_one_keeps_minimum.
Print Assumptions overlap_distance_found_for_all_inputs.
Print Assumptions overlap_distance_none_for_all_inputs.
