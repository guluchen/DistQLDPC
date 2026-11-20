(* Consecutive Boolean entries allow linear passes for GF(2) dot and xor. *)
Require Import VST.floyd.proofauto.
Require Import CCV.CCModel CCV.CCFunctional CCV.CCCache CCV.CCRepresentation
 CCV.CCSearchSpecs CCV.CCPCMInput CCV.CCPCMLayout CCV.CCPCMDetectors CCV.CCPCMFast.
Import ListNotations. Local Open Scope nat_scope.

Fixpoint row_dot (xs ys : list bool) : bool :=
  match xs,ys with
  | x::xt,y::yt => xorb (andb x y) (row_dot xt yt)
  | _,_ => false
  end.

Fixpoint row_xor (xs ys : list bool) : list bool :=
  match xs,ys with
  | x::xt,y::yt => xorb x y :: row_xor xt yt
  | _,_ => []
  end.

Lemma row_dot_last xs ys x y : length xs = length ys ->
  row_dot (xs ++ [x]) (ys ++ [y]) = xorb (andb x y) (row_dot xs ys).
Proof.
  revert ys; induction xs as [|a xs IH]; intros [|b ys] H; try discriminate.
  - reflexivity.
  - cbn [app row_dot]. rewrite IH by (injection H; auto).
    destruct (andb a b), (andb x y), (row_dot xs ys); reflexivity.
Qed.

Lemma row_dot_tab n a b : row_dot (tabulate n a) (tabulate n b) = parity n a b.
Proof.
  induction n as [|n IH]; [reflexivity|].
  unfold tabulate in *; rewrite seq_S, !map_app.
  cbn [map Nat.add parity]. rewrite row_dot_last, IH; [reflexivity|now rewrite !map_length].
Qed.

Lemma row_xor_tab n a b : row_xor (tabulate n a) (tabulate n b) = tabulate n (vxor a b).
Proof.
  unfold tabulate. generalize (seq 0 n); intro ix.
  induction ix as [|i is IH]; [reflexivity|].
  cbn [map row_xor]. rewrite IH. reflexivity.
Qed.

Lemma tab_cache n a : tabulate n (cached_vector n a) = tabulate n a.
Proof.
  unfold tabulate at 1 2. apply map_ext_in.
  intros i Hi. unfold cached_vector. apply tabulate_at. apply in_seq in Hi; lia.
Qed.

Lemma filter_image {A B} (f:A->B) p q xs :
  (forall a, p (f a) = q a) -> filter p (map f xs) = map f (filter q xs).
Proof.
  intro E; induction xs as [|x xs IH]; [reflexivity|].
  cbn [map filter]; rewrite E, IH; destruct (q x); reflexivity.
Qed.

Fixpoint bit_detectors n (gs:list (list bool)) : list (list bool) :=
  match gs with
  | [] => map (fun i => tabulate n (unit_vector i)) (seq 0 n)
  | g::tail =>
      let rows := bit_detectors n tail in
      let '(odd,even) := List.partition (fun r => row_dot r g) rows in
      match odd with
      | [] => rows
      | pivot::rest => even ++ map (fun r => row_xor r pivot) rest
      end
  end.

Lemma bit_detectors_correct n gs :
  bit_detectors n (map (tabulate n) gs) = map (tabulate n) (pcm_detectors n gs).
Proof.
  induction gs as [|g gs IH].
  - cbn [bit_detectors pcm_detectors map]; rewrite map_map; reflexivity.
  - cbn [map bit_detectors pcm_detectors]; rewrite IH, partition_filters.
    rewrite (filter_image (tabulate n) _ (fun r => parity n r g)) by (intro; apply row_dot_tab).
    rewrite (filter_image (tabulate n) (fun r => negb (row_dot r (tabulate n g)))
               (fun r => negb (parity n r g))) by (intro; rewrite row_dot_tab; reflexivity).
    unfold restrict_detectors. destruct (filter (fun r => parity n r g) (pcm_detectors n gs)) as [|p rest].
    + reflexivity.
    + cbn [map]. rewrite map_app, !map_map. f_equal. apply map_ext. intro r.
      rewrite row_xor_tab, tab_cache; reflexivity.
Qed.

Definition bit_commute (hs gs:list (list bool)) :=
  forallb (fun g => forallb (fun h => negb (row_dot h g)) hs) gs.
Lemma bit_commute_correct n hs gs :
  bit_commute (map (tabulate n) hs) (map (tabulate n) gs) =
  forallb (fun g => forallb (fun h => negb (parity n h g)) hs) gs.
Proof.
  unfold bit_commute. induction gs as [|g gs IH]; [reflexivity|].
  cbn [map forallb]; rewrite IH; f_equal; clear IH.
  induction hs as [|h hs IH]; [reflexivity|]. cbn [map forallb]; rewrite row_dot_tab, IH; reflexivity.
Qed.

Definition bit_prepare q : option half_model :=
  if raw_shape q then
    let n := Z.to_nat (width q) in
    let rows m bs := map (tabulate n) (sliced_vectors (width q) m bs) in
    let hs := rows (check_count q) (checks q) in
    let gs := rows (same_count q) (same_bytes q) in
    if bit_commute hs gs then
      let ds := match bit_detectors n gs with
                | [] => [tabulate n zero_vector] | rs => rs end in
      let count := Zlength ds in
      if (count <=? 2147483647 / width q)%Z then
        Some {| model_n:=width q; model_m:=check_count q; model_k:=same_count q;
                model_l:=count; model_h:=checks q; model_g:=same_bytes q;
                model_lg:=flat_map (map bitZ) ds |}
      else None
    else None
  else None.

Lemma bit_flat n rs : flat_map (map bitZ) (map (tabulate n) rs) = pcm_flat n rs.
Proof. unfold pcm_flat, pcm_bytes. induction rs as [|r rs IH]; [reflexivity|].
  cbn [flat_map map]; rewrite IH; reflexivity. Qed.

Lemma tabulate_sentinel n rs :
  (match map (tabulate n) rs with [] => [tabulate n zero_vector] | xs => xs end) =
  map (tabulate n) (match rs with [] => [zero_vector] | xs => xs end).
Proof. destruct rs; reflexivity. Qed.

Theorem bit_prepare_correct q : bit_prepare q = prepare_pcm_half q.
Proof.
  unfold bit_prepare, prepare_pcm_half, commute, prepared, detectors,
         same_rows, check_rows, c_detector_rows.
  rewrite !sliced_vectors_correct, bit_commute_correct, bit_detectors_correct.
  rewrite tabulate_sentinel, Zlength_map, bit_flat.
  destruct (pcm_detectors (Z.to_nat (width q)) _); reflexivity.
Qed.
