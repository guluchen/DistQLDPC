(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.zlist.list_solver.
From Coq Require Import List Lia.
Import ListNotations.

Definition adjust (delta:Z) (base:list int) (q:Z) :=
  upd_Znth q base (Int.add (Znth q base) (Int.repr delta)).
Definition sweep delta (xs:list Z) (base:list int) := fold_left (adjust delta) xs base.
Definition in_array n (xs:list Z) := Forall (fun q=>0<=q<n) xs.
Definition visits (xs:list Z) q := Z.of_nat (count_occ Z.eq_dec xs q).

Lemma add_encoded a b : Int.add (Int.repr a) (Int.repr b)=Int.repr (a+b).
Proof.
  unfold Int.add;apply Int.eqm_samerepr;apply Int.eqm_add;
    apply Int.eqm_sym;apply Int.eqm_unsigned_repr.
Qed.
Lemma decrement_word x : Int.sub x Int.one=Int.add x (Int.repr (-1)).
Proof. rewrite Int.sub_add_opp;reflexivity. Qed.
Lemma sweep_size delta xs base : in_array (Zlength base) xs ->
  Zlength (sweep delta xs base)=Zlength base.
Proof.
  revert base;induction xs as [|x xs IH];intros base range;[reflexivity|].
  inversion range;subst. cbn [sweep fold_left];fold (sweep delta xs (adjust delta base x)).
  unfold adjust;rewrite IH,upd_Znth_Zlength by (rewrite ?upd_Znth_Zlength;assumption);reflexivity.
Qed.
Lemma sweep_cell delta xs base q : in_array (Zlength base) xs -> 0<=q<Zlength base ->
  Znth q (sweep delta xs base)=Int.add (Znth q base) (Int.repr (delta*visits xs q)).
Proof.
  revert base;induction xs as [|x xs IH];intros base range valid.
  - change (Znth q base=Int.add (Znth q base) (Int.repr (delta*0))).
    rewrite Z.mul_0_r,Int.add_zero;reflexivity.
  - inversion range as [|? ? within tail];subst.
    change (Znth q (sweep delta xs (adjust delta base x)) =
            Int.add (Znth q base) (Int.repr (delta*visits (x::xs) q))).
    assert (len:Zlength (adjust delta base x)=Zlength base) by (unfold adjust;apply upd_Znth_Zlength;exact within).
    rewrite IH by (rewrite len;assumption). unfold adjust,visits;cbn [count_occ].
    destruct (Z.eq_dec x q) as [->|diff].
    + rewrite upd_Znth_same,Int.add_assoc,add_encoded,Nat2Z.inj_succ by assumption.
      f_equal;f_equal;ring.
    + rewrite upd_Znth_diff by lia;reflexivity.
Qed.

(* dfs undoes earlier sibling exclusions in their original order. The
   equation includes inherited counts and even repeated labels. *)
Theorem rollback_siblings xs base : in_array (Zlength base) xs ->
  sweep (-1) xs (sweep 1 xs base)=base.
Proof.
  intro range. pose proof (sweep_size 1 xs base range) as len.
  assert (outer:in_array (Zlength (sweep 1 xs base)) xs) by (rewrite len;assumption).
  apply Znth_eq_ext.
  - rewrite sweep_size by assumption;exact len.
  - intros q valid. rewrite sweep_size,len in valid by assumption.
    rewrite !sweep_cell by (rewrite ?len;assumption).
    rewrite Int.add_assoc,add_encoded. replace (1*visits xs q + -1*visits xs q) with 0 by ring.
    apply Int.add_zero.
Qed.

Lemma cancel_child base q : 0<=q<Zlength base ->
  adjust (-1) (adjust 1 base q) q=base.
Proof. intro valid;apply (@rollback_siblings [q] base);constructor;[exact valid|constructor]. Qed.
