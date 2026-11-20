(* Byte layout of generated detector rows at the frozen C boundary. *)
Require Import VST.floyd.proofauto.
Require Import CCV.CCModel CCV.CCFunctional CCV.CCCache CCV.CCCSSBridge CCV.CCQuotientCertificate
 CCV.CCValidation CCV.CCRepresentation CCV.CCMatrixModel CCV.CCSearchSpecs CCV.CCPCMDetectors.
Import ListNotations.
Local Open Scope nat_scope.
Definition pcm_bytes n (row:vector) := map bitZ (tabulate n row).
Definition pcm_flat n (rows:list vector) := flat_map (pcm_bytes n) rows.
Lemma row_bytes_length n r : length (pcm_bytes n r)=n.
Proof. unfold pcm_bytes,tabulate;rewrite !map_length,seq_length;reflexivity. Qed.
Lemma flat_length n rows : length(pcm_flat n rows)=length rows*n.
Proof. induction rows;[reflexivity|];change (length(pcm_bytes n a ++ pcm_flat n rows)=n+length rows*n);rewrite app_length,row_bytes_length,IHrows;lia. Qed.
Lemma flat_bits n rows : Forall(fun z:Z=>z=0%Z \/ z=1%Z)(pcm_flat n rows).
Proof. induction rows;[constructor|];cbn [pcm_flat flat_map];apply Forall_app;split;[|assumption].
 apply Forall_forall;intros z H;apply in_map_iff in H as [b [<- H]];destruct b;simpl;auto. Qed.
Lemma pcm_lookup n rows i j : i<length rows -> j<n ->
 nth (i*n+j) (pcm_flat n rows) 0%Z = bitZ (nth i rows zero_vector j).
Proof.
 revert i;induction rows as [|r rs IH];intros [|i] jbound inside;cbn [length] in jbound;try lia.
 - cbn [pcm_flat flat_map Nat.mul Nat.add nth]. rewrite app_nth1 by (rewrite row_bytes_length;lia).
   unfold pcm_bytes;rewrite nth_indep with (d':=bitZ false) by (rewrite map_length;unfold tabulate;rewrite map_length,seq_length;lia).
   rewrite map_nth,tabulate_at by lia;reflexivity.
 - cbn [pcm_flat flat_map Nat.mul nth]. rewrite app_nth2 by (rewrite row_bytes_length;lia).
   rewrite row_bytes_length;replace (n+i*n+j-n) with (i*n+j) by lia;apply IH;lia.
Qed.

Lemma flat_kernel n rows e : 0<n ->
 kernel n (matrix_vectors (Z.of_nat n) (Z.of_nat(length rows)) (pcm_flat n rows)) e <->kernel n rows e.
Proof.
 intros N.
 assert (R:forall i, i<length rows -> parity n (row_vector (Z.of_nat n) (Z.of_nat i) (pcm_flat n rows)) e =
   parity n (nth i rows zero_vector) e).
 { intros i I;rewrite !(qcert_parity_comm n _ e). apply parity_ext;intros j J.
   replace j with (Z.to_nat(Z.of_nat j)) at 1 by apply Nat2Z.id.
   rewrite (row_vector_column _ (Z.of_nat(length rows))) by (rewrite ?Zlength_correct,?flat_length,?Nat2Z.inj_mul;lia).
   rewrite nonnegative_lookup by lia.
   rewrite <-Nat2Z.inj_mul,<-Nat2Z.inj_add,Nat2Z.id,pcm_lookup by lia.
   destruct (nth i rows zero_vector j);reflexivity. }
 unfold matrix_vectors;rewrite Nat2Z.id. split.
 - intros K r Hr;apply In_nth with (d:=zero_vector) in Hr as [i [I Eq]];subst r.
   rewrite <-R by exact I;apply K;apply in_map_iff;exists i;split;[reflexivity|apply in_seq;lia].
 - intros K r Hr;apply in_map_iff in Hr as [i [<- I]];apply in_seq in I;rewrite R by lia;apply K;apply nth_In;lia.
Qed.

Lemma zero_coeffs t : forall i, linear_combination t (repeat false (length t)) i=false.
Proof. induction t;intro i;cbn [length repeat linear_combination zero_vector];auto. Qed.
Lemma generator_in_span n (rows:list vector) g : In g rows -> rowspan n rows g.
Proof.
 induction rows as [|h t IH];intro H;[contradiction|].
 apply extend_rowspan. destruct H as [<-|Ht];[right|left;auto].
 exists (repeat false (length t));split;[apply repeat_length|].
 intros i Hi;unfold vxor;rewrite zero_coeffs,xorb_nilpotent;reflexivity.
Qed.
Definition c_detector_rows n same :=
 match pcm_detectors n same with []=>[zero_vector] | rs=>rs end.
Lemma c_detector_kernel n same e :
 kernel n (c_detector_rows n same) e <-> rowspan n same e.
Proof.
 rewrite <-detectors_characterize_rowspan;unfold c_detector_rows.
 destruct (pcm_detectors n same) as [|a t];[|tauto].
 split;intros K r H;[contradiction|destruct H as [<-|[]];apply qcert_zero_dot].
Qed.
Lemma detector_count_positive n same : 0<length(c_detector_rows n same).
Proof. unfold c_detector_rows;destruct(pcm_detectors n same);simpl;lia. Qed.
