(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VerifDetected VerifChildVisit VerifClosesBody VerifFlipBody VerifLookup
 NativeFlipPayload NativeDepthFlip OverlapColumnState PreparedWitnessRegister PreparedIndexWitnessLeaf
 PreparedCounterJoin PreparedIndexArena PreparedLeafWorkspace PreparedIndexBaseCases PreparedIndexTerminal
 PreparedDFSClosed PreparedDFSOneLeft VerifOneLeft PreparedPairStorage VerifToggleBody BuiltLookup HashLookup PreparedFlip flag_level_ast.
#[local] Existing Instance VerifDetected.CompSpecs.
Local Open Scope Z_scope.

Lemma return_separated_triple (from x y z:mpred):
 (from |-- (x*y)*z) -> (from |-- x*(y*z)).
Proof. intro returns;eapply derives_trans;[exact returns|cancel;try apply derives_refl]. Qed.

Definition single_leaf_counter s:mpred:=EX leaves:int64,field_at Tsh level_type [StructField _leaf1] (Vlong leaves) s.
Definition last_frame s base stride levels words (outside:val->mpred):=
 (independent_leaf_counters s * outside s * live_arena base stride levels (Zlength (words:list int)))%logic.

Lemma last_arena_split c s cp p budget base stride levels w blocks cells ks mask tab links init words outside saved:
 let t:=payload_after Bare ks init words in let v:=words_at t in
 let b:=table_book ks mask (checksum t) tab links blocks in
 let heap:=index_flip_heap c p ks mask tab links init
  (fun level=>(visit_storage level budget levels*(single_leaf_counter level*outside level))%logic) in
 (child_fields s cp (pb p) w blocks cells * weight_bounded_rows base stride levels heap w s words *
   witness_register s saved)%logic =
 (!!(w<=levels /\ physical_prefix c words) &&
 (EX nodes:int64,EX counts:list int64,EX leaves:int64,!!(Zlength counts=levels) &&
   (PreparedDFSOneLeft.one_left_fields s budget cp w counts cells nodes leaves saved *
     close_mem Tsh s (odd_count t) v * book_mem s b p * last_frame s base stride levels words outside)))%logic.
Proof.
 intros t v b heap;unfold heap,weight_bounded_rows,depth_rows,index_flip_heap,physical_store,visit_storage,
   single_leaf_counter,last_frame,PreparedDFSOneLeft.one_left_fields,close_mem,book_mem,child_fields,packed_mem,toggle_mem,
   tally_cells,witness_register,static_leaf_index,lookup_index.
 unfold b,v,width;cbn [table_book slots HashLookup.mask HashLookup.links HashLookup.keys
    HashLookup.blocked query policy_storage];fold t.
 apply pred_ext;Intros nodes counts leaves;Exists nodes counts leaves;first [solve [normalize;cancel;apply derives_refl]|entailer!;cancel;try apply derives_refl].
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
Require Import PreparedInitialLookup PreparedFinalLookup PreparedLookupMatrix PreparedPlainPhysicalPair ClosureMatrix BuiltPCM LeafAPI PCMLeafAPI.
Section Last.
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
 (fun s=>(visit_storage s budget levels*(single_leaf_counter s*outside s))%logic).
Let rec_heap:=weight_bounded_rows base stride levels heap.
Definition last_entry:entry_domain:=fun _ _ _ bp w st words=>
 bp=pb p /\ reachable_prefix n st words /\ Zlength words=(w-1)%coqZ /\ odd_count (payload_after Bare keys initial words)<>0%coqZ.
Definition last_call:=index_dfs_using_globals gv last_entry rec_heap
 (recursive_report H S G eligible) (stored_css_prefix H S) Int.zero.
Hypotheses (orth:H*m S^T=0) (det:G*m S^T=0) (shape:(\rank (col_mx H G)+\rank S=n)%N)
 (row_cap:(Z.of_nat m<=Int.max_signed)%coqZ)
 (idx:@table_for_lookup m n H columns rowkey keys mask cap bits tab links c p)
 (base_safe:book_safe (table_book keys mask (checksum initial) tab links initial_blocks) (words_at initial) (odd_count initial))
 (packed_init:@encoded_at m n k G columns Bare initial)
 (zero:pcm_response H G rowkey (0:'cV['F_2]_n) initial).

