(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.floyd.reassoc_seq VST.zlist.list_solver.
Require Import VerifDetected level_ast VerifChildVisit SeedLoopModel VerifRootCall VerifRootAdmission
 VerifSeedBranch EnabledCall EnabledLoopFacts OverlapColumnState OverlapChildState OverlapView SeedPolicyView
 SeedColumnModel SeedColumnRestore SeedResume RootOwnerMemory VerifSeedMove SeedCallFrame SeedFramedCallback.
#[local] Existing Instance VerifDetected.CompSpecs.
Local Open Scope Z_scope.
Record exemption_source:={ seed_geom:seed_column; limit_address:val; base_address:val; fallback_address:val; seed_limits:list int }.
Definition row_heap c fp d:=seed_heap c fp (limit_address d) (base_address d) (fallback_address d) (seed_geom d) (seed_limits d).
Definition keep_seed c fp d:=seed_reserve c fp (seed_geom d) (limit_address d) (base_address d) (fallback_address d) (seed_limits d).
Definition before_visit c s cp w path fp d moving st calls extra:=
 ((row_heap c fp d moving * root_reserve c s cp w path st) *
  (active_support (nested c) s None * seed_counter s calls * extra))%logic.
Definition after_exemption d enter q st:=full_column (seed_geom d) (seed_limits d) enter q st.
Definition seed_calls_count st q calls :=if available st q then Int64.add calls Int64.one else calls.
Lemma reserve_with_counts c s cp w path run st:
 root_reserve c s cp w path (make_run run st)=root_reserve c s cp w path run.
Proof. reflexivity. Qed.

Lemma transfer_dfs_heap c s cp w path fp d moving st calls extra:
 isptr (callback_owner c) -> @field_compatible SeedC seed_type [] (callback_owner c) ->
 column_offsets (geometry c)=col_starts (seed_geom d) -> column_rows (geometry c)=col_rows (seed_geom d) ->
 exempt_qubits (geometry c)=Some (exempts moving) -> blocked st=reference_counts moving ->
 forbidden st=forbidden_events moving -> 0<Zlength (exempts moving) -> 0<Zlength (reference_counts moving) ->
 before_visit c s cp w path fp d moving st calls extra =
 (enabled_memory c s cp w path st * active_support (nested c) s None * live_links c * seed_counter s calls *
  (keep_seed c fp d * extra))%logic.
Proof.
 intros;unfold before_visit,row_heap,keep_seed;rewrite start_root_borrow by assumption;apply pred_ext;cancel.
Qed.

Lemma seed_callback_framed {Espec:OracleKind} policies c s cp w path fp d moving st q enter i count result calls extra :
 isptr (nested_policy (nested c)) -> isptr fp -> is_pointer_or_null (callback_owner c) ->
 column_safe (seed_geom d) (seed_limits d) enter q moving ->
 semax (func_tycontext f_cc_run_level Vprog (RootG policies) [])
 (PROPx [] (LOCALx (seed_preserved s (nested_policy (nested c)) q i count result)
   (SEPx [before_visit c s cp w path fp d moving st calls extra])))
 (if enter then exempt_in else exempt_out)
 (normal_ret_assert (PROPx [] (LOCALx (seed_preserved s (nested_policy (nested c)) q i count result)
   (SEPx [before_visit c s cp w path fp d (after_exemption d enter q moving) st calls extra])))).
Proof.
 intros pp pf own safe;unfold before_visit.
 rewrite !sepcon_assoc.
 apply one_call_frame;unfold row_heap,seed_heap,after_exemption,full_column.
 apply dispatch_tiebreak;assumption.
Qed.

Theorem physical_seed_visit {Espec:OracleKind} c s cp w path fp d initial template q i count calls extra :
 let entered:=after_exemption d true q initial in let active:=make_run template entered in
 let r:=seed_outcome c active q in
 1<=w<=Int.max_signed -> w<=Zlength path -> 0<=q<Zlength (blocked active) -> q<=Int.max_signed ->
 isptr (nested_policy (nested c)) -> isptr fp -> isptr (callback_addr c) ->
 isptr (callback_owner c) -> @field_compatible SeedC seed_type [] (callback_owner c) ->
 column_offsets (geometry c)=col_starts (seed_geom d) -> column_rows (geometry c)=col_rows (seed_geom d) ->
 exempt_qubits (geometry c)=Some (exempts entered) ->
 0<Zlength (exempts entered) -> 0<Zlength (reference_counts initial) ->
 column_safe (seed_geom d) (seed_limits d) true q initial ->
 column_safe (seed_geom d) (seed_limits d) false q entered ->
 (forall k,0<=k<Zlength (exempts initial) -> touched (seed_geom d) q (index_at (seed_geom d) (q+1)) k=true ->
  Znth k (exempts initial)=Int.repr (seed_choice (base_order (seed_geom d)) (first_block (seed_geom d)) k q false)) ->
 (available active q=true -> seed_checked c active q) ->
 semax (func_tycontext f_cc_run_level Vprog (RootG c) [])
 (PROPx [] (LOCALx (root_call_loc c s q i count) (SEPx [before_visit c s cp w path fp d initial template calls extra])))
 visit_and_restore
 (normal_ret_assert (EX final:snapshot,EX tail:list int,EX left:moving_state,
  PROPx [same_search final active;0<=r<=3;Zlength tail=Zlength path;same_seed_state left initial;
    available active q=false -> tail=path;available active q=true ->
     root_trace c (after_column (geometry c) q true (selected active q)) q path tail]
  (LOCALx (temp _result (Vint (Int.repr r))::root_call_loc c s q i count)
   (SEPx [before_visit c s cp w tail fp d left final (seed_calls_count active q calls) extra])))).
Proof.
 intros entered active r size room key sign pp pf overlap_addr owner_valid layout_ok starts rows ex cur_size width on off rest choose.
 assert (owner_ok:is_pointer_or_null (callback_owner c)) by (destruct (callback_owner c);try contradiction;constructor).
 unfold visit_and_restore;eapply semax_seq'.
 { eapply semax_pre;[|apply (@seed_callback_framed Espec c c s cp w path fp d initial template q true i count None calls extra pp pf owner_ok on)].
   unfold seed_preserved,root_call_loc;cbn [app];entailer!;try apply derives_refl. }
 unfold seed_preserved;cbn [app];Intros;rewrite checked_zero_result;abbreviate_semax;forward.
 fold entered;eapply semax_seq'.
 { eapply semax_pre;[|apply (@enabled_root_admission Espec c s cp w q active path i count calls (keep_seed c fp d * extra)%logic)];
     try eassumption.
   assert (mem:before_visit c s cp w path fp d entered template calls extra =
      (enabled_memory c s cp w path active * active_support (nested c) s None * live_links c * seed_counter s calls *
       (keep_seed c fp d * extra))%logic).
   { change (before_visit c s cp w path fp d entered active calls extra =
       (enabled_memory c s cp w path active * active_support (nested c) s None * live_links c * seed_counter s calls *
        (keep_seed c fp d * extra))%logic).
     apply transfer_dfs_heap;try assumption;try reflexivity;unfold active,make_run in key;cbn [blocked] in key;lia. }
   unfold root_call_loc;rewrite mem;entailer!;try cancel. }
 Intros final tail;set (resumed:=borrow_moving (exempts entered) final).
 assert (saved:same_seed_state entered resumed) by
  (split;[reflexivity|symmetry;match goal with H:same_search final active |- _=>exact (proj2 H) end]).
 assert (leave:column_safe (seed_geom d) (seed_limits d) false q resumed) by (eapply same_seed_precondition;eassumption).
 set (left:=after_exemption d false q resumed).
 assert (restored:same_seed_state left initial) by
  (unfold left,after_exemption;eapply restored_after_root_visit;eassumption).
 eapply semax_post'.
 2:{ eapply semax_pre;[|apply (@seed_callback_framed Espec c c s cp w tail fp d resumed final q false i count
     (Some (Int.repr r)) (seed_calls_count active q calls) extra pp pf owner_ok leave)].
     rewrite transfer_dfs_heap;try assumption;try reflexivity.
     2:{ change (0<Zlength (blocked final));match goal with H:same_search final active |- _=>rewrite (proj2 H);lia end. }
     unfold root_call_loc,seed_preserved,seed_calls_count,r;cbn [app];entailer!;try cancel. }
 Exists final tail left;unfold root_call_loc,seed_preserved;cbn [app];fold left;entailer!;try apply derives_refl.
Qed.
