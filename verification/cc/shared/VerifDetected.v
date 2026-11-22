(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto.
Require Import level_ast.

#[export] Instance CompSpecs : compspecs. make_compspecs prog. Defined.
Definition Vprog : varspecs. mk_varspecs prog. Defined.
Definition level_type := Tstruct _cc_level noattr.

Definition parity_union (words : list int64) :=
  fold_right Int64.or Int64.zero words.

Lemma parity_union_snoc words word :
  parity_union (words ++ [word]) = Int64.or (parity_union words) word.
Proof.
  induction words as [|head tail IH].
  - simpl. rewrite Int64.or_zero, Int64.or_zero_l. reflexivity.
  - change (Int64.or head (parity_union (tail ++ [word])) = Int64.or (Int64.or head (parity_union tail)) word).
    rewrite IH, Int64.or_assoc. reflexivity.
Qed.

Lemma parity_union_zero words :
  parity_union words = Int64.zero <-> Forall (eq Int64.zero) words.
Proof.
  induction words as [|head tail IH].
  - split; auto.
  - change (Int64.or head (parity_union tail) = Int64.zero <-> Forall (eq Int64.zero) (head :: tail)).
    split.
    + intro H. pose proof (Int64.and_or_absorb head (parity_union tail)) as E.
      rewrite H, Int64.and_zero in E. subst head.
      rewrite Int64.or_zero_l in H. constructor; [reflexivity | apply IH; exact H].
    + intro H. inversion H; subst. rewrite Int64.or_zero_l. now apply IH.
Qed.

Definition detected_value words :=
  Vint (if Int64.eq (parity_union words) Int64.zero then Int.zero else Int.one).

Lemma detected_value_correct words :
  (Forall (eq Int64.zero) words /\ detected_value words = Vint Int.zero) \/
  (~ Forall (eq Int64.zero) words /\ detected_value words = Vint Int.one).
Proof.
  unfold detected_value. pose proof (Int64.eq_spec (parity_union words) Int64.zero) as E.
  destruct (Int64.eq (parity_union words) Int64.zero).
  - left. split; [now apply parity_union_zero | reflexivity].
  - right. split; [intro H; apply E; now apply parity_union_zero | reflexivity].
Qed.

(* An empty C++ vector may supply a null data pointer. For zero words the
   routine does not dereference it, so the contract needs no array storage. *)
Definition parity_storage sh (words : list int64) (p : val) :=
  match words with
  | [] => emp
  | _ :: _ => data_at sh (tarray tulong (Zlength words)) (map Vlong words) p
  end.

Lemma parity_storage_nonempty sh words p :
  0 < Zlength words ->
  parity_storage sh words p =
    data_at sh (tarray tulong (Zlength words)) (map Vlong words) p.
Proof. destruct words; [rewrite Zlength_nil; lia | reflexivity]. Qed.

(* Only the two struct fields and the borrowed parity array are read. Other
   fields and caller-owned storage can be carried through with the frame rule. *)
Definition detected_spec : ident * funspec :=
 DECLARE _detected
 WITH s : val, parity : val, words : list int64, sh : share
 PRE [tptr level_type]
   PROP (readable_share sh; Zlength words <= Int.max_signed)
   PARAMS (s)
   SEP (field_at sh level_type [StructField _kw] (Vint (Int.repr (Zlength words))) s;
        field_at sh level_type [StructField _gpar] parity s;
        parity_storage sh words parity)
 POST [tint]
   PROP () RETURN (detected_value words)
   SEP (field_at sh level_type [StructField _kw] (Vint (Int.repr (Zlength words))) s;
        field_at sh level_type [StructField _gpar] parity s;
        parity_storage sh words parity).

Definition Gprog : funspecs := ltac:(with_library prog [detected_spec]).

Lemma registered_detected : In (_detected, Gfun (Internal f_detected)) (prog_defs prog).
Proof. repeat (first [left; reflexivity | right]). Qed.

Theorem body_detected : semax_body Vprog Gprog f_detected detected_spec.
Proof.
  start_function. forward. forward.
  forward_loop
    (EX i : Z, PROP (0 <= i <= Zlength words)
     LOCAL (temp _s s; temp _i (Vint (Int.repr i));
            temp _acc (Vlong (parity_union (sublist 0 i words))))
     SEP (field_at sh level_type [StructField _kw] (Vint (Int.repr (Zlength words))) s;
          field_at sh level_type [StructField _gpar] parity s;
          parity_storage sh words parity))%assert
  break:
    (PROP () LOCAL (temp _acc (Vlong (parity_union words)))
     SEP (field_at sh level_type [StructField _kw] (Vint (Int.repr (Zlength words))) s;
          field_at sh level_type [StructField _gpar] parity s;
          parity_storage sh words parity))%assert.
  - Exists 0. entailer!.
  - Intros i. forward. forward_if.
    + rewrite parity_storage_nonempty by lia.
      forward. forward. forward. forward.
      Exists (i+1). try rewrite parity_storage_nonempty by lia. entailer!.
      rewrite (sublist_split 0 i (i+1)) by lia.
      rewrite (sublist_one i) by lia. now rewrite parity_union_snoc.
    + assert (i = Zlength words) by lia. subst i.
      forward. entailer!; autorewrite with sublist; reflexivity.
  - forward. entailer!. unfold detected_value.
    fold Int64.zero. destruct (Int64.eq (parity_union words) Int64.zero); reflexivity.
Qed.

Print Assumptions body_detected.
