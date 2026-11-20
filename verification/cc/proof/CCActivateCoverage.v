(* Phase0-to-phase1 initialization retains every minimum target. Exact C
   stores and the complete while invariant are composed separately. *)
Require Import VST.floyd.proofauto.
Require Import CCV.CCModel CCV.CCFunctional CCV.CCStackInvariant CCV.CCCriticalFrame CCV.CCFrameUpdates
 CCV.CCResumeMemory CCV.CCProtectedFrames.
Import ListNotations. Open Scope nat_scope.
Definition activated_record(g:ghost_frame)(row:nat):ghost_frame:={|
 ghost_phase:=1;ghost_row:=row;ghost_next:=0;
 ghost_chosen:=ghost_chosen g;ghost_mark:=ghost_mark g|}.
Lemma activation_length prefix g row:
 length(prefix++[activated_record g row])=length(prefix++[g]).
Proof. rewrite !app_length;reflexivity. Qed.
Lemma activation_before prefix g row i:i<length prefix ->
 nth_error(prefix++[activated_record g row])i=nth_error(prefix++[g])i.
Proof.
 revert i;induction prefix as[|a prefix IH];intros[|i]I;cbn[app nth_error length]in*;
 try lia;try reflexivity;apply IH;lia.
Qed.
Lemma activation_marks prefix g row i:
 ghost_mark(nth i(prefix++[activated_record g row])empty_ghost)=
 ghost_mark(nth i(prefix++[g])empty_ghost).
Proof.
 revert i;induction prefix as[|a prefix IH];intros[|i];cbn[app nth activated_record];
 try reflexivity;apply IH.
Qed.
Lemma snapshot_activation n base log prefix g row k:
 frame_snapshot n base log(prefix++[activated_record g row])k=
 frame_snapshot n base log(prefix++[g])k.
Proof.
 unfold frame_snapshot;rewrite activation_length.
 destruct(lt_dec(S k)(length(prefix++[g])));[rewrite activation_marks|];reflexivity.
Qed.
Lemma critical_ancestor_activation n hs base log path prefix g row e k:
 k<length prefix ->critical_at n hs base log path(prefix++[g])e k ->
 critical_at n hs base log path(prefix++[activated_record g row])e k.
Proof.
 intros K[gk[At Critical]];exists gk;split.
 - rewrite activation_before by assumption;assumption.
 - cbv zeta in Critical |- *;rewrite snapshot_activation;assumption.
Qed.
Lemma critical_top_activation n hs base log path prefix g row e:
 ghost_phase g=0 ->row<length hs ->kernel n hs e ->
 parity n(nth row hs zero_vector)(prefix_selected path(length prefix))=true ->
 critical_at n hs base log path(prefix++[g])e(length prefix) ->
 critical_at n hs base log path(prefix++[activated_record g row])e(length prefix).
Proof.
 intros Phase Row Ker Odd[gk[At Critical]].
 rewrite old_last in At;inversion At;subst gk.
 cbv zeta in Critical;rewrite Phase in Critical.
 exists(activated_record g row);split;[apply old_last|].
 cbv zeta;cbn[activated_record ghost_phase ghost_row ghost_next].
 rewrite snapshot_activation.
 apply odd_row_starts_critical;try assumption.
 apply Ker;apply nth_In;assumption.
Qed.
Theorem activation_preserves_live_targets n hs ls cap seed base log path prefix g row:
 ghost_phase g=0 ->row<length hs ->
 parity n(nth row hs zero_vector)(prefix_selected path(length prefix))=true ->
 target_stack_live n hs ls cap seed base log path(prefix++[g]) ->
 target_stack_live n hs ls cap seed base log path(prefix++[activated_record g row]).
Proof.
 intros Phase Row Odd Live e Min Cap Seed.
 destruct(Live e Min Cap Seed)as[k Critical].
 pose proof(critical_at_index _ _ _ _ _ _ _ _ Critical)as Index.
 exists k;destruct(lt_dec k(length prefix))as[Before|Last].
 - apply critical_ancestor_activation;assumption.
 - assert(Eq:k=length prefix)by(rewrite app_length in Index;cbn[length]in Index;lia);subst k.
   apply critical_top_activation;try assumption.
   destruct Min as[[_[Ker Log]]Best];assumption.
Qed.
Print Assumptions activation_preserves_live_targets.
