(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VerifDetected VerifClosesBody VerifToggleBody VerifChildVisit VerifFlipBody
 VerifLookup NativeFlipPayload OverlapColumnState NativeDepthFlip PreparedDFSClosed PreparedDFSTerminal
 PreparedIndexBaseCases PreparedIndexWitnessLeaf PreparedCounterJoin PreparedIndexArena PreparedWitnessRegister
 PreparedFlip PreparedLeafWorkspace flag_level_ast.
#[local] Existing Instance VerifDetected.CompSpecs.
Local Open Scope Z_scope.

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

Section Terminal.
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
Definition terminal_entry:entry_domain:=fun _ _ _ bp w st words=>
 bp=pb p /\ reachable_prefix n st words /\ Zlength words=w.
Definition terminal_call:=index_dfs_using_globals gv terminal_entry rec_heap
 (recursive_report H S G eligible) (stored_css_prefix H S) Int.zero.
Hypotheses (orth:H*m S^T=0) (det:G*m S^T=0) (shape:(\rank (col_mx H G)+\rank S=n)%N)
 (row_cap:(Z.of_nat m<=Int.max_signed)%coqZ)
 (idx:@table_for_lookup m n H columns rowkey keys mask cap bits tab links c p)
 (base_safe:book_safe (table_book keys mask (checksum initial) tab links initial_blocks) (words_at initial) (odd_count initial))
 (packed_init:@encoded_at m n k G columns Bare initial)
 (zero:pcm_response H G rowkey (0:'cV['F_2]_n) initial).

Lemma terminal_report_from_pcm (ids:seq 'I_n) st cells (t:packed_support) saved:
 let w:=Z.of_nat (size ids) in let yes:=leaf_accept (odd_count t) (parities (words_at t)) in
 let code:=if yes then 1%coqZ else 0%coqZ in let written:=if yes then Int.repr w else saved in
 uniq ids -> (0<w<=Int.max_signed)%coqZ -> (w<=Zlength cells)%coqZ ->
 active_prefix w cells=literal_path ids ->
 pcm_response H G rowkey (indicator [set q:'I_n | q \in ids]) t ->
 recursive_result H S G eligible w st (literal_path ids) code cells /\
 witness_at_limit w saved code written cells /\
 (witness_status code -> stored_css_prefix H S (Int.signed written) cells).
Proof.
 move=>w yes code written unique width room trace physical.
 have fit:(levels<=Int.max_signed)%coqZ by rewrite /levels -(all_keys idx);exact:(qubits_fit _ _ _ base_safe).
 rewrite -(path_is_its_indicator unique) in physical.
 have yes_model:yes=((H*m vector_on (0:'cV['F_2]_n) ids==0) &&
                 ~~((vector_on (0:'cV['F_2]_n) ids)^T<=S)%MS)%bool.
 { rewrite /yes (physical_terminal physical).
   case closed:(H*m vector_on (0:'cV['F_2]_n) ids==0)=> //=.
   by rewrite (validated_detector orth det shape (eqP closed)). }
 have model:code=Int.signed (@result_word m r n H S ids None).
 { unfold code,result_word;rewrite -yes_model;by destruct yes. }
 have reaches:=@terminal_at_actual_budget m n r k H S G eligible ids st fit unique orth det shape None cells ltac:(lia) trace.
 rewrite -model in reaches;split;first exact reaches.
 move:reaches;unfold code,written;case live:yes=>certificate.
 - split;first by unfold witness_at_limit;intuition (try lia;try congruence).
   move=>_;rewrite Int.signed_repr;last by change Int.min_signed with (-2147483648)%coqZ;lia.
   exact:(proj1 (proj2 certificate) Logic.eq_refl).
 - split;[unfold witness_at_limit|unfold witness_status];intuition (try lia;try congruence).
Qed.
(* A terminal call is made with the very same recursive storage as a deep
   call. The target weight is obtained from the represented prefix. *)
