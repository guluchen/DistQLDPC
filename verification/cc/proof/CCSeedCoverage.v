(* Universal root-loop coverage invariant. Pure mathematics; its preservation
   by the actual complete C DFS remains a separate proof obligation. *)
From Coq Require Import Bool List Arith Lia.
Require Import CCV.CCModel CCV.CCFunctional CCV.CCCandidateScan.
Definition seeds_before_clear n hs ls cap seed:=forall e,
 minimum n hs ls e ->weight n e<=cap ->forall q,q<seed ->e q=false.
Lemma seeds_initial n hs ls cap:seeds_before_clear n hs ls cap 0.
Proof. intros e Min Cap q Q;lia. Qed.
Lemma current_seed_target_compatible n hs ls cap seed e:
 seeds_before_clear n hs ls cap seed ->seed<n ->
 minimum n hs ls e ->weight n e<=cap ->e seed=true ->
 compatible n e(root_selected seed)(root_forbidden seed).
Proof.
 intros Before Seed Min Cap Hit;apply first_target_root_compatible;try assumption.
 apply(Before e Min Cap).
Qed.
Theorem completed_seed_advances n hs ls cap seed:
 seeds_before_clear n hs ls cap seed ->
 (forall e,minimum n hs ls e ->weight n e<=cap ->e seed=true ->False) ->
 seeds_before_clear n hs ls cap(S seed).
Proof.
 intros Before Closed e Min Cap q Q.
 destruct(Nat.eq_dec q seed)as[->|Ne].
 - destruct(e seed)eqn:Bit;[exfalso;exact(Closed e Min Cap Bit)|reflexivity].
 - apply(Before e Min Cap);lia.
Qed.
Theorem all_seeds_empty_no_good n hs ls cap:
 seeds_before_clear n hs ls cap n ->forall e,good n hs ls e ->cap<weight n e.
Proof.
 intros Before e Good.
 destruct(Nat.le_gt_cases(weight n e)cap)as[Within|Above];[|assumption].
 exfalso;destruct(minimum_exists_below_witness n hs ls e Good)as[v[Min Bound]].
 assert(Bits:forall q,q<n ->v q=false)by(apply(Before v Min);lia).
 assert(Zero:weight n v=0).
 { rewrite(weight_ext n v zero_vector Bits);apply zero_weight. }
 destruct Min as[[Pos Rest]Best];lia.
Qed.
Print Assumptions current_seed_target_compatible.
Print Assumptions completed_seed_advances.
Print Assumptions all_seeds_empty_no_good.
