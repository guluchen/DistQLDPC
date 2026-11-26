(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto.
From mathcomp Require Import all_ssreflect all_algebra.
Require Import LeafMatrix LevelSearch PreparedMatrixPath PreparedChildPrefix PreparedDepthSpec PreparedObservedWitness.
Set Implicit Arguments.
Unset Strict Implicit.
Local Open Scope ring_scope.
Local Delimit Scope Z_scope with coqZ.

Section Physical.
Variable n:nat.
Hypothesis fits:(Z.of_nat n<=Int.max_signed)%coqZ.
Let addr (q:'I_n):=Int.repr (Z.of_nat q).
Lemma distinct_encoding:injective addr.
Proof.
 move=>q j equal;have qn:=elimT ltP (ltn_ord q);have jn:=elimT ltP (ltn_ord j).
 have signed:=f_equal Int.signed equal;unfold addr in signed;rewrite !Int.signed_repr in signed;try rep_lia.
 apply:val_inj;exact:(Nat2Z.inj _ _ signed).
Qed.
Lemma matching_address i q:Int.eq (addr i) (addr q)=(i==q).
Proof.
 case same:(i==q);first by move/eqP:same=>->;rewrite Int.eq_true.
 apply/negbTE/negP=>equal;have bad: i=q by apply:distinct_encoding;exact:(Int.same_if_eq _ _ equal).
 by rewrite bad eqxx in same.
Qed.

(* A repeated or out-of-range C word contributes no new physical qubit
   to the support. Reaching full cardinality rules out either case. *)
Theorem full_cardinality_path words:
 (#|@prefix_set n words|<=size words)%N /\
 (#|@prefix_set n words|=size words ->
  exists ids:seq 'I_n,uniq ids /\ literal_path ids=words).
Proof.
 elim:words=>[|head tail [bound decode]].
 - have empty:@prefix_set n [::]=set0 by apply/setP=>i;rewrite /prefix_set !inE.
   rewrite empty cards0;split=>// _;by exists [::].
 - case has:[pick q:'I_n | Int.eq (addr q) head] => [q|].
   + have matchq:Int.eq (addr q) head by move:has;case:pickP=>[j test [<-]|absent].
     have head_value:=Int.same_if_eq _ _ matchq.
     have added:@prefix_set n (head::tail)=q |: @prefix_set n tail.
     { apply/setP=>i;rewrite /prefix_set !inE /= -head_value;fold (addr i);by rewrite matching_address. }
     rewrite added cardsU1 /=;case inside:(q \in @prefix_set n tail) => /=;rewrite ?add0n ?add1n.
     * split;first exact:(leq_trans bound (leqnSn _)).
       by move=>same;move:bound;rewrite same ltnn.
     * split;first exact bound.
       move=>/succn_inj eqsize;have [ids [unique same]]:=decode eqsize.
       exists (q::ids);split;last by change (addr q :: literal_path ids=head :: tail);rewrite head_value same.
       rewrite -same literal_prefix_set // in inside.
       by rewrite /= inE in inside;rewrite /= inside unique.
   + have misses:forall q:'I_n,Int.eq (addr q) head=false.
     { move=>q;case test:(Int.eq (addr q) head)=>//.
       have present:[exists i:'I_n,Int.eq (addr i) head] by apply/existsP;exists q.
       move:has;case:pickP=>[i _|none] // _;move/existsP:present=>[i hit].
       by move:(none i);rewrite hit. }
     have unchanged:@prefix_set n (head::tail)=@prefix_set n tail.
     { apply/setP=>i;rewrite /prefix_set !inE /=;fold (addr i).
       by rewrite misses. }
     rewrite unchanged /=;split;first exact:(leq_trans bound (leqnSn _)).
     by move=>same;move:bound;rewrite same ltnn.
Qed.
Theorem physical_replay_indices m r (H:'M['F_2]_(m,n)) (S:'M['F_2]_(r,n)) w cells:
 stored_css_prefix H S w cells -> exists ids:seq 'I_n,uniq ids /\
 literal_path ids=active_prefix w cells /\ Z.of_nat (size ids)=w.
Proof.
 move=>[room closed outside [weight lower]].
 rewrite support_indicator in weight.
 have len:Z.of_nat (size (active_prefix w cells))=w by rewrite -Zlength_correct /active_prefix Zlength_sublist;lia.
 have full:#|@prefix_set n (active_prefix w cells)|=size (active_prefix w cells) by apply Nat2Z.inj;lia.
 have [ids [unique same]]:=(proj2 (full_cardinality_path _) full).
 exists ids;split=>//;split=>//.
 by rewrite -len -same /literal_path size_map.
Qed.
End Physical.
