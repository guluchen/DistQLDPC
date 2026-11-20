(* Minimum-target coverage across overlap's allowed journal extension. A
   divergent descendant need not protect its current bitmap from every target;
   critical ancestors retain their protected entry-prefix snapshots. Pure math,
   separate from the complete actual C phase0 caller. *)
Require Import VST.floyd.proofauto.
Require Import CCV.CCModel CCV.CCFunctional CCV.CCStackInvariant CCV.CCCriticalFrame
 CCV.CCSearchPolicies CCV.CCProtectedFrames CCV.CCJournalArray CCV.CCJournalTrace
 CCV.CCRepresentation CCV.CCResumeCoverage CCV.CCPushCoverage CCV.CCFrameUpdates.
Import ListNotations. Open Scope Z_scope.
Lemma geometry_log_growth n m cap hs path ghosts old new:
 Zlength old<=Zlength new ->stack_geometry n m cap hs path ghosts old ->
 stack_geometry n m cap hs path ghosts new.
Proof.
 intros Growth[Len[ND[Range[Depth Per]]]];unfold stack_geometry.
 split;[assumption|split;[assumption|split;[assumption|split;[assumption|]]]].
 intros k g At;destruct(Per k g At)as[PB[Mark[Root[Anc Init]]]].
 split;[assumption|split;[lia|split;[assumption|split;assumption]]].
Qed.
Lemma snapshot_extension_ancestor n base old new ghosts k Allowed:
 allowed_extension old new Allowed ->(S k<length ghosts)%nat ->
 0<=ghost_mark(nth(S k)ghosts empty_ghost)<=Zlength old ->
 frame_snapshot n base new ghosts k=frame_snapshot n base old ghosts k.
Proof.
 intros Ext Deep Mark;unfold frame_snapshot;destruct(lt_dec(S k)(length ghosts));[|lia].
 rewrite(extension_retains_prefix old new _ Allowed Ext Mark);reflexivity.
Qed.
Lemma critical_extension_ancestor n hs base old new path ghosts e k Allowed:
 allowed_extension old new Allowed ->(S k<length ghosts)%nat ->
 0<=ghost_mark(nth(S k)ghosts empty_ghost)<=Zlength old ->
 critical_at n hs base old path ghosts e k ->critical_at n hs base new path ghosts e k.
Proof.
 intros Ext Deep Mark[gk[At Critical]].
 exists gk;split;[assumption|]. cbv zeta in Critical |- *.
 rewrite(snapshot_extension_ancestor n base old new ghosts k Allowed Ext Deep Mark);exact Critical.
Qed.
Theorem overlap_top_preserves_critical n hs ls cap base old new path prefix g xs e:
 0<=n ->0<=cap ->Zlength base=n ->
 Forall(fun q:Z=>0<=q<n)old ->Forall(fun q:Z=>0<=q<n)new ->
 allowed_extension old new(overlap_allows_all n hs ls cap xs) ->
 ghost_phase g=0%nat ->
 (forall i,(i<Z.to_nat n)%nat ->decode xs i=prefix_selected path(length prefix)i) ->
 minimum(Z.to_nat n)hs ls e ->(weight(Z.to_nat n)e<=Z.to_nat cap)%nat ->
 critical_at(Z.to_nat n)hs base old path(prefix++[g])e(length prefix) ->
 critical_at(Z.to_nat n)hs base new path(prefix++[g])e(length prefix).
Proof.
 intros N Cap Len Rold Rnew Ext Phase Selected Min Within[gk[At Critical]].
 rewrite old_last in At;inversion At;subst gk.
 cbv zeta in Critical;rewrite Phase,snapshot_top in Critical.
 destruct Critical as[Sub Avoid].
 assert(SubXS:subset(Z.to_nat n)(decode xs)e).
 { intros i I Hit;apply Sub;[assumption|rewrite <-Selected by assumption;assumption]. }
 assert(WithinZ:Z.of_nat(weight(Z.to_nat n)e)<=cap).
 { apply Nat2Z.inj_le in Within;rewrite Z2Nat.id in Within by assumption;assumption. }
 destruct Ext as[added[Eq All]]. subst new.
 apply Forall_app in Rnew;destruct Rnew as[OldRange AddedRange].
 exists g;split;[apply old_last|]. cbv zeta;rewrite Phase,snapshot_top.
 split;[exact Sub|].
 apply(bitmap_extension_avoids n base old added e);try assumption.
 intros q InAdded;apply Forall_forall with(x:=q)in All;[|assumption].
 destruct All as[Free Allowed];apply Allowed;assumption.
Qed.
Theorem overlap_preserves_live_targets n hs ls cap seed base old new path prefix g xs:
 0<=n ->0<=cap ->Zlength base=n ->
 Forall(fun q:Z=>0<=q<n)old ->Forall(fun q:Z=>0<=q<n)new ->
 allowed_extension old new(overlap_allows_all n hs ls cap xs) ->ghost_phase g=0%nat ->
 (forall i,(i<Z.to_nat n)%nat ->decode xs i=prefix_selected path(length prefix)i) ->
 (forall i,(i<length(prefix++[g]))%nat ->
 0<=ghost_mark(nth i(prefix++[g])empty_ghost)<=Zlength old) ->
 target_stack_live(Z.to_nat n)hs ls(Z.to_nat cap)seed base old path(prefix++[g]) ->
 target_stack_live(Z.to_nat n)hs ls(Z.to_nat cap)seed base new path(prefix++[g]).
Proof.
 intros N Cap Len Rold Rnew Ext Phase Selected Marks Live e Min Within Hit.
 destruct(Live e Min Within Hit)as[k Critical].
 pose proof(critical_at_index _ _ _ _ _ _ _ _ Critical)as Index.
 exists k;destruct(lt_dec k(length prefix))as[K|K].
 - apply(critical_extension_ancestor(Z.to_nat n)hs base old new path(prefix++[g])e k
   (overlap_allows_all n hs ls cap xs));try assumption.
   + rewrite app_length;cbn[length];lia.
   + apply Marks;rewrite app_length;cbn[length];lia.
 - assert(Eq:k=length prefix)by(rewrite app_length in Index;cbn[length]in Index;lia).
   subst k;apply(overlap_top_preserves_critical n hs ls cap base old new path prefix g xs e);assumption.
Qed.
Theorem overlap_rejects_no_critical_top n hs ls cap base log path prefix g xs:
 0<=cap ->ghost_phase g=0%nat ->overlap_rejects_all n hs ls cap xs ->
 (forall i,(i<Z.to_nat n)%nat ->decode xs i=prefix_selected path(length prefix)i) ->
 forall e,minimum(Z.to_nat n)hs ls e ->(weight(Z.to_nat n)e<=Z.to_nat cap)%nat ->
 ~critical_at(Z.to_nat n)hs base log path(prefix++[g])e(length prefix).
Proof.
 intros Cap Phase Bad Selected e Min Within[gk[At Critical]].
 rewrite old_last in At;inversion At;subst gk.
 cbv zeta in Critical;rewrite Phase in Critical.
 destruct Critical as[Sub Avoid].
 assert(WithinZ:Z.of_nat(weight(Z.to_nat n)e)<=cap).
 { apply Nat2Z.inj_le in Within;rewrite Z2Nat.id in Within by assumption;assumption. }
 apply(Bad e Min WithinZ).
 intros i I Hit;apply Sub;[assumption|rewrite <-Selected by assumption;assumption].
Qed.
Print Assumptions overlap_preserves_live_targets.
Print Assumptions overlap_rejects_no_critical_top.
