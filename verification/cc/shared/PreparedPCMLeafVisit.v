(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto.
From mathcomp Require Import all_ssreflect all_algebra.
Require Import LeafMatrix LevelSearch SyndromeHash ClosureMatrix VerifDetected VerifChildVisit VerifFlipBody
 VerifClosesBody VerifLookup HashLookup BuiltLookup TableFlow NativeFlipPayload NativeDepthFlip PCMLeafAPI
 EnabledCall OverlapColumnState OverlapChildState OverlapView PreparedMatrixPath PreparedMatrixResponse PreparedChildCall
 PreparedDepthSpec PreparedPairDispatch PreparedPairEvent PreparedPairLedger PreparedLeafWorkspace
 PreparedLeafVisit PreparedBothLeaves PreparedLeafLoopBridge PreparedRootStages PreparedBudgetContract
 PreparedNativeCallees PreparedRecursiveCall PreparedSiblingScan PreparedSiblingRestore PreparedCandidateArena
 PreparedArenaRoot PreparedArenaContext SiblingCounters VerifEnabledSiblings EnabledLoopFacts PreparedSeedDispatch.
Require flag_level_ast.
Import flag_level_ast.
#[local] Existing Instance VerifDetected.CompSpecs.
Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.
Local Open Scope ring_scope.
Local Delimit Scope Z_scope with coqZ.

Section Actual.
Variable Espec:OracleKind.
#[local] Existing Instance Espec.
Variables m n k:nat.
Variables (H:'M['F_2]_(m,n)) (G:'M['F_2]_(k,n)) (rows:'I_n->seq 'I_m) (rowkey:'I_m->int64)
 (keys:seq int64) (mask:int64) (cap bits:Z) (tab links:seq Z)
 (c:policy_state) (policy:row_policy) (p:lookup_ptrs) (initial:packed_support).

Record table_for_lookup:Prop:={
 built_index:history keys mask cap (-1)%coqZ tab links;
 nonempty_keys:(0<Zlength keys)%coqZ; all_keys:Zlength keys=Z.of_nat n;
 spare_slot:(Zlength keys<cap)%coqZ; power_two:cap=(2^bits)%coqZ;
 fits_word:(0<=bits<64)%coqZ; table_mask:mask=Int64.repr (Z.ones bits);
 row_capacity:(Z.of_nat m<=Int.modulus)%coqZ;
 no_duplicate_rows:forall q,uniq (rows q); pcm_incidence:forall q,[set r in rows q]=support (col q H);
 stored_keys:forall q:'I_n,Znth (Z.of_nat q) keys=signature rowkey (support (col q H));
 shared_blocks:pb p=blockp (conn c)
}.
Definition available_now (st:snapshot):=[set i:'I_n | Int.eq (Znth (Z.of_nat i) (blocked st)) Int.zero].
Lemma available_in_view st (q:'I_n):Znth (Z.of_nat q) (blocked st)=Int.zero <-> q \in available_now st.
Proof.
 rewrite /available_now inE;split;[by move=> ->;rewrite Int.eq_true|].
 by move=> test;exact:Int.same_if_eq.
Qed.
Definition reached_leaf (P:{set 'I_n}) (st:snapshot) prefix:=
 let t:=payload_after policy keys initial prefix in let v:=words_at t in
 let b:=table_book keys mask (checksum t) tab links (blocked st) in
 [ /\ [disjoint available_now st & P],@encoded_at m n k G rows policy t,
  pcm_response H G rowkey (indicator P) t,(odd_count t<>0%coqZ -> book_safe b v (odd_count t)) &
  (0<=odd_count t<=Int.max_signed)%coqZ /\ (Zlength (parities v)<=Int.max_signed)%coqZ ].
Variables (workspace:Values.val->mpred) (s cp:Values.val).

Theorem concrete_leaf_in_recursive_heap (loan:mpred) (P:{set 'I_n}) st depth q children count i options cells:
 table_for_lookup -> reached_leaf P st (append_qubit cells depth q) ->
 (1<=depth<=Int.max_signed-2)%coqZ -> (depth+1<Zlength cells)%coqZ ->
 let w:=(depth+2)%coqZ in let node:=append_qubit cells depth q in let t:=payload_after policy keys initial node in
 let hold:=leaf_flip_heap c policy p keys mask tab links initial workspace in
 let accept:=pcm_completion H G P (available_now st) in
 let locs:=descent_loc c s depth q children count i options false in
 semax pair_delta (PROPx nil (LOCALx (temp _result (Vint Int.zero)::locs)
    (SEPx [::enabled_memory c s cp w cells st;hold s node;loan]))) child_bracket
 (normal_ret_assert (EX tail:seq Integers.int,EX code:Z,PROPx [::(0<=code<=3)%coqZ;Zlength tail=Zlength cells;
    active_prefix (depth+1)%coqZ tail=node;pair_observation t accept (Z.of_nat n) depth q cells code tail]
    (LOCALx (temp _result (Vint (Int.repr code))::locs) (SEPx [::enabled_memory c s cp w tail st;hold s node;loan])))).
Proof.
 move=> tab_ok [dis enc response memory [odd width]] depth_ok enough w node t hold accept locs.
 apply (@fast_search_with_flip_heap Espec c policy p keys mask tab links initial workspace loan s cp depth q i
   (Z.of_nat n) st cells children count options accept).
 move=> cl lv sv.
 have [built positive all_keys spare period bits_ok low fit distinct inc stored same]:=tab_ok.
 exact:(@run_both_fast_paths Espec m n k H G P (available_now st) rows rowkey c st t policy keys mask cap bits
  tab links s cp p built positive all_keys spare period bits_ok low dis (@available_in_view st)
  fit distinct inc enc stored response memory same depth q children count i options cells cl lv sv depth_ok enough odd width).
Qed.

Theorem actual_fast_sibling_loop (xs:seq Z) (root:snapshot) (cells:seq Integers.int)
 (depth stride levels:Z) (base:Values.val) (options:Integers.int) (report:budget_report)
 (selected_set:seq Integers.int->{set 'I_n}):
 let w:=(depth+2)%coqZ in let hold:=leaf_flip_heap c policy p keys mask tab links initial workspace in
 let candidates:=row_pointer base stride depth in let scratch:=pool base stride levels in
 let loan:=remaining_arena base stride levels (depth+1)%coqZ in let g:=geometry c in
 let observe:=fun st cur q code tail=>
    let node:=append_qubit cur depth q in let t:=payload_after policy keys initial node in
    pair_observation t (pcm_completion H G (selected_set node) (available_now st)) (Z.of_nat n) depth q cur code tail in
 table_for_lookup -> (1<=depth<=Int.max_signed-2)%coqZ -> (w<=Zlength cells)%coqZ ->
 (Zlength xs<=Int.max_signed)%coqZ -> (0<Zlength (blocked root)<=Int.max_signed)%coqZ ->
 in_array (Zlength (blocked root)) xs -> is_pointer_or_null (callback_owner c) ->
 (forall i,(0<=i<Zlength xs)%coqZ -> (Znth i xs+1<Zlength (column_offsets g))%coqZ) ->
 (forall i st cur,(0<=i<Zlength xs)%coqZ -> same_search st (sibling_state root xs i) ->
    Zlength cur=Zlength cells -> active_prefix depth cur=active_prefix depth cells ->
    let q:=Znth i xs in let node:=append_qubit cur depth q in reached_leaf (selected_set node) (selected st q) node) ->
 (forall i st cur code tail,(0<=i<Zlength xs)%coqZ -> same_search st (sibling_state root xs i) ->
    Zlength cur=Zlength cells -> active_prefix depth cur=active_prefix depth cells ->
    let q:=Znth i xs in let seen:=selected st q in observe seen cur q code tail ->
    report w g seen (append_qubit cur depth q) code tail /\
    (witness_status code -> returned_trace (nested c) (blocked seen) q tail)) ->
 semax (func_tycontext f_dfs prepared_vars (policy_callees c hold (fun _=>node_heap hold scratch) report options) nil)
 (PROPx nil (LOCALx (scan_loc_mode false c s candidates depth (Zlength xs) 0%coqZ 0%coqZ options)
  (SEPx [::enabled_memory c s cp w cells root;hold s (active_prefix depth cells);loan;child_array candidates xs])))
 (Ssequence search_children undo_children)
 (normal_ret_assert (EX i:Z,EX r:Z,EX st:snapshot,EX tail:seq Integers.int,
  PROPx [::scan_outcome_mode false (report w) g root xs (active_prefix depth cells) i r tail;
    keeps_witness_mode false c root xs i r tail;(0<=r<=3)%coqZ;same_search st root;
    Zlength tail=Zlength cells;active_prefix depth tail=active_prefix depth cells]
   (LOCALx (scan_loc_mode false c s candidates depth (Zlength xs) i r options)
     (SEPx [::enabled_memory c s cp w tail st;hold s (active_prefix depth cells);loan;child_array candidates xs])))).
Proof.
 move=> w hold candidates scratch loan g observe table_ok depth_ok room bound sizes valid owner offset live interpret.
 eapply complete_fast_sibling_search with (observe:=observe);
    [exact depth_ok|exact room|exact bound|exact sizes|exact valid|exact owner|exact offset| | |exact interpret].
 - move=>node len;unfold node_heap,scratch,pool,loan;rewrite len;reflexivity.
 - move=>i st cur range same len prefix q post_flip node locs.
   have reached:=live i st cur range same len prefix.
   apply (@concrete_leaf_in_recursive_heap (loan * child_array candidates xs)%logic (selected_set node) post_flip
      depth q candidates (Zlength xs) i options cur table_ok reached depth_ok).
   unfold w in room;lia.
Qed.
End Actual.
