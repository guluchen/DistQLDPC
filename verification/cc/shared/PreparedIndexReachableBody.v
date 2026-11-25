(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.floyd.reassoc_seq VerifDetected VerifChildVisit VerifClosesBody VerifLookup VerifFlipBody
 HashLookup BuiltLookup NativeFlipPayload NativeDepthFlip EnabledCall EnabledLoopFacts SiblingCounters
 OverlapColumnState PreparedSeedDispatch PreparedRootStages PreparedChildCall PreparedDepthSpec
 PreparedBudgetContract PreparedSiblingScan PreparedRecursiveCall PreparedWitnessRegister PreparedPlainDescent
 PreparedPlainSiblings PreparedPlainReachable PreparedPlainPCMScan PreparedPCMChooser PreparedIndexFinish
 PreparedIndexWhile PreparedIndexNodeReport PreparedIndexWitnessCall PreparedIndexWitnessScan
 PreparedIndexWitnessUndo PreparedIndexWitnessLeaf PreparedSiblingRestore PreparedVerdictExit PreparedSampling PreparedCallerLocals.
Require Import PreparedIndexGlobals PreparedIndexGlobalTree.
Require Import PreparedChooserStorage PreparedInitializeScan PreparedSelectedReturn PreparedIndexReuse.
Require Import VerifToggleBody VerifClosedPrefix PreparedDFSRejected PreparedInteriorGuards PreparedCounterJoin PreparedInteriorEntry PreparedCandidateArena PreparedCandidateSlice PreparedArenaContext PreparedIndexCall PreparedIndexWitnessParent PreparedIndexContiguous PreparedIndexLink PreparedNativeCallees PreparedUniformIndex PreparedIndexSyndromeLoan PreparedChoiceCall PreparedChooseReturn PreparedLeafWorkspace.
From mathcomp Require Import all_ssreflect all_algebra.
Require Import PreparedMatrixPath PreparedMatrixResponse PreparedInteriorReport PreparedObservedWitness
 PreparedPCMLeafVisit LeafMatrix LevelSearch NativePackingScan IndexRowBridge flag_level_ast.
#[local] Existing Instance VerifDetected.CompSpecs.
Set Implicit Arguments.
Unset Strict Implicit.
Local Open Scope ring_scope.
Local Delimit Scope Z_scope with coqZ.

Require Import PreparedIndexSelected PreparedIndexArena PreparedIndexSite PreparedLeafAtPath PreparedReusableBook.
Section Reachable.
Variable Espec:OracleKind.
#[local] Existing Instance Espec.
Variables m n r k:nat.
Variables (H:'M['F_2]_(m,n)) (S:'M['F_2]_(r,n)) (G:'M['F_2]_(k,n))
 (rows:'I_m->seq 'I_n) (columns:'I_n->seq 'I_m) (rowkey:'I_m->int64)
 (keys:seq int64) (mask:int64) (cap bits:Z) (tab links:seq Z) (c:policy_state) (p:lookup_ptrs)
 (initial:packed_support) (initial_blocks:seq Integers.int)
 (eligible:seq Integers.int->'cV['F_2]_n->Prop) (root:snapshot) (parent:seq 'I_n)
 (offsets:seq Z) (cols:seq Integers.int) (remaining:nat).
Let P:=[set a:'I_n | a \in parent].
Let node:=literal_path parent.
Let w:=Z.of_nat (size parent+remaining)%N.
Let d:=Z.of_nat (size parent).


Variables (gv:globals) (sh:share) (s cp base budgetp op qp mp:Values.val) (stride:Z) (pollmask:int64)
 (extra:Values.val->mpred) (cells:seq Integers.int) (saved:Integers.int) (ptr:Values.val).
Let levels:=Z.of_nat n.
Let cur:=payload_after Bare keys initial node.
Let nw:=Zlength (syndrome (words_at initial)).
Let buffer:=row_pointer base stride d.
Let companion level:=(visit_storage level budgetp levels * mask_field level pollmask * extra level)%logic.
Let frame level:=(candidate_fields level base stride * companion level)%logic.
Let storage level:=reusable_index gv sh level op qp mp offsets cols nw levels.
Let work level:=(storage level * frame level)%logic.
Let heap:=index_flip_heap c p keys mask tab links initial work.
Let rec_heap:=weight_bounded_rows base stride levels heap.
Let loan:=live_arena base stride levels (d+1)%coqZ.
Let entry:entry_domain:=fun geom level trace blocks _ st words=>
 geom=geometry c /\ level=s /\ trace=cp /\ blocks=pb p /\ reachable_prefix n st words.
Let report:=recursive_report H S G eligible.
Let witness:=stored_css_prefix H S.
Let flip:=snd (depth_flip c heap Int.zero).
Let dfs:=snd (index_dfs_using_globals gv entry rec_heap report witness Int.zero).
Let D:=func_tycontext f_dfs prepared_vars (index_callees H rows flip dfs) nil.
Let owned path written:=(child_fields s cp (pb p) w (blocked root) path *
    rec_heap w s node * witness_register s written)%logic.
Let args:=(Z*(Z*(seq Integers.int*Integers.int)))%type.
Let result:ret_assert:=existential_ret_assert (fun v:args=>function_body_ret_assert tint
    (PROP(recursive_result H S G eligible w root node v.2.1 v.2.2.1 /\ (0<=v.2.1<=3)%coqZ /\
      Zlength v.2.2.1=Zlength cells /\ active_prefix d v.2.2.1=node /\ witness_at_limit w saved v.2.1 v.2.2.2 v.2.2.1 /\
      (witness_status v.2.1 -> witness (Int.signed v.2.2.2) v.2.2.1))
     LOCAL(temp ret_temp (Vint (Int.repr v.2.1))) SEP(data_at_ Tsh sample_type ptr;owned v.2.2.1 v.2.2.2)))%assert.

Hypotheses (orth:H*m S^T=0) (det:G*m S^T=0) (shape:(\rank (col_mx H G)+\rank S=n)%N)
 (row_cap:(Z.of_nat m<=Int.max_signed)%coqZ)
 (idx:@table_for_lookup m n H columns rowkey keys mask cap bits tab links c p)
 (base_safe:book_safe (table_book keys mask (checksum initial) tab links initial_blocks) (words_at initial) (odd_count initial))
 (packed_init:@encoded_at m n k G columns Bare initial) (zero:pcm_response H G rowkey (0:'cV['F_2]_n) initial)
 (plain:nested_policy (nested c)=nullval) (distinct:forall i,uniq (rows i))
 (covers:forall i q,H i q!=0 -> q \in rows i)
 (maxrow:forall i,(Zlength (encoded rows i)<=Int.max_signed)%coqZ)
 (offset_size:Zlength offsets=(Z.of_nat m+1)%coqZ)
 (csr:forall i:'I_m,let lo:=Znth (Z.of_nat i) offsets in let hi:=Znth (Z.of_nat i+1)%coqZ offsets in
    (0<=lo<=hi)%coqZ /\ (hi<=Int.max_unsigned)%coqZ /\ (hi<=Zlength cols)%coqZ /\ sublist lo hi cols=encoded rows i)
 (capacity:forall i:'I_m,(Znth (Z.of_nat i+1)%coqZ offsets-Znth (Z.of_nat i) offsets<=stride)%coqZ)
 (step:(0<=stride<=Int.max_signed)%coqZ)
 (padding:forall i,(0<=i<nw)%coqZ -> Znth i (syndrome (words_at initial))=Int64.zero)
 (word_cap:(nw<=Int.max_signed)%coqZ) (share_ok:readable_share sh)
 (colroom:(levels<Zlength (column_offsets (geometry c)))%coqZ)
 (inherit:forall x (a:'I_n),eligible node x -> eligible (node++[::Int.repr (Z.of_nat a)]) x).

Theorem reachable_deep_index_body:
 uniq parent -> Zlength (blocked root)=levels ->
 (forall q:'I_n,q \in parent -> Znth (Z.of_nat q) (blocked root)<>Int.zero) ->
 active_prefix d cells=node -> (w<=Zlength cells)%coqZ -> (1<=d<=w-2)%coqZ ->
 (w<=levels)%coqZ -> odd_count cur<>0%coqZ -> isptr base -> is_pointer_or_null s ->
 semax D (PROPx nil (LOCALx (guard_loc s (nested_policy (nested c)) d Int.zero ptr++[::gvars gv])
       (SEPx [::data_at_ Tsh sample_type ptr;owned cells saved]))) (fn_body f_dfs) result.
Proof.
 move=>unique width protected prefix room depth fits live address valid.
 have fit:(levels<=Int.max_signed)%coqZ by rewrite /levels -(all_keys idx);exact:(qubits_fit _ _ _ base_safe).
 have positive:(0<levels<=Int.max_signed)%coqZ by split;[rewrite /levels -(all_keys idx);exact:(nonempty_keys idx)|exact fit].
 have signed:(w<=Int.max_signed)%coqZ by lia.
 have len:Zlength node=d by rewrite /node /literal_path Zlength_map Zlength_correct.
 have open_node:(d<levels)%coqZ by lia.
 have [enc [same_off same_rs same_kw same_mask same_words] physical]:=
    @emitted_path_matches_pcm m n k H G rowkey columns Bare keys fit parent initial
       (row_capacity idx) (no_duplicate_rows idx) (pcm_incidence idx) (fun _=>List.Forall_nil _)
       (stored_keys idx) unique packed_init zero.
 have allowed:=@count_at_leaf m n k H G (indicator P) rowkey cur row_cap physical.
 have bound:(0<odd_count cur<=Int.max_signed)%coqZ by lia.
 fold cur in same_words.
 pose old:=nseq (Z.to_nat stride) Int.zero.
 pose tags:=nseq n Int64.zero.
 have old_len:Zlength old=stride.
 { rewrite Zlength_correct;change (Z.of_nat (size old)=stride);rewrite /old size_nseq Z2Nat.id;lia. }
 have tags_len:Zlength tags=levels.
 { rewrite Zlength_correct;change (Z.of_nat (size tags)=levels);by rewrite /tags size_nseq. }
 have legal:=@reached_choice_is_legal m n k H G rows columns rowkey keys initial offsets cols stride row_cap
    positive covers offset_size csr capacity (proj2 step) (no_duplicate_rows idx) (pcm_incidence idx) (stored_keys idx)
    packed_init zero padding word_cap gv sh s op qp (pb p) mp buffer root parent remaining old
    Int64.zero Int64.zero Int64.zero tags unique width tags_len old_len share_ok ltac:(lia) signed live.
 have lend:forall sub,Zlength sub=(d+1)%coqZ -> rec_heap w s sub=(heap s sub*loan)%logic
    by move=>sub sublen;exact:(lend_bounded_child _ _ _ _ _ _ _ _ fits sublen).
 have split_mem path written:
    owned path written=(child_fields s cp (pb p) w (blocked root) path * ready_row buffer stride *
       heap s node * loan * witness_register s written)%logic
    by exact:(@bounded_activation_owns_row base stride levels heap w s cp (pb p) (blocked root) path written node d fits ltac:(lia) len).
 have out:is_pointer_or_null buffer by unfold buffer,row_pointer;destruct base;cbn in address |- *;tauto.
 unfold reached_site in legal.
 pose proof (@deep_open_dfs_body Espec m n r k H S G rows columns rowkey keys mask cap bits tab links c p initial
   initial_blocks eligible root parent offsets cols remaining gv sh op qp mp nw frame orth det shape row_cap idx
   base_safe packed_init zero plain width unique protected distinct covers maxrow rec_heap s cp buffer cells loan
   Int.zero saved room depth signed ltac:(rewrite width;exact colroom) prefix lend inherit old Int64.zero Int64.zero
   Int64.zero tags ptr (Int.repr (-1)) Float.zero Float.zero base budgetp levels pollmask (extra s)
   ltac:(rewrite old_len;reflexivity)) as raw.
 rewrite old_len in raw.
 specialize (raw Logic.eq_refl address step legal (Logic.eq_sym same_words) bound ltac:(lia)
     Logic.eq_refl Logic.eq_refl Logic.eq_refl Logic.eq_refl Logic.eq_refl Logic.eq_refl Logic.eq_refl valid out).
 have same_heap:owned=(fun path written=>(child_fields s cp (pb p) w (blocked root) path *
    ready_row buffer stride * heap s node * loan * witness_register s written)%logic).
 { extensionality path;extensionality written;apply split_mem. }
 unfold result;rewrite same_heap;exact raw.
Qed.
End Reachable.
