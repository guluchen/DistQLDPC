(* Ghost-frame update performed by the actual phase2 branch.
   Only the stated local/ancestor facts are proved here, not the whole C loop. *)
Require Import VST.floyd.proofauto.
Require Import CCV.ccv_core CCV.CCSearchSpecs CCV.CCSearchHeap CCV.CCStackInvariant
 CCV.CCModel CCV.CCFunctional CCV.CCCriticalFrame CCV.CCJournalTrace
 CCV.CCProtectedFrames CCV.CCJournalArray CCV.CCRepresentation.
Import ListNotations. Open Scope nat_scope.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
Definition resumed_record(g:ghost_frame):ghost_frame:={|
 ghost_phase:=1;ghost_row:=ghost_row g;ghost_next:=ghost_next g;
 ghost_chosen:=ghost_chosen g;ghost_mark:=ghost_mark g|}.
Definition set_raw_phase(raw:frame_value)(phase:Z):frame_value:=
 (fst raw,(fst(snd raw),(fst(snd(snd raw)),
 (fst(snd(snd(snd raw))),Vint(Int.repr phase))))).
Lemma resumed_record_mark g:ghost_mark(resumed_record g)=ghost_mark g.
Proof. reflexivity. Qed.
Lemma resume_marks prefix g i:
 ghost_mark(nth i(prefix++[resumed_record g])empty_ghost)=
 ghost_mark(nth i(prefix++[g])empty_ghost).
Proof.
 revert i;induction prefix as[|a prefix IH];intros[|i];cbn[app nth resumed_record];
 try reflexivity;apply IH.
Qed.
Lemma resume_length prefix g:length(prefix++[resumed_record g])=length(prefix++[g]).
Proof. rewrite !app_length;reflexivity. Qed.
Lemma resume_before prefix g i:i<length prefix ->
 nth_error(prefix++[resumed_record g])i=nth_error(prefix++[g])i.
Proof.
 revert i;induction prefix as[|a prefix IH];intros[|i]I;cbn[app nth_error length]in*;
 try lia;try reflexivity;apply IH;lia.
Qed.
Lemma resume_last prefix g:nth_error(prefix++[resumed_record g])(length prefix)=Some(resumed_record g).
Proof. induction prefix;cbn[app length nth_error];auto. Qed.
Lemma old_last(prefix:list ghost_frame)(g:ghost_frame):nth_error(prefix++[g])(length prefix)=Some g.
Proof. induction prefix;cbn[app length nth_error];auto. Qed.
Lemma frame_represents_resume g raw:ghost_phase g=2 ->frame_represents g raw ->
 frame_represents(resumed_record g)(set_raw_phase raw 1%Z).
Proof.
 intros Phase Rep;unfold frame_represents in Rep;rewrite Phase in Rep;subst raw.
 unfold frame_represents,resumed_record,set_raw_phase;cbn.
 exists(Vint(Int.repr(Z.of_nat(ghost_chosen g))));reflexivity.
Qed.
Lemma snapshot_resume_same_log n base log prefix g k:
 frame_snapshot n base log(prefix++[resumed_record g])k=
 frame_snapshot n base log(prefix++[g])k.
Proof.
 unfold frame_snapshot;rewrite !app_length;cbn[length].
 destruct(lt_dec(S k)(length prefix+1));[rewrite resume_marks|];reflexivity.
Qed.
Lemma snapshot_resume_ancestor n base old new prefix g k Allowed:
 k<length prefix ->allowed_extension old new Allowed ->
 (0<=ghost_mark(nth(S k)(prefix++[g])empty_ghost)<=Zlength old)%Z ->
 frame_snapshot n base new(prefix++[resumed_record g])k=
 frame_snapshot n base old(prefix++[g])k.
Proof.
 intros K Ext Mark;unfold frame_snapshot;rewrite !app_length;cbn[length].
 destruct(lt_dec(S k)(length prefix+1))as[Inside|Outside];[|lia].
 rewrite resume_marks.
 rewrite(extension_retains_prefix old new(ghost_mark(nth(S k)(prefix++[g])empty_ghost))Allowed Ext Mark).
 reflexivity.
Qed.
Theorem critical_ancestor_resume n hs base old new path prefix g e k Allowed:
 k<length prefix ->allowed_extension old new Allowed ->
 (0<=ghost_mark(nth(S k)(prefix++[g])empty_ghost)<=Zlength old)%Z ->
 critical_at n hs base old path(prefix++[g])e k ->
 critical_at n hs base new path(prefix++[resumed_record g])e k.
Proof.
 intros K Ext Mark[gk[At Critical]];exists gk;split.
 - rewrite resume_before by assumption;assumption.
 - cbv zeta in Critical |- *.
   rewrite(snapshot_resume_ancestor n base old new prefix g k Allowed K Ext Mark).
   exact Critical.
Qed.
Print Assumptions frame_represents_resume.
Print Assumptions snapshot_resume_ancestor.
Print Assumptions critical_ancestor_resume.
