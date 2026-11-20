(* Minimum-target coverage under a fresh phase1 child push. Mathematical stack
   transition only; the actual C caller/invariant connection remains separate. *)
Require Import VST.floyd.proofauto VST.zlist.list_solver.
Require Import CCV.CCModel CCV.CCFunctional CCV.CCCriticalFrame CCV.CCCandidateScan
 CCV.CCRepresentation CCV.CCFrameUpdates CCV.CCStackInvariant CCV.CCResumeCoverage CCV.CCJournalArray CCV.CCSearchPhases.
Import ListNotations. Open Scope nat_scope.
Definition chosen_record(g:ghost_frame)(q:nat):ghost_frame:={|
 ghost_phase:=2;ghost_row:=ghost_row g;ghost_next:=S q;
 ghost_chosen:=q;ghost_mark:=ghost_mark g|}.
Definition child_record(log:list Z):ghost_frame:={|
 ghost_phase:=0;ghost_row:=0;ghost_next:=0;ghost_chosen:=0;ghost_mark:=Zlength log|}.
Definition pushed_records prefix g q log:=prefix++[chosen_record g q;child_record log].
Lemma firstn_append_prefix{A:Type}(xs ys:list A)k:k<=length xs ->
 firstn k(xs++ys)=firstn k xs.
Proof.
 revert k;induction xs as[|a xs IH];intros[|k]K;cbn[length app firstn]in*;
 try lia;try reflexivity;f_equal;apply IH;lia.
Qed.
Lemma prefix_selected_push path q k:S k<=length path ->
 prefix_selected(path++[q])k=prefix_selected path k.
Proof. intros K;unfold prefix_selected;rewrite firstn_append_prefix by assumption;reflexivity. Qed.
Lemma pushed_lookup_before prefix g q log k:k<length prefix ->
 nth_error(pushed_records prefix g q log)k=nth_error(prefix++[g])k.
Proof.
 unfold pushed_records;revert k;induction prefix as[|a prefix IH];intros[|k]K;
 cbn[length app nth_error]in*;try lia;try reflexivity;apply IH;lia.
Qed.
Lemma pushed_mark_before prefix g q log i:i<length(prefix++[g]) ->
 ghost_mark(nth i(pushed_records prefix g q log)empty_ghost)=
 ghost_mark(nth i(prefix++[g])empty_ghost).
Proof.
 unfold pushed_records;revert i;induction prefix as[|a prefix IH];intros[|i]I;
 cbn[length app nth chosen_record ghost_mark]in*;try reflexivity;try lia;apply IH;lia.
Qed.
Lemma pushed_parent_lookup prefix g q log:
 nth_error(pushed_records prefix g q log)(length prefix)=Some(chosen_record g q).
Proof. unfold pushed_records;induction prefix;cbn[length app nth_error];auto. Qed.
Lemma pushed_child_lookup prefix g q log:
 nth_error(pushed_records prefix g q log)(S(length prefix))=Some(child_record log).
Proof. unfold pushed_records;induction prefix;cbn[length app nth_error];auto. Qed.
Lemma pushed_child_nth prefix g q log:
 nth(S(length prefix))(pushed_records prefix g q log)empty_ghost=child_record log.
Proof. unfold pushed_records;induction prefix;cbn[length app nth];auto. Qed.
Lemma snapshot_push_ancestor n base log prefix g q k:k<length prefix ->
 frame_snapshot n base log(pushed_records prefix g q log)k=
 frame_snapshot n base log(prefix++[g])k.
Proof.
 intros K;unfold frame_snapshot.
 assert(LenNew:length(pushed_records prefix g q log)=length prefix+2)
 by(unfold pushed_records;rewrite app_length;reflexivity).
 assert(LenOld:length(prefix++[g])=length prefix+1)by(rewrite app_length;reflexivity).
 rewrite LenNew,LenOld.
 destruct(lt_dec(S k)(length prefix+2));[|lia].
 destruct(lt_dec(S k)(length prefix+1));[|lia].
 rewrite pushed_mark_before by(rewrite app_length;cbn[length];lia);reflexivity.
Qed.
Lemma snapshot_push_parent n base log prefix g q:
 frame_snapshot n base log(pushed_records prefix g q log)(length prefix)=
 decode(journal_bitmap base log).
