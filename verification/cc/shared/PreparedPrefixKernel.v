(* SPDX-License-Identifier: GPL-3.0-or-later *)
From mathcomp Require Import all_ssreflect all_algebra.
Require Import LeafMatrix MinimumPrefix LevelSearch PreparedMatrixPath PreparedWitnessWeight.
Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.
Local Open Scope ring_scope.

Section EarlyReturn.
Variables m n k:nat.
Variables (H:'M['F_2]_(m,n)) (L:'M['F_2]_(k,n)).
Variables (selected:seq 'I_n) (target:'cV['F_2]_n).
Let x:=vector_on (0:'cV['F_2]_n) selected.

(* The DFS early-closed branch cannot discard a larger minimum logical
   witness extending the exact distinct qubits stored in its active trace. *)
Theorem closed_prefix_rules_out_minimum:
 uniq selected -> selected!=[::] -> support x \subset support target ->
 (size selected < #|support target|)%N -> H*m x=0 -> ~minimum H L target.
Proof.
 move=> distinct nonempty sub smaller closed minimum.
 have wt:=selected_path_weight distinct;fold x in wt.
 have strict:support x \proper support target by rewrite properEcard sub wt.
 have positive:(0<size selected)%N by rewrite lt0n size_eq0.
 have present:support x!=set0 by rewrite -cards_eq0 wt -lt0n.
 have odd:=@minimum_prefix_odd m n k H L x target minimum present strict.
 by move:odd;rewrite closed eqxx.
Qed.
End EarlyReturn.
