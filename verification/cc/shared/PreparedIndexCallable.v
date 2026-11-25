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
Lemma eliminate_environment_answer (A:Type) (P:A->environ->mpred) rho (R:mpred):
 (forall a,P a rho |-- R) -> ((EX a:A,P a)%assert rho |-- R).
Proof. move=>all_answers;change ((EX a:A,P a rho)%logic |-- R);apply exp_left;exact all_answers. Qed.

Lemma from_local_frame (P:environ->mpred) i t ptr rho (R:mpred):
 (locald_denote (lvar i t ptr) rho -> P rho |-- R) ->
 ((P * (PROP() LOCAL(lvar i t ptr) SEP())%assert)%logic rho |-- R).
Proof.
 move=>finish.
 change ((P rho*(!! True && (!! (locald_denote (lvar i t ptr) rho /\ True) && emp)))%logic |-- R).
 normalize;apply finish;tauto.
Qed.
Lemma typed_return_frame (T:Prop) (P Q F:mpred):
 (P |-- Q*F) -> (!!T && P |-- (!!T && Q)*F).
Proof. intros finish;normalize;rewrite ?prop_true_andp //;exact finish. Qed.
Lemma introduce_environment_answer (A:Type) (P:A->environ->mpred) (a:A) rho:
 P a rho |-- (EX x:A,P x)%assert rho.
Proof. change (P a rho |-- (EX x:A,P x rho)%logic);apply exp_right with a;apply derives_refl. Qed.

Section Interface.
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
Let companion level:=(visit_storage level budgetp levels * mask_field level pollmask * extra level)%logic.
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


(* This case of the uniform C contract is entered from an arbitrary
   physical call rather than from a preselected mathematical tree. *)
Definition open_entry:entry_domain:=fun geom level trace blocks w st words=>
 entry geom level trace blocks w st words /\
 (Zlength words<=w-2)%coqZ /\ odd_count (payload_after Bare keys initial words)<>0%coqZ.
Definition open_call:=index_dfs_using_globals gv open_entry rec_heap report witness Int.zero.

