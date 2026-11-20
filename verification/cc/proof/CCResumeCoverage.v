(* Critical-target coverage across the actual phase2 ghost update.
   This is a pure invariant transition, not the complete C while proof. *)
Require Import VST.floyd.proofauto.
Require Import CCV.CCModel CCV.CCFunctional CCV.CCCriticalFrame CCV.CCResumeTarget
 CCV.CCStackInvariant CCV.CCFrameUpdates CCV.CCJournalArray CCV.CCJournalTrace CCV.CCRepresentation.
Import ListNotations. Open Scope nat_scope.
Definition resume_log(exclude:bool)(log:list Z)(g:ghost_frame):list Z:=
 if exclude then log++[Z.of_nat(ghost_chosen g)]else log.
Lemma snapshot_top n base log prefix g:
 frame_snapshot n base log(prefix++[g])(length prefix)=decode(journal_bitmap base log).
Proof.
 unfold frame_snapshot;rewrite app_length;cbn[length].
 destruct(lt_dec(S(length prefix))(length prefix+1));[lia|reflexivity].
Qed.
Lemma lookup_bounded{A:Type}(xs:list A)(d:A)i:i<length xs ->
 nth_error xs i=Some(nth i xs d).
Proof.
 revert i;induction xs as[|a xs IH];intros[|i]I;cbn[length nth nth_error]in*;
 try lia;try reflexivity;apply IH;lia.
Qed.
Lemma geometry_marks n m cap hs path ghosts log:
 stack_geometry n m cap hs path ghosts log ->forall i,i<length ghosts ->
 (0<=ghost_mark(nth i ghosts empty_ghost)<=Zlength log)%Z.
Proof.
 intros[Len[ND[Range[Depth Per]]]]i I.
 pose proof(Per i(nth i ghosts empty_ghost)(lookup_bounded ghosts empty_ghost i I))as Parts.
 exact(proj1(proj2 Parts)).
Qed.
Lemma resume_log_extension exclude log g:
 allowed_extension log(resume_log exclude log g)(fun _=>True).
Proof.
 unfold resume_log;destruct exclude.
 - exists[Z.of_nat(ghost_chosen g)];split;[reflexivity|constructor;[exact I|constructor]].
 - apply allowed_extension_refl.
Qed.
Lemma resume_bitmap_decode n base log g:
 (0<=n)%Z ->Zlength base=n ->Forall(fun q:Z=>(0<=q<n)%Z)log ->
 ghost_chosen g<Z.to_nat n ->
 decode(journal_bitmap base(log++[Z.of_nat(ghost_chosen g)]))=
 setbit(decode(journal_bitmap base log))(ghost_chosen g).
Proof.
 intros N Len Range Q.
 assert(QZ:(0<=Z.of_nat(ghost_chosen g)<n)%Z).
 { apply Nat2Z.inj_lt in Q;rewrite Z2Nat.id in Q by assumption;lia. }
 apply functional_extensionality;intro i;rewrite journal_bitmap_push.
 rewrite decode_set_one by(rewrite(journal_bitmap_length n base log Len Range);assumption).
 rewrite Nat2Z.id;reflexivity.
Qed.
Theorem critical_top_resume n hs base log path prefix g e exclude:
 (0<=n)%Z ->Zlength base=n ->Forall(fun q:Z=>(0<=q<n)%Z)log ->
 ghost_phase g=2 ->ghost_chosen g<Z.to_nat n ->
 critical_at(Z.to_nat n)hs base log path(prefix++[g])e(length prefix) ->
 critical_at(Z.to_nat n)hs base(resume_log exclude log g)path
   (prefix++[resumed_record g])e(length prefix).
Proof.
 intros N Len Range Phase Q[gk[At Critical]].
 rewrite old_last in At;inversion At;subst gk.
 cbv zeta in Critical;rewrite Phase in Critical.
 rewrite snapshot_top in Critical;destruct Critical as[Critical Outside].
 exists(resumed_record g);split;[apply resume_last|].
 cbv zeta;rewrite snapshot_top.
 cbn[resumed_record ghost_phase ghost_row ghost_next].
 unfold resume_log;destruct exclude.
 - rewrite(resume_bitmap_decode n base log g N Len Range Q).
   exact(critical_forbid_outside(Z.to_nat n)(nth(ghost_row g)hs zero_vector)e
     (prefix_selected path(length prefix))(decode(journal_bitmap base log))
     (ghost_next g)(ghost_chosen g)true Critical Outside).
 - exact Critical.
Qed.
Theorem resume_preserves_live_targets n hs ls cap seed base log path prefix g exclude:
 (0<=n)%Z ->Zlength base=n ->Forall(fun q:Z=>(0<=q<n)%Z)log ->
 ghost_phase g=2 ->ghost_chosen g<Z.to_nat n ->
 (forall i,i<length(prefix++[g]) ->
   (0<=ghost_mark(nth i(prefix++[g])empty_ghost)<=Zlength log)%Z) ->
 target_stack_live(Z.to_nat n)hs ls cap seed base log path(prefix++[g]) ->
 target_stack_live(Z.to_nat n)hs ls cap seed base(resume_log exclude log g)path
   (prefix++[resumed_record g]).
Proof.
 intros N Len Range Phase Q Marks Live e Min Within Hit.
 destruct(Live e Min Within Hit)as[k Critical].
 pose proof(critical_at_index _ _ _ _ _ _ _ _ Critical)as Index.
 exists k;destruct(lt_dec k(length prefix))as[K|K].
 - apply(critical_ancestor_resume(Z.to_nat n)hs base log(resume_log exclude log g)
     path prefix g e k(fun _=>True));try assumption.
   + apply resume_log_extension.
   + apply Marks;rewrite app_length;cbn[length];lia.
 - assert(Eq:k=length prefix)by(rewrite app_length in Index;cbn[length]in Index;lia).
   subst k;apply(critical_top_resume n hs base log path prefix g e exclude);assumption.
Qed.
Print Assumptions critical_top_resume.
Print Assumptions resume_preserves_live_targets.
