(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto.
From mathcomp Require Import all_ssreflect all_algebra.
Require Import PreparedPCMChooser PreparedIndexWhile PreparedIndexFinish PreparedChildCall
 PreparedChildPrefix PreparedDepthSpec PreparedSelectedBlocks PreparedPCMLeafVisit PreparedMatrixPath
 PreparedIndexAdmission LeafMatrix LevelSearch NativePackingScan IndexRowBridge RowTally
 EnabledLoopFacts OverlapChildState OverlapColumnState ChildColumn VerifSeedIndex.
Set Implicit Arguments.
Unset Strict Implicit.
Local Delimit Scope Z_scope with coqZ.
Local Open Scope ring_scope.

(* Reachable inputs to DFS own a block vector of the correct size.
   The active trace is a sequence of distinct, protected qubits. *)
Definition reachable_prefix n (st:snapshot) (path:seq Integers.int):Prop:=
 exists ids:seq 'I_n,uniq ids /\ path=literal_path ids /\ Zlength (blocked st)=Z.of_nat n /\
   forall q:'I_n,q \in ids -> Znth (Z.of_nat q) (blocked st)<>Int.zero.

Lemma index_seed_is_reachable n (q:'I_n) st:
 blocked st=seen (Z.of_nat n) (Z.of_nat q+1)%coqZ ->
 reachable_prefix n st (literal_path [::q]).
Proof.
 move=>physical;have inside:=elimT ltP (ltn_ord q).
 exists [::q];split;first by rewrite /=.
 split;first reflexivity.
 split;first by rewrite physical seen_length //;lia.
 move=>b;rewrite inE=>/eqP ->;rewrite physical seen_cell;try lia.
 case:Z_lt_dec=>h;[discriminate|lia].
Qed.

Section Child.
Variables m n:nat.
Variables (H:'M['F_2]_(m,n)) (rows:'I_m->seq 'I_n) (parent:seq 'I_n)
 (root:snapshot) (offsets:seq Z) (cols:seq Integers.int) (budget:nat) (res:scan_exit).
Let P:=[set q:'I_n | q \in parent].
Let xs:=map Int.unsigned (output_columns offsets cols (blocked root) res).
Hypotheses (fits:(Z.of_nat n<=Int.max_signed)%coqZ)
 (width:Zlength (blocked root)=Z.of_nat n) (distinct:forall i,uniq (rows i))
 (unique:uniq parent) (protected:forall q:'I_n,q \in parent -> Znth (Z.of_nat q) (blocked root)<>Int.zero)
 (origin:selection_origin rows H (indicator P) (@available_now n root) budget offsets cols (blocked root) res).

Theorem all_visited_children_are_reachable i depth cells:
 (0<=i<Zlength xs)%coqZ -> active_prefix depth cells=literal_path parent ->
 reachable_prefix n (sibling_state root xs (i+1)%coqZ) (append_qubit cells depth (Znth i xs)).
Proof.
 unfold xs;case:res origin=>[r val tags|tags|tags] proof0 pos prefix.
 - case:proof0=>check [_ [_ written]]. rewrite written in pos |- *.
   pose ids:=rows check.
   pose choices:=map Int.unsigned (free_row (blocked root) (encoded rows check)).
   pose current:=sibling_state root choices i.
   have same:same_search current (sibling_state root choices i) by split.
   have [a [address fresh extend physical blocked_here]]:=
     @child_extends_protected_prefix n parent ids root current i cells depth fits width (distinct check)
        unique prefix protected pos same.
   have agree:=proj2 (@selected_sibling root choices i current pos same).
   exists (rcons parent a);split;first exact fresh.
   split;first exact extend.
   split;first by rewrite -agree.
   move=>q member;rewrite -agree;exact:blocked_here member.
 - change (0<=i<0)%coqZ in pos;lia.
 - change (0<=i<0)%coqZ in pos;lia.
Qed.
End Child.
