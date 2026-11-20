(* Sparse, order-preserving refinement of the raw PCM front end. *)
Require Import VST.floyd.proofauto.
Require Import CCV.CCModel CCV.CCFunctional CCV.CCCache CCV.CCRows
 CCV.CCValidation CCV.CCMatrixModel CCV.CCSearchSpecs CCV.CCPCMDetectors
 CCV.CCPCMLayout CCV.CCPCMInput.
Import ListNotations.
Local Open Scope Z_scope.

(* Keep row slicing outside the returned bit accessor in extracted code. *)
Definition sliced_vectors n m (flat : list Z) : list vector :=
  map (fun row j => nth j row 0 =? 1)
      (map (fun i => matrix_row n (Z.of_nat i) flat) (seq 0 (Z.to_nat m))).

Lemma sliced_vectors_correct n m flat :
  sliced_vectors n m flat = matrix_vectors n m flat.
Proof. unfold sliced_vectors, matrix_vectors; rewrite map_map; reflexivity. Qed.

Fixpoint support (n : nat) (g : vector) : list nat :=
  match n with
  | O => []
  | S k => if g k then k :: support k g else support k g
  end.

Fixpoint support_dot (indices : list nat) (r : vector) : bool :=
  match indices with
  | [] => false
  | i :: more => xorb (r i) (support_dot more r)
  end.

Lemma support_dot_correct n g r : support_dot (support n g) r = parity n r g.
Proof.
  induction n as [|n IH]; [reflexivity|].
  cbn [support parity]; destruct (g n), (r n) eqn:R;
    cbn [support_dot]; rewrite ?R, IH; destruct (parity n r g); reflexivity.
Qed.

Lemma partition_filters {A} (p : A -> bool) xs :
  List.partition p xs = (filter p xs, filter (fun x => negb (p x)) xs).
Proof.
  induction xs as [|x xs IH]; [reflexivity|].
  cbn [List.partition filter]; rewrite IH; destruct (p x); reflexivity.
Qed.

Fixpoint sparse_detectors n (supports : list (list nat)) : list vector :=
  match supports with
  | [] => map unit_vector (seq 0 n)
  | g :: tail =>
      let rows := sparse_detectors n tail in
      let '(odd, even) := List.partition (support_dot g) rows in
      match odd with
      | [] => rows
      | pivot :: rest => even ++ map (fun r => cached_vector n (vxor r pivot)) rest
      end
  end.

Lemma sparse_detectors_correct n gs :
  sparse_detectors n (map (support n) gs) = pcm_detectors n gs.
Proof.
  induction gs as [|g gs IH]; [reflexivity|].
  cbn [map sparse_detectors pcm_detectors]; rewrite IH, partition_filters.
  unfold restrict_detectors.
  rewrite (filter_ext (support_dot (support n g)) (fun r => parity n r g)) by apply support_dot_correct.
  rewrite (filter_ext (fun r => negb (support_dot (support n g) r)) (fun r => negb (parity n r g))) by
    (intro r; rewrite support_dot_correct; reflexivity).
  reflexivity.
Qed.

Definition commutes_with hs g := forallb (fun h => negb (support_dot g h)) hs.

Lemma sparse_commute_correct n gs hs :
  forallb (commutes_with hs) (map (support n) gs) =
  forallb (fun g => forallb (fun h => negb (parity n h g)) hs) gs.
Proof.
  induction gs as [|g gs IH]; [reflexivity|].
  cbn [map forallb]; rewrite IH; f_equal.
  unfold commutes_with; clear IH; induction hs as [|h hs IH]; [reflexivity|].
  cbn [forallb]; rewrite support_dot_correct, IH; reflexivity.
Qed.

Definition fast_prepare_pcm_half q : option half_model :=
  if raw_shape q then
    let n := Z.to_nat (width q) in
    let hs := sliced_vectors (width q) (check_count q) (checks q) in
    let gs := sliced_vectors (width q) (same_count q) (same_bytes q) in
    let supports := map (support n) gs in
    if forallb (commutes_with hs) supports then
      let rows := match sparse_detectors n supports with
                  | [] => [zero_vector] | rs => rs end in
      let count := Zlength rows in
      if count <=? 2147483647 / width q then
        Some {| model_n := width q; model_m := check_count q; model_k := same_count q;
                model_l := count; model_h := checks q; model_g := same_bytes q;
                model_lg := pcm_flat n rows |}
      else None
    else None
  else None.

(* Equality of the whole option includes rejection, detector order and bytes. *)
Theorem fast_prepare_pcm_half_correct q :
  fast_prepare_pcm_half q = prepare_pcm_half q.
Proof.
  unfold fast_prepare_pcm_half, prepare_pcm_half, commute, prepared, detectors,
         c_detector_rows, same_rows, check_rows.
  rewrite !sliced_vectors_correct, sparse_commute_correct, sparse_detectors_correct.
  reflexivity.
Qed.