Theorem open_call_body:semax_body prepared_vars (index_callees H rows flip dfs) f_dfs open_call.
Proof.
 unfold open_call,index_dfs_using_globals.
 start_function1.
 destruct x as [[[[[[[[geom0 level0] cp0] bp0] weight0] d0] snap] cells0] saved0].
 cbn beta iota;start_function2;start_function3.
 match goal with h:open_entry _ _ _ _ _ _ _ |- _=>
   destruct h as [[g_id [s_id [c_id [b_id reach]]]] [two live]];subst geom0 level0 cp0 bp0 end.
 destruct reach as [ids [unique [prefix [width protected]]]].
 have size_eq:Zlength (literal_path ids)=d0 by rewrite -prefix /active_prefix Zlength_sublist;lia.
 have id_depth:Z.of_nat (size ids)=d0 by move:size_eq;rewrite /literal_path Zlength_map Zlength_correct.
 assert_PROP (weight0<=levels)%coqZ as at_width.
 { unfold rec_heap,weight_bounded_rows;entailer!. }
 pose moves:=Z.to_nat (weight0-d0).
 have budget:Z.of_nat (size ids+moves)%N=weight0 by rewrite Nat2Z.inj_add id_depth /moves Z2Nat.id;lia.
 have depth:(1<=d0<=weight0-2)%coqZ by rewrite prefix size_eq in two;lia.
 have live_node:odd_count (payload_after Bare keys initial (literal_path ids))<>0%coqZ by rewrite -prefix.
 match goal with
 | |- context [witness_register _ ?old] =>
   match goal with |- context [lvar _sample _ ?loc] =>
    pose proof (@reachable_deep_index_body Espec m n r k H S G rows columns rowkey keys mask cap bits tab links c p
      initial initial_blocks eligible snap ids offsets cols moves gv sh levelp pathp base budgetp op qp mp stride pollmask
      extra cells0 old loc orth det shape row_cap idx base_safe packed_init zero plain distinct covers maxrow
      offset_size csr capacity step padding word_cap share_ok colroom (@inherit (literal_path ids))
      unique width protected ltac:(rewrite id_depth;exact prefix) ltac:(rewrite budget;assumption)
      ltac:(rewrite id_depth budget;exact depth) ltac:(rewrite budget;exact at_width) live_node base_address level_address) as body
   end
 end.
 rewrite id_depth budget -prefix plain in body.
 set (names:=(PROP() LOCAL(lvar _sample sample_type v_sample) SEP())%assert).
 have stable:closed_wrt_modvars (fn_body f_dfs) names by unfold names;auto 100 with closed.
 pose proof (@semax_frame VerifDetected.CompSpecs Espec _ _ (fn_body f_dfs) _ names stable body) as framed.
 eapply semax_post_flipped.
 - eapply semax_pre;last exact framed.
   unfold guard_loc,names;cbn [app];go_lowerx;normalize;try cancel;try apply derives_refl.
   all: try (apply andp_right;[apply prop_right;repeat split;try assumption|cancel]).
   all: try solve [match goal with h:_ |- _=>first [exact (proj1 h)|exact (proj2 h)] end].
   all: try solve [apply andp_left2;apply derives_refl|apply andp_left1;apply derives_refl|apply derives_refl].
   all: try solve [unfold rec_heap,heap,work,storage,frame,companion,nw,levels;cancel;apply derives_refl].
 - apply andp_left2;intro rho;cbn [RA_normal existential_ret_assert frame_ret_assert function_body_ret_assert bind_ret].
   rewrite exp_sepcon1.
   change ((EX _:Z*(Z*(seq Integers.int*Integers.int)),(@FF mpred Nveric*names rho))%logic |-- RA_normal POSTCONDITION rho).
   apply exp_left;intro a;normalize.
 - apply andp_left2;intro rho;cbn [RA_break existential_ret_assert frame_ret_assert function_body_ret_assert bind_ret].
   rewrite exp_sepcon1.
   change ((EX _:Z*(Z*(seq Integers.int*Integers.int)),(@FF mpred Nveric*names rho))%logic |-- RA_break POSTCONDITION rho).
   apply exp_left;intro a;normalize.
 - apply andp_left2;intro rho;cbn [RA_continue existential_ret_assert frame_ret_assert function_body_ret_assert bind_ret].
   rewrite exp_sepcon1.
   change ((EX _:Z*(Z*(seq Integers.int*Integers.int)),(@FF mpred Nveric*names rho))%logic |-- RA_continue POSTCONDITION rho).
   apply exp_left;intro a;normalize.
 - intros [v|];apply andp_left2;intro rho;unfold POSTCONDITION,abbreviate;
    cbn [RA_return existential_ret_assert function_body_ret_assert frame_ret_assert bind_ret];
    rewrite exp_sepcon1;apply (@eliminate_environment_answer (Z*(Z*(seq Integers.int*Integers.int))) _ rho _);intros [unused [code [tail written]]].
   2:{ match goal with |- _ |-- ?R=>change ((@FF mpred Nveric * names rho)%logic |-- R) end;normalize. }
   unfold names;apply from_local_frame;intro local_sample.
   unfold liftx;cbn [fst snd].
   assert (stack:data_at_ Tsh sample_type v_sample |-- stackframe_of f_dfs rho).
   { unfold stackframe_of;cbn [f_dfs fn_vars fold_right List.map].
     rewrite (var_block_data_at_ Tsh _sample sample_type);last first.
     all: try solve [reflexivity | auto].
     change (data_at_ Tsh sample_type v_sample |-- (data_at_ Tsh sample_type (eval_lvar _sample sample_type rho)*emp)%logic).
     rewrite (lvar_eval_lvar _sample sample_type v_sample rho local_sample);cancel. }
   lazymatch goal with |- ?L |-- ?R =>
    lazymatch L with context [lift_curry _ ?P] =>
     lazymatch R with context [lift_curry _ ?Q] =>
      change ((!!tc_val tint v && P (make_args [::ret_temp] [::v] rho)) |--
        (!!tc_val tint v && Q (make_args [::ret_temp] [::v] rho))*stackframe_of f_dfs rho)%logic
     end end end.
   apply typed_return_frame.
   eapply derives_trans;last first.
   { apply sepcon_derives;last apply derives_refl.
     eapply derives_trans;last apply (@introduce_environment_answer _ _ tail).
     eapply derives_trans;last apply (@introduce_environment_answer _ _ code).
     apply (@introduce_environment_answer _ _ written). }
   unfold PROPx,LOCALx,SEPx,local,lift1;unfold_lift;simpl;normalize.
   sep_apply stack;unfold report,recursive_report;entailer!;cancel;try apply derives_refl.
Qed.
End Interface.
