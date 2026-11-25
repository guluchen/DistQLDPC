(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.floyd.reassoc_seq VerifDetected VerifChildVisit VerifClosesBody VerifLookup VerifFlipBody
 HashLookup BuiltLookup NativeFlipPayload NativeDepthFlip EnabledCall EnabledLoopFacts SiblingCounters
 OverlapColumnState PreparedSeedDispatch PreparedRootStages PreparedChildCall PreparedDepthSpec
 PreparedBudgetContract PreparedSiblingScan PreparedRecursiveCall PreparedWitnessRegister PreparedPlainDescent
 PreparedPlainSiblings PreparedPlainReachable PreparedPlainPCMScan PreparedPCMChooser PreparedIndexFinish
 PreparedIndexWhile PreparedIndexNodeReport PreparedIndexWitnessCall PreparedIndexWitnessScan
 PreparedIndexWitnessUndo PreparedIndexWitnessLeaf PreparedSiblingRestore PreparedVerdictExit PreparedSampling PreparedCallerLocals.
Require Import PreparedChooserStorage PreparedInitializeScan PreparedSelectedReturn PreparedIndexReuse.
Require Import PreparedInteriorEntry PreparedCandidateArena PreparedCandidateSlice PreparedArenaContext PreparedIndexCall PreparedIndexWitnessParent PreparedIndexContiguous PreparedIndexLink PreparedNativeCallees PreparedUniformIndex PreparedIndexSyndromeLoan PreparedChoiceCall PreparedChooseReturn PreparedLeafWorkspace.
From mathcomp Require Import all_ssreflect all_algebra.
Require Import PreparedMatrixPath PreparedMatrixResponse PreparedInteriorReport PreparedObservedWitness
 PreparedPCMLeafVisit LeafMatrix LevelSearch NativePackingScan IndexRowBridge flag_level_ast.
#[local] Existing Instance VerifDetected.CompSpecs.
Set Implicit Arguments.
Unset Strict Implicit.
Local Open Scope ring_scope.
Local Delimit Scope Z_scope with coqZ.

Lemma link_index_visits m n (H:'M['F_2]_(m,n)) (rows:'I_m->seq 'I_n) (flip dfs:funspec):
 tycontext_sub (func_tycontext f_dfs prepared_vars (visit_calls flip dfs) nil)
    (func_tycontext f_dfs prepared_vars (index_callees H rows flip dfs) nil).
Proof.
 apply (tycontext_sub_i99 f_dfs prepared_vars prepared_vars
          (visit_calls flip dfs) (index_callees H rows flip dfs) nil).
 split.
 { apply sub_option_get.
   let old:=constr:(make_tycontext_g prepared_vars (visit_calls flip dfs)) in
   let tree:=make_ground_PTree old in change old with tree.
   let new:=constr:(make_tycontext_g prepared_vars (index_callees H rows flip dfs)) in
   let tree:=make_ground_PTree new in change new with tree.
   repeat (apply Forall_cons;[reflexivity|]);apply Forall_nil. }
 apply subsume_spec_get.
 let old:=constr:(make_tycontext_s (visit_calls flip dfs)) in
 let tree:=make_ground_PTree old in change old with tree.
 let new:=constr:(make_tycontext_s (index_callees H rows flip dfs)) in
 let tree:=make_ground_PTree new in change new with tree.
 repeat (apply Forall_cons;[apply subsumespec_refl|]);apply Forall_nil.
Qed.

(* The local sample and the computed row pointer are live in the very
   environment whose global lookup table the next C call will read. *)
Lemma hold_global_environment {Espec:OracleKind} D gv code (before after:seq localdef)
 (owned returned:seq mpred):
 closed_wrt_modvars code (LOCALx [::gvars gv] (SEPx nil)) ->
 semax D (PROPx nil (LOCALx before (SEPx owned))) code
   (normal_ret_assert (PROPx nil (LOCALx after (SEPx returned)))) ->
 semax D (PROPx nil (LOCALx (before++[::gvars gv]) (SEPx owned))) code
   (normal_ret_assert (PROPx nil (LOCALx (after++[::gvars gv]) (SEPx returned)))).
