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
Require Import PreparedIndexUnified PreparedIndexFunctions PhysicalPrefixInvariant PhysicalColumnBounds
 PreparedPhysicalPCM SparseSyndrome FlipRoundtrip RedundantState PreparedFlip.
Section Library.
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
Hypotheses (column_extent:Zlength (column_offsets (geometry c))=(levels+1)%coqZ)
 (signed_count:(Z.of_nat m<Int.max_signed)%coqZ).

Let decoded (j:Z):seq 'I_m:=
 if (insub (Z.to_nat j):option 'I_n) is Some q then columns q else [::].

Lemma address_of_physical_column j:column_in c j ->
 exists q:'I_n,j=Z.of_nat q /\ decoded j=columns q.
Proof.
 move=>[[nonnegative _] room];rewrite column_extent /levels in room.
 have small:(Z.to_nat j<n)%N by apply/ltP;lia.
 pose q:'I_n:=Ordinal small.
 have id:Z.of_nat q=j by rewrite /q /= Z2Nat.id.
 have parsed:insub (Z.to_nat j)=Some q by change (insub (val q)=Some q);exact:valK.
 exists q;split;first by rewrite id.
 by rewrite /decoded parsed.
Qed.

Lemma initial_flip_data:pcm_state decoded (column_in c) Bare keys initial.
Proof.
 have [built positive dim spare period bits_ok low fit no_dup incidence stored alias]:=idx.
 have [odd _]:=zero;split;last by eexists;exact odd.
 move=>j valid;have [q [address decoded_q]]:=address_of_physical_column valid.
 have bound:=elimT ltP (ltn_ord q).
 have in_keys:(0<=j<Zlength keys)%coqZ by rewrite dim address;lia.
 have safe:=VerifLookup.column_safe _ _ _ base_safe j in_keys.
 have [_ [end_offset [ordered [ending [rows_fit [_ [wid [mask_fit _]]]]]]]]:=safe.
 have [enc _]:=packed_init q.
 split.
 - unfold static_column;repeat split;try assumption;try lia;exact I.
 - split;first by rewrite decoded_q address.
   rewrite address enc /extra_rows cats0;apply Forall_forall=>row /List.in_map_iff[i [<- member]].
   have row_bound:=elimT ltP (ltn_ord i).
   have total: (Z.of_nat m<=64*Zlength (syndrome (words_at initial)))%coqZ:=proj1 odd.
   rewrite /encode Int.unsigned_repr;first lia.
   change Int.max_signed with 2147483647%coqZ in signed_count.
   change Int.max_unsigned with 4294967295%coqZ;lia.
Qed.

Lemma actual_column_flip:funspec_sub (snd PreparedFlip.flip_spec) flip.
Proof.
 unfold flip,heap,index_flip_heap;apply depth_flip_refinement;first exact plain.
 - reflexivity.
 - have pos:forall j,column_in c j -> (0<=j)%coqZ by move=>j [[ok _] _].
   have unique:forall j,column_in c j -> uniq (decoded j).
   { move=>j valid;have [q [_ ->]]:=address_of_physical_column valid.
     have [_ _ _ _ _ _ _ _ nodup _ _ _]:=idx;exact:(nodup q). }
   have high:forall j,column_in c j ->
     Forall (fun r=>(Z.of_nat m<=Int.unsigned r)%coqZ) (extra_rows Bare j)
       by move=>j valid;constructor.
   move=>path j allowed ready;apply pcm_state_pair with (m:=m) (inc:=decoded) (usable:=column_in c)=> //.
   unfold payload_after;apply pcm_prefix with (inc:=decoded) (usable:=column_in c)=> //.
   exact initial_flip_data.
Qed.

Theorem native_index_function_library {Espec:OracleKind}:
 semax_func prepared_vars (index_callees H rows (snd PreparedFlip.flip_spec) dfs)
   (Genv.globalenv flag_level_ast.prog) index_functions (index_specs H rows (snd PreparedFlip.flip_spec) dfs).
Proof.
 apply (@publish_index_functions Espec m n H rows c heap dfs);[reflexivity|exact actual_column_flip|].
 exact (@native_index_dfs_body m n r k H S G rows columns rowkey keys mask cap bits tab links c p
    initial initial_blocks eligible offsets cols gv sh levelp pathp base budgetp op qp mp stride pollmask extra
    orth det shape row_cap idx base_safe packed_init zero plain distinct covers maxrow offset_size csr capacity
    step padding word_cap share_ok colroom inherit base_address level_address).
Qed.
End Library.
