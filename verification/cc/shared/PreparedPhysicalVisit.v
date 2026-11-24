(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.floyd.reassoc_seq VST.zlist.list_solver.
Require Import VerifDetected level_ast VerifChildVisit SeedLoopModel VerifRootCall VerifRootAdmission
 VerifSeedBranch EnabledCall EnabledLoopFacts OverlapColumnState OverlapChildState OverlapView SeedPolicyView
 SeedColumnModel SeedColumnRestore SeedResume RootOwnerMemory VerifSeedMove SeedCallFrame SeedFramedCallback RootSearchPhases PreparedSeedDispatch PreparedOwnerLoan PreparedExemptionFrame
 PreparedRootStages PreparedRecursiveCall PreparedRootAdmission.
Require flag_level_ast.
Import flag_level_ast.
#[local] Existing Instance VerifDetected.CompSpecs.
Local Open Scope Z_scope.
Theorem physical_seed_visit {Espec:OracleKind} c report s cp w path fp d initial template q i count calls bits extra :
 let entered:=after_exemption d true q initial in let active:=make_run template entered in
 1<=w<=Int.max_signed -> w<=Zlength path -> 0<=q<Zlength (blocked active) -> q<=Int.max_signed ->
 Int.and bits (Int.repr 32)<>Int.zero -> Int.and bits (Int.repr 16)<>Int.zero ->
 isptr (callback_owner c) -> @field_compatible SeedC seed_type [] (callback_owner c) ->
 column_offsets (geometry c)=col_starts (seed_geom d) -> column_rows (geometry c)=col_rows (seed_geom d) ->
 exempt_qubits (geometry c)=Some (exempts entered) ->
 0<Zlength (exempts entered) -> 0<Zlength (reference_counts initial) ->
 column_safe (seed_geom d) (seed_limits d) true q initial ->
 column_safe (seed_geom d) (seed_limits d) false q entered ->
 (forall k,0<=k<Zlength (exempts initial) -> touched (seed_geom d) q (index_at (seed_geom d) (q+1)) k=true ->
  Znth k (exempts initial)=Int.repr (seed_choice (base_order (seed_geom d)) (first_block (seed_geom d)) k q false)) ->
 (available active q=true -> seed_checked c active q) ->
 semax (func_tycontext f_cc_run_prepared_level prepared_vars (RecG c report bits) [])
 (PROPx [] (LOCALx (visit_loc c s q i count bits) (SEPx [before_visit c s cp w path fp d initial template calls extra])))
 run_root
 (normal_ret_assert (EX final:snapshot,EX tail:list int,EX left:moving_state,EX r:Z,
  PROPx [same_search final active;0<=r<=3;Zlength tail=Zlength path;same_seed_state left initial;
    available active q=false -> r=0 /\ tail=path;available active q=true ->
     let where_:=after_column (geometry c) q true (selected active q) in
     report (geometry c) where_ q r tail /\ Znth 0 tail=Int.repr q /\
     (witness_status r -> returned_trace (nested c) (blocked where_) q tail)]
  (LOCALx (temp _result (Vint (Int.repr r))::visit_loc c s q i count bits)
   (SEPx [before_visit c s cp w tail fp d left final (seed_calls_count active q calls) extra])))).
Proof.
 intros entered active size room key sign seed_bit overlap_bit owner_valid layout_ok starts rows ex cur_size width on off rest choose.
 assert (owner_ok:is_pointer_or_null (callback_owner c)) by (destruct (callback_owner c);try contradiction;constructor).
 unfold run_root;eapply semax_seq'.
 { eapply semax_pre;[|apply (@framed_exemption Espec (snd (root_flip c bits)) (snd (root_dfs_spec c report bits)) c s cp w path fp d initial template q true i count bits None calls extra seed_bit owner_ok on)].
   unfold callback_loc,prepared_loc,saved_loc,visit_loc;cbn [app];entailer!;try apply derives_refl. }
 unfold callback_loc,prepared_loc,saved_loc;cbn [app];Intros;change clear_verdict with (Sset _result (Econst_int (Int.repr 0) tint));abbreviate_semax;forward.
 fold entered;eapply semax_seq'.
 { eapply semax_pre;[|apply (@prepared_root_admission Espec c report s cp w q active path i count calls bits (keep_seed c fp d * extra)%logic)];
     try eassumption.
   assert (mem:before_visit c s cp w path fp d entered template calls extra =
      (enabled_memory c s cp w path active * active_support (nested c) s None * seed_counter s calls *
       (keep_seed c fp d * extra))%logic).
   { change (before_visit c s cp w path fp d entered active calls extra =
       (enabled_memory c s cp w path active * active_support (nested c) s None * seed_counter s calls *
        (keep_seed c fp d * extra))%logic).
     apply transfer_dfs_heap;try assumption;try reflexivity;unfold active,make_run in key;cbn [blocked] in key;lia. }
   unfold visit_loc;rewrite mem;entailer!;try cancel. }
 Intros final tail r;set (resumed:=borrow_moving (exempts entered) final).
 assert (saved:same_seed_state entered resumed) by
  (split;[reflexivity|symmetry;match goal with H:same_search final active |- _=>exact (proj2 H) end]).
 assert (leave:column_safe (seed_geom d) (seed_limits d) false q resumed) by (eapply same_seed_precondition;eassumption).
 set (left:=after_exemption d false q resumed).
 assert (restored:same_seed_state left initial) by
  (unfold left,after_exemption;eapply restored_after_root_visit;eassumption).
 eapply semax_post'.
 2:{ eapply semax_pre;[|apply (@framed_exemption Espec (snd (root_flip c bits)) (snd (root_dfs_spec c report bits)) c s cp w tail fp d resumed final q false i count bits
     (Some (Int.repr r)) (seed_calls_count active q calls) extra seed_bit owner_ok leave)].
     rewrite transfer_dfs_heap;try assumption;try reflexivity.
     2:{ change (0<Zlength (blocked final));match goal with H:same_search final active |- _=>rewrite (proj2 H);lia end. }
     unfold visit_loc,callback_loc,prepared_loc,saved_loc,seed_calls_count;cbn [app];entailer!;try cancel. }
 Exists final tail left r;unfold visit_loc,callback_loc,prepared_loc,saved_loc;cbn [app];fold left;entailer!;try apply derives_refl.
Qed.
