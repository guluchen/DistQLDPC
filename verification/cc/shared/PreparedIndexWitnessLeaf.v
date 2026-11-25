(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VerifDetected VerifChildVisit VerifClosesBody VerifFlipBody VerifLookup
 HashLookup BuiltLookup NativeFlipPayload NativeDepthFlip EnabledCall OverlapColumnState OverlapView
 PreparedPairStorage PreparedPairLedger PreparedPairEvent PreparedWitnessRegister PreparedLeafWorkspace
 PreparedPairDispatch PreparedPlainDescent PreparedPlainLeafEvent PreparedIndexWitnessScan PreparedIndexWitnessUndo
 PreparedDepthSpec PreparedChildCall PreparedAnswerFrame PreparedPCMLeafVisit PreparedPlainReachable.
From mathcomp Require Import all_ssreflect all_algebra.
Require Import PreparedMatrixPath PreparedMatrixResponse PreparedLeafAtPath PreparedInteriorReport PreparedObservedWitness
 PreparedRecursiveCall PreparedSeedDispatch PreparedInitialLookup PackedDetector PCMLeafAPI LeafMatrix LevelSearch flag_level_ast.
#[local] Existing Instance VerifDetected.CompSpecs.
Set Implicit Arguments.
Unset Strict Implicit.
Local Open Scope ring_scope.
Local Delimit Scope Z_scope with coqZ.

Definition independent_leaf_counters s:=
 (EX cl:int64, EX lv:int64, field_at Tsh level_type [StructField _closed] (Vlong cl) s *
        field_at Tsh level_type [StructField _leaf2] (Vlong lv) s)%logic.
Definition index_flip_heap c p ks mask tab links initial (frame:Values.val->mpred):=
 physical_store c Bare ks (pk p) initial (fun s=>
   (static_leaf_index s p mask tab links * independent_leaf_counters s * frame s)%logic).

Lemma open_registered_leaf c p ks mask tab links initial frame s cp w path st prefix saved:
 let t:=payload_after Bare ks initial prefix in
 (child_fields s cp (pb p) w (OverlapColumnState.blocked st) path *
  index_flip_heap c p ks mask tab links initial frame s prefix * witness_register s saved)%logic =
 (!!physical_prefix c prefix && (EX cl:int64, EX lv:int64,
      index_pair_storage s cp w st path t p ks mask tab links cl lv saved * frame s))%logic.
Proof.
 move=>t;unfold index_flip_heap,physical_store,static_leaf_index,independent_leaf_counters,
     index_pair_storage,lookup_index,pair_registers,t.
 cbn [table_book slots HashLookup.mask HashLookup.links];apply pred_ext;
 Intros cl lv;Exists cl lv;entailer!;cancel.
Qed.

Section Leaf.
Variable Espec:OracleKind.
#[local] Existing Instance Espec.
Variables m n r k:nat.
Variables (H:'M['F_2]_(m,n)) (S:'M['F_2]_(r,n)) (G:'M['F_2]_(k,n))
 (column_rows:'I_n->seq 'I_m) (rowkey:'I_m->int64) (keys:seq int64) (mask:int64) (cap bits:Z)
 (tab links:seq Z) (c:policy_state) (p:lookup_ptrs) (initial:packed_support) (initial_blocks:seq Integers.int)
 (work:Values.val->mpred) (eligible:seq Integers.int->'cV['F_2]_n->Prop)
 (s cp children:Values.val) (options saved:Integers.int) (cells:seq Integers.int) (st:snapshot).
Hypotheses (orth:H*m S^T=0) (det:G*m S^T=0) (shape:(\rank (col_mx H G)+\rank S=n)%N)
 (row_cap:(Z.of_nat m<=Int.max_signed)%coqZ)
 (idx:@table_for_lookup m n H column_rows rowkey keys mask cap bits tab links c p)
 (base_safe:book_safe (table_book keys mask (checksum initial) tab links initial_blocks) (words_at initial) (odd_count initial))
 (encoded:@encoded_at m n k G column_rows Bare initial)
 (zero:pcm_response H G rowkey (0:'cV['F_2]_n) initial) (plain:nested_policy (nested c)=nullval).

