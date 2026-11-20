(* Physical explicit-stack array update for the phase1 child push.
   Pure representation theorem, separate from complete actual C loop refinement. *)
Require Import VST.floyd.proofauto.
Require Import CCV.ccv_core CCV.CCSearchSpecs CCV.CCSearchHeap CCV.CCSearchMemory
 CCV.CCStackInvariant CCV.CCPushCoverage CCV.CCResumeMemory CCV.CCFrameForget
 CCV.CCFrameFields CCV.VerifPhaseOneTail CCV.VerifSearchPush CCV.CCSearchPhases
 CCV.CCLoopInvariant CCV.CCRootInvariant CCV.CCRepresentation CCV.CCCache.
Import ListNotations. Open Scope nat_scope.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
Definition push_raw_frames(path:list nat)g q(log:list Z)(raw:list frame_value):=
 child_frames(Z.of_nat(length path))(Z.of_nat(ghost_row g))(Z.of_nat q)
 (ghost_mark g)(Zlength log)raw.
Lemma pushed_nth_before prefix g q log i:i<length prefix ->
 nth i(pushed_records prefix g q log)empty_ghost=nth i(prefix++[g])empty_ghost.
Proof.
 unfold pushed_records;revert i;induction prefix as[|a prefix IH];intros[|i]I;
 cbn[length app nth]in*;try lia;try reflexivity;apply IH;lia.
Qed.
Lemma pushed_parent_nth prefix g q log:
 nth(length prefix)(pushed_records prefix g q log)empty_ghost=chosen_record g q.
Proof. unfold pushed_records;induction prefix;cbn[length app nth];auto. Qed.
Theorem push_physical_stack n path prefix g q log raw:
 length path=length(prefix++[g]) ->length path<n ->
 physical_stack n(prefix++[g])raw ->
 physical_stack n(pushed_records prefix g q log)(push_raw_frames path g q log raw).
Proof.
 intros Len Capacity[RawLen Cells].
 assert(Depth:length path=S(length prefix))by(rewrite app_length in Len;cbn[length]in Len;lia).
 assert(P:(0<=Z.of_nat(length prefix)<Zlength raw)%Z)by(rewrite RawLen;lia).
 assert(C:(0<=Z.of_nat(length path)<Zlength raw)%Z)by(rewrite RawLen;lia).
 unfold push_raw_frames,child_frames,choice_frames.
 replace(Z.of_nat(length path)-1)%Z with(Z.of_nat(length prefix))by lia.
 set(parent:=frame_words(Z.of_nat(ghost_row g))(Z.of_nat q+1)
 (Vint(Int.repr(Z.of_nat q)))(ghost_mark g)2).
 set(parents:=upd_Znth(Z.of_nat(length prefix))raw parent).
 assert(ParentsLen:Zlength parents=Zlength raw)by(unfold parents;rewrite upd_Znth_Zlength by assumption;reflexivity).
 assert(ChildOld:Znth(Z.of_nat(length path))parents=default_frame).
 { unfold parents;rewrite upd_Znth_diff by lia.
   pose proof(Cells(length path)Capacity)as Cell.
   destruct(lt_dec(length path)(length(prefix++[g])))as[Inside|Outside];[lia|exact Cell]. }
 change(physical_stack n(pushed_records prefix g q log)
 (upd_Znth(Z.of_nat(length path))parents
 (initialized_child(Znth(Z.of_nat(length path))parents)(Zlength log)))).
 unfold physical_stack;split.
 - rewrite upd_Znth_Zlength by lia;rewrite ParentsLen;exact RawLen.
 - intros i I.
   assert(IZ:(0<=Z.of_nat i<Zlength raw)%Z)by(rewrite RawLen;lia).
   assert(NewLen:length(pushed_records prefix g q log)=S(length path))
   by(unfold pushed_records;rewrite app_length;cbn[length];lia).
   rewrite NewLen.
   destruct(Nat.eq_dec i(length path))as[->|NotChild].
   + destruct(lt_dec(length path)(S(length path)))as[Inside|Outside];[|lia].
     rewrite upd_Znth_same by lia. rewrite ChildOld.
     rewrite Depth,pushed_child_nth.
     unfold frame_represents,child_record;cbn[ghost_phase ghost_mark].
     rewrite initialized_default_child.
     exists Vundef,Vundef,Vundef;reflexivity.
   + rewrite upd_Znth_diff by lia.
     destruct(Nat.eq_dec i(length prefix))as[->|NotParent].
     * destruct(lt_dec(length prefix)(S(length path)))as[Inside|Outside];[|lia].
       unfold parents;rewrite upd_Znth_same by assumption.
       rewrite pushed_parent_nth.
       unfold frame_represents,chosen_record,parent;cbn[ghost_phase ghost_mark ghost_row ghost_next ghost_chosen].
       rewrite Nat2Z.inj_succ;reflexivity.
     * unfold parents;rewrite upd_Znth_diff by lia.
       pose proof(Cells i I)as Cell.
       destruct(lt_dec i(S(length path)))as[Active|Inactive].
       -- assert(Before:i<length prefix)by lia.
          rewrite pushed_nth_before by assumption.
          destruct(lt_dec i(length(prefix++[g])))as[WasActive|WasInactive];[exact Cell|lia].
       -- destruct(lt_dec i(length(prefix++[g])))as[WasActive|WasInactive];[lia|exact Cell].
Qed.
Theorem pushed_selected_tracks n seed path prefix g q log xs:
 Zlength xs=Z.of_nat n ->Forall(fun z:Z=>z=0%Z\/z=1%Z)xs ->q<n ->
 decode xs q=false ->ghost_phase g=1 ->
 selected_tracks_stack n seed path(prefix++[g])xs ->
 selected_tracks_stack n seed(path++[q])(pushed_records prefix g q log)
 (chosen_xs(Z.of_nat q)xs).
Proof.
 intros XL XB Q Free Phase Tracks.
 unfold selected_tracks_stack in Tracks |- *.
 rewrite rev_app_distr in Tracks;cbn[rev app]in Tracks.
 destruct Tracks as[Nonempty[Root State]];rewrite Phase in State.
 unfold pushed_records;rewrite rev_app_distr;cbn[rev app child_record ghost_phase ghost_chosen].
 split.
 - intro Empty;apply app_eq_nil in Empty;destruct Empty as[_ Empty];discriminate.
 - split.
   + destruct path as[|a path];[contradiction|exact Root].
   + apply(phase_selected_ext n(length(path++[q]))0 0(path++[q])(flip(decode xs)q)).
     * intros i I.
       unfold chosen_xs.
       rewrite(decode_toggle xs(Z.of_nat q)ltac:(lia)XB i
       ltac:(rewrite XL,Nat2Z.id;exact I)).
       rewrite Nat2Z.id;reflexivity.
     * replace(length(path++[q]))with(length path+1)by(rewrite app_length;reflexivity).
       apply(phase_push n(length path)(ghost_chosen g)path(decode xs)q);assumption.
Qed.
Print Assumptions push_physical_stack.
Print Assumptions pushed_selected_tracks.
