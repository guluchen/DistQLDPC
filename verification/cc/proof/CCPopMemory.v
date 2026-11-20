(* Physical frame forgetting and phase-sensitive selected bits after a pop.
   Pure representation facts; complete actual C caller refinement is separate. *)
Require Import VST.floyd.proofauto.
Require Import CCV.ccv_core CCV.CCSearchSpecs CCV.CCSearchHeap CCV.CCStackInvariant
 CCV.CCPopCoverage CCV.CCFrameForget CCV.CCResumeMemory CCV.CCSearchPhases
 CCV.CCLoopInvariant CCV.CCRootInvariant CCV.CCRepresentation CCV.CCFrameUpdates
 CCV.CCResumeCoverage CCV.CCFunctional.
Import ListNotations. Open Scope nat_scope.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
Definition popped_raw_frames(prefix:list ghost_frame)(raw:list frame_value):=
 upd_Znth(Z.of_nat(length prefix))raw default_frame.
Theorem pop_physical_stack n prefix g raw:
 length prefix<n ->physical_stack n(prefix++[g])raw ->
 physical_stack n prefix(popped_raw_frames prefix raw).
Proof.
 intros Capacity[Len Cells];unfold physical_stack,popped_raw_frames.
 assert(P:(0<=Z.of_nat(length prefix)<Zlength raw)%Z)by(rewrite Len;lia).
 split;[rewrite upd_Znth_Zlength by assumption;exact Len|].
 intros i I;assert(IZ:(0<=Z.of_nat i<Zlength raw)%Z)by(rewrite Len;lia).
 destruct(Nat.eq_dec i(length prefix))as[->|Ne].
 - destruct(lt_dec(length prefix)(length prefix));[lia|].
   rewrite upd_Znth_same by assumption;reflexivity.
 - rewrite upd_Znth_diff by lia;pose proof(Cells i I)as Cell.
   destruct(lt_dec i(length prefix))as[Active|Inactive].
   + rewrite nth_append_before in Cell by assumption.
     destruct(lt_dec i(length(prefix++[g])))as[WasActive|Bad];[exact Cell|rewrite app_length in Bad;cbn[length]in Bad;lia].
   + destruct(lt_dec i(length(prefix++[g])))as[WasActive|Bad];[rewrite app_length in WasActive;cbn[length]in WasActive;lia|exact Cell].
Qed.
Lemma phase_finish_selected n depth phase chosen path selected:
 (phase=0\/phase=1) ->phase_path n depth phase chosen path selected ->
 phase_path n depth 0 0 path selected.
Proof.
 intros Kind[ND[Range[Len State]]];unfold phase_path.
 split;[assumption|split;[assumption|split;[assumption|]]].
 destruct Kind as[-> | ->];assumption.
Qed.
Theorem popped_selected_tracks n m cap hs seed parent_path prefix g log q xs:
 length parent_path=length prefix ->(ghost_phase g=0\/ghost_phase g=1) ->
 stack_geometry n m cap hs(parent_path++[q])(prefix++[g])log ->
 selected_tracks_stack n seed(parent_path++[q])(prefix++[g])xs ->
 selected_tracks_stack n seed parent_path prefix xs.
Proof.
 intros Len Kind Geo Tracks.
 unfold selected_tracks_stack in Tracks.
 rewrite rev_app_distr in Tracks;cbn[rev app]in Tracks.
 destruct Tracks as[Nonempty[Root State]].
 pose proof(phase_finish_selected _ _ _ _ _ _ Kind State)as OldState.
 induction prefix as[|parent prefix IH]using rev_ind.
 - assert(Empty:parent_path=[])by(apply length_zero_iff_nil;rewrite Len;reflexivity).
   subst parent_path;unfold selected_tracks_stack;cbn[rev app].
   split;[reflexivity|].
   cbn[app hd]in Root.
   destruct OldState as[ND[Range[Length Eq]]].
   intros i I;rewrite Eq by assumption;change(path_bits[q]i=CCCandidateScan.root_selected seed i);rewrite singleton_path_bits,Root;reflexivity.
 - pose proof Geo as Parts;unfold stack_geometry in Parts.
   destruct Parts as[PL[ND[Range[Depth Per]]]].
   assert(ParentAt:nth_error((prefix++[parent])++[g])(length prefix)=Some parent).
   { rewrite lookup_append_before by(rewrite app_length;cbn[length];lia);apply old_last. }
   destruct(Per(length prefix)parent ParentAt)as[PB[Mark[RootMark[Anc Init]]]].
   assert(Deep:S(length prefix)<length((prefix++[parent])++[g]))
   by(rewrite !app_length;cbn[length];lia).
   destruct(Anc Deep)as[Wait[Chosen[Next Order]]].
   assert(PathLen:length parent_path=S(length prefix))by(rewrite app_length in Len;cbn[length]in Len;lia).
   assert(Choice:ghost_chosen parent=q).
   { rewrite Chosen,<-PathLen,nth_snoc_last;reflexivity. }
   unfold selected_tracks_stack;rewrite rev_app_distr;cbn[rev app].
   split.
   + intro Empty;rewrite Empty in PathLen;simpl in PathLen;lia.
   + split.
     * destruct parent_path as[|r tail];[simpl in PathLen;lia|exact Root].
     * rewrite Wait,Choice.
       apply(phase_child_finish n(length parent_path)0 parent_path q(decode xs)).
       replace(length parent_path+1)with(length(parent_path++[q]))by(rewrite app_length;reflexivity).
       exact OldState.
Qed.
Print Assumptions pop_physical_stack.
Print Assumptions popped_selected_tracks.
