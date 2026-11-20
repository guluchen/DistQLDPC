(* Semantic obligations of the actual increasing-cap C distance driver.
   Each query step assumes the search contract; that contract still requires
   a separate C body proof. This is not a whole-program VST theorem. *)
From Coq Require Import Bool List Arith Lia.
Require Import CCV.CCModel CCV.CCFunctional.
Inductive driver_result :=
 | DistanceFound (out:vector)
 | DistanceEmpty
 | DistanceUnknown.
Definition below_cap n hs ls cap :=forall e,good n hs ls e ->cap<=weight n e.
Definition empty_cap n hs ls cap :=forall e,good n hs ls e ->cap<weight n e.
Inductive driver_run n hs ls : nat ->driver_result ->Prop :=
 | driver_found cap out : cap<=n ->good n hs ls out ->weight n out<=cap ->
     driver_run n hs ls cap(DistanceFound out)
 | driver_unknown cap : cap<=n ->driver_run n hs ls cap DistanceUnknown
 | driver_next cap result : cap<=n ->empty_cap n hs ls cap ->
     driver_run n hs ls(S cap)result ->driver_run n hs ls cap result
 | driver_exhausted cap : n<cap ->driver_run n hs ls cap DistanceEmpty.
Theorem cap_lower_bound_initial n hs ls : below_cap n hs ls 1.
Proof. intros e[Pos Rest];lia. Qed.
Theorem cap_lower_bound_advance n hs ls cap :
 empty_cap n hs ls cap ->below_cap n hs ls(S cap).
Proof. unfold empty_cap,below_cap;intros Empty e Good;specialize(Empty e Good);lia. Qed.
Theorem driver_found_is_minimum n hs ls cap result :
 driver_run n hs ls cap result ->below_cap n hs ls cap ->
 forall out,result=DistanceFound out ->minimum n hs ls out.
Proof.
 intros Run;induction Run;intros Lower target Result.
 - inversion Result;subst target;split;[assumption|].
   intros e Good;specialize(Lower e Good);lia.
 - discriminate.
 - eapply IHRun;[apply cap_lower_bound_advance;assumption|assumption].
 - discriminate.
Qed.
Theorem driver_empty_is_infeasible n hs ls cap result :
 driver_run n hs ls cap result ->below_cap n hs ls cap ->
 result=DistanceEmpty ->~exists e,good n hs ls e.
Proof.
 intros Run;induction Run;intros Lower Result [e Good].
 - discriminate.
 - discriminate.
 - eapply IHRun;[apply cap_lower_bound_advance;assumption|assumption|exists e;assumption].
 - pose proof(Lower e Good);pose proof(vector_weight_bound n e);lia.
Qed.
Theorem distance_driver_correct n hs ls result :
 driver_run n hs ls 1 result ->
 (forall out,result=DistanceFound out ->minimum n hs ls out) /\
 (result=DistanceEmpty ->~exists e,good n hs ls e).
Proof.
 intros Run;split.
 - apply(driver_found_is_minimum n hs ls 1 result Run);apply cap_lower_bound_initial.
 - apply(driver_empty_is_infeasible n hs ls 1 result Run);apply cap_lower_bound_initial.
Qed.
(* Reaching UNKNOWN makes no infeasibility/minimum assertion. Its output and
   distance clearing are separate spatial obligations in the actual C spec. *)
Theorem at_most_n_queries n hs ls cap result : driver_run n hs ls cap result ->
 exists queries,queries<=n+1-cap /\
 (result=DistanceEmpty ->queries=n+1-cap).
Proof.
 intros Run;induction Run.
 - exists 1;split;[lia|discriminate].
 - exists 1;split;[lia|discriminate].
 - destruct IHRun as[q[Bound Empty]].
   exists(S q);split;[lia|intros E;specialize(Empty E);lia].
 - exists 0;split;[lia|intros;lia].
Qed.
Print Assumptions distance_driver_correct.
Print Assumptions at_most_n_queries.
