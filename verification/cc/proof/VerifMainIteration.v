(* Complete real inner-search iteration, including budget exhaustion and all
   phase dispatches. This is partial correctness; total termination is separate. *)
Require Import VST.floyd.proofauto.
Require Import CCV.ccv_core CCV.CCSearchSpecs CCV.CCSearchContext CCV.CCSearchFragments
 CCV.CCSearchMemory CCV.CCSearchHeap CCV.CCLoopInvariant CCV.CCStackInvariant CCV.CCJournalArray
 CCV.CCRootArray CCV.CCSearchExit CCV.CCAPIBridge CCV.CCStatsFields CCV.CCStatsInvariant CCV.CCPhaseZeroStats
 CCV.CCReturnCompose CCV.VerifSearchEnter CCV.VerifPhaseDispatch CCV.VerifUnknownResult.
Import ListNotations. Open Scope Z_scope.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
Definition iteration_head sh a p tp rp cap seed budget rules s(path:list nat)log buf xs ys zs pk frames:assert:=
 (PROP()LOCAL(temp _p(ptr_problem p);temp _w(ptr_workspace p);temp _out(ptr_out p);
 temp _stats(ptr_stats p);temp _cap(Vint(Int.repr cap));temp _seed(Vint(Int.repr seed));
 temp _budget(Vint(Int.repr budget));temp _rules(Vint(Int.repr rules));
 temp _depth(Vint(Int.repr(Z.of_nat(length path))));lvar _top tuint tp;lvar _row tuint rp)
 SEP(search_heap sh a p tp rp(Zlength log)xs(journal_bitmap(root_mask(model_n a)seed)log)
 ys zs pk buf frames(Zrepeat 0(model_n a))s))%assert.
Section Proof.
Context{Espec:OracleKind}.
Lemma block_main_iteration:forall sh a p tp rp cap seed budget rules s0 s path prefix g log buf xs ys zs pk frames,
 readable_share sh ->legal_model a ->1<=cap<=model_n a ->0<=seed<=model_n a ->0<=rules<=63 ->
 legal_stats budget s ->stats_monotone s0 s ->
 loop_shape a cap seed path(prefix++[g])log buf xs ys zs pk frames ->
 semax CCSearchContext.Delta
 (iteration_head sh a p tp rp cap seed budget rules s path log buf xs ys zs pk frames)
 search_main_iteration
 (overridePost(search_while_invariant sh a p tp rp cap seed budget rules s0)
 (function_body_ret_assert tint(search_return sh a p tp rp cap budget s0))).
