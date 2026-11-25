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
Require Import PreparedIndexReachableBody.
From Coq Require Import Logic.FunctionalExtensionality.
Require Import PreparedIndexCallable PreparedIndexTerminalCall PreparedIndexClosedCall PreparedIndexOneLeftCall PreparedIndexBranches.
Section Unified.
Variables m n r k:nat.
Variables (H:'M['F_2]_(m,n)) (S:'M['F_2]_(r,n)) (G:'M['F_2]_(k,n))
 (rows:'I_m->seq 'I_n) (columns:'I_n->seq 'I_m) (rowkey:'I_m->int64)
 (keys:seq int64) (mask:int64) (cap bits:Z) (tab links:seq Z) (c:policy_state) (p:lookup_ptrs)
 (initial:packed_support) (initial_blocks:seq Integers.int)
 (eligible:seq Integers.int->'cV['F_2]_n->Prop)
 (offsets:seq Z) (cols:seq Integers.int).
Variables (gv:globals) (sh:share) (levelp pathp base budgetp op qp mp:Values.val) (stride:Z) (pollmask:int64)
 (extra:Values.val->mpred).
Let levels:=Z.of_nat n.
Let nw:=Zlength (syndrome (words_at initial)).
Let companion level:=(visit_storage level budgetp levels * mask_field level pollmask * (single_leaf_counter level * extra level))%logic.
Let frame level:=(candidate_fields level base stride * companion level)%logic.
Let storage level:=reusable_index gv sh level op qp mp offsets cols nw levels.
Let work level:=(storage level * frame level)%logic.
Let heap:=index_flip_heap c p keys mask tab links initial work.
Let rec_heap:=weight_bounded_rows base stride levels heap.
Let entry:entry_domain:=fun geom level trace blocks _ st words=>
 geom=geometry c /\ level=levelp /\ trace=pathp /\ blocks=pb p /\ reachable_prefix n st words.
