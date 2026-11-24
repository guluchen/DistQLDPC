(* SPDX-License-Identifier: GPL-3.0-or-later *)
From Coq Require Import ZArith Lia.
From mathcomp Require Import all_ssreflect all_algebra.
Require Import LeafMatrix LevelSearch MinimumPrefix ColumnParityPCM CSSSearchSchedule CertifiedSchedule.
Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.
Local Open Scope ring_scope.
Local Delimit Scope Z_scope with coqZ.

Definition machine_next (w:Z) (even_only:bool) :=
 if (even_only && Z.testbit (w+1) 0)%bool then (w+2)%coqZ else (w+1)%coqZ.
Definition next_level (w:nat) (even_only:bool) :=
 if even_only && odd w.+1 then w.+2 else w.+1.
Lemma nat_low_bit (w:nat):Z.testbit (Z.of_nat w) 0=odd w.
Proof.
rewrite Z.bit0_odd;elim:w=>[|n IH] //=.
change (Z.odd (Z.of_nat n.+1)=~~odd n);rewrite Nat2Z.inj_succ Z.odd_succ -Z.negb_odd;by rewrite IH.
Qed.
Lemma next_encoding (w:nat) even_only:machine_next (Z.of_nat w) even_only=Z.of_nat (next_level w even_only).
Proof.
rewrite /machine_next /next_level.
replace (Z.of_nat w+1)%coqZ with (Z.of_nat w.+1) by (rewrite Nat2Z.inj_succ;lia).
rewrite nat_low_bit;case:(even_only && odd w.+1)=> //;rewrite !Nat2Z.inj_succ;lia.
Qed.

Section Half.
Variables m n k:nat.
Variables (H:'M['F_2]_(m,n)) (L:'M['F_2]_(k,n)).
Let d:=distance_index H L.
Theorem justified_next w (even_only:bool) :
 (w<=d)%N -> w!=d -> (d<=n)%N ->
 (even_only -> forall q,odd #|support (col q H)|) ->
 (next_level w even_only<=d)%N.
Proof.
move=> lower refuted finite odd_cols.
have step:(w.+1<=d)%N by rewrite ltn_neqAle refuted lower.
rewrite /next_level;case E:(even_only && odd w.+1)=> //.
move/andP:E=> [enabled skipped];rewrite ltn_neqAle step andbT.
apply/eqP=> same;have room:(w.+1<=n)%N:=leq_trans step finite.
have impossible:=@parity_skip_excludes m n k H L w.+1 room (odd_cols enabled) skipped.
by move:impossible;rewrite same eqxx.
Qed.
End Half.

(* A hit in the selected half is an exact mixed distance only after the
   other half has reached that weight, or has no logical operator. *)
Lemma close_with_other w other lower :
 (lower<=other)%N -> (w<=lower)%N -> minn w other=w.
Proof. move=> valid stop;apply/minn_idPl;exact:leq_trans stop valid. Qed.
Lemma close_with_absent w n:(w<=n)%N -> minn w n.+1=w.
Proof. move=> cap;apply/minn_idPl;exact:leq_trans cap (leqnSn n). Qed.
Lemma clip_halves dx dz lx lz : (lx<=dx)%N -> (lz<=dz)%N -> (minn lx lz<=minn dx dz)%N.
Proof. move=> x z;rewrite leq_min;apply/andP;split;[exact:leq_trans (geq_minl _ _) x|exact:leq_trans (geq_minr _ _) z]. Qed.
