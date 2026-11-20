(* Physical-array and journal facts for pending-child resume. Pure transitions;
   no claim that all C iterations preserve the whole-loop invariant. *)
Require Import VST.floyd.proofauto.
Require Import CCV.ccv_core CCV.CCSearchSpecs CCV.CCSearchHeap CCV.CCStackInvariant
 CCV.CCFrameUpdates CCV.CCResumeCoverage CCV.CCJournalArray CCV.CCJournalTrace
 CCV.CCRepresentation CCV.CCFunctional CCV.CCCache CCV.CCSearchPhases
 CCV.CCRootInvariant CCV.CCLoopInvariant CCV.VerifPhaseOneTail CCV.VerifForbid.
Import ListNotations. Open Scope nat_scope.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
Definition resume_raw_frames(prefix:list ghost_frame)(raw:list frame_value):=
 upd_Znth(Z.of_nat(length prefix))raw
 (set_raw_phase(Znth(Z.of_nat(length prefix))raw)1%Z).
Definition resume_buffer(exclude:bool)(log:list Z)(buf:list val)(g:ghost_frame):=
 if exclude then upd_Znth(Zlength log)buf(Vint(Int.repr(Z.of_nat(ghost_chosen g))))else buf.
Lemma nth_snoc_last{A:Type}(prefix:list A)a d:nth(length prefix)(prefix++[a])d=a.
Proof. induction prefix;cbn[length app nth];auto. Qed.
Lemma resume_nth_before prefix g i:i<length prefix ->
 nth i(prefix++[resumed_record g])empty_ghost=nth i(prefix++[g])empty_ghost.
Proof.
 revert i;induction prefix as[|a prefix IH];intros[|i]I;cbn[app nth length]in*;
 try lia;try reflexivity;apply IH;lia.
Qed.
Theorem resume_physical_stack n prefix g raw:
 ghost_phase g=2 ->length(prefix++[g])<=n ->physical_stack n(prefix++[g])raw ->
 physical_stack n(prefix++[resumed_record g])(resume_raw_frames prefix raw).
Proof.
 intros Phase Capacity[Len Cells].
 assert(Top:length prefix<n)by(rewrite app_length in Capacity;cbn[length]in Capacity;lia).
 assert(Bound:(0<=Z.of_nat(length prefix)<Zlength raw)%Z)by(rewrite Len;lia).
 unfold physical_stack,resume_raw_frames;split.
 - rewrite upd_Znth_Zlength by exact Bound;exact Len.
 - intros i I;pose proof(Cells i I)as Cell.
   destruct(Nat.eq_dec i(length prefix))as[->|Ne].
   + destruct(lt_dec(length prefix)(length(prefix++[resumed_record g])))as[Inside|Outside].
     2:{ rewrite app_length in Outside;cbn[length]in Outside;lia. }
     rewrite nth_snoc_last,upd_Znth_same by exact Bound.
     apply frame_represents_resume;[assumption|].
     destruct(lt_dec(length prefix)(length(prefix++[g])))as[InOld|OutOld].
     2:{ rewrite app_length in OutOld;cbn[length]in OutOld;lia. }
     rewrite nth_snoc_last in Cell;exact Cell.
   + assert(IZ:(0<=Z.of_nat i<Zlength raw)%Z)by(rewrite Len;lia).
     rewrite upd_Znth_diff by lia.
     rewrite resume_length.
     destruct(lt_dec i(length(prefix++[g])))as[Active|Inactive].
     * assert(Before:i<length prefix)by(rewrite app_length in Active;cbn[length]in Active;lia).
       rewrite resume_nth_before by assumption;exact Cell.
     * exact Cell.
Qed.
Open Scope Z_scope.
Lemma resume_bitmap base log g exclude:
 journal_bitmap base(resume_log exclude log g)=
 if exclude then upd_Znth(Z.of_nat(ghost_chosen g))(journal_bitmap base log)1
 else journal_bitmap base log.
Proof. unfold resume_log;destruct exclude;[apply journal_bitmap_push|reflexivity]. Qed.
Theorem resume_journal_trace n base log buf g exclude:
 0<=n ->Zlength base=n ->journal_trace n base log buf ->
 0<=Z.of_nat(ghost_chosen g)<n ->Znth(Z.of_nat(ghost_chosen g))(journal_bitmap base log)=0 ->
 journal_trace n base(resume_log exclude log g)(resume_buffer exclude log buf g).
Proof.
 intros N Len Trace Q Free;destruct exclude;[|exact Trace].
 pose proof(forbid_trace_step n base log buf(Z.of_nat(ghost_chosen g))N Len Trace Q)as[Ret New].
 assert(Range:Forall(fun q:Z=>0<=q<n)log)by(unfold journal_trace in Trace;tauto).
 assert(ND:NoDup(nat_journal log))by(unfold journal_trace in Trace;tauto).
 pose proof(journal_fresh_capacity n base log(Z.of_nat(ghost_chosen g))N Len Range ND Q Free)as[Room Rest].
 assert(Fresh:fresh_push(journal_bitmap base log)(Z.of_nat(ghost_chosen g))(Zlength log)n=true).
 { unfold fresh_push;repeat if_tac;try congruence;try lia;reflexivity. }
 unfold pushed_log,pushed_buffer in New;rewrite Fresh in New;exact New.
Qed.
Lemma resumed_selected_decode n g xs:
 Zlength xs=n ->Forall(fun z:Z=>z=0\/z=1)xs ->0<=Z.of_nat(ghost_chosen g)<n ->
 forall i,(i<Z.to_nat n)%nat ->
 decode(chosen_xs(Z.of_nat(ghost_chosen g))xs)i=flip(decode xs)(ghost_chosen g)i.
Proof.
 intros Len Bits Q i I;unfold chosen_xs.
 rewrite(decode_toggle xs(Z.of_nat(ghost_chosen g))ltac:(lia)Bits i ltac:(rewrite Len;exact I)).
 rewrite Nat2Z.id;reflexivity.
Qed.
Theorem resumed_selected_tracks n seed path prefix g xs:
 Zlength xs=n ->Forall(fun z:Z=>z=0\/z=1)xs ->0<=Z.of_nat(ghost_chosen g)<n ->
 ghost_phase g=2%nat ->
 selected_tracks_stack(Z.to_nat n)seed path(prefix++[g])xs ->
 selected_tracks_stack(Z.to_nat n)seed path(prefix++[resumed_record g])
 (chosen_xs(Z.of_nat(ghost_chosen g))xs).
Proof.
 intros Len Bits Q Phase Tracks.
 unfold selected_tracks_stack in Tracks |- *.
 rewrite !rev_app_distr in Tracks |- *;cbn[rev app resumed_record ghost_phase ghost_chosen]in*.
 destruct Tracks as[Nonempty[Root State]];rewrite Phase in State.
 split;[assumption|split;[assumption|]].
 change(phase_path(Z.to_nat n)(length path)1 0 path
   (decode(chosen_xs(Z.of_nat(ghost_chosen g))xs))).
 apply(phase_selected_ext _ _ _ _ _ (flip(decode xs)(ghost_chosen g))).
 - intros i I;exact(resumed_selected_decode n g xs Len Bits Q i I).
 - apply phase_pending_undo;exact State.
Qed.
Print Assumptions resume_physical_stack.
Print Assumptions resume_journal_trace.
Print Assumptions resumed_selected_tracks.
