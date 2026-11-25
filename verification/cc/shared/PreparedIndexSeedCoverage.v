(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto.
From mathcomp Require Import all_ssreflect all_algebra.
Require Import VerifSeedIndex PreparedPlainReachable PreparedChildPrefix PreparedInteriorReport PreparedPCMLeafVisit
 PreparedMatrixPath OverlapColumnState LeafMatrix MinimumPrefix LevelSearch.
Set Implicit Arguments.
Unset Strict Implicit.
Local Open Scope ring_scope.
Local Delimit Scope Z_scope with coqZ.

Section Seeds.
Variables m n r k:nat.
Variables (H:'M['F_2]_(m,n)) (S:'M['F_2]_(r,n)) (G:'M['F_2]_(k,n)).
Variables (st:'I_n->snapshot) (path:'I_n->seq Integers.int).
Hypotheses (fit:(Z.of_nat n<=Int.max_signed)%coqZ)
 (blocks:forall q:'I_n,blocked (st q)=seen (Z.of_nat n) (Z.of_nat q+1)%coqZ).
Let eligible:=fun (_:seq Integers.int) (_:'cV['F_2]_n)=>True.

(* At seed q the C loop has excluded every smaller address. Choose the
   least physical address in a minimum target to expose its unique seed. *)
Theorem exhausted_index_seeds_exclude_a_minimum w:
 (forall q:'I_n,recursive_result H S G eligible w (st q) (literal_path [::q]) 0%coqZ (path q)) ->
 forall x,minimum H G x -> Z.of_nat #|LeafMatrix.support x|<>w.
Proof.
 move=>all_empty x best weight.
 have /set0Pn[q0 initial]:=logical_nonempty (proj1 best).
 case: (@arg_minnP _ q0 (mem (LeafMatrix.support x)) (@nat_of_ord n) initial)=>q present least.
 have no:=proj1 (all_empty q).
 apply:(no x I best weight _ _ Logic.eq_refl).
 - rewrite literal_prefix_set //;apply/subsetP=>j;rewrite inE in_cons in_nil orbF=>/eqP->;exact present.
 - rewrite literal_prefix_set //;apply/subsetP=>j.
   rewrite !inE=>/andP[not_q member].
   have inside:j \in LeafMatrix.support x by rewrite /LeafMatrix.support inE.
   have smaller:=least j inside.
   have diff:j!=q by exact not_q.
   have distinct:val j!=val q by rewrite (inj_eq val_inj).
   have past:(q<j)%N by rewrite ltn_neqAle eq_sym distinct smaller.
   have bounded:=elimT ltP (ltn_ord j);have qbound:=elimT ltP (ltn_ord q);have ordered:=elimT ltP past.
   rewrite blocks seen_cell;try lia.
   case:Z_lt_dec=>[bad|_];[lia|reflexivity].
Qed.
End Seeds.
