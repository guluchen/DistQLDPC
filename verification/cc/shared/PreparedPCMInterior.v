(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto.
From mathcomp Require Import all_ssreflect all_algebra.
Require Import LeafMatrix MinimumPrefix LevelSearch VerifDetected VerifChildVisit VerifEnabledSiblings
 EnabledCall EnabledLoopFacts OverlapChildState OverlapColumnState OverlapTargetProgress ChildColumn
 IndexRowBridge RowTally SiblingCounters PreparedChildMode PreparedRecursiveCall PreparedSeedDispatch
 PreparedDepthSpec PreparedRootStages PreparedArenaRoot PreparedArenaContext PreparedCandidateArena
 PreparedBudgetArena PreparedBudgetContract PreparedChildCall PreparedSiblingScan PreparedSiblingRestore
 PreparedMatrixPath PreparedPCMLeafVisit PreparedChildPrefix PreparedResidualIndex PreparedOverlapDepth
 PreparedInteriorReport.
Require Import PreparedDescentFuel.
Require flag_level_ast.
Import flag_level_ast.
#[local] Existing Instance VerifDetected.CompSpecs.
Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.
Local Open Scope ring_scope.
Local Delimit Scope Z_scope with coqZ.

Section Interior.
Variable Espec:OracleKind.
#[local] Existing Instance Espec.
Variables m n r k:nat.
Variables (H:'M['F_2]_(m,n)) (S:'M['F_2]_(r,n)) (G:'M['F_2]_(k,n))
 (c:policy_state) (heap:node_storage) (options:Integers.int) (s cp base:Values.val)
 (parent row:seq 'I_n) (check:'I_m) (root:snapshot) (cells:seq Integers.int) (w depth stride levels:Z).
