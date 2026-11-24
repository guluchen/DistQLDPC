(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VerifDetected VerifChildVisit EnabledCall EnabledLoopFacts OverlapChildState
 OverlapColumnState ChildColumn SiblingCounters VerifEnabledSiblings PreparedSeedDispatch PreparedDepthSpec PreparedArenaContext PreparedCandidateArena
 PreparedArenaRoot PreparedChildCall PreparedSiblingScan PreparedSiblingRestore.
Require flag_level_ast.
Import flag_level_ast.
#[local] Existing Instance VerifDetected.CompSpecs.
Local Open Scope Z_scope.

Theorem recursive_scan_keeps_parent_row {Espec:OracleKind} c packed obs bits s cp xs root path w depth base stride levels:
 1<=depth<w-3 -> w<=Int.max_signed -> w<=Zlength path -> Zlength xs<=Int.max_signed ->
 0<Zlength (blocked root)<=Int.max_signed -> in_array (Zlength (blocked root)) xs ->
 is_pointer_or_null (callback_owner c) ->
 (forall i,0<=i<Zlength xs -> check_child (geometry c) (Znth i xs) (sibling_state root xs (i+1))) ->
 let children:=row_pointer base stride depth in let next:=remaining_arena base stride levels (depth+1) in
 let scratch:=pool base stride levels in
 semax (func_tycontext f_dfs prepared_vars (full_calls c packed scratch obs bits) [])
 (PROPx [] (LOCALx (scan_loc c s children depth (Zlength xs) 0 0 bits)
  (SEPx [enabled_memory c s cp w path root;packed s (active_prefix depth path);next;child_array children xs])))
 (Ssequence search_children undo_children)
 (normal_ret_assert (EX i:Z,EX r:Z,EX st:snapshot,EX tail:list int,
  PROPx [scan_outcome obs (geometry c) root xs (active_prefix depth path) i r tail;keeps_witness c root xs i r tail;
   0<=r<=3;same_search st root;Zlength tail=Zlength path;active_prefix depth tail=active_prefix depth path]
  (LOCALx (scan_loc c s children depth (Zlength xs) i r bits)
   (SEPx [enabled_memory c s cp w tail st;packed s (active_prefix depth path);next;child_array children xs])))).
Proof.
 intros deep cap room count total all owner safe children next scratch.
 apply (restore_siblings_with_loan c packed (node_heap packed scratch) next obs bits s cp children xs root path w depth);try assumption.
 intros prefix length;unfold node_heap,scratch,pool,next;rewrite length;reflexivity.
Qed.