Theorem reached_inline_visit flip dfs depth q count i (frame:mpred):
 (1<=depth<=Int.max_signed-2)%coqZ -> (depth+1<Zlength cells)%coqZ ->
 let node:=append_qubit cells depth q in let w:=(depth+2)%coqZ in
 reachable_prefix n st node ->
 let heap:=index_flip_heap c p keys mask tab links initial work in
 let owned path written:=(child_fields s cp (pb p) w (OverlapColumnState.blocked st) path *
         heap s node * witness_register s written * frame)%logic in
 let locs:=plain_descent_loc s depth q children count i options in
 semax (func_tycontext f_dfs prepared_vars (visit_calls flip dfs) nil)
 (PROPx nil (LOCALx (temp _result (Vint Int.zero)::locs) (SEPx [::owned cells saved]))) child_bracket
 (normal_ret_assert (EX tail:seq Integers.int, EX code:Z, EX written:Integers.int,
   PROPx [::(0<=code<=3)%coqZ;Zlength tail=Zlength cells;active_prefix (depth+1)%coqZ tail=node;
      recursive_result H S G eligible w st node code tail;
      witness_at_limit w saved code written tail /\ (witness_status code -> stored_css_prefix H S (Int.signed written) tail)]
   (LOCALx (temp _result (Vint (Int.repr code))::locs) (SEPx [::owned tail written])))).
Proof.
 move=>bound room node w [ids [unique [trace [width protected]]]] heap owned locs.
 have [built positive dim spare period bits_ok low fit no_dup incidence stored alias]:=idx.
 have n_fit:(Z.of_nat n<=Int.max_signed)%coqZ by rewrite -dim;exact:(qubits_fit _ _ _ base_safe).
 have num:Zlength node=(depth+1)%coqZ by rewrite /node /append_qubit /active_prefix Zlength_app Zlength_sublist;cbn;lia.
 rewrite trace /literal_path Zlength_map Zlength_correct in num.
 pose P:=[set a:'I_n | a \in ids].
 pose t:=payload_after Bare keys initial node.
 have reached:@reached_leaf m n k H G column_rows rowkey keys mask tab links Bare initial P st node.
 { rewrite trace;apply (@reached_leaf_from_initial m n k H G rowkey column_rows Bare keys mask tab links initial
     initial_blocks row_cap dim positive no_dup incidence);try eassumption.
   - move=>a;constructor.
   - by rewrite width dim. }
 case:reached=>dis enc physical safe [odd pars].
 eapply semax_Delta_subsumption;[exact (proj2 (visit_contexts _ _))|].
 have expose path written:
   owned path written=( (!!physical_prefix c node &&
      (EX cl:int64,EX lv:int64,index_pair_storage s cp w st path t p keys mask tab links cl lv written * work s)) * frame)%logic.
 { unfold owned,heap,t;by rewrite open_registered_leaf. }
 rewrite expose;Intros cl lv.
 have raw:=@inline_child_verdict Espec m n k H G P (@available_now n st) column_rows rowkey c st t keys mask
   cap bits tab links s cp p built positive dim spare period bits_ok low dis (@available_in_view n st)
   fit no_dup incidence enc stored physical safe plain r S ids eligible depth q children count i options cells
   cl lv saved orth det shape n_fit unique Logic.eq_refl Logic.eq_refl bound room (Logic.eq_sym num) trace odd pars.
 pose proof (frame_answer _ _ _ _ _ _ _ _ (work s * frame)%logic raw) as held.
 eapply semax_post'.
 2:{ eapply semax_pre;last exact held;unfold locs,plain_descent_loc;entailer!;cancel;try apply derives_refl. }
 Intros e.
 pose detect:=packed_detects (parities (words_at t)).
 Exists (pair_path depth (upd_Znth depth cells (Int.repr q)) e) (pair_code detect e) (pair_size depth saved detect e).
 rewrite expose trace;unfold locs,plain_descent_loc,detect;entailer!.
 Exists (pair_counts cl lv e).1 (pair_counts cl lv e).2;entailer!;cancel;try apply derives_refl.
Qed.
End Leaf.
