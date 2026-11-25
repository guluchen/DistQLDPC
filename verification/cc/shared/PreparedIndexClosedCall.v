(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VerifDetected VerifChildVisit VerifClosesBody VerifFlipBody VerifLookup
 NativeFlipPayload NativeDepthFlip OverlapColumnState PreparedWitnessRegister PreparedIndexWitnessLeaf
 PreparedCounterJoin PreparedIndexArena PreparedLeafWorkspace PreparedIndexBaseCases PreparedIndexTerminal
 PreparedDFSClosed flag_level_ast.
#[local] Existing Instance VerifDetected.CompSpecs.
Local Open Scope Z_scope.

(* Closed interior nodes additionally increment the level's closed counter.
   This word is already present in the same heap used by the inline leaf. *)
Lemma supply_closed_counter s b par w words budgets nodes cl saved:
 (budget_leaf_fields s b par w 0 words nodes budgets (Vint saved) *
   field_at Tsh level_type [StructField _closed] (Vlong cl) s)%logic =
 prefix_fields s b par w words budgets nodes cl saved.
Proof. unfold prefix_fields,budget_leaf_fields;apply pred_ext;cancel. Qed.

Definition closed_frame s cp p blocks cells ks mask tab links init words base stride levels
  (outside:val->mpred) leaves:=
 (terminal_sparse_part s (pk p) ks (payload_after Bare ks init words) *
    trace_and_blocks s cp (pb p) blocks cells * static_leaf_index s p mask tab links *
    field_at Tsh level_type [StructField _leaf2] (Vlong leaves) s *
    outside s * live_arena base stride levels (Zlength words))%logic.

Lemma closed_arena_split c s cp p budget base stride levels w blocks cells ks mask tab links init words outside saved:
 let t:=payload_after Bare ks init words in let v:=words_at t in
 let heap:=index_flip_heap c p ks mask tab links init
   (fun level=>(visit_storage level budget levels*outside level)%logic) in
 let rest:=closed_frame s cp p blocks cells ks mask tab links init words base stride levels outside in
 0<width v -> odd_count t=0 ->
 (child_fields s cp (pb p) w blocks cells * weight_bounded_rows base stride levels heap w s words *
     witness_register s saved)%logic =
 (!!(w<=levels /\ physical_prefix c words) &&
   (EX nodes:int64,EX counts:list int64,EX cl:int64,EX leaves:int64,!!(Zlength counts=levels) &&
      (prefix_fields s budget (ppar v) w (parities v) counts nodes cl saved *rest leaves)))%logic.
Proof.
 intros t v heap rest wide closed;unfold heap.
 rewrite (terminal_arena_split c s cp p budget base stride levels w blocks cells ks mask tab links init words outside saved wide).
 unfold terminal_frame,independent_leaf_counters,rest,closed_frame;fold t v;rewrite closed.
 apply pred_ext;Intros nodes counts cl leaves;Exists nodes counts cl leaves;
   rewrite <-supply_closed_counter;entailer!;cancel;try apply derives_refl.
Qed.

Require Import PreparedIndexTerminal EnabledCall PreparedChildPrefix NativePackingScan PreparedPlainDescent PreparedSeedDispatch.
Require Import PreparedIndexBaseContext PreparedIndexLink PreparedIndexGlobals PreparedPlainReachable
 PreparedBudgetContract PreparedRecursiveCall PreparedInteriorReport PreparedObservedWitness PreparedWeightCases
 PreparedCSSTerminal PreparedDeadline PreparedMatrixPath PreparedMatrixResponse PreparedLeafAtPath
 PreparedDepthSpec PreparedChildCall PreparedPCMLeafVisit PreparedReusableBook BuiltLookup HashLookup
 LeafMatrix MinimumPrefix DetectorRank PackedDetector LevelSearch.
From mathcomp Require Import all_ssreflect all_algebra.
Set Implicit Arguments.
Unset Strict Implicit.
Local Open Scope ring_scope.
Local Delimit Scope Z_scope with coqZ.

Require Import PreparedIndexTerminalCall PreparedCutReports PreparedDFSTerminal.
Section Closed.
Variables m n r k:nat.
Variables (H:'M['F_2]_(m,n)) (S:'M['F_2]_(r,n)) (G:'M['F_2]_(k,n))
 (rows:'I_m->seq 'I_n) (columns:'I_n->seq 'I_m) (rowkey:'I_m->int64)
 (keys:seq int64) (mask:int64) (cap bits:Z) (tab links:seq Z) (c:policy_state) (p:lookup_ptrs)
 (initial:packed_support) (initial_blocks:seq Integers.int)
 (eligible:seq Integers.int->'cV['F_2]_n->Prop).
Variables (gv:globals) (budget base:Values.val) (stride:Z) (outside:Values.val->mpred)
 (flip dfs:funspec).
Let levels:=Z.of_nat n.
Let heap:=index_flip_heap c p keys mask tab links initial
 (fun s=>(visit_storage s budget levels*outside s)%logic).
Let rec_heap:=weight_bounded_rows base stride levels heap.
Definition closed_entry:entry_domain:=fun _ _ _ bp w st words=>
 bp=pb p /\ reachable_prefix n st words /\ (Zlength words<w)%coqZ /\ odd_count (payload_after Bare keys initial words)=0%coqZ.
Definition closed_call:=index_dfs_using_globals gv closed_entry rec_heap
 (recursive_report H S G eligible) (stored_css_prefix H S) Int.zero.
