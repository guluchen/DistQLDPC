(* SPDX-License-Identifier: GPL-3.0-or-later *)
From mathcomp Require Import all_ssreflect all_algebra.
Require Import LeafMatrix.
Set Implicit Arguments.
Unset Strict Implicit.
Import GRing.Theory.
Local Open Scope ring_scope.

Section Eliminate.
Variables r n:nat.
Variable A:'M['F_2]_(r,n).
Variables (p:'I_r) (q:'I_n).
Hypothesis pivot_one:A p q= 1.

(* The C loop skips the pivot, and XORs its row wherever the column is one. *)
Definition selector:'cV['F_2]_r:=\col_i (if i==p then 0 else A i q).
Definition add_pivot (M:'M['F_2]_(r,n)):=M + selector *m row p M.
Lemma add_pivot_cell M i j:
 add_pivot M i j=M i j+(if i==p then 0 else A i q)*M p j.
Proof. by rewrite /add_pivot !mxE big_ord1 /selector !mxE. Qed.
Lemma pivot_kept M j:add_pivot M p j=M p j.
Proof. by rewrite add_pivot_cell eqxx mul0r addr0. Qed.
Lemma binary_double (v:'F_2):v+v=0.
Proof. by rewrite -[X in v+X=0](oppr_char2 (char_Fp (erefl : prime 2)) v) addrN. Qed.
Lemma binary_unit (v:'F_2): v!=0 -> v= 1.
Proof.
 have alternatives:v=0 \/ v= 1.
 { case:v=> a ha;case:a ha=>[|[|a]] ha;[left|right|];try by apply:val_inj.
   by []. }
 by case:alternatives=>->;rewrite ?eqxx.
Qed.

Theorem cleared_column i:add_pivot A i q=(i==p)%:R.
Proof. rewrite add_pivot_cell pivot_one;case e:(i==p);[move/eqP:e=>->|];by rewrite ?pivot_one ?mul0r ?mulr1 ?addr0 ?binary_double. Qed.
Theorem earlier_pivot_columns j:A p j=0 -> col j (add_pivot A)=col j A.
Proof. move=>off;apply/matrixP=>i k;by rewrite [LHS]mxE [RHS]mxE add_pivot_cell off mulr0 addr0. Qed.

Lemma pivot_operation_involutive M:add_pivot (add_pivot M)=M.
Proof. apply/matrixP=>i j;by rewrite add_pivot_cell pivot_kept add_pivot_cell -addrA binary_double addr0. Qed.
Lemma operations_stay_in_span M:(add_pivot M<=M)%MS.
Proof.
 apply/submxP;exists (1%:M + selector *m delta_mx 0 p).
 by rewrite mulmxDl mul1mx -mulmxA -rowE.
Qed.
Theorem pivot_operation_preserves_span:(add_pivot A<=A)%MS /\ (A<=add_pivot A)%MS.
Proof. split;first exact:operations_stay_in_span.
 by rewrite -{1}(pivot_operation_involutive A);apply:operations_stay_in_span. Qed.

Definition visit_row (M:'M['F_2]_(r,n)) (i:'I_r):'M['F_2]_(r,n):=
 \matrix_(u,j) if [&& u==i, i!=p & M i q!=0] then M u j+M p j else M u j.
Definition after_rows (visited:seq 'I_r):'M['F_2]_(r,n):=
 \matrix_(i,j) if i \in visited then add_pivot A i j else A i j.
Lemma after_cell visited i j:
 after_rows visited i j=if i \in visited then add_pivot A i j else A i j.
Proof. by rewrite /after_rows mxE. Qed.
Lemma after_no_rows:after_rows [::]=A.
Proof. by apply/matrixP=>i j;rewrite /after_rows mxE in_nil. Qed.
Lemma after_keeps_pivot visited j:after_rows visited p j=A p j.
Proof. rewrite /after_rows mxE pivot_kept;by case:(p \in visited). Qed.
Lemma advance_row processed i: i \notin processed ->
 visit_row (after_rows processed) i=after_rows (i::processed).
Proof.
 move=>fresh;have absent:=negbTE fresh.
 apply/matrixP=>u j;rewrite /visit_row mxE after_keeps_pivot !after_cell absent in_cons.
 case same:(u==i);last by rewrite /=.
 move/eqP:same=>->;rewrite absent /= add_pivot_cell.
 case is_p:(i==p);first by rewrite /= mul0r addr0.
 case hit:(A i q!=0);rewrite /=.
 - by rewrite (binary_unit hit) mul1r.
 - have off:A i q=0 by move:hit;case: eqP=> //.
   by rewrite off mul0r addr0.
Qed.
Lemma visit_fresh_rows order processed:uniq (order++processed) ->
 foldl visit_row (after_rows processed) order=after_rows (rev order++processed).
Proof.
 elim:order processed=>[|i rest ih] processed;first by [].
 move=>/= /andP[fresh clean].
 have away:i \notin processed by move:fresh;rewrite mem_cat negb_or=>/andP[].
 rewrite advance_row //.
 have per:perm_eq (rest++[::i]++processed) ([::i]++rest++processed) by rewrite perm_catCA.
 have reorder:uniq (rest++i::processed) by rewrite (perm_uniq per) /= fresh clean.
 rewrite ih // rev_cons -cats1 -catA;by [].
Qed.
Theorem native_row_visits_clear_the_pivot:
 foldl visit_row A (enum 'I_r)=add_pivot A.
Proof.
 rewrite -{1}after_no_rows (visit_fresh_rows _).
 - apply/matrixP=>i j;by rewrite /after_rows mxE cats0 mem_rev mem_enum.
 - by rewrite cats0 enum_uniq.
Qed.
End Eliminate.
