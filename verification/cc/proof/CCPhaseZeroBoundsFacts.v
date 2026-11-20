(* Bounds rejection discharges the critical-top condition required by pop.
   Uses the current phase0 bitmap, not an ancestor's protected snapshot. *)
Require Import VST.floyd.proofauto.
Require Import CCV.CCModel CCV.CCFunctional CCV.CCSearchPolicies CCV.CCMatrixModel
 CCV.CCRepresentation CCV.CCStackInvariant CCV.CCFrameUpdates CCV.CCResumeCoverage
 CCV.CCJournalArray.
Import ListNotations. Open Scope Z_scope.
Theorem bounds_rejects_no_critical_top n m h ls cap base log path prefix g xs:
 0<=cap ->ghost_phase g=0%nat ->
 bounds_rejects_all n m h ls cap xs(journal_bitmap base log) ->
 (forall i,(i<Z.to_nat n)%nat ->decode xs i=prefix_selected path(length prefix)i) ->
 forall e,minimum(Z.to_nat n)(matrix_vectors n m h)ls e ->
 (weight(Z.to_nat n)e<=Z.to_nat cap)%nat ->
 ~critical_at(Z.to_nat n)(matrix_vectors n m h)base log path(prefix++[g])e(length prefix).
Proof.
 intros Cap Phase Bad Selected e Min Within[gk[At Critical]].
 rewrite old_last in At;inversion At;subst gk.
 cbv zeta in Critical;rewrite Phase,snapshot_top in Critical.
 destruct Critical as[Sub Avoid].
 assert(WithinZ:Z.of_nat(weight(Z.to_nat n)e)<=cap).
 { apply Nat2Z.inj_le in Within;rewrite Z2Nat.id in Within by assumption;assumption. }
 apply(Bad e Min WithinZ);split;[|assumption].
 intros i I Hit;apply Sub;[assumption|rewrite <-Selected by assumption;assumption].
Qed.
Print Assumptions bounds_rejects_no_critical_top.
