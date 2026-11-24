(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto.
From mathcomp Require Import all_ssreflect all_algebra.
Require Import OverlapRowState OverlapColumnState OverlapRollback OverlapChildState
 OverlapTargetProgress EffectiveRowTarget.
Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.
Local Delimit Scope Z_scope with coqZ.
Local Open Scope ring_scope.

Lemma tight_after_push (word:Integers.int):
 Int.eq (Int.sub word Int.one) Int.zero=true -> Int.signed word = 1%coqZ.
Proof.
move=> result;apply Int.same_if_eq in result.
have restored:=f_equal (fun v=>Int.add v Int.one) result.
rewrite Int.sub_add_opp Int.add_assoc in restored.
rewrite (Int.add_commut (Int.neg Int.one) Int.one) Int.add_neg_zero in restored.
rewrite Int.add_zero Int.add_zero_l in restored.
by rewrite restored.
Qed.

Section Column.
Variable n:nat.
Variables (P T:{set 'I_n}) (chosen:'I_n) (g:layout) (st:snapshot).
Variables (row_set:Integers.int->{set 'I_n}) (limit:Integers.int->nat).
Let zq:=Z.of_nat chosen.
Let rows:=entries g zq.
Definition row_words r :=
 sublist (offset (row_offsets g) (row_number r)) (offset (row_offsets g) (row_number r+1)%coqZ)
         (row_qubits g).
Hypotheses (fresh:chosen \notin P) (enclosed:chosen |: P \subset T).
(* These are properties of the CSR representation and signed slack before
   the push. The exempt-qubit sentinel and a per-row exemption share this
   interface because the machine skips exactly the exempt entry. *)
Hypothesis column_incidence:forall r, In r rows ->
 Int.eq (exempt_for g (row_number r)) (Int.repr zq)=false -> chosen \in row_set r.
Hypothesis row_incidence:forall r (a:'I_n),In r rows ->
 In (Z.of_nat a) (effective (exempt_for g (row_number r)) (row_words r)) -> a \in row_set r.
Hypothesis slack_rep:forall r,In r rows ->
 Int.signed (Znth (row_number r) (slack st)) =
 (Z.of_nat (limit r) - Z.of_nat #|P :&: row_set r|)%coqZ.
Hypothesis target_cap:forall r,In r rows -> (#|T :&: row_set r|<=limit r)%N.

Theorem no_future_target_in_native_hits a :
 a \in T -> a \notin (chosen |: P) -> ~ In (Z.of_nat a) (new_blocks g zq st).
Proof.
move=> inside later used;apply in_flat_map in used as [r [indexed hit]].
change (In r rows) in indexed.
unfold hits in hit.
case skipped:(Int.eq (exempt_for g (row_number r)) (Int.repr zq))=> [|] in hit;first exact:hit.
case zero:(Int.eq (Int.sub (Znth (row_number r) (slack st)) Int.one) Int.zero)=> [|] in hit;last exact:hit.
have active:=column_incidence indexed skipped.
have query_in:=row_incidence indexed hit.
have full : #|(chosen |: P) :&: row_set r|=limit r.
  have only : [set chosen] :&: row_set r = [set chosen] by apply/setIidPl;rewrite sub1set.
  rewrite setIUl only cardsU1 !inE (negbTE fresh) /=.
  have one:=tight_after_push zero;rewrite (slack_rep indexed) in one.
  change (S #|P :&: row_set r|=limit r);apply Nat2Z.inj;rewrite Nat2Z.inj_succ;lia.
have away:=@saturated_row _ (chosen |: P) T (row_set r) (limit r)
  enclosed full (target_cap indexed) a inside later.
by move:away;rewrite query_in.
Qed.
End Column.
