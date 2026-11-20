(* Compile row/column incidence from the same checked half model used by C. *)
From Coq Require Import List Bool Arith Lia Uint63.
Require Import CCV.CCModel CCV.CCFunctional CCV.CCPCMDetectors CCV.CCPackedWords
 CCV.CCPackedBranch CCV.CCPackedRefute.
Import ListNotations. Local Open Scope nat_scope.

Lemma decode_out a i : 189<=i -> decode a i=false.
Proof. intro I;unfold decode;destruct (Nat.ltb_spec0 i 63),(Nat.ltb_spec0 i 126),(Nat.ltb_spec0 i 189);try lia;reflexivity. Qed.
Lemma singleton_at i j : i<189 -> decode (singleton i) j=Nat.eqb i j.
Proof.
  intro I; destruct (lt_dec j 189);[apply singleton_bit;assumption|].
  rewrite decode_out by lia;symmetry;apply Nat.eqb_neq;lia.
Qed.
Fixpoint encode_from start xs : bits :=
  match xs with
  | []=>none
  | true::more=>join (singleton start) (encode_from (S start) more)
  | false::more=>encode_from (S start) more
  end.
Lemma encode_index start xs j : start+length xs<=189 ->
  decode (encode_from start xs) j=if j <? start then false else nth (j-start) xs false.
Proof.
  revert start;induction xs as [|x xs IH];intros start B.
  - cbn [encode_from];rewrite decode_none;destruct (j<?start);[reflexivity|]. now destruct (j-start).
  - cbn [length] in B. destruct x;cbn [encode_from];rewrite ?decode_join,?singleton_at,IH by lia;
      destruct (Nat.ltb_spec0 j start), (Nat.ltb_spec0 j (S start)), (Nat.eqb_spec start j);
      subst;try lia;try rewrite Nat.sub_diag;try reflexivity;
      replace (j-start) with (S (j-S start)) by lia;reflexivity.
Qed.
Definition encode xs := encode_from 0 xs.
Lemma encode_nth xs i : length xs<=189 -> decode (encode xs) i=nth i xs false.
Proof. intro B;unfold encode;rewrite encode_index by lia;rewrite Nat.sub_0_r. destruct (Nat.ltb_spec0 i 0);[lia|reflexivity]. Qed.

Definition pack_column (rows:list vector) q := encode (map (fun r=>r q) rows).
Lemma pack_column_ok rows q : length rows<=189 ->column_signature rows q (pack_column rows q).
Proof.
  intros B i;unfold pack_column;rewrite encode_nth by (rewrite map_length;exact B).
  change false with (zero_vector q). rewrite (map_nth (fun r:vector=>r q)); reflexivity.
Qed.
Definition columns n hs ls :=
  map (fun q=>col q (singleton q) (pack_column hs q) (pack_column ls q)) (seq 0 n).
Lemma columns_positions n hs ls : map position (columns n hs ls)=seq 0 n.
Proof. unfold columns;rewrite map_map;apply map_id. Qed.
Lemma columns_valid n hs ls : n<=189 -> length hs<=189 ->length ls<=189 ->
  Forall (col_ok n hs ls) (columns n hs ls).
Proof.
  intros N H L;apply Forall_forall;intros c InC;apply in_map_iff in InC as [q [<- I]];apply in_seq in I.
  unfold col_ok;cbn [position mark check_delta logical_delta];repeat split;try lia;try (apply pack_column_ok;assumption).
  intros i J;rewrite singleton_at by lia;apply Nat.eqb_sym.
Qed.

Definition make_row n cs (h:vector) :=
  prow (encode (tabulate n h)) (filter (fun c=>h (position c)) cs).
Definition compiled_rows n hs ls := map (make_row n (columns n hs ls)) hs.
Definition bad_row := prow none [].
Lemma compile_layout n hs ls : n<=189 -> length hs<=189 ->length ls<=189 ->
  layout n hs ls (fun i=>nth i (compiled_rows n hs ls) bad_row).
Proof.
  intros N H L i I;unfold compiled_rows.
  rewrite (nth_indep _ bad_row (make_row n (columns n hs ls) zero_vector)) by (rewrite map_length;exact I).
  rewrite map_nth;split.
  - intros q Q;cbn [make_row support_mask];rewrite encode_nth by (unfold tabulate;rewrite map_length,seq_length;lia).
    apply tabulate_at;assumption.
  - cbn [make_row neighbors];split.
    + apply Forall_forall;intros c InC;apply filter_In in InC as [InC _].
      apply (proj1 (Forall_forall _ _) (columns_valid _ _ _ N H L));assumption.
    + intros q Q Bit. unfold columns.
      exists (col q (singleton q) (pack_column hs q) (pack_column ls q));split;[|reflexivity].
      apply filter_In;split;[apply in_map_iff;exists q;split;[reflexivity|apply in_seq;lia]|exact Bit].
Qed.