Proof.
 unfold frame_snapshot.
 assert(Len:length(pushed_records prefix g q log)=length prefix+2)
 by(unfold pushed_records;rewrite app_length;reflexivity).
 rewrite Len;destruct(lt_dec(S(length prefix))(length prefix+2));[|lia].
 rewrite pushed_child_nth;cbn[child_record ghost_mark].
 replace(sublist 0(Zlength log)log)with log by list_solve;reflexivity.
Qed.
Lemma snapshot_push_child n base log prefix g q:
 frame_snapshot n base log(pushed_records prefix g q log)(S(length prefix))=
 decode(journal_bitmap base log).
Proof.
 unfold frame_snapshot,pushed_records;rewrite app_length;cbn[length].
 destruct(lt_dec(S(S(length prefix)))(length prefix+2));[lia|reflexivity].
Qed.
Lemma pushed_ancestor_critical n hs base log path prefix g q e k:
 length path=length(prefix++[g]) ->k<length prefix ->
 critical_at n hs base log path(prefix++[g])e k ->
 critical_at n hs base log(path++[q])(pushed_records prefix g q log)e k.
Proof.
 intros Len K[gk[At Critical]].
 exists gk;split;[rewrite pushed_lookup_before by assumption;assumption|].
 cbv zeta in Critical |- *.
 rewrite prefix_selected_push by(rewrite Len,app_length;cbn[length];lia).
 rewrite snapshot_push_ancestor by assumption;exact Critical.
Qed.
Lemma parent_prefix_all path(prefix:list ghost_frame):length path=S(length prefix) ->
 prefix_selected path(length prefix)=path_bits path.
Proof. intros Len;unfold prefix_selected;rewrite <-Len,firstn_all;reflexivity. Qed.
Lemma pushed_child_prefix path(prefix:list ghost_frame)q:length path=S(length prefix) ->
 prefix_selected(path++[q])(S(length prefix))=setbit(prefix_selected path(length prefix))q.
Proof.
 intros Len;rewrite(parent_prefix_all path prefix Len).
 unfold prefix_selected.
 replace(S(S(length prefix)))with(length(path++[q]))by(rewrite app_length;cbn[length];lia).
 rewrite firstn_all;apply functional_extensionality;intro i;apply path_bits_append.
Qed.
Theorem push_preserves_live_targets n hs ls cap seed base log path prefix g q:
 length path=length(prefix++[g]) ->ghost_phase g=1 ->
 q=scan_candidates n(ghost_next g)(nth(ghost_row g)hs zero_vector)
 (prefix_selected path(length prefix))(decode(journal_bitmap base log)) ->
 target_stack_live n hs ls cap seed base log path(prefix++[g]) ->
 target_stack_live n hs ls cap seed base log(path++[q])(pushed_records prefix g q log).
Proof.
 intros Len Phase Scan Live e Min Within Hit.
 destruct(Live e Min Within Hit)as[k Critical].
 pose proof(critical_at_index _ _ _ _ _ _ _ _ Critical)as Index.
 destruct(lt_dec k(length prefix))as[K|K].
 - exists k;apply pushed_ancestor_critical;assumption.
 - assert(Eq:k=length prefix)by(rewrite app_length in Index;cbn[length]in Index;lia).
   subst k;destruct Critical as[gk[At Critical]].
   rewrite old_last in At;inversion At;subst gk.
   cbv zeta in Critical;rewrite Phase,snapshot_top in Critical.
   pose proof(critical_scan_transition n(nth(ghost_row g)hs zero_vector)e
   (prefix_selected path(length prefix))(decode(journal_bitmap base log))
   (ghost_next g)false Critical)as New.
   cbn zeta in New;rewrite <-Scan in New.
   destruct New as[Q[Selected[Forbidden[[Inside Child]|[Outside Parent]]]]].
   + exists(S(length prefix));unfold critical_at;exists(child_record log).
     split;[apply pushed_child_lookup|].
     cbv zeta;cbn[child_record ghost_phase].
     rewrite snapshot_push_child,pushed_child_prefix by(rewrite app_length in Len;cbn[length]in Len;lia).
     exact Child.
   + exists(length prefix);unfold critical_at;exists(chosen_record g q).
     split;[apply pushed_parent_lookup|].
     cbv zeta;cbn[chosen_record ghost_phase ghost_row ghost_next ghost_chosen].
     rewrite snapshot_push_parent,prefix_selected_push by(rewrite Len,app_length;cbn[length];lia).
     split;assumption.
Qed.
Print Assumptions push_preserves_live_targets.
