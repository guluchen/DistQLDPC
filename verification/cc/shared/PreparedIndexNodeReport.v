(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto.
From mathcomp Require Import all_ssreflect all_algebra.
Require Import PreparedPCMChooser PreparedIndexAdmission PreparedIndexFinish PreparedIndexWhile
 PreparedInteriorReport PreparedResidualIndex PreparedDepthSpec PreparedSiblingScan
 PreparedPCMLeafVisit PreparedMatrixPath LeafMatrix MinimumPrefix LevelSearch
 PreparedChildPrefix PreparedRecursiveCall OverlapChildState OverlapColumnState
 NativePackingScan IndexRowBridge RowTally EnabledLoopFacts ChildColumn SiblingCounters.
Set Implicit Arguments.
Unset Strict Implicit.
Local Delimit Scope Z_scope with coqZ.
Local Open Scope ring_scope.

Section Node.
Variables m n r k:nat.
Variables (H:'M['F_2]_(m,n)) (S:'M['F_2]_(r,n)) (G:'M['F_2]_(k,n))
 (eligible:seq Integers.int->'cV['F_2]_n->Prop)
 (rows:'I_m->seq 'I_n) (parent:seq 'I_n) (st:snapshot)
 (offsets:seq Z) (cols:seq Integers.int) (budget:nat).
Let P:=[set q:'I_n | q \in parent].
Let F:=@available_now n st.
Let word:=literal_path parent.
Let w:=Z.of_nat (size parent+budget)%N.
Let xs result:=map Int.unsigned (output_columns offsets cols (blocked st) result).
Hypotheses (fits:(Z.of_nat n<=Int.max_signed)%coqZ) (width:Zlength (blocked st)=Z.of_nat n)
 (covers:forall i q,H i q!=0 -> q \in rows i) (distinct:forall i,uniq (rows i))
 (unique:uniq parent).

Lemma cut_at_current_weight tail :
 no_completion H (indicator P) F budget -> recursive_result H S G eligible w st word 0%coqZ tail.
Proof.
 move=>cut;split;last by split;discriminate.
 rewrite /word literal_prefix_set //;move=>x keep best weight sub free.
 have [/andP[/eqP kernel _] _]:=best.
 have count:#|P|=size parent by rewrite /P cardsE (card_uniqP unique).
 have total:#|support x|=(#|P|+budget)%N by apply Nat2Z.inj;rewrite count;exact weight.
 have parts:=cardsID P (support x);have inter:support x :&: P = P :=elimT setIidPr sub.
 rewrite inter total in parts;have room:#|support x :\: P|=budget:=addnI parts.
 rewrite /no_completion support_indicator in cut.
 by exfalso;apply:(cut x sub kernel free);rewrite room.
Qed.

(* For either cut the physical child count is zero. For a continuing
   scan the actual array is the free portion of a particular odd row.
   Its identity suffices even when several odd rows tie. *)
Theorem index_children_preserve_recursive_result g result stop code tail :
 selection_origin rows H (indicator P) F budget offsets cols (blocked st) result ->
 (forall x (a:'I_n),eligible word x -> eligible (word++[::Int.repr (Z.of_nat a)]) x) ->
 scan_outcome_mode false (recursive_report H S G eligible w) g st (xs result) word stop code tail ->
 recursive_result H S G eligible w st word code tail.
Proof.
 case:result=>[row packed tags|tags|tags] origin inherit scan.
 - case:origin=>i [_ [odd image]].
   rewrite /xs image in scan.
   apply:(@interior_scan_preserves_weight_and_witness m n r k H S G eligible st parent (rows i) i g false
       fits width (@covers i) (distinct i) odd inherit _ w stop code tail scan).
   by move=>x _ _ _ _ impossible.
 - have [_ [[_ ->]|[within _]]]:=scan;first exact:cut_at_current_weight origin.
   change (0<=stop<0)%coqZ in within;lia.
 - have [_ [[_ ->]|[within _]]]:=scan;first exact:cut_at_current_weight origin.
   change (0<=stop<0)%coqZ in within;lia.
Qed.
End Node.