Proof.
 intros sh a p tp rp cap seed budget rules s0 s path prefix g log buf xs ys zs pk frames
 SH Legal Cap Seed Rules Stats Mono Whole.
 pose proof(legal_model_ranges a Legal)as[NR[MR[LR[KR Rest]]]].
 assert(Geo:stack_geometry(Z.to_nat(model_n a))(Z.to_nat(model_m a))(Z.to_nat cap)
 (model_h_rows a)path(prefix++[g])log)by(unfold loop_shape in Whole;tauto).
 assert(Phys:physical_stack(Z.to_nat(model_n a))(prefix++[g])frames)by(unfold loop_shape in Whole;tauto).
 destruct Geo as[Len[ND[Range[Depth Per]]]].
 pose proof(CCSearchPhases.path_length_bound(Z.to_nat(model_n a))path ND Range)as Capacity.
 assert(PathLen:length path=S(length prefix))by(rewrite app_length in Len;cbn[length]in Len;lia).
 assert(DRange:1<=Z.of_nat(length path)<=model_n a).
 { apply Nat2Z.inj_le in Capacity;rewrite Z2Nat.id in Capacity by lia;lia. }
 assert(FrameLen:Zlength frames=model_n a)by(unfold physical_stack in Phys;rewrite Z2Nat.id in Phys by lia;tauto).
 destruct(Z_le_dec budget(stat_steps s))as[Exhausted|Fuel].
 - rewrite enter_actual_layout.
   eapply returned_sequence with(R:=function_body_ret_assert tint(search_return sh a p tp rp cap budget s0));[reflexivity|].
   eapply semax_pre.
   2:{ apply(block_exhausted_guard_result sh a p tp rp(Zlength log)xs
   (journal_bitmap(root_mask(model_n a)seed)log)ys zs pk buf frames(Zrepeat 0(model_n a))s cap budget s0);
   try assumption;try(unfold loop_shape in Whole;tauto).
   - apply journal_bitmap_length;[apply root_mask_length;assumption|].
     assert(Trace:CCJournalTrace.journal_trace(model_n a)(root_mask(model_n a)seed)log buf)by(unfold loop_shape in Whole;tauto).
     unfold CCJournalTrace.journal_trace in Trace;tauto.
   - rewrite Zlength_Zrepeat;lia.
   }
   unfold iteration_head;go_lowerx;normalize;cancel;try(apply andp_right;[apply prop_right;tauto|cancel]).
 - assert(FuelRoom:stat_steps s<budget)by lia.
   pose proof(other_phase_step_safe budget s Stats FuelRoom)as[StepStats StepMono].
   pose proof(stats_monotone_trans s0 s(step_stats s)Mono StepMono)as TotalMono.
   pose proof(step_creates_node_room budget s Stats)as NodeRoom.
   assert(Add:Int.add(Int.repr(stat_steps s))(Int.repr 1)=Int.repr(stat_steps s+1)).
   { unfold Int.add;rewrite !Int.unsigned_repr by(unfold legal_stats in Stats;rep_lia);reflexivity. }
   unfold iteration_head at 1.
   unfold CCSearchContext.Delta;abbreviate_semax.
   let C:=eval cbv -[Int.repr]in search_main_iteration in
   lazymatch goal with|-semax ?D ?P _ ?R=>change(semax D P C R)end.
   unfold search_heap,workspace_fields;rewrite stats_repr_fields;unfold stats_fields. Intros.
   assert_PROP(field_compatible(tarray CCSearchSpecs.frame_type(model_n a))[](ptr_frames p))as FC by entailer!.
   assert(Address:active_frame_address p(model_n a)(Z.of_nat(length path))=
   offset_val(20*(Z.of_nat(length path)-1))(ptr_frames p)).
   { unfold active_frame_address,CCSearchMemory.frame_type.
     rewrite field_address0_offset by auto with field_compatible.
     cbn. autorewrite with norm. reflexivity. }
   forward. forward_if.
   { unfold legal_stats in Stats;rewrite !Int.unsigned_repr in * by lia;lia. }
   forward. forward. rewrite Add.
   forward. forward. forward.
   eapply semax_pre.
   2:{ apply(block_phase_dispatch sh a p tp rp cap seed budget rules s0(step_stats s)
   path prefix g log buf xs ys zs pk frames);assumption. }
   unfold search_heap,workspace_fields;rewrite stats_repr_fields;unfold stats_fields.
   cbn[step_stats stat_steps stat_nodes stat_pack stat_charge stat_overlap].
   rewrite Address;go_lowerx;normalize;cancel;try(apply andp_right;[apply prop_right;tauto|cancel]).
   unfold_lift in *.
   assert(Ptr:isptr(ptr_frames p))by(unfold field_compatible in FC;tauto).
   assert(SubDepth:Int.sub(Int.repr(Z.of_nat(length path)))(Int.repr 1)=Int.repr(Z.of_nat(length path)-1)).
   { unfold Int.sub;rewrite !Int.unsigned_repr by rep_lia;reflexivity. }
   rewrite SubDepth in *.
   unfold sem_add_ptr_int in *.
   rewrite sem_add_pi_ptr in * by(auto;rep_lia).
   cbn[force_val]in *.
   change(sizeof(Tstruct _ccv_frame noattr))with 20 in *.
   apply andp_right;[apply prop_right;tauto|cancel].
Qed.
End Proof.
Print Assumptions block_main_iteration.