Let report:=recursive_report H S G eligible.
Let witness:=stored_css_prefix H S.
Let flip:=snd (depth_flip c heap Int.zero).
Let dfs:=snd (index_dfs_using_globals gv entry rec_heap report witness Int.zero).
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
 (inherit:forall pre x (a:'I_n),eligible pre x -> eligible (pre++[::Int.repr (Z.of_nat a)]) x)
 (base_address:isptr base) (level_address:is_pointer_or_null levelp).



Let outside level:=(storage level*candidate_fields level base stride*mask_field level pollmask*extra level)%logic.
Let with_leaf level:=(single_leaf_counter level * outside level)%logic.
Let leaf_work level:=(visit_storage level budgetp levels * with_leaf level)%logic.
Let leaf_heap:=weight_bounded_rows base stride levels
    (index_flip_heap c p keys mask tab links initial leaf_work).
Lemma same_storage_at_every_depth:rec_heap=leaf_heap.
Proof.
 have eq_work:work=leaf_work.
 { apply functional_extensionality=>s;unfold work,leaf_work,with_leaf,outside,frame,companion;apply pred_ext;cancel. }
 by unfold rec_heap,leaf_heap,heap;rewrite eq_work.
Qed.

Let odd_at words:=odd_count (payload_after Bare keys initial words).
Let common:=index_dfs_using_globals gv entry rec_heap report witness Int.zero.
Let calls:=index_callees H rows flip dfs.

Local Definition at_end:entry_domain:=fun _ _ _ bp w st xs=>
 bp=pb p /\ reachable_prefix n st xs /\ Zlength xs=w.
Local Definition shut:entry_domain:=fun _ _ _ bp w st xs=>
 bp=pb p /\ reachable_prefix n st xs /\ (Zlength xs<w)%coqZ /\ odd_at xs=0%coqZ.
Local Definition at_last:entry_domain:=fun _ _ _ bp w st xs=>
 bp=pb p /\ reachable_prefix n st xs /\ Zlength xs=(w-1)%coqZ /\ odd_at xs<>0%coqZ.
Local Definition interior:entry_domain:=fun g s cp bp w st xs=>
 entry g s cp bp w st xs /\ (Zlength xs<=w-2)%coqZ /\ odd_at xs<>0%coqZ.

(* This is the self-recursive C ABI: the very same funspec occurs in the
   function table and at the conclusion, for arbitrary initial PCM layouts. *)
Theorem native_index_dfs_body:semax_body prepared_vars calls f_dfs common.
Proof.
 unfold common;eapply (@combine_c_bodies calls gv odd_at entry rec_heap report witness Int.zero).
 move=>part;case:part.
 - rewrite same_storage_at_every_depth.
   have checked:semax_body prepared_vars calls f_dfs
       (index_dfs_using_globals gv at_end leaf_heap report witness Int.zero).
   { unfold calls,leaf_heap,leaf_work,with_leaf;eapply terminal_call_body with
       (columns:=columns) (rowkey:=rowkey) (cap:=cap) (bits:=bits) (initial_blocks:=initial_blocks);try eassumption.
   }
   eapply semax_body_funspec_sub;first exact checked.
   + apply narrow_index_domain;move=>g s cp bp w st words depth.
     have part:=@classify_match odd_at w words depth.
     rewrite /at_native_case;case tag:(classify_call odd_at w words);rewrite tag in part;cbn [same_branch] in *;
       unfold at_end,entry,odd_at in *;tauto.
   + apply compute_list_norepet_e;vm_compute;reflexivity.
 - rewrite same_storage_at_every_depth.
   have checked:semax_body prepared_vars calls f_dfs
       (index_dfs_using_globals gv shut leaf_heap report witness Int.zero).
   { unfold calls,leaf_heap,leaf_work,with_leaf;eapply closed_call_body with
       (columns:=columns) (rowkey:=rowkey) (cap:=cap) (bits:=bits) (initial_blocks:=initial_blocks);try eassumption. }
   eapply semax_body_funspec_sub;first exact checked.
   + apply narrow_index_domain;move=>g s cp bp w st words depth.
     have part:=@classify_match odd_at w words depth.
     rewrite /at_native_case;case tag:(classify_call odd_at w words);rewrite tag in part;cbn [same_branch] in *;
       unfold shut,entry,odd_at in *;tauto.
   + apply compute_list_norepet_e;vm_compute;reflexivity.
 - rewrite same_storage_at_every_depth.
   have checked:semax_body prepared_vars calls f_dfs
       (index_dfs_using_globals gv at_last leaf_heap report witness Int.zero).
   { unfold calls,leaf_heap,leaf_work,with_leaf;eapply last_call_body with
       (columns:=columns) (rowkey:=rowkey) (cap:=cap) (bits:=bits) (initial_blocks:=initial_blocks);try eassumption. }
   eapply semax_body_funspec_sub;first exact checked.
   + apply narrow_index_domain;move=>g s cp bp w st words depth.
     have part:=@classify_match odd_at w words depth.
     rewrite /at_native_case;case tag:(classify_call odd_at w words);rewrite tag in part;cbn [same_branch] in *;
       unfold at_last,entry,odd_at in *;tauto.
   + apply compute_list_norepet_e;vm_compute;reflexivity.
 - have checked:semax_body prepared_vars calls f_dfs
       (index_dfs_using_globals gv interior rec_heap report witness Int.zero).
   { exact (@open_call_body m n r k H S G rows columns rowkey keys mask cap bits tab links c p
        initial initial_blocks eligible offsets cols gv sh levelp pathp base budgetp op qp mp stride pollmask
        (fun s=>(single_leaf_counter s*extra s)%logic) orth det shape row_cap idx base_safe packed_init zero
        plain distinct covers maxrow offset_size csr capacity step padding word_cap share_ok colroom inherit
        base_address level_address). }
   eapply semax_body_funspec_sub;first exact checked.
   + apply narrow_index_domain;move=>g s cp bp w st words depth.
     have part:=@classify_match odd_at w words depth.
     rewrite /at_native_case;case tag:(classify_call odd_at w words);rewrite tag in part;cbn [same_branch] in *;
       unfold interior,entry,odd_at in *;tauto.
   + apply compute_list_norepet_e;vm_compute;reflexivity.
Qed.
End Unified.
