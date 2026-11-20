(* Actual ascending C scan facts to the mathematical path-based child push.
   No complete C caller or whole-search theorem is asserted here. *)
Require Import VST.floyd.proofauto.
Require Import CCV.CCModel CCV.CCFunctional CCV.CCCandidateScan CCV.CCScanBridge
 CCV.CCRepresentation CCV.CCValidation CCV.CCMatrixModel CCV.VerifCandidateScan.
Import ListNotations. Open Scope nat_scope.
Lemma scan_from_ext fuel start a b:
 (forall i,start<=i<start+fuel ->a i=b i) ->scan_from fuel start a=scan_from fuel start b.
Proof.
 revert start;induction fuel as[|fuel IH];intros start Eq;cbn[scan_from];[reflexivity|].
 rewrite Eq by lia;destruct(b start);[reflexivity|apply IH;intros i I;apply Eq;lia].
Qed.
Lemma scan_selected_ext n next h before after f:
 next<=n ->(forall i,i<n ->before i=after i) ->
 scan_candidates n next h before f=scan_candidates n next h after f.
Proof.
 intros Next Eq;unfold scan_candidates;apply scan_from_ext.
 intros i I;rewrite Eq by lia;reflexivity.
Qed.
Lemma nth_mapped_sequence{A:Type}(f:nat->A)start count(default:A)i:
 i<count ->nth i(map f(seq start count))default=f(start+i).
Proof.
 revert start i;induction count as[|count IH];intros start[|i]I;cbn[seq map nth]in*;try lia.
 - rewrite Nat.add_0_r;reflexivity.
 - rewrite IH by lia;f_equal;lia.
Qed.
Open Scope Z_scope.
Lemma matrix_vectors_nth n m h r:(r<Z.to_nat m)%nat ->
 nth r(matrix_vectors n m h)zero_vector=row_vector n(Z.of_nat r)h.
Proof.
 intros R;unfold matrix_vectors.
 rewrite nth_mapped_sequence by assumption;reflexivity.
Qed.
Theorem concrete_scan_path_facts n m row next q h xs fs(path:list nat):
 0<n ->0<=m ->0<=row<m ->0<=next ->next<=q<=n ->
 Zlength h=m*n ->Zlength xs=n ->Zlength fs=n ->
 Forall(fun z:Z=>z=0\/z=1)h ->Forall(fun z:Z=>z=0\/z=1)xs ->
 Forall(fun z:Z=>z=0\/z=1)fs ->
 (forall i,(i<Z.to_nat n)%nat ->decode xs i=CCSearchPhases.path_bits path i) ->
 scan_skipped n row h xs fs next q ->(q<n ->scan_available n row h xs fs q=true) ->
 q=Z.of_nat(scan_candidates(Z.to_nat n)(Z.to_nat next)(row_vector n row h)
 (CCSearchPhases.path_bits path)(decode fs)) /\
 (q<n ->decode xs(Z.to_nat q)=false /\decode fs(Z.to_nat q)=false).
Proof.
 intros N M Row Next Q Hlen Xlen Flen HB XB FB Selected Skip Hit.
 pose proof(concrete_scan_is_abstract n m row next q h xs fs N M Row ltac:(lia)
 Hlen Xlen Flen HB XB FB Skip Hit)as Exact.
 split.
 - rewrite Exact;f_equal;apply scan_selected_ext.
   + apply Z2Nat.inj_le;lia.
   + exact Selected.
 - intros Inside;pose proof(Hit Inside)as Available.
   rewrite(concrete_candidate_decode n m row h xs fs q N M Row ltac:(lia)
   Hlen Xlen Flen HB XB FB)in Available.
   apply andb_true_iff in Available;destruct Available as[Hq Available].
   apply andb_true_iff in Available;destruct Available as[Xq Fq].
   apply negb_true_iff in Xq,Fq;auto.
Qed.
Print Assumptions concrete_scan_path_facts.
