(* Concrete C scan contract to the abstract critical-target search scan.
   This bridge is separate from the whole C search invariant. *)
Require Import VST.floyd.proofauto.
Require Import CCV.VerifCandidateScan CCV.CCCandidateScan CCV.CCRepresentation.
Import ListNotations. Open Scope Z_scope.
Lemma scan_result_unique fuel start available q :
 (start<=q<=start+fuel)%nat ->
 (forall j,(start<=j<q)%nat ->available j=false) ->
 ((q<start+fuel)%nat ->available q=true) ->
 CCCandidateScan.scan_from fuel start available=q.
Proof.
 intros Range Skip Hit.
 pose proof(CCCandidateScan.scan_bounds fuel start available)as Bounds.
 destruct(Nat.lt_trichotomy(CCCandidateScan.scan_from fuel start available)q)as[Before|[Same|After]].
 - pose proof(CCCandidateScan.scan_returns_available fuel start available ltac:(lia))as A.
   pose proof(Skip (CCCandidateScan.scan_from fuel start available) ltac:(lia));congruence.
 - assumption.
 - pose proof(CCCandidateScan.scan_before_false fuel start available q ltac:(lia))as A.
   pose proof(Hit ltac:(lia));congruence.
Qed.
Lemma concrete_candidate_decode n m row h xs fs q :
 0<n ->0<=m ->0<=row<m ->0<=q<n ->
 Zlength h=m*n ->Zlength xs=n ->Zlength fs=n ->
 Forall(fun z:Z=>z=0\/z=1)h ->Forall(fun z:Z=>z=0\/z=1)xs ->
 Forall(fun z:Z=>z=0\/z=1)fs ->
 scan_available n row h xs fs q=
 andb(CCValidation.row_vector n row h(Z.to_nat q))
 (andb(negb(CCRepresentation.decode xs(Z.to_nat q)))
       (negb(CCRepresentation.decode fs(Z.to_nat q)))).
Proof.
 intros N M Row Q Hlen Xlen Flen HB XB FB.
 rewrite CCRepresentation.row_vector_column with(m:=m)by assumption.
 unfold scan_available.
 rewrite !CCRepresentation.decode_at_nat,!Z2Nat.id by lia.
 assert(Hbit:Znth(row*n+q)h=0\/Znth(row*n+q)h=1).
 { apply (proj1(Forall_Znth _ _)HB);rewrite Hlen;apply CCMatrix.matrix_index;lia. }
 assert(Xbit:Znth q xs=0\/Znth q xs=1)by(apply (proj1(Forall_Znth _ _)XB);lia).
 assert(Fbit:Znth q fs=0\/Znth q fs=1)by(apply (proj1(Forall_Znth _ _)FB);lia).
 destruct Hbit as[H|H];destruct Xbit as[X|X];destruct Fbit as[F|F];rewrite H,X,F;reflexivity.
Qed.
Theorem concrete_scan_is_abstract n m row next q h xs fs :
 0<n ->0<=m ->0<=row<m ->(0<=next /\ next<=q<=n) ->
 Zlength h=m*n ->Zlength xs=n ->Zlength fs=n ->
 Forall(fun z:Z=>z=0\/z=1)h ->Forall(fun z:Z=>z=0\/z=1)xs ->
 Forall(fun z:Z=>z=0\/z=1)fs ->
 scan_skipped n row h xs fs next q ->
 (q<n ->scan_available n row h xs fs q=true) ->
 q=Z.of_nat(CCCandidateScan.scan_candidates(Z.to_nat n)(Z.to_nat next)
 (CCValidation.row_vector n row h)(CCRepresentation.decode xs)(CCRepresentation.decode fs)).
Proof.
 intros N M Row Range Hlen Xlen Flen HB XB FB Skip Hit.
 assert(Next:0<=next)by lia;assert(Q:0<=q)by lia.
 pose proof(Z2Nat.id n ltac:(lia))as Nnat.
 pose proof(Z2Nat.id next Next)as Nextnat.
 pose proof(Z2Nat.id q Q)as Qnat.
 assert(E:CCCandidateScan.scan_candidates(Z.to_nat n)(Z.to_nat next)
   (CCValidation.row_vector n row h)(CCRepresentation.decode xs)(CCRepresentation.decode fs)=Z.to_nat q).
 { unfold CCCandidateScan.scan_candidates;apply scan_result_unique.
   - lia.
   - intros j J.
     pose proof(concrete_candidate_decode n m row h xs fs (Z.of_nat j) N M Row ltac:(lia) Hlen Xlen Flen HB XB FB)as Ej.
     rewrite Nat2Z.id in Ej. rewrite <-Ej. apply Skip;lia.
   - intros J.
     rewrite <- (concrete_candidate_decode n m row h xs fs q) by (try assumption;lia).
     apply Hit;lia. }
 rewrite E;lia.
Qed.
Print Assumptions concrete_scan_is_abstract.
Require Import CCV.CCCriticalFrame.
Theorem concrete_scan_critical_transition n m row next q h xs fs e exclude :
 0<n ->0<=m ->0<=row<m ->(0<=next /\next<=q<=n) ->
 Zlength h=m*n ->Zlength xs=n ->Zlength fs=n ->
 Forall(fun z:Z=>z=0\/z=1)h ->Forall(fun z:Z=>z=0\/z=1)xs ->
 Forall(fun z:Z=>z=0\/z=1)fs ->
 scan_skipped n row h xs fs next q ->
 (q<n ->scan_available n row h xs fs q=true) ->
 CCCriticalFrame.critical_frame(Z.to_nat n)(CCValidation.row_vector n row h)e
   (decode xs)(decode fs)(Z.to_nat next) ->
 q<n /\
 ((e(Z.to_nat q)=true /\
   CCFunctional.compatible(Z.to_nat n)e(CCFunctional.setbit(decode xs)(Z.to_nat q))(decode fs)) \/
  (e(Z.to_nat q)=false /\
   CCCriticalFrame.critical_frame(Z.to_nat n)(CCValidation.row_vector n row h)e
     (decode xs)(CCCriticalFrame.sibling_forbidden exclude(decode fs)(Z.to_nat q))(S(Z.to_nat q)))).
Proof.
 intros N M Row Range Hlen Xlen Flen HB XB FB Skip Hit Critical.
 pose proof(concrete_scan_is_abstract n m row next q h xs fs
   N M Row Range Hlen Xlen Flen HB XB FB Skip Hit)as Exact.
 pose proof(CCCriticalFrame.critical_scan_transition(Z.to_nat n)
   (CCValidation.row_vector n row h)e(decode xs)(decode fs)(Z.to_nat next)exclude Critical)as T.
 cbn zeta in T.
 assert(Qnat:Z.to_nat q=CCCandidateScan.scan_candidates(Z.to_nat n)(Z.to_nat next)
   (CCValidation.row_vector n row h)(decode xs)(decode fs))by(rewrite Exact,Nat2Z.id;reflexivity).
 rewrite <-Qnat in T. destruct T as[Inside[Selected[Forbidden Branch]]].
 split;[apply Z2Nat.inj_lt;lia|assumption].
Qed.
Print Assumptions concrete_scan_critical_transition.
