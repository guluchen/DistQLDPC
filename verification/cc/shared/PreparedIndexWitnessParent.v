(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VerifDetected VerifChildVisit VerifClosesBody VerifLookup VerifFlipBody
 HashLookup BuiltLookup NativeFlipPayload NativeDepthFlip EnabledCall EnabledLoopFacts SiblingCounters
 OverlapColumnState PreparedSeedDispatch PreparedRootStages PreparedChildCall PreparedDepthSpec
 PreparedBudgetContract PreparedSiblingScan PreparedRecursiveCall PreparedWitnessRegister PreparedPlainDescent
 PreparedPlainSiblings PreparedPlainReachable PreparedPlainPCMScan PreparedPCMChooser PreparedIndexFinish
 PreparedIndexWhile PreparedIndexNodeReport PreparedIndexWitnessCall PreparedIndexWitnessScan
 PreparedIndexWitnessUndo PreparedIndexWitnessLeaf PreparedSiblingRestore PreparedVerdictExit PreparedSampling PreparedCallerLocals.
From mathcomp Require Import all_ssreflect all_algebra.
Require Import PreparedMatrixPath PreparedMatrixResponse PreparedInteriorReport PreparedObservedWitness
 PreparedPCMLeafVisit LeafMatrix LevelSearch NativePackingScan IndexRowBridge flag_level_ast.
#[local] Existing Instance VerifDetected.CompSpecs.
Set Implicit Arguments.
Unset Strict Implicit.
Local Open Scope ring_scope.
Local Delimit Scope Z_scope with coqZ.

Section Search.
Variable Espec:OracleKind.
#[local] Existing Instance Espec.
Variables m n r k:nat.
Variables (H:'M['F_2]_(m,n)) (S:'M['F_2]_(r,n)) (G:'M['F_2]_(k,n))
 (rows:'I_m->seq 'I_n) (columns:'I_n->seq 'I_m) (rowkey:'I_m->int64)
 (keys:seq int64) (mask:int64) (cap bits:Z) (tab links:seq Z) (c:policy_state) (p:lookup_ptrs)
 (initial:packed_support) (initial_blocks:seq Integers.int) (work:Values.val->mpred)
 (eligible:seq Integers.int->'cV['F_2]_n->Prop) (root:snapshot) (parent:seq 'I_n)
 (offsets:seq Z) (cols:seq Integers.int) (remaining:nat) (choice:scan_exit).
Let P:=[set a:'I_n | a \in parent].
Let xs:=map Int.unsigned (output_columns offsets cols (blocked root) choice).
Let node:=literal_path parent.
Let w:=Z.of_nat (size parent+remaining)%N.
Let d:=Z.of_nat (size parent).
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
 (maxrow:forall i,(Zlength (encoded rows i)<=Int.max_signed)%coqZ)
 (actual:selection_origin rows H (indicator P) (@available_now n root) remaining offsets cols (blocked root) choice).
Variables (rec_heap:budget_heap) (s cp buffer:Values.val) (cells:seq Integers.int) (loan:mpred) (options saved:Integers.int).
Let entry:entry_domain:=fun geom level trace blocks _ st words=>
 geom=geometry c /\ level=s /\ trace=cp /\ blocks=pb p /\ reachable_prefix n st words.
Let flip:=snd (depth_flip c heap options).
Let dfs:=snd (index_dfs_with_witness entry rec_heap report witness options).
Let D:=func_tycontext f_dfs prepared_vars (visit_calls flip dfs) nil.
Let regs:=plain_scan_regs s buffer d (Zlength xs).
Let own blocks path written:=(child_fields s cp (pb p) w blocks path * child_array buffer xs *
                             heap s node * loan * witness_register s written)%logic.
Hypotheses (room:(w<=Zlength cells)%coqZ) (depth:(1<=d<=w-2)%coqZ) (signed:(w<=Int.max_signed)%coqZ)
 (colroom:(Zlength (blocked root)<Zlength (column_offsets (geometry c)))%coqZ)
 (prefix:active_prefix d cells=node)
 (lend:forall sub,Zlength sub=(d+1)%coqZ -> rec_heap w s sub=(heap s sub*loan)%logic)
 (inherit:forall x (a:'I_n),eligible node x -> eligible (node++[::Int.repr (Z.of_nat a)]) x).

Theorem scan_all_remaining_depths:
 semax D (PROPx nil (LOCALx (regs 0%coqZ 0%coqZ options) (SEPx [::own (blocked root) cells saved])))
  (Ssequence search_children undo_children)
  (normal_ret_assert (EX stop:Z,EX code:Z,EX tail:seq Integers.int,EX written:Integers.int,PROPx
   [::recursive_result H S G eligible w root node code tail;(0<=code<=3)%coqZ;
      Zlength tail=Zlength cells;active_prefix d tail=node;
      witness_at_limit w saved code written tail;witness_status code -> witness (Int.signed written) tail]
   (LOCALx (regs stop code options) (SEPx [::own (blocked root) tail written])))).
Proof.
 have fit:(Z.of_nat n<=Int.max_signed)%coqZ by rewrite -(all_keys idx);exact:(qubits_fit _ _ _ base_safe).
 have limit:(Zlength (blocked root)<=Int.max_signed)%coqZ by rewrite block_width.
 have [range count]:in_array (Zlength (blocked root)) xs /\ (Zlength xs<=Int.max_signed)%coqZ.
 { exact:(@actual_candidates_fit m n H rows parent root offsets cols choice remaining fit block_width maxrow actual). }
 eapply semax_seq'.
 { eapply semax_pre;last first.
   - apply (@scan_preserves_witness_register Espec c heap dfs loan report witness options s cp (pb p) buffer
        xs root cells w d saved plain depth room count limit range colroom).
     move=>i cur pos len matched q st sub locs state.
     have pat:active_prefix d cur=node by rewrite matched.
     have reached:=@all_visited_children_are_reachable m n H rows parent root offsets cols remaining choice
       fit block_width distinct unique protected actual i d cur pos pat.
     have sublen:Zlength sub=(d+1)%coqZ by unfold sub,append_qubit,active_prefix;
       rewrite Zlength_app Zlength_sublist;cbn;lia.
     case:(Z.eq_dec w (d+2))=>[two|more].
     + pose proof (@reached_inline_visit Espec m n r k H S G columns rowkey keys mask cap bits tab links c p initial
         initial_blocks work eligible s cp buffer options saved cur st orth det shape row_cap idx base_safe packed_init zero plain
         flip dfs d q (Zlength xs) i (child_array buffer xs * loan)%logic ltac:(lia) ltac:(lia) reached) as raw.
       cbn zeta in raw;fold sub locs in raw.
       eapply semax_post';last first.
       * eapply semax_pre;last exact raw;unfold state,locs,plain_descent_loc,heap;rewrite two;entailer!;cancel.
       * Intros tail code written;Exists tail code written;unfold state,locs,plain_descent_loc,report,witness,heap;
           rewrite two;entailer!;cancel;try apply derives_refl.
     + have permitted:entry (geometry c) s cp (pb p) w st sub.
       { unfold entry;split;[reflexivity|split;[reflexivity|split;[reflexivity|split;[reflexivity|exact reached]]]]. }
       pose proof (@deep_registered_visit Espec entry c heap rec_heap report witness options
            s cp (pb p) w d q st cur saved buffer (Zlength xs) i loan cells ltac:(lia) signed ltac:(lia) len
            permitted (@lend sub sublen) (child_array buffer xs)) as child_call.
       cbn zeta in child_call;fold sub locs dfs flip in child_call.
       eapply semax_post';last first.
       * eapply semax_pre;last exact child_call.
         unfold state,locs,plain_descent_loc;entailer!;cancel.
       * Intros tail code written;Exists tail code written;unfold state,locs,plain_descent_loc;entailer!;cancel.
   - rewrite prefix;unfold own,added;rewrite sublist_nil //;cbn [sweep List.fold_left].
     apply andp_left2;apply derives_refl. }
 Intros stop code tail written.
 match goal with h:scan_outcome_mode _ _ _ _ _ _ _ _ _ |- _=>pose proof h as ran end.
 rewrite prefix in ran.
 have bounded:(0<=stop<=Zlength xs)%coqZ by
   case:ran=>_ [[-> _]|[position _]];[pose proof (Zlength_nonneg xs)|];lia.
 have answer:=@index_children_preserve_recursive_result m n r k H S G eligible rows parent root offsets cols
   remaining fit block_width covers distinct unique (geometry c) choice stop code tail actual inherit ran.
 pose proof (@undo_keeps_registered_result Espec flip dfs s cp (pb p) buffer d w options xs (blocked root) tail
    stop code written (heap s node*loan)%logic count limit range bounded) as back.
 eapply semax_post';last first.
 - eapply semax_pre;last exact back;unfold regs,plain_scan_regs;rewrite prefix;entailer!;cancel.
 - Exists stop code tail written;unfold own,regs,plain_scan_regs;entailer!;cancel;try apply derives_refl;intuition.
Qed.

Definition parent_evidence code tail written:Prop:=
 recursive_result H S G eligible w root node code tail /\ (0<=code<=3)%coqZ /\
 Zlength tail=Zlength cells /\ active_prefix d tail=node /\ witness_at_limit w saved code written tail /\
 (witness_status code -> witness (Int.signed written) tail).

Theorem return_registered_index_result ptr klass t1 t2:
 (Int.signed klass<0)%coqZ ->
 let answers:=(Z*(Z*(seq Integers.int*Integers.int)))%type in
 semax D (PROPx nil (LOCALx (regs 0%coqZ 0%coqZ options++[::lvar _sample sample_type ptr])
   (SEPx [::own (blocked root) cells saved;sample_data ptr klass t1 t2]))) search_finish
   (existential_ret_assert (fun a:answers=>function_body_ret_assert tint
     (PROP(parent_evidence a.2.1 a.2.2.1 a.2.2.2) LOCAL(temp ret_temp (Vint (Int.repr a.2.1)))
       SEP(data_at_ Tsh sample_type ptr;own (blocked root) a.2.2.1 a.2.2.2))))%assert.
Proof.
 move=>off answers.
 pose before:=regs 0%coqZ 0%coqZ options.
 pose after (a:answers):=regs a.1 a.2.1 options.
 pose facts (a:answers):=[::parent_evidence a.2.1 a.2.2.1 a.2.2.2].
 pose chunks (a:answers):=[::own (blocked root) a.2.2.1 a.2.2.2].
 have loop:semax D (PROPx nil (LOCALx before (SEPx [::own (blocked root) cells saved])))
     (Ssequence search_children undo_children) (normal_ret_assert (EX a:answers,
         PROPx (facts a) (LOCALx (after a) (SEPx (chunks a))))).
 { eapply semax_post';last exact scan_all_remaining_depths.
   Intros stop code tail written;Exists (stop,(code,(tail,written)));
     unfold facts,parent_evidence,after,chunks,regs,plain_scan_regs;cbn [fst snd];entailer!;try apply derives_refl. }
 apply:(@finish_after_siblings answers Espec D _ ptr klass t1 t2 (fun a=>a.2.1)
   (fun a=>parent_evidence a.2.1 a.2.2.1 a.2.2.2) (fun a=>own (blocked root) a.2.2.1 a.2.2.2) _ off).
 - unfold D,visit_calls;apply tycontext_sub_Gprog_nil;vm_compute;
   repeat (apply list_norepet_cons;[simpl;intuition congruence|]);apply list_norepet_nil.
 - pose held:=[::lvar _sample sample_type ptr].
   pose extra:=[::sample_data ptr klass t1 t2].
   have stable:closed_wrt_modvars (Ssequence search_children undo_children) (LOCALx held (SEPx extra))
     by unfold held,extra,search_children,undo_children;auto 100 with closed.
   eapply semax_post';last exact:(@keep_caller_locals_for_answer answers Espec VerifDetected.CompSpecs D
     (Ssequence search_children undo_children) nil before [::own (blocked root) cells saved]
     held extra facts after chunks stable loop).
   Intros a;Exists a;unfold after,regs,plain_scan_regs,facts,held,chunks,extra;cbn [app];entailer!;try apply derives_refl.
Qed.
End Search.
