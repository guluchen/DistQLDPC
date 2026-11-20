(* Complete PURE loop-shape transition for a discardable top frame. The raw
   frame update models spatial forgetting of stale bytes, not a C write. Actual
   complete C caller/while composition remains a separate obligation. *)
Require Import VST.floyd.proofauto.
Require Import CCV.CCModel CCV.CCFunctional CCV.CCCache CCV.CCSearchSpecs
 CCV.CCStackInvariant CCV.CCLoopInvariant CCV.CCPopCoverage CCV.CCPopMemory
 CCV.CCPopGeometry CCV.CCSearchPhases CCV.CCSearchSeparation CCV.CCJournal
 CCV.CCJournalArray CCV.CCJournalTrace CCV.CCJournalSnapshots CCV.CCRootArray
 CCV.CCRepresentation CCV.CCResumeCoverage CCV.CCFrameUpdates CCV.CCAPIBridge.
Import ListNotations. Open Scope Z_scope.
Lemma journal_prefix_false n base log mark i:
 Zlength base=n ->Forall(fun q:Z=>0<=q<n)log ->0<=mark<=Zlength log ->
 decode(journal_bitmap base log)i=false ->
 decode(journal_bitmap base(sublist 0 mark log))i=false.
Proof.
 intros Len Range Mark Old.
 rewrite(journal_bitmap_decode n base log Len Range)in Old.
 rewrite(journal_bitmap_decode n base(sublist 0 mark log)Len)
 by(apply Forall_sublist;assumption).
 apply fresh_journal in Old;destruct Old as[Base Clear].
 unfold forbidden;rewrite Base;cbn;apply memberb_false.
 intro Hin;apply Clear;rewrite(nat_journal_split log mark Mark);apply in_or_app;right;assumption.
Qed.
Theorem loop_shape_pop a cap seed parent_path prefix g log buf xs ys zs pk frames q:
 legal_model a ->0<=seed<=model_n a ->
 (ghost_phase g=0%nat\/ghost_phase g=1%nat) ->
 loop_shape a cap seed(parent_path++[q])(prefix++[g])log buf xs ys zs pk frames ->
 (forall e,minimum(Z.to_nat(model_n a))(model_h_rows a)(model_l_rows a)e ->
 (weight(Z.to_nat(model_n a))e<=Z.to_nat cap)%nat ->e(Z.to_nat seed)=true ->
 ~critical_at(Z.to_nat(model_n a))(model_h_rows a)(root_mask(model_n a)seed)log
 (parent_path++[q])(prefix++[g])e(length prefix)) ->
 loop_shape a cap seed parent_path prefix(popped_log g log)buf xs ys zs pk
 (popped_raw_frames prefix frames).
Proof.
 intros Legal Seed Kind Whole NoLast.
 pose proof(legal_model_ranges a Legal)as[NR[MR[LR[KR Rest]]]].
 assert(N:0<model_n a)by lia.
 pose proof Whole as Shape;unfold loop_shape in Shape.
 destruct Shape as[XL[YL[ZL[PKL[XB[YB[ZB[PKB[Trace[HC[LC[Phys[Geo[Tracks[Sep[Wgt[Before Live]]]]]]]]]]]]]]]]].
 pose proof Geo as Geometry;unfold stack_geometry in Geometry.
 destruct Geometry as[Len[ND[Range[Depth Per]]]].
 assert(ParentLen:length parent_path=length prefix)by(rewrite !app_length in Len;cbn[length]in Len;lia).
 pose proof(Per(length prefix)g(old_last prefix g))as[PB[Mark More]].
 assert(BaseLen:Zlength(root_mask(model_n a)seed)=model_n a)by(apply root_mask_length;assumption).
 assert(LogRange:Forall(fun i:Z=>0<=i<model_n a)log)by(unfold journal_trace in Trace;tauto).
 pose proof(path_length_bound(Z.to_nat(model_n a))(parent_path++[q])ND Range)as Capacity.
 assert(FrameRoom:(length prefix<Z.to_nat(model_n a))%nat).
 { rewrite app_length in Capacity;cbn[length]in Capacity;lia. }
 unfold loop_shape.
 split;[assumption|split;[assumption|split;[assumption|split;[assumption|]]]].
 split;[assumption|split;[assumption|split;[assumption|split;[assumption|]]]].
 split;[unfold popped_log;apply journal_trace_prefix;assumption|].
 split;[assumption|split;[assumption|]].
 split;[apply(pop_physical_stack(Z.to_nat(model_n a))prefix g frames);assumption|].
 split;[apply(geometry_pop(Z.to_nat(model_n a))(Z.to_nat(model_m a))(Z.to_nat cap)
 (model_h_rows a)parent_path prefix g log q);assumption|].
 split;[apply(popped_selected_tracks(Z.to_nat(model_n a))(Z.to_nat(model_m a))(Z.to_nat cap)
 (model_h_rows a)(Z.to_nat seed)parent_path prefix g log q xs);assumption|].
 split.
 - intros i I Hit;unfold popped_log.
   apply(journal_prefix_false(model_n a)(root_mask(model_n a)seed)log(ghost_mark g)i);
   try assumption;apply Sep;assumption.
 - split;[assumption|split;[assumption|]].
   apply(pop_preserves_live_with_geometry(Z.to_nat(model_n a))(Z.to_nat(model_m a))
   (model_h_rows a)(model_l_rows a)(Z.to_nat cap)(Z.to_nat seed)(root_mask(model_n a)seed)
   log parent_path prefix g q);assumption.
Qed.
Print Assumptions journal_prefix_false.
Print Assumptions loop_shape_pop.