Hypotheses (orth:H*m S^T=0) (det:G*m S^T=0) (shape:(\rank (col_mx H G)+\rank S=n)%N)
 (row_cap:(Z.of_nat m<=Int.max_signed)%coqZ)
 (idx:@table_for_lookup m n H columns rowkey keys mask cap bits tab links c p)
 (base_safe:book_safe (table_book keys mask (checksum initial) tab links initial_blocks) (words_at initial) (odd_count initial))
 (packed_init:@encoded_at m n k G columns Bare initial)
 (zero:pcm_response H G rowkey (0:'cV['F_2]_n) initial).

Theorem closed_call_body:semax_body prepared_vars (index_callees H rows flip dfs) f_dfs closed_call.
Proof.
 have checked:=proj1 (proj2 (@native_base_cases_in_recursive_context m n H rows flip dfs)).
 eapply semax_body_funspec_sub;[exact checked| |].
 2:{ apply compute_list_norepet_e;vm_compute;reflexivity. }
 rename gv into static_globals;unfold closed_call,index_dfs_using_globals.
 do_funspec_sub;destruct w as [[[[[[[[geom0 s] cp] bp] wt] d] st] cells] saved];cbn [fst snd];normalize.
 match goal with h:closed_entry _ _ _ _ _ _ _ |- _=>
    destruct h as [-> [[ids [unique [prefix [blocks protected]]]] [early closed]]] end.
 have at_depth:Zlength (active_prefix d cells)=d by unfold active_prefix;rewrite Zlength_sublist;lia.
 have id_size:Z.of_nat (size ids)=d by move:at_depth;rewrite prefix /literal_path Zlength_map Zlength_correct.
 have fit:(levels<=Int.max_signed)%coqZ by rewrite /levels -(all_keys idx);exact:(qubits_fit _ _ _ base_safe).
 have [encoded [off rows_same word_count ms sz] physical]:=
    @emitted_path_matches_pcm m n k H G rowkey columns Bare keys fit ids initial
       (row_capacity idx) (no_duplicate_rows idx) (pcm_incidence idx) (fun _=>List.Forall_nil _)
       (stored_keys idx) unique packed_init zero.
 pose t:=payload_after Bare keys initial (literal_path ids).
 rewrite prefix in closed;fold t in closed,physical,word_count.
 have kb:=column_safe _ _ _ base_safe 0%coqZ (conj (Z.le_refl 0) (nonempty_keys idx)).
 have wide:(0<width (words_at t)<=Int.max_signed)%coqZ by rewrite word_count;unfold close_safe in kb;tauto.
 have split_heap:=@closed_arena_split c s cp p budget base stride levels wt (OverlapColumnState.blocked st) cells
    keys mask tab links initial (literal_path ids) outside saved (proj1 wide) closed.
 unfold rec_heap,heap;rewrite prefix -sepcon_assoc split_heap;Intros nodes counts cl leaves.
 pose hold:=closed_frame s cp p (OverlapColumnState.blocked st) cells keys mask tab links initial
      (literal_path ids) base stride levels outside leaves.
 Exists (s,nullval,budget,ppar (words_at t),wt,d,parities (words_at t),counts,nodes,cl,saved,Int.zero) hold.
 apply andp_right.
 - unfold width in wide;entailer!;try lia;try cancel;try apply derives_refl.
   unfold hold,t;rewrite sepcon_comm;apply derives_refl.
 - apply prop_right;intro rho;normalize.
   pose yes:=packed_detects (parities (words_at t)).
   pose code:=(if yes then 3 else 0)%coqZ.
   pose written:=if yes then Int.repr d else saved.
   have observed:pcm_response H G rowkey (vector_on (0:'cV['F_2]_n) ids) t
     by rewrite (path_is_its_indicator unique).
   have report:recursive_result H S G eligible wt st (literal_path ids) code cells.
   { unfold code,yes;eapply early_closed_has_valid_shorter_witness;try eassumption;rewrite ?id_size;try assumption;lia. }
   have status:witness_at_limit wt saved code written cells by apply closed_pair_register;lia.
   have terminal:=@terminal_report_from_pcm m n r k H S G columns rowkey keys mask cap bits tab links c p
      initial initial_blocks eligible orth det shape idx base_safe ids st cells t saved unique
      ltac:(rewrite id_size;lia) ltac:(rewrite id_size;lia) ltac:(rewrite id_size;exact prefix) physical.
   cbn zeta in terminal;rewrite id_size /leaf_accept closed /= in terminal;fold yes written in terminal.
   have reg:witness_status code -> stored_css_prefix H S (Int.signed written) cells.
   { move=>hit;apply (proj2 (proj2 terminal));unfold code,witness_status in hit|-*;destruct yes;intuition congruence. }
   Exists cells code written.
   have restore:=@closed_arena_split c s cp p budget base stride levels wt (OverlapColumnState.blocked st) cells
          keys mask tab links initial (literal_path ids) outside written (proj1 wide) closed.
   unfold rec_heap,heap;rewrite prefix;fold yes code written.
   have limit:(0<=code<=3)%coqZ by unfold code;destruct yes;lia.
   apply andp_right;first by apply prop_right;unfold recursive_report;tauto.
   apply andp_right;first by apply prop_right;repeat split;try discriminate;unfold code,yes;congruence.
   rewrite !sepcon_emp;first [rewrite restore|rewrite -sepcon_assoc restore].
   apply andp_right;first by apply prop_right;split;[lia|assumption].
   Exists (Int64.add nodes Int64.one) (PreparedDFSClosed.bump counts (wt-d)%coqZ) (Int64.add cl Int64.one) leaves.
   apply andp_right.
   { apply prop_right;unfold PreparedDFSClosed.bump;rewrite upd_Znth_Zlength;lia. }
   unfold hold,t;rewrite sepcon_comm;apply derives_refl.
Qed.
End Closed.