Variable admissible_target:seq Integers.int -> 'cV['F_2]_n -> Prop.
Let report:=recursive_report H S G admissible_target.
Let geom:=geometry c.
Let P:=[set b:'I_n | b \in parent].
Let F:=@available_now n root.
Let xs:=map Int.unsigned (free_row (blocked root) (map (@address n) row)).
Let update:=enabled_at options w depth.
Let buf:=row_pointer base stride depth.
Let loan:=remaining_arena base stride levels (depth+1)%coqZ.
Hypotheses (dims:(0<Z.of_nat n<=Int.max_signed)%coqZ) (size_ok:Zlength (blocked root)=Z.of_nat n)
 (row_ok:forall q:'I_n,H check q!=0 -> q \in row) (unique:uniq row)
 (odd:(H*m indicator P) check 0!=0) (prefix:active_prefix depth cells=literal_path parent)
 (fit:(1<=depth<w-2)%coqZ) (budget:(w<=Int.max_signed)%coqZ) (cap:(w<=Zlength cells)%coqZ)
 (owner:is_pointer_or_null (callback_owner c)) (count:(Zlength xs<=Int.max_signed)%coqZ)
 (ready:forall i,(0<=i<Zlength xs)%coqZ -> mode_ready update geom (Znth i xs) (sibling_state root xs (i+1)%coqZ)).
Hypothesis inherited:forall x (a:'I_n),admissible_target (literal_path parent) x ->
 admissible_target (literal_path parent++[::Int.repr (Z.of_nat a)]) x.
Hypothesis overlap:forall x,admissible_target (literal_path parent) x -> minimum H G x -> P \subset support x -> support x :\: P \subset F ->
 let wanted:=physical_member (support x :\: P) in update=true ->
 forall i,(0<=i<Zlength xs)%coqZ -> wanted (Znth i xs)=true ->
 let st:=sibling_state root xs (i+1)%coqZ in column_bounds geom (Znth i xs) st /\
  forall a,wanted a=true -> a<>Znth i xs -> ~List.In a (new_blocks geom (Znth i xs) st).

(* The recursive call uses the same distance contract and machine weight
   as its caller. The proof uses the native branch, array and rollback
   instructions, including when the cached overlap bit is false. *)
Section ChildCalls.
Variable children:budget_heap.
Hypothesis at_child:forall node,Zlength node=(depth+1)%coqZ ->
 children w s node=(heap s node * loan)%logic.

Theorem recursive_loop_at_physical_weight_with_children:
 semax (func_tycontext f_dfs prepared_vars (with_child_heap c heap children report options) nil)
 (PROPx nil (LOCALx (scan_loc_mode update c s buf depth (Zlength xs) 0%coqZ 0%coqZ options)
  (SEPx [::enabled_memory c s cp w cells root;heap s (active_prefix depth cells);loan;child_array buf xs])))
 (Ssequence search_children undo_children)
 (normal_ret_assert (EX i:Z,EX code:Z,EX st:snapshot,EX tail:seq Integers.int,
  PROPx [::recursive_result H S G admissible_target w root (active_prefix depth cells) code tail;
    (0<=code<=3)%coqZ;keeps_witness_mode update c root xs i code tail;same_search st root;
    Zlength tail=Zlength cells;active_prefix depth tail=active_prefix depth cells]
   (LOCALx (scan_loc_mode update c s buf depth (Zlength xs) i code options)
    (SEPx [::enabled_memory c s cp w tail st;heap s (active_prefix depth cells);loan;child_array buf xs])))).
Proof.
 have unsigned:(Z.of_nat n<=Int.max_unsigned)%coqZ by move:dims;change Int.max_signed with 2147483647%coqZ;
   change Int.max_unsigned with 4294967295%coqZ;lia.
 have [range _]:=@emitted_range_and_availability n row _ F unsigned size_ok (@available_in_view n root).
 have positive:(0<Zlength (blocked root)<=Int.max_signed)%coqZ by rewrite size_ok.
 eapply semax_post';last exact:(@restore_siblings_at_weight Espec c heap children loan report options s cp buf xs root cells w depth
      update fit budget cap count positive range owner ready at_child).
 Intros i code st tail.
 match goal with h:scan_outcome_mode _ _ _ _ _ _ _ _ _ |- _ => pose proof h as scan end.
 rewrite prefix in scan.
 have outcome:=@interior_scan_preserves_weight_and_witness m n r k H S G admissible_target root parent row check geom update
    (proj2 dims) size_ok row_ok unique odd inherited overlap w i code tail scan.
 rewrite -prefix in outcome.
 Exists i code st tail;unfold scan_loc_mode;entailer!;try apply derives_refl;auto.
Qed.
End ChildCalls.

Theorem recursive_loop_at_physical_weight:
 semax (func_tycontext f_dfs prepared_vars (recursive_policy c heap (pool base stride levels) report options) nil)
 (PROPx nil (LOCALx (scan_loc_mode update c s buf depth (Zlength xs) 0%coqZ 0%coqZ options)
  (SEPx [::enabled_memory c s cp w cells root;heap s (active_prefix depth cells);loan;child_array buf xs])))
 (Ssequence search_children undo_children)
 (normal_ret_assert (EX i:Z,EX code:Z,EX st:snapshot,EX tail:seq Integers.int,
  PROPx [::recursive_result H S G admissible_target w root (active_prefix depth cells) code tail;
    (0<=code<=3)%coqZ;keeps_witness_mode update c root xs i code tail;same_search st root;
    Zlength tail=Zlength cells;active_prefix depth tail=active_prefix depth cells]
   (LOCALx (scan_loc_mode update c s buf depth (Zlength xs) i code options)
    (SEPx [::enabled_memory c s cp w tail st;heap s (active_prefix depth cells);loan;child_array buf xs])))).
Proof.
 apply recursive_loop_at_physical_weight_with_children with (children:=fun _=>node_heap heap (pool base stride levels));
  intros node length;unfold node_heap,pool,loan;rewrite length;reflexivity.
Qed.
End Interior.
