(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.zlist.list_solver.
Require Import VerifClosesBody VerifToggleBody SparseFlipBits ClosureWord.

Fixpoint toggled_row (j : Z) (rs : list int) : bool :=
  match rs with
  | nil => false
  | r :: tail => xorb (Z.eqb j (Int.unsigned r)) (toggled_row j tail)
  end.

Lemma step_storage_length syn odd r :
  Zlength (fst (sparse_flip (syn,odd) r)) = Zlength syn.
Proof.
  unfold sparse_flip; cbn [fst].
  destruct (Z_lt_dec (word_index r) (Zlength syn)).
  - apply upd_Znth_Zlength. split; [apply Int.unsigned_range | assumption].
  - rewrite upd_Znth_out_of_range by lia. reflexivity.
Qed.

Lemma walk_length rs st :
  Zlength (fst (fold_left sparse_flip rs st)) = Zlength (fst st).
Proof.
  revert st; induction rs as [|r rs IH]; intros [syn odd]; [reflexivity|].
  cbn [fold_left]. rewrite IH. apply step_storage_length.
Qed.

Lemma walk_bit rs syn odd j :
  0 <= j < 64 * Zlength syn ->
  Forall (fun r => Int.unsigned r < 64 * Zlength syn) rs ->
  syndrome_bit (fst (fold_left sparse_flip rs (syn,odd))) j =
  xorb (toggled_row j rs) (syndrome_bit syn j).
Proof.
  revert syn odd; induction rs as [|r rs IH]; intros syn odd J located.
  - cbn [toggled_row fold_left fst]; destruct (syndrome_bit syn j); reflexivity.
  - inversion located as [|a tail inside next]; subst.
    cbn [fold_left toggled_row]. destruct (sparse_flip (syn,odd) r) as [syn' odd'] eqn:one.
    pose proof (step_storage_length syn odd r) as len; rewrite one in len; cbn [fst] in len.
    rewrite IH by (rewrite len; assumption).
    pose proof (sparse_flip_bits syn odd r j J inside) as bit; rewrite one in bit; cbn [fst] in bit.
    rewrite bit. destruct (Z.eq_dec j (Int.unsigned r)) as [equal|unequal].
    + rewrite (proj2 (Z.eqb_eq _ _) equal).
      destruct (toggled_row j rs), (syndrome_bit syn j); reflexivity.
    + rewrite (proj2 (Z.eqb_neq _ _) unequal).
      destruct (toggled_row j rs), (syndrome_bit syn j); reflexivity.
Qed.

(* Restoration includes spare bits in the final word. The C traversal
   rolls back in the same CSR order, including any repeated entries. *)
Theorem sparse_words_restore rs syn odd :
  Forall (fun r => Int.unsigned r < 64 * Zlength syn) rs ->
  fst (fold_left sparse_flip rs (fold_left sparse_flip rs (syn,odd))) = syn.
Proof.
  intros inside. destruct (fold_left sparse_flip rs (syn,odd)) as [syn' odd'] eqn:pass.
  pose proof (walk_length rs (syn,odd)) as len; rewrite pass in len; cbn [fst] in len.
  apply Znth_eq_ext.
  - rewrite walk_length; exact len.
  - intros w W. rewrite walk_length in W; cbn [fst] in W.
    apply Int64.same_bits_eq. intros j J. change (0<=j<64) in J.
    set (row := 64*w+j).
    assert (address : row / 64 = w).
    { unfold row; symmetry; apply Z.div_unique with (r:=j); [left;lia|ring]. }
    assert (bitpos : row mod 64 = j).
    { unfold row; symmetry; apply Z.mod_unique with (q:=w); [left;lia|ring]. }
    assert (R: 0<=row<64*Zlength syn) by (unfold row;lia).
    (* Each array word is determined by its 64 bit addresses. *)
    replace w with (row / 64) by exact address; replace j with (row mod 64) by exact bitpos.
    change (syndrome_bit (fst (fold_left sparse_flip rs (syn',odd'))) row = syndrome_bit syn row).
    rewrite walk_bit by (rewrite len;assumption).
    pose proof (walk_bit rs syn odd row R inside) as first; rewrite pass in first; cbn [fst] in first.
    rewrite first. destruct (toggled_row row rs), (syndrome_bit syn row); reflexivity.
Qed.
