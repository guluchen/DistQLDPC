(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto.
From mathcomp Require Import all_ssreflect all_algebra.
Require Import LeafMatrix MinimumPrefix LevelSearch PreparedLeafReport PreparedInteriorReport
 PreparedBudgetContract PreparedChildPrefix PreparedPCMLeafVisit PreparedFastCoverage PreparedObservedWitness
 PreparedRecursiveCall PreparedMatrixPath OverlapColumnState.
Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.
Local Open Scope ring_scope.
Local Delimit Scope Z_scope with coqZ.

Section Child.
Variables m n r k:nat.
Variables (H:'M['F_2]_(m,n)) (S:'M['F_2]_(r,n)) (G:'M['F_2]_(k,n))
 (qualified:seq Integers.int->'cV['F_2]_n->Prop).
Theorem one_move_report_at_registered_weight (ids:seq 'I_n) g st node code tail w:
 (Z.of_nat n<=Int.max_signed)%coqZ -> uniq ids -> node=literal_path ids ->
 (0<Z.of_nat (size ids))%coqZ -> w=(Z.of_nat (size ids)+1)%coqZ ->
 leaf_report H S G w g st node code tail -> recursive_result H S G qualified w st node code tail.
Proof.
 move=>fits unique -> positive -> [hits [_ witness]];split.
 - move=>x _ best weight sub free.
   have count:#|@prefix_set n (literal_path ids)|=size ids by rewrite literal_prefix_set // cardsE (card_uniqP unique).
   apply:(hits x best _ _ sub free).
   + rewrite count;apply Nat2Z.inj;rewrite Nat2Z.inj_succ;lia.
   + apply/negP=> /eqP empty;rewrite empty cards0 in count;lia.
 - split=>found;subst code.
   + apply:(witness _);by left.
   + exists (Z.of_nat (size ids));split;first lia.
     have ok:witness_status 3%coqZ by right.
     move:(witness ok);unfold reported_len;replace (Z.of_nat (size ids)+1-1)%coqZ with (Z.of_nat (size ids)) by lia.
     by case:Z.eq_dec=>//.
Qed.
End Child.
