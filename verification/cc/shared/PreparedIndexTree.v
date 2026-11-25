(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto.
From mathcomp Require Import all_ssreflect all_algebra.
Require Import PreparedRankedChildren PreparedIndexNodeReport PreparedPCMChooser
 PreparedIndexWhile PreparedIndexFinish PreparedInteriorReport PreparedMatrixPath
 PreparedPCMLeafVisit PreparedRecursiveCall PreparedSiblingScan PreparedDepthSpec
 OverlapChildState OverlapColumnState LeafMatrix LevelSearch EnabledLoopFacts.
Set Implicit Arguments.
Unset Strict Implicit.
Local Delimit Scope Z_scope with coqZ.
Local Open Scope ring_scope.

Section Tree.
Variables m n r k:nat.
Variables (H:'M['F_2]_(m,n)) (S:'M['F_2]_(r,n)) (G:'M['F_2]_(k,n))
 (eligible:seq Integers.int->'cV['F_2]_n->Prop) (rows:'I_m->seq 'I_n).
Hypotheses (orth:H*m S^T=0) (det:G*m S^T=0) (shape:(\rank (col_mx H G)+\rank S=n)%N)
 (fits:(Z.of_nat n<=Int.max_signed)%coqZ)
 (covers:forall i q,H i q!=0 -> q \in rows i) (distinct:forall i,uniq (rows i)).

(* One observation of the non-policy C call and the reports of the
   children that actually ran. Earlier siblings have returned EMPTY,
   while an interrupt or either kind of witness ends this scan. *)
Inductive index_step (fuel:nat) (subtree:node_report) (w:Z) (g:layout) (st:snapshot) :
 seq Integers.int->Z->seq Integers.int->Prop :=
| from_physical_children parent offsets cols result stop code tail :
 let P:=[set q:'I_n | q \in parent] in
 let node:=literal_path parent in
 let choices:=map Int.unsigned (output_columns offsets cols (blocked st) result) in
 w=Z.of_nat (size parent+fuel)%N -> uniq parent -> Zlength (blocked st)=Z.of_nat n ->
 selection_origin rows H (indicator P) (@available_now n st) fuel offsets cols (blocked st) result ->
 (forall x (a:'I_n),eligible node x -> eligible (node++[::Int.repr (Z.of_nat a)]) x) ->
 scan_outcome_mode false subtree g st choices node stop code tail ->
 index_step fuel subtree w g st node code tail.

Fixpoint index_execution (fuel:nat) (w:Z):node_report :=
 fun g st node code tail=>local_exit H S G w st node code tail \/
 match fuel with
 | O=>False
 | rest.+1=>index_step rest.+1 (index_execution rest w) w g st node code tail
 end.

Theorem index_execution_sound fuel w g st node code tail :
 index_execution fuel w g st node code tail -> recursive_result H S G eligible w st node code tail.
Proof.
 elim:fuel g st node code tail=>[|rest ih] g st node code tail.
 - case=>[local|//];exact:(@local_sound m n r k H S G eligible orth det shape fits w st node code tail local).
 - case=>[local|observation];first exact:(@local_sound m n r k H S G eligible orth det shape fits w st node code tail local).
   case:observation=>parent offsets cols result stop value path P words xs weight unique width origin inherit ran.
   subst w.
   apply:(@index_children_preserve_recursive_result m n r k H S G eligible rows parent st offsets cols rest.+1
      fits width covers distinct unique g result stop value path origin inherit).
   eapply map_children_of_scan;last exact ran.
   move=>seen q returned trace child;exact (ih g seen _ returned trace child).
Qed.
End Tree.