Theorem terminal_call_body:semax_body prepared_vars (index_callees H rows flip dfs) f_dfs terminal_call.
Proof.
 have checked:=proj1 (@native_base_cases_in_recursive_context m n H rows flip dfs).
 eapply semax_body_funspec_sub;[exact checked| |].
 2:{ apply compute_list_norepet_e;vm_compute;reflexivity. }
 rename gv into static_globals;unfold terminal_call,index_dfs_using_globals.
 do_funspec_sub;destruct w as [[[[[[[[geom0 s] cp] bp] wt] d] st] cells] saved];cbn [fst snd];normalize.
 match goal with h:terminal_entry _ _ _ _ _ _ _ |- _=>
    destruct h as [-> [[ids [unique [prefix [blocks protected]]]] at_bound]] end.
 have at_depth:Zlength (active_prefix d cells)=d by unfold active_prefix;rewrite Zlength_sublist;lia.
 have dw:d=wt by lia.
 clear at_bound;subst wt.
 have id_size:Z.of_nat (size ids)=d by move:at_depth;rewrite prefix /literal_path Zlength_map Zlength_correct.
 have fit:(levels<=Int.max_signed)%coqZ by rewrite /levels -(all_keys idx);exact:(qubits_fit _ _ _ base_safe).
 have [encoded [off rows_same word_count ms sz] physical]:=
    @emitted_path_matches_pcm m n k H G rowkey columns Bare keys fit ids initial
       (row_capacity idx) (no_duplicate_rows idx) (pcm_incidence idx) (fun _=>List.Forall_nil _)
       (stored_keys idx) unique packed_init zero.
 pose t:=payload_after Bare keys initial (literal_path ids).
 fold t in physical,word_count.
 have odd_bound:=@count_at_leaf m n k H G (indicator [set a:'I_n | a \in ids]) rowkey t row_cap physical.
 have kb:=column_safe _ _ _ base_safe 0%coqZ (conj (Z.le_refl 0) (nonempty_keys idx)).
 have wide:(0<width (words_at t)<=Int.max_signed)%coqZ by rewrite word_count;unfold close_safe in kb;tauto.
 have split_heap:=@terminal_arena_split c s cp p budget base stride levels d (OverlapColumnState.blocked st) cells
    keys mask tab links initial (literal_path ids) outside saved (proj1 wide).
 unfold rec_heap,heap;rewrite prefix.
 rewrite -sepcon_assoc split_heap;Intros nodes counts.
 pose hold:=terminal_frame s cp p (OverlapColumnState.blocked st) cells keys mask tab links initial
      (literal_path ids) base stride levels outside.
 Exists (s,nullval,budget,ppar (words_at t),d,odd_count t,parities (words_at t),nodes,counts,saved,Int.zero) hold.
 apply andp_right.
 - unfold width in wide;entailer!;try lia;try cancel;try apply derives_refl.
   unfold hold,t;rewrite sepcon_comm;apply derives_refl.
 - apply prop_right;intro rho;normalize.
   pose yes:=leaf_accept (odd_count t) (parities (words_at t)).
   pose code:=(if yes then 1 else 0)%coqZ.
   pose written:=(if yes then Int.repr d else saved).
   have cert:=@terminal_report_from_pcm ids st cells t saved unique
      ltac:(rewrite id_size;lia) ltac:(rewrite id_size;lia) ltac:(rewrite id_size;exact prefix) physical.
   cbn zeta in cert;rewrite id_size in cert;fold yes code written in cert.
   destruct cert as [report [status reg]].
   Exists cells code written.
   have restore:=@terminal_arena_split c s cp p budget base stride levels d (OverlapColumnState.blocked st) cells
          keys mask tab links initial (literal_path ids) outside written (proj1 wide).
   unfold rec_heap,heap;rewrite prefix;fold yes written.
   have limit:(0<=code<=3)%coqZ by unfold code;destruct yes;lia.
   have rc:(if yes then Int.one else Int.zero)=Int.repr code by unfold code;destruct yes;reflexivity.
   apply andp_right;first by apply prop_right;unfold recursive_report;tauto.
   apply andp_right.
   { apply prop_right;repeat split;try discriminate;rewrite -rc;unfold yes;congruence. }
   rewrite !sepcon_emp.
   first [rewrite restore |rewrite -sepcon_assoc restore].
   apply andp_right;first by apply prop_right;split;[lia|assumption].
   Exists (Int64.add nodes Int64.one) (PreparedDFSClosed.bump counts 0%coqZ).
   apply andp_right.
   { apply prop_right;unfold PreparedDFSClosed.bump;rewrite upd_Znth_Zlength;lia. }
   unfold hold,t;rewrite sepcon_comm;apply derives_refl.
Qed.
End Terminal.
