(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VerifDetected VerifChildVisit EnabledCall EnabledLoopFacts OverlapChildState
 OverlapColumnState ChildColumn SiblingCounters VerifEnabledSiblings PreparedSeedDispatch PreparedDepthSpec
 PreparedArenaContext PreparedCandidateArena PreparedArenaRoot PreparedChildCall PreparedChildMode
 PreparedBudgetContract PreparedOverlapDepth PreparedSiblingScan PreparedSiblingRestore PreparedRootStages.
Require flag_level_ast.
Import flag_level_ast.
#[local] Existing Instance VerifDetected.CompSpecs.
Local Open Scope Z_scope.

Definition recursive_policy c packed scratch (report:budget_report) bits:=
 prepared_calls (snd (depth_flip c packed bits)) (snd (budget_dfs c (fun _=>node_heap packed scratch) report bits)).

Theorem scan_native_candidate_arena {Espec:OracleKind} c packed obs bits s cp xs root path w depth base stride levels:
 let update:=enabled_at bits w depth in let children:=row_pointer base stride depth in
 let next:=remaining_arena base stride levels (depth+1) in
 1<=depth<w-2 -> w<=Int.max_signed -> w<=Zlength path -> Zlength xs<=Int.max_signed ->
 0<Zlength (blocked root)<=Int.max_signed -> in_array (Zlength (blocked root)) xs ->
 is_pointer_or_null (callback_owner c) ->
 (forall i,0<=i<Zlength xs -> mode_ready update (geometry c) (Znth i xs) (sibling_state root xs (i+1))) ->
 semax (func_tycontext f_dfs prepared_vars (recursive_policy c packed (pool base stride levels) obs bits) [])
 (PROPx [] (LOCALx (scan_loc_mode update c s children depth (Zlength xs) 0 0 bits)
  (SEPx [enabled_memory c s cp w path root;packed s (active_prefix depth path);next;child_array children xs])))
 (Ssequence search_children undo_children)
 (normal_ret_assert (EX i:Z,EX r:Z,EX st:snapshot,EX tail:list int,
  PROPx [scan_outcome_mode update (obs w) (geometry c) root xs (active_prefix depth path) i r tail;
   keeps_witness_mode update c root xs i r tail;0<=r<=3;same_search st root;
   Zlength tail=Zlength path;active_prefix depth tail=active_prefix depth path]
  (LOCALx (scan_loc_mode update c s children depth (Zlength xs) i r bits)
   (SEPx [enabled_memory c s cp w tail st;packed s (active_prefix depth path);next;child_array children xs])))).
Proof.
 intros update children next deep cap room count total keys own safe.
 apply (@restore_siblings_at_weight Espec c packed (fun _=>node_heap packed (pool base stride levels))
      next obs bits s cp children xs root path w depth update);try assumption.
 intros prefix length;unfold node_heap,pool,next;rewrite length;reflexivity.
Qed.
