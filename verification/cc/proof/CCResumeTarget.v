(* Pending-child cleanup and optional sibling exclusion preserve the same
   critical target. Pure bridge, not the C caller or whole-search proof. *)
From Coq Require Import Bool List Arith Lia.
Require Import CCV.CCCache CCV.CCModel CCV.CCFunctional CCV.CCCriticalFrame CCV.CCSearchPhases.
Import ListNotations.
Lemma critical_selected_ext n h e old new f next:
 (forall i,i<n ->new i=old i) ->
 critical_frame n h e old f next ->critical_frame n h e new f next.
Proof.
 intros Eq [[Sub Avoid][target[[Lo Hi][H[Free[Allowed Hit]]]]]].
 split.
 - split;[intros i I Selected;apply Sub;[assumption|rewrite <-Eq by assumption;assumption]|assumption].
 - exists target;repeat split;try assumption;rewrite Eq by lia;assumption.
Qed.
Theorem critical_forbid_outside n h e s f next q exclude:
 critical_frame n h e s f next ->e q=false ->
 critical_frame n h e s(sibling_forbidden exclude f q)next.
Proof.
 intros [Compat[target[[Lo Hi][H[Free[Allowed Hit]]]]]] Outside.
 unfold sibling_forbidden;destruct exclude;[|split;[assumption|eauto 8]].
 split.
 - split;[exact(proj1 Compat)|apply avoids_setbit;[exact(proj2 Compat)|assumption]].
 - exists target;repeat split;try assumption.
   unfold setbit;assert(Ne:Nat.eqb target q=false).
   { apply Nat.eqb_neq;intro E;subst target;congruence. }
   rewrite Ne;assumption.
Qed.
Theorem pending_resume_keeps_target n depth q path selected h e f next exclude:
 phase_path n depth 2 q path selected ->
 critical_frame n h e(path_bits path)f next ->e q=false ->
 phase_path n depth 1 0 path(flip selected q) /\
 critical_frame n h e(flip selected q)(sibling_forbidden exclude f q)next.
Proof.
 intros State Critical Outside.
 pose proof(phase_pending_undo n depth q path selected State)as Resumed.
 split;[assumption|].
 destruct Resumed as[ND[Range[Len Eq]]].
 eapply critical_selected_ext;[exact Eq|].
 apply critical_forbid_outside;assumption.
Qed.
Print Assumptions pending_resume_keeps_target.
