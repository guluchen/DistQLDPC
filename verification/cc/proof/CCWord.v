(* SPDX-License-Identifier: GPL-3.0-or-later.
   Bridge between unsigned machine arithmetic and mathematical charge bound. *)
From Coq Require Import ZArith Lia.
Require Import compcert.lib.Integers.
Open Scope Z_scope.
Definition ceil_Z a b := a/b + if a mod b =? 0 then 0 else 1.
Lemma ceil_Z_range a b : 0<=a -> 0<b -> 0<=ceil_Z a b<=a.
Proof.
 intros Ha Hb;unfold ceil_Z.
 pose proof (Z.div_mod a b ltac:(lia)) as E.
 pose proof (Z.mod_pos_bound a b Hb) as R.
 assert (Q:0<=a/b) by (apply Z.div_pos;lia).
 destruct (a mod b =? 0) eqn:T.
 - apply Z.eqb_eq in T;rewrite T in E;nia.
 - apply Z.eqb_neq in T;nia.
Qed.
Lemma repr_eq_zero_test r : 0<=r<=Int.max_unsigned ->
 Int.eq (Int.repr r) Int.zero=(r=?0).
Proof.
 intros Hr;destruct (Z.eq_dec r 0) as [->|Hne].
 - rewrite Z.eqb_refl;apply Int.eq_true.
 - assert (T:(r=?0)=false) by (apply Z.eqb_neq;assumption). rewrite T.
   apply Int.eq_false;intro E.
   apply (f_equal Int.unsigned) in E.
   rewrite Int.unsigned_repr in E by exact Hr.
   rewrite Int.unsigned_zero in E;contradiction.
Qed.
Definition machine_ceil (a b:int) :=
 Int.add (Int.divu a b) (if Int.eq (Int.modu a b) Int.zero then Int.zero else Int.one).
Theorem machine_ceil_is_mathematical a b : Int.unsigned b<>0 ->
 Int.unsigned (machine_ceil a b)=ceil_Z (Int.unsigned a) (Int.unsigned b).
Proof.
 intros Hnz.
 pose proof (Int.unsigned_range_2 a) as Ha.
 pose proof (Int.unsigned_range_2 b) as Hb.
 assert (B:0<Int.unsigned b) by lia.
 pose proof (Z.mod_pos_bound (Int.unsigned a) (Int.unsigned b) B) as R.
 assert (RQ:0<=Int.unsigned a/Int.unsigned b<=Int.max_unsigned).
 { split;[apply Z.div_pos;lia|].
   apply Z.div_le_upper_bound;nia. }
 assert (RR:0<=Int.unsigned a mod Int.unsigned b<=Int.max_unsigned) by lia.
 pose proof (ceil_Z_range _ _ (proj1 Ha) B) as C.
 unfold machine_ceil,Int.divu,Int.modu.
 rewrite (repr_eq_zero_test _ RR).
 unfold ceil_Z in *.
 destruct (Int.unsigned a mod Int.unsigned b=?0) eqn:T;
 unfold Int.add;rewrite (Int.unsigned_repr _ RQ).
 - rewrite Int.unsigned_zero;apply Int.unsigned_repr;lia.
 - rewrite Int.unsigned_one;apply Int.unsigned_repr;lia.
Qed.
Print Assumptions machine_ceil_is_mathematical.

Lemma machine_ceil_repr a b : Int.unsigned b<>0 -> machine_ceil a b=Int.repr (ceil_Z (Int.unsigned a) (Int.unsigned b)).
Proof. intros Hb;rewrite <- (machine_ceil_is_mathematical a b Hb). symmetry;apply Int.repr_unsigned. Qed.
Theorem ceil_Z_minimal a b k : 0<=a -> 0<b -> (ceil_Z a b<=k <-> a<=k*b).
Proof. intros Ha Hb;unfold ceil_Z. pose proof (Z.div_mod a b ltac:(lia)) as E. pose proof (Z.mod_pos_bound a b Hb) as R. assert (Q:0<=a/b) by (apply Z.div_pos;lia). destruct (a mod b=?0) eqn:T. - apply Z.eqb_eq in T;rewrite T in E;split;intro H;nia. - apply Z.eqb_neq in T;split;intro H;nia. Qed.
Print Assumptions machine_ceil_repr.
Print Assumptions ceil_Z_minimal.
