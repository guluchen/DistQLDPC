(* An exhausted phase1 candidate scan cannot discard the last live critical
   target frame. Pure coverage fact; actual pop/caller refinement is separate. *)
Require Import VST.floyd.proofauto.
Require Import CCV.CCModel CCV.CCFunctional CCV.CCCriticalFrame CCV.CCResumeTarget
 CCV.CCStackInvariant CCV.CCFrameUpdates CCV.CCResumeCoverage CCV.CCScanBridge
 CCV.CCRepresentation CCV.CCJournalArray CCV.CCValidation CCV.VerifPhaseOne
 CCV.VerifCandidateScan CCV.CCCandidateScan.
Import ListNotations. Open Scope nat_scope.
Theorem exhausted_scan_top_not_critical n hs base log path prefix g:
 ghost_phase g=1 ->
 scan_candidates n(ghost_next g)(nth(ghost_row g)hs zero_vector)
 (prefix_selected path(length prefix))(decode(journal_bitmap base log))=n ->
 forall e,~critical_at n hs base log path(prefix++[g])e(length prefix).
Proof.
 intros Phase Exact e[gk[At Critical]].
 rewrite old_last in At;inversion At;subst gk.
 cbv zeta in Critical;rewrite Phase,snapshot_top in Critical.
 pose proof(critical_scan_cannot_finish n(nth(ghost_row g)hs zero_vector)e
 (prefix_selected path(length prefix))(decode(journal_bitmap base log))
 (ghost_next g)Critical)as Impossible;apply Impossible;exact Exact.
Qed.
Open Scope Z_scope.
Theorem concrete_exhausted_top_not_critical n m hs base log path prefix g h xs:
 0<n ->0<=m ->0<=Z.of_nat(ghost_row g)<m ->ghost_phase g=1%nat ->
 Zlength h=m*n ->Zlength xs=n ->Zlength(journal_bitmap base log)=n ->
 Forall(fun z:Z=>z=0\/z=1)h ->Forall(fun z:Z=>z=0\/z=1)xs ->
 Forall(fun z:Z=>z=0\/z=1)(journal_bitmap base log) ->
 nth(ghost_row g)hs zero_vector=row_vector n(Z.of_nat(ghost_row g))h ->
 (forall i,(i<Z.to_nat n)%nat ->decode xs i=prefix_selected path(length prefix)i) ->
 phase1_certificate n(Z.of_nat(ghost_row g))(Z.of_nat(ghost_next g))h xs
 (journal_bitmap base log)n ->
 forall e,~critical_at(Z.to_nat n)hs base log path(prefix++[g])e(length prefix).
Proof.
 intros N M Row Phase HL XL FL HB XB FB RowEq Selected[Bounds[Skip Hit]]e[gk[At Critical]].
 rewrite old_last in At;inversion At;subst gk.
 cbv zeta in Critical;rewrite Phase,snapshot_top,RowEq in Critical.
 pose proof(critical_selected_ext(Z.to_nat n)(row_vector n(Z.of_nat(ghost_row g))h)e
 (prefix_selected path(length prefix))(decode xs)(decode(journal_bitmap base log))
 (ghost_next g)Selected Critical)as ActualCritical.
 replace(ghost_next g)with(Z.to_nat(Z.of_nat(ghost_next g)))in ActualCritical
 by(rewrite Nat2Z.id;reflexivity).
 pose proof(concrete_scan_critical_transition n m(Z.of_nat(ghost_row g))
 (Z.of_nat(ghost_next g))n h xs(journal_bitmap base log)e false N M Row ltac:(lia)
 HL XL FL HB XB FB Skip Hit ActualCritical)as[Impossible Rest];lia.
Qed.
Print Assumptions concrete_exhausted_top_not_critical.
