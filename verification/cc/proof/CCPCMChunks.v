(* Stream the row-major PCM with a single advancing cursor. *)
Require Import VST.floyd.proofauto.
Require Import CCV.CCRows.
Import ListNotations.
Local Open Scope nat_scope.

Fixpoint row_chunks {A} (n m : nat) (flat : list A) : list (list A) :=
  match m with
  | O => []
  | S k => firstn n flat :: row_chunks n k (skipn n flat)
  end.

Lemma chunks_at {A} n m start (flat : list A) :
  row_chunks n m (skipn (start*n) flat) =
  map (fun i => firstn n (skipn (i*n) flat)) (seq start m).
Proof.
  revert start; induction m as [|m IH]; intro start; [reflexivity|].
  cbn [row_chunks seq map]. rewrite List.skipn_skipn.
  change (n + start*n) with (S start * n). rewrite IH; reflexivity.
Qed.

Lemma row_slice n i (flat : list Z) :
  matrix_row (Z.of_nat n) (Z.of_nat i) flat = firstn n (skipn (i*n) flat).
Proof.
  unfold matrix_row, sublist. rewrite <- Nat2Z.inj_mul.
  replace ((Z.of_nat i + 1) * Z.of_nat n)%Z with (Z.of_nat (S i*n)) by lia.
  rewrite !Nat2Z.id, List.skipn_firstn_comm.
  replace (S i*n-i*n) with n by lia. reflexivity.
Qed.

Lemma chunks_matrix_rows n m flat :
  row_chunks (Z.to_nat n) m flat = map (fun i => matrix_row n (Z.of_nat i) flat) (seq 0 m).
Proof.
  pose proof (chunks_at (Z.to_nat n) m 0 flat) as Eq.
  cbn [Nat.mul skipn] in Eq. rewrite Eq; apply map_ext; intro i.
  destruct (Z_le_dec 0 n) as [N|N].
  - replace n with (Z.of_nat (Z.to_nat n)) at 3 by lia.
    symmetry; apply row_slice.
  - unfold matrix_row, sublist.
    replace (Z.to_nat ((Z.of_nat i + 1) * n)) with 0 by nia.
    replace (Z.to_nat n) with 0 by lia. cbn [firstn].
    rewrite List.skipn_nil; reflexivity.
Qed.