Proof.
 move=>stable call.
 pose proof (@semax_frame VerifDetected.CompSpecs Espec D _ code _ _ stable call) as both.
 rewrite frame_normal in both.
 have split regs chunks:PROPx nil (LOCALx (regs++[::gvars gv]) (SEPx chunks))=
     (PROPx nil (LOCALx regs (SEPx chunks)) * LOCALx [::gvars gv] (SEPx nil))%logic.
 { have complete:=@separate_caller_env nil regs chunks [::gvars gv] nil.
   rewrite List.app_nil_r in complete;exact complete. }
 rewrite !split;exact both.
Qed.

Theorem initialize_index_frame {Espec:OracleKind} gv c s base stride depth options ptr (frame:mpred):
 (0<=depth<=Int.max_signed)%coqZ -> (0<=stride<=Int.max_signed)%coqZ -> isptr base ->
 let before:=[::temp _s s;temp _size (Vint (Int.repr depth));temp _options (Vint options);
   temp _policy (nested_policy (nested c));lvar _sample sample_type ptr] in
 semax (func_tycontext f_dfs prepared_vars nil nil)
 (PROPx nil (LOCALx (before++[::gvars gv]) (SEPx [::data_at_ Tsh sample_type ptr;candidate_fields s base stride;frame])))
 sample_and_slice (normal_ret_assert (PROPx nil
   (LOCALx (before_choice c s (row_pointer base stride depth) ptr depth options++[::gvars gv])
   (SEPx [::sample_data ptr (Int.repr (-1)) Float.zero Float.zero;candidate_fields s base stride;frame])))).
Proof.
 move=>bound step live before;apply hold_global_environment.
 - unfold sample_and_slice,init_sample,child_slice;auto 100 with closed.
 - exact:(@set_up_nonterminal_frame Espec c s base stride depth options ptr frame bound step live).
Qed.

Section Selected.
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

