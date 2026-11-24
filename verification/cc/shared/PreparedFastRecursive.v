(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto.
From mathcomp Require Import all_ssreflect all_algebra.
Require Import LeafMatrix MinimumPrefix LevelSearch SyndromeHash RowTally IndexRowBridge ClosureMatrix
 VerifDetected VerifChildVisit VerifFlipBody VerifClosesBody VerifLookup HashLookup BuiltLookup
 NativeFlipPayload RedundantState NativeDepthFlip PCMLeafAPI EnabledCall OverlapColumnState OverlapChildState
 OverlapView PreparedDepthSpec PreparedChildCall PreparedSeedDispatch PreparedRootStages PreparedBudgetContract
 PreparedRecursiveCall PreparedNativeCallees PreparedSiblingScan PreparedSiblingRestore PreparedArenaContext
 PreparedCandidateArena PreparedArenaRoot PreparedMatrixPath PreparedMatrixResponse PreparedInitialLookup
 PreparedLeafWorkspace PreparedLeafVisit PreparedPCMLeafVisit PreparedChildPrefix PreparedFastCoverage
 PreparedLeafReport PreparedLeafReturnContract PreparedInteriorReport PreparedObservedWitness PreparedResidualIndex EnabledLoopFacts VerifEnabledSiblings SiblingCounters.
Require flag_level_ast.
Import flag_level_ast.
#[local] Existing Instance VerifDetected.CompSpecs.
Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.
Local Open Scope ring_scope.
Local Delimit Scope Z_scope with coqZ.

Section Unified.
Variable Espec:OracleKind.
#[local] Existing Instance Espec.
Variables m n r k:nat.
Variables (H:'M['F_2]_(m,n)) (S:'M['F_2]_(r,n)) (G:'M['F_2]_(k,n))
 (columns:'I_n->seq 'I_m) (rowkey:'I_m->int64)
 (keys:seq int64) (mask:int64) (cap bits:Z) (tab links:seq Z)
 (c:policy_state) (policy:row_policy) (p:lookup_ptrs) (initial:packed_support)
 (old_blocks:seq Integers.int) (frame:Values.val->mpred) (s cp:Values.val).
Hypotheses (orth:H*m S^T=0) (det:G*m S^T=0) (rank_ok:(\rank (col_mx H G)+\rank S=n)%N)
 (rows_fit:(Z.of_nat m<=Int.max_signed)%coqZ)
 (idx:@table_for_lookup m n H columns rowkey keys mask cap bits tab links c p)
 (base_safe:book_safe (table_book keys mask (checksum initial) tab links old_blocks) (words_at initial) (odd_count initial))
 (redundant:forall q:'I_n,Forall (fun row=>(Z.of_nat m<=Int.unsigned row)%coqZ) (extra_rows policy (Z.of_nat q)))
 (encoded:@encoded_at m n k G columns policy initial)
 (zero:pcm_response H G rowkey (0:'cV['F_2]_n) initial).
Variables (root:snapshot) (parent row:seq 'I_n) (cells:seq Integers.int) (depth stride levels:Z)
 (base:Values.val) (options:Integers.int).
Let w:=(depth+2)%coqZ.
Let buf:=row_pointer base stride depth.
Let hold:=leaf_flip_heap c policy p keys mask tab links initial frame.
Let loan:=remaining_arena base stride levels (depth+1)%coqZ.
Let xs:=map Int.unsigned (free_row (OverlapColumnState.blocked root) (map (@address n) row)).
Variable qualified:seq Integers.int->'cV['F_2]_n->Prop.
Let goal_report:=recursive_report H S G qualified.
Let P:=[set q:'I_n | q \in parent].
Let F:=@available_now n root.
Hypotheses (signed_depth:(1<=depth<=Int.max_signed-2)%coqZ) (room:(w<=Zlength cells)%coqZ)
 (blocked_size:Zlength (OverlapColumnState.blocked root)=Z.of_nat n)
 (distinct:uniq row) (legal_parent:uniq parent)
 (prefix:active_prefix depth cells=literal_path parent)
 (parent_length:depth=Z.of_nat (size parent))
 (protected:forall q:'I_n,q \in parent -> Znth (Z.of_nat q) (OverlapColumnState.blocked root)<>Int.zero)
 (rows_in_storage:(Zlength xs<=Int.max_signed)%coqZ) (owner:is_pointer_or_null (callback_owner c))
 (csr_safe:forall i,(0<=i<Zlength xs)%coqZ -> (Znth i xs+1<Zlength (column_offsets (geometry c)))%coqZ).

(* The caller may attach an observation predicate to successful calls.
   A caller accepting a checked CSS trace discharges this ghost premise. *)
Hypothesis notify:forall st q code tail, witness_status code -> stored_css_prefix H S (reported_len w code) tail ->
 returned_trace (nested c) (OverlapColumnState.blocked st) q tail.
Variable selected_check:'I_m.
Hypotheses (covered:forall q:'I_n,H selected_check q!=0 -> q \in row)
 (odd:(H*m indicator P) selected_check 0!=0)
 (inherited:forall x (q:'I_n),qualified (literal_path parent) x ->
   qualified (literal_path parent++[::Int.repr (Z.of_nat q)]) x).

(* Both depth dispatches now install precisely the same CSS report for
   the recursive symbol. The fast loop itself never calls that symbol. *)
Theorem fast_search_with_recursive_contract:
 semax (func_tycontext f_dfs prepared_vars (policy_callees c hold
   (fun _=>node_heap hold (pool base stride levels)) goal_report options) nil)
 (PROPx nil (LOCALx (scan_loc_mode false c s buf depth (Zlength xs) 0%coqZ 0%coqZ options)
  (SEPx [::enabled_memory c s cp w cells root;hold s (active_prefix depth cells);loan;child_array buf xs])))
 (Ssequence search_children undo_children)
 (normal_ret_assert (EX i:Z,EX code:Z,EX st:snapshot,EX tail:seq Integers.int,
  PROPx [::recursive_result H S G qualified w root (active_prefix depth cells) code tail;
    (0<=code<=3)%coqZ;keeps_witness_mode false c root xs i code tail;
    same_search st root;Zlength tail=Zlength cells;active_prefix depth tail=active_prefix depth cells]
   (LOCALx (scan_loc_mode false c s buf depth (Zlength xs) i code options)
    (SEPx [::enabled_memory c s cp w tail st;hold s (active_prefix depth cells);loan;child_array buf xs])))).
Proof.
 have [history nonempty dim spare period bits_ok mask_ok cap_ok no_dups incidence stored alias]:=idx.
 have fit:(Z.of_nat n<=Int.max_signed)%coqZ by rewrite -dim;exact:(qubits_fit _ _ _ base_safe).
 have positive:(0<Zlength (OverlapColumnState.blocked root)<=Int.max_signed)%coqZ by rewrite blocked_size;lia.
 have unsigned:(Z.of_nat n<=Int.max_unsigned)%coqZ by move:fit;change Int.max_signed with 2147483647%coqZ;
    change Int.max_unsigned with 4294967295%coqZ;lia.
 have [bounds free]:=@emitted_range_and_availability n row _ F unsigned blocked_size (@available_in_view n root).
 have child_input:forall i st cur,(0<=i<Zlength xs)%coqZ -> same_search st (sibling_state root xs i) ->
   active_prefix depth cur=active_prefix depth cells -> let q:=Znth i xs in let node:=append_qubit cur depth q in
   exists ids:seq 'I_n,[ /\ uniq ids,node=literal_path ids,(depth+1)%coqZ=Z.of_nat (size ids) &
   @reached_leaf m n k H G columns rowkey keys mask tab links policy initial (@prefix_set n node) (selected st q) node ].
 { move=>i st cur range same match_root q node.
   have [a [addr unique trace width used]]:=@child_extends_protected_prefix n parent row root st i cur depth fit
      blocked_size distinct legal_parent (etrans match_root prefix) protected range same.
   change (node=literal_path (rcons parent a)) in trace.
   exists (rcons parent a);split=> //.
   - rewrite size_rcons parent_length;lia.
   - rewrite trace literal_prefix_set //;apply (@reached_leaf_from_initial m n k H G rowkey columns policy keys
      mask tab links initial old_blocks rows_fit dim nonempty no_dups incidence redundant stored encoded zero base_safe);
      [exact unique|by rewrite width dim|exact used]. }
 eapply semax_post'.
 2:{ apply (@actual_fast_sibling_loop Espec m n k H G columns rowkey keys mask cap bits tab links c policy p
      initial frame s cp xs root cells depth stride levels base options goal_report (@prefix_set n)
      idx signed_depth room rows_in_storage positive bounds owner csr_safe).
    - move=>i st cur range same len matched;have [ids [_ _ _ reached]]:=child_input i st cur range same matched.
      exact reached.
    - move=>i st cur code tail range same len matched q child observed.
      have [ids [unique trace count [_ _ live _ _]]]:=child_input i st cur range same matched.
      have facts:=@prepared_leaf_evidence m n r k H S G ids child _ rowkey depth q cur code tail (geometry c)
          orth det rank_ok fit unique ltac:(lia) ltac:(unfold w in room;lia) count trace live observed.
      split.
      + apply:(@one_move_report_at_registered_weight m n r k H S G qualified ids (geometry c) child _ code tail w
          fit unique trace _ _ facts);unfold w;lia.
      + move=>found;apply (@notify child q code tail found);exact:((proj2 (proj2 facts)) found). }
 Intros i code st tail.
 match goal with h:scan_outcome_mode _ _ _ _ _ _ _ _ _ |- _=>pose proof h as actual end.
 rewrite prefix in actual.
 have result:=@interior_scan_preserves_weight_and_witness m n r k H S G qualified root parent row selected_check
      (geometry c) false fit blocked_size covered distinct odd inherited ltac:(intros;discriminate) w i code tail actual.
 rewrite -prefix in result;Exists i code st tail;unfold scan_loc_mode;entailer!;try apply derives_refl;auto.
Qed.
End Unified.
