(* Executable preparation of one half from two raw, row-major binary PCMs. *)
Require Import VST.floyd.proofauto.
Require Import CCV.CCModel CCV.CCFunctional CCV.CCCSSBridge CCV.CCCSSResultBridge
 CCV.CCRepresentation CCV.CCMatrixModel CCV.CCValidation CCV.CCSearchSpecs
 CCV.CCPCMDetectors CCV.CCPCMLayout CCV.CCQuotientCertificate.
Import ListNotations.
Local Open Scope Z_scope.
Local Open Scope bool_scope.

Record raw_half := { width:Z; check_count:Z; same_count:Z; checks:list Z; same_bytes:list Z }.
Definition same_rows q :=matrix_vectors (width q) (same_count q) (same_bytes q).
Definition check_rows q :=matrix_vectors (width q) (check_count q) (checks q).
Definition detectors q :=c_detector_rows (Z.to_nat(width q)) (same_rows q).
Definition prepared q : half_model :=
 {|model_n:=width q; model_m:=check_count q; model_k:=same_count q;
   model_l:=Zlength(detectors q);model_h:=checks q;model_g:=same_bytes q;
   model_lg:=pcm_flat (Z.to_nat(width q)) (detectors q)|}.
Definition valid_bytes rows:= forallb (fun b=> orb (b=?0) (b=?1)) rows.
Definition raw_shape q :=
 (0 <? width q) && (width q <=? 107374182) &&
 (0 <=? check_count q) && (check_count q <=? 2147483647 / width q) &&
 (0 <=? same_count q) && (same_count q <=? 2147483647 / width q) &&
 (Zlength(checks q)=?check_count q * width q) &&
 (Zlength(same_bytes q)=?same_count q * width q) &&
 valid_bytes(checks q) && valid_bytes(same_bytes q).
Definition commute q :=
 forallb (fun g=>forallb (fun h=>negb(parity (Z.to_nat(width q)) h g)) (check_rows q)) (same_rows q).
Definition prepare_pcm_half q : option half_model :=
 if raw_shape q then if commute q then
 let a:=prepared q in if model_l a <=? 2147483647 / width q then Some a else None
 else None else None.

Lemma bytes_sound xs : valid_bytes xs=true -> Forall (fun b:Z=>b=0 \/ b=1) xs.
Proof.
 unfold valid_bytes;rewrite forallb_forall,Forall_forall;intros H b B.
 specialize (H b B);rewrite orb_true_iff,!Z.eqb_eq in H;exact H.
Qed.
Lemma commute_sound q : commute q=true <->Forall(kernel (Z.to_nat(width q))(check_rows q))(same_rows q).
Proof.
 unfold commute;rewrite forallb_forall,Forall_forall;split;intros H g G;specialize(H g G).
 - rewrite forallb_forall in H;intros h R;specialize(H h R);apply negb_true_iff;exact H.
 - apply forallb_forall;intros h R;apply negb_true_iff;apply H;exact R.
Qed.
Lemma prepared_detectors q e : 0<width q ->
 (kernel (Z.to_nat(width q)) (model_l_rows(prepared q)) e <->rowspan (Z.to_nat(width q)) (same_rows q) e).
Proof.
 intros W;unfold model_l_rows;cbn [prepared model_n model_l model_lg].
 rewrite Zlength_correct;replace (width q) with (Z.of_nat(Z.to_nat(width q))) at 2 by lia.
 rewrite flat_kernel by lia;apply c_detector_kernel.
Qed.
Lemma prep_components q a : prepare_pcm_half q=Some a <->
 raw_shape q=true /\ commute q=true /\ Zlength(detectors q)<=2147483647/width q /\ a=prepared q.
Proof.
 unfold prepare_pcm_half;cbn [prepared model_l].
 destruct(raw_shape q), (commute q), (Zlength(detectors q) <=? 2147483647/width q)eqn:L;
 try apply Z.leb_le in L;try apply Z.leb_gt in L;split;intros K;try discriminate;try tauto;
 try solve [intuition congruence|intuition lia].
Qed.
Theorem prepare_pcm_contract q a : prepare_pcm_half q=Some a ->
 legal_model a /\ complete_css_model a (same_rows q) /\
 Forall(kernel (Z.to_nat(model_n a))(model_h_rows a))(same_rows q).
Proof.
 rewrite prep_components;intros [Shape [Comm [Fits ->]]];apply commute_sound in Comm.
 unfold raw_shape in Shape;rewrite !andb_true_iff,!Z.ltb_lt,!Z.leb_le,!Z.eqb_eq in Shape.
 assert(W:0<width q) by tauto.
 assert(M:0<=check_count q) by tauto. assert(K:0<=same_count q) by tauto.
 assert(L:0<Zlength(detectors q)).
 { rewrite Zlength_correct;pose proof(detector_count_positive (Z.to_nat(width q))(same_rows q));unfold detectors;lia. }
 split.
 - unfold legal_model;cbn [prepared model_n model_m model_l model_k model_h model_g model_lg].
   repeat apply conj;try tauto;try solve [apply bytes_sound;tauto|apply flat_bits].
   + rewrite !Zlength_correct,flat_length,Nat2Z.inj_mul,Z2Nat.id by lia;reflexivity.
   + intros i I.
     assert (G:In (row_vector (width q) i (same_bytes q)) (same_rows q)).
     { apply matrix_vectors_member;[assumption|exists i;auto]. }
     split;intros j J.
     * rewrite Forall_forall in Comm;apply (Comm _ G);apply matrix_vectors_member;[assumption|exists j;auto].
     * assert (D:kernel (Z.to_nat(width q)) (model_l_rows(prepared q)) (row_vector (width q) i (same_bytes q))).
       { apply prepared_detectors;[exact W|apply generator_in_span;exact G]. }
       apply D;unfold model_l_rows;apply matrix_vectors_member;[cbn;lia|exists j;split;[exact J|reflexivity]].
 - split;[intros e He;symmetry;apply prepared_detectors;exact W|exact Comm].
Qed.