Variables (gv:globals) (sh:share) (op qp mp:Values.val) (nw:Z) (frame:Values.val->mpred).
Let storage s:=reusable_index gv sh s op qp mp offsets cols nw (Z.of_nat n).
Let work s:=(storage s * frame s)%logic.
Let heap:=index_flip_heap c p keys mask tab links initial work.
Let report:=recursive_report H S G eligible.
Let witness:=stored_css_prefix H S.
Hypotheses (orth:H*m S^T=0) (det:G*m S^T=0) (shape:(\rank (col_mx H G)+\rank S=n)%N)
 (row_cap:(Z.of_nat m<=Int.max_signed)%coqZ)
 (idx:@table_for_lookup m n H columns rowkey keys mask cap bits tab links c p)
 (base_safe:book_safe (table_book keys mask (checksum initial) tab links initial_blocks) (words_at initial) (odd_count initial))
 (packed_init:@encoded_at m n k G columns Bare initial) (zero:pcm_response H G rowkey (0:'cV['F_2]_n) initial)
 (plain:nested_policy (nested c)=nullval) (block_width:Zlength (blocked root)=Z.of_nat n)
 (unique:uniq parent) (protected:forall q:'I_n,q \in parent -> Znth (Z.of_nat q) (blocked root)<>Int.zero)
 (distinct:forall i,uniq (rows i)) (covers:forall i q,H i q!=0 -> q \in rows i)
 (maxrow:forall i,(Zlength (encoded rows i)<=Int.max_signed)%coqZ).
Variables (rec_heap:budget_heap) (s cp buffer:Values.val) (cells:seq Integers.int) (loan:mpred) (options saved:Integers.int).
Let entry:entry_domain:=fun geom level trace blocks _ st words=>
 geom=geometry c /\ level=s /\ trace=cp /\ blocks=pb p /\ reachable_prefix n st words.
Let flip:=snd (depth_flip c heap options).
Let dfs:=snd (index_dfs_with_witness entry rec_heap report witness options).
Hypotheses (room:(w<=Zlength cells)%coqZ) (depth:(1<=d<=w-2)%coqZ) (signed:(w<=Int.max_signed)%coqZ)
 (colroom:(Zlength (blocked root)<Zlength (column_offsets (geometry c)))%coqZ)
 (prefix:active_prefix d cells=node)
 (lend:forall sub,Zlength sub=(d+1)%coqZ -> rec_heap w s sub=(heap s sub*loan)%logic)
 (inherit:forall x (a:'I_n),eligible node x -> eligible (node++[::Int.repr (Z.of_nat a)]) x).


Variables (old:seq Integers.int) (last nc cut_count:int64) (tags:seq int64) (ptr:Values.val) (klass:Integers.int) (t1 t2:Floats.float).
Let cur:=payload_after Bare keys initial node.
Let a:=@Site n gv sh s (psyn (words_at cur)) op qp (pb p) mp buffer offsets cols (blocked root)
 d w (syndrome (words_at cur)) nc cut_count old last tags (indicator P) (@available_now n root) remaining (odd_count cur).
Let stride:=Zlength old.
Let retained path written:=(child_fields s cp (pb p) w (blocked root) path *
    ready_row buffer stride * heap s node * loan * witness_register s written)%logic.
Let args:=(Z*(Z*(seq Integers.int*Integers.int)))%type.
Let result:ret_assert:=existential_ret_assert (fun v:args=>function_body_ret_assert tint
    (PROP(recursive_result H S G eligible w root node v.2.1 v.2.2.1 /\ (0<=v.2.1<=3)%coqZ /\
      Zlength v.2.2.1=Zlength cells /\ active_prefix d v.2.2.1=node /\ witness_at_limit w saved v.2.1 v.2.2.2 v.2.2.1 /\
      (witness_status v.2.1 -> witness (Int.signed v.2.2.2) v.2.2.1))
     LOCAL(temp ret_temp (Vint (Int.repr v.2.1))) SEP(data_at_ Tsh sample_type ptr;retained v.2.2.1 v.2.2.2)))%assert.
Let start:=caller_locals gv s buffer d options ++[::temp _policy nullval;lvar _sample sample_type ptr].
Let D:=func_tycontext f_dfs prepared_vars (index_callees H rows flip dfs) nil.

Let rest: mpred := (!!physical_prefix c node && (static_leaf_index s p mask tab links * independent_leaf_counters s * frame s *
        loan * witness_register s saved * sample_data ptr klass t1 t2))%logic.

Theorem choose_visit_restore_return:
 legal_choice H rows a -> nw=Zlength (syndrome (words_at cur)) ->
 Int.and options (Int.repr 1)=Int.zero -> Int.and options (Int.repr 16)=Int.zero ->
 (Int.signed klass<0)%coqZ -> is_pointer_or_null s -> is_pointer_or_null buffer ->
 semax D (PROPx nil (LOCALx start (SEPx [::retained cells saved;sample_data ptr klass t1 t2])))
    choose_search_return result.
Proof.
 move=>legal width direct disabled off valid out.
 eapply semax_pre;last first.
 - eapply (@choose_and_search Espec m n H rows a flip dfs (pk p) cp keys cur cells options ptr rest result
        legal erefl erefl direct valid out).
   move=>choice spare [origin extent] release.
   have meaning:selection_origin rows H (indicator P) (@available_now n root) remaining offsets cols (blocked root) choice
      by exact origin.
   pose picks:=output_columns offsets cols (blocked root) choice.
   have count:Zlength (map Int.unsigned picks)=length_at a choice by rewrite Zlength_map.
   have recover:(child_array buffer (map Int.unsigned picks) * spare |-- ready_row buffer stride)%logic
      by exact release.
   have smaller:tycontext_sub (func_tycontext f_dfs prepared_vars (visit_calls flip dfs) nil) D.
   { exact:link_index_visits. }
   eapply semax_Delta_subsumption;[exact smaller|].
   pose proof (@selected_restores_whole_row Espec m n r k H S G rows columns rowkey keys mask cap bits tab links c p
         initial initial_blocks work eligible root parent offsets cols remaining choice orth det shape row_cap idx base_safe
         packed_init zero plain block_width unique protected distinct covers maxrow meaning rec_heap s cp buffer cells loan
         options saved room depth signed colroom prefix lend inherit ptr klass t1 t2 spare stride disabled off recover) as sub.
     cbn zeta in sub;fold picks in sub;rewrite count in sub.
     eapply semax_pre;last exact sub.
     unfold plain_chosen_loc,heap,index_flip_heap,physical_store,rest,work,storage,cur.
     cbn [a level_p output_p blocks_p call_depth odd_words row_offsets entries blocked_cells offsets_p columns_p marks_p globals_at const_share requested_weight];rewrite -width.
     go_lowerx;normalize;try cancel;try apply derives_refl.
     all: try (apply andp_right;[apply prop_right;repeat split;try assumption;try congruence|cancel]).
     all: try solve [match goal with h:_ |- _=>first [exact (proj1 h)|exact (proj2 h)] end].
     all: try solve [fold node;assumption|cancel|apply derives_refl].
 - unfold retained,heap,index_flip_heap,physical_store,work,storage,start,caller_locals,rest,cur.
   cbn [a level_p output_p blocks_p call_depth odd_words row_offsets entries blocked_cells offsets_p columns_p marks_p globals_at const_share requested_weight spare_cells];try rewrite -width.
   go_lowerx;normalize;try cancel;try apply derives_refl.
   all: try (apply andp_right;[apply prop_right;repeat split;try assumption;try congruence|cancel]).
 all: try solve [match goal with h:_ |- _=>first [exact (proj1 h)|exact (proj2 h)] end].
 all: try apply derives_refl.
 all: match goal with |- ?G=> fail 1 "compose input" G end.
Qed.
(* Before the first chooser invocation this activation owns the initialized
   depth slice. The same two header fields must be usable at deeper calls. *)
Let stack_remainder (external:mpred):mpred:=((!!physical_prefix c node && (child_fields s cp (pb p) w (blocked root) cells *
     ready_row buffer stride * packed_mem s (pk p) Bare keys cur * static_leaf_index s p mask tab links *
     independent_leaf_counters s * storage s * external * loan * witness_register s saved))%logic : mpred).

Theorem search_from_the_stack base (external:mpred):
 buffer=row_pointer base stride d -> frame s=(candidate_fields s base stride*external)%logic ->
 isptr base -> (0<=stride<=Int.max_signed)%coqZ ->
 legal_choice H rows a -> nw=Zlength (syndrome (words_at cur)) ->
 Int.and options (Int.repr 1)=Int.zero -> Int.and options (Int.repr 16)=Int.zero ->
 klass=Int.repr (-1) -> t1=Float.zero -> t2=Float.zero ->
 is_pointer_or_null s -> is_pointer_or_null buffer ->
 let regs:=[::temp _s s;temp _size (Vint (Int.repr d));temp _options (Vint options);
   temp _policy (nested_policy (nested c));lvar _sample sample_type ptr;gvars gv] in
 semax D (PROPx nil (LOCALx regs (SEPx [::data_at_ Tsh sample_type ptr;retained cells saved])))
    nonterminal_search result.
Proof.
 move=>slice fields base_ok step legal width direct disabled k0 t10 t20 valid out regs.
 pose without:=stack_remainder external.
 have unseal:retained cells saved=(candidate_fields s base stride * without)%logic.
 { unfold retained,heap,index_flip_heap,physical_store,work,without,stack_remainder;rewrite fields;apply pred_ext;normalize;try cancel;try apply derives_refl.
   all: try (apply andp_right;[apply prop_right;assumption|cancel]).
   all: match goal with |- ?G=>fail 1 "scratch unseal" G end. }
 have small:tycontext_sub (func_tycontext f_dfs prepared_vars nil nil) D.
 { have base_small:tycontext_sub (func_tycontext f_dfs prepared_vars nil nil)
       (func_tycontext f_dfs prepared_vars (visit_calls flip dfs) nil).
   { apply tycontext_sub_Gprog_nil;vm_compute;
     repeat (apply list_norepet_cons;[simpl;intuition congruence|]);apply list_norepet_nil. }
   eapply tycontext_sub_trans;[exact base_small|exact:link_index_visits]. }
 apply interior_code_is_contiguous;eapply semax_seq'.
 - eapply semax_Delta_subsumption;[exact small|].
   eapply semax_pre;last exact:(@initialize_index_frame Espec gv c s base stride d options ptr without
                                               ltac:(lia) step base_ok).
   rewrite unseal;unfold regs;cbn [app];go_lowerx;normalize;cancel;try apply derives_refl.
 - have off:(Int.signed klass<0)%coqZ by rewrite k0;vm_compute;reflexivity.
   eapply semax_pre;last exact (choose_visit_restore_return legal width direct disabled off valid out).
   rewrite unseal k0 t10 t20;unfold start,caller_locals,before_choice,choice_loc;rewrite plain slice.
     cbn [app];go_lowerx;normalize;try cancel;try apply derives_refl.
     all: try (apply andp_right;[apply prop_right;repeat split;try assumption;try congruence|cancel]).
     all: try solve [match goal with h:_ |- _=>first [exact (proj1 h)|exact (proj2 h)] end].
Qed.
End Selected.