(* Derive the hash probe from the constructor and current PCM. No lookup
   answer, or oracle for the physical qubit, is an argument of the C call. *)
Lemma last_probe_from_pcm ids st:
 uniq ids -> Zlength (OverlapColumnState.blocked st)=levels ->
 (forall q:'I_n,q \in ids -> Znth (Z.of_nat q) (OverlapColumnState.blocked st)<>Int.zero) ->
 let t:=payload_after Bare keys initial (literal_path ids) in
 let v:=words_at t in let b:=table_book keys mask (checksum t) tab links (OverlapColumnState.blocked st) in
 let P:=[set q:'I_n | q \in ids] in
 odd_count t<>0%coqZ ->
 pcm_response H G rowkey (indicator P) t /\ (0<odd_count t<=Int.max_signed)%coqZ /\
 book_safe b v (odd_count t) /\ exists a,probe_run b v (odd_count t) (origin b) a /\
     leaf_answer (pcm_completion H G P (@available_now n st)) levels a.
Proof.
 move=>unique blocks protected t v b P open_node.
 have [built positive dim spare period bits_ok low fit no_dup incidence stored alias]:=idx.
 have reached:=@reached_leaf_from_initial m n k H G rowkey columns Bare keys mask tab links initial
    initial_blocks row_cap dim positive no_dup incidence (fun _=>List.Forall_nil _) stored packed_init zero base_safe
    st ids unique ltac:(rewrite blocks dim;reflexivity) protected.
 have [dis enc physical safe [odd pars]]:=reached;fold t v b P in dis,enc,physical,safe,odd,pars.
 have ready:=safe open_node.
 have layout:forall a:'I_n,@ClosureMatrix.layout m n k H G (indicator P) a (columns a) v.
 { move=>a;have aj:=elimT ltP (ltn_ord a).
   have valid:(0<=Z.of_nat a<Zlength (HashLookup.keys b))%coqZ by change (0<=Z.of_nat a<Zlength keys)%coqZ;rewrite dim;lia.
   have [_ [_ [bounds [ends _]]]]:=VerifLookup.column_safe _ _ _ ready _ valid.
   have [csr [_ [column [width room]]]]:=enc a.
   exact:(@matrix_view_for_lookup m n k H G (indicator P) rowkey a (columns a) t fit (no_dup a)
      (incidence a) (conj bounds ends) csr column width physical). }
 have [response [detector hash]]:=physical.
 have actual:odd_count t=Z.of_nat #|LeafMatrix.support (H*m indicator P)| by exact:(proj2 (proj2 response)).
 have [qs image]:=@constructor_pcm_image m n k H G P (@available_now n st) v columns rowkey keys mask
    (checksum t) cap bits tab links (OverlapColumnState.blocked st) built positive dim spare period bits_ok low dis
    (@available_in_view n st) layout hash stored.
 rewrite -actual in image.
 have [a [run decision]]:=@checked_answer _ b v (odd_count t) qs ready image.
 have extent_ok:extent b=levels by exact dim.
 rewrite extent_ok in decision;split;[exact physical|split;[lia|split;[exact ready|by exists a]]].
Qed.

Theorem last_call_body:semax_body prepared_vars (index_callees H rows flip dfs) f_dfs last_call.
Proof.
 have checked:=proj2 (proj2 (@native_base_cases_in_recursive_context m n H rows flip dfs)).
 eapply semax_body_funspec_sub;[exact checked| |].
 2:{ apply compute_list_norepet_e;vm_compute;reflexivity. }
 rename gv into static_globals;unfold last_call,index_dfs_using_globals.
 do_funspec_sub;destruct w as [[[[[[[[geom0 s] cp] bp] wt] d] st] cells] saved];cbn [fst snd];normalize.
 match goal with h:last_entry _ _ _ _ _ _ _ |- _=>
    destruct h as [-> [[ids [unique [prefix [blocks protected]]]] [last_step live]]] end.
 have at_depth:Zlength (active_prefix d cells)=d by unfold active_prefix;rewrite Zlength_sublist;lia.
 have id_size:Z.of_nat (size ids)=d by move:at_depth;rewrite prefix /literal_path Zlength_map Zlength_correct.
 have wt_eq:wt=(d+1)%coqZ by lia.
 subst wt;rewrite prefix in live.
 have fit:(levels<=Int.max_signed)%coqZ by rewrite /levels -(all_keys idx);exact:(qubits_fit _ _ _ base_safe).
 pose t:=payload_after Bare keys initial (literal_path ids).
 pose b:=table_book keys mask (checksum t) tab links (OverlapColumnState.blocked st).
 have [physical [odd [safe [a [run decision]]]]]:=@last_probe_from_pcm ids st unique blocks protected live.
 fold t b in physical,odd,safe,run,decision,live.
 have split_heap:=@last_arena_split c s cp p budget base stride levels (d+1)%coqZ (OverlapColumnState.blocked st) cells
    keys mask tab links initial (literal_path ids) outside saved.
 unfold rec_heap,heap;rewrite prefix -sepcon_assoc split_heap;Intros nodes counts leaves.
 pose hold:=last_frame s base stride levels (literal_path ids) outside.
 Exists (s,budget,cp,p,b,words_at t,odd_count t,a,d,counts,cells,nodes,leaves,saved,nullval,Int.zero) hold.
 apply andp_right.
 - entailer!;try lia;try cancel;try apply derives_refl.
   unfold hold,t,b;cancel;try apply derives_refl.
 - apply prop_right;intro rho;normalize.
   pose tail:=last_path d a cells;pose code:=final_pick a;pose written:=last_size (d+1)%coqZ a saved.
   have room:(d<Zlength cells)%coqZ by lia.
   have nonempty:ids!=[::] by apply/eqP=>empty;move:id_size;rewrite empty /=;lia.
   have report:=@final_lookup_proves_recursive_verdict m n r k H S G eligible ids st rowkey t cells a
     orth det shape fit unique nonempty ltac:(rewrite id_size;lia) ltac:(rewrite id_size;exact prefix) physical live decision.
   rewrite id_size in report;fold code tail in report.
   have status:witness_at_limit (d+1)%coqZ saved code written tail by apply open_pair_register;lia.
   have reg:witness_status code -> stored_css_prefix H S (Int.signed written) tail.
   { have hit:=proj1 (proj2 report).
     unfold code,written,final_pick,last_size,witness_status;destruct (Z_lt_dec a 0);first by intuition discriminate.
     rewrite Int.signed_repr;last by change Int.min_signed with (-2147483648)%coqZ;lia.
     move=>_;apply hit;unfold code,final_pick;destruct (Z_lt_dec a 0);lia. }
   have size:Zlength tail=Zlength cells by unfold tail,last_path;destruct (Z_lt_dec a 0);rewrite ?upd_Znth_Zlength;lia.
   have trace:active_prefix d tail=literal_path ids.
   { unfold tail,last_path;destruct (Z_lt_dec a 0);first exact prefix.
     unfold active_prefix;rewrite sublist_upd_Znth_l;try lia;exact prefix. }
   have limit:(0<=code<=3)%coqZ by unfold code,final_pick;destruct (Z_lt_dec a 0);lia.
   Exists tail code written.
   have restore:=@last_arena_split c s cp p budget base stride levels (d+1)%coqZ (OverlapColumnState.blocked st) tail
        keys mask tab links initial (literal_path ids) outside written.
   unfold rec_heap,heap;rewrite ?prefix.
   apply andp_right;first by apply prop_right;unfold recursive_report;tauto.
   apply andp_right.
   { apply prop_right;repeat split;try discriminate;try assumption;unfold code;try congruence.
     all: try solve [unfold final_pick in *;destruct (Z_lt_dec a 0);congruence].
 }
   rewrite ?sepcon_emp.
   fold tail written t b;fold tail written t b in restore.
   apply return_separated_triple;cbn zeta in restore;rewrite restore.
   apply andp_right;first by apply prop_right;split;[lia|assumption].
   Exists (Int64.add nodes Int64.one) (PreparedDFSClosed.bump counts 1%coqZ) (Int64.add leaves Int64.one).
   apply andp_right.
   { apply prop_right;unfold PreparedDFSClosed.bump;rewrite upd_Znth_Zlength;lia. }
   unfold hold,b,t,tail,written;cancel;try apply derives_refl.
Qed.
End Last.
