(* Protected ancestor snapshots and minimum-target coverage across a frame pop.
   Pure ghost transition, not the actual complete Clight pop caller. *)
Require Import VST.floyd.proofauto VST.zlist.list_solver.
Require Import CCV.CCModel CCV.CCFunctional CCV.CCStackInvariant CCV.CCPushCoverage
 CCV.CCFrameUpdates CCV.CCResumeCoverage CCV.CCProtectedFrames CCV.CCResumeMemory CCV.CCJournalArray
 CCV.CCRepresentation.
Import ListNotations. Open Scope nat_scope.
Definition popped_log(g:ghost_frame)(log:list Z):=sublist 0(ghost_mark g)log.
Lemma nth_append_before{A:Type}(xs ys:list A)(d:A)i:i<length xs ->
 nth i(xs++ys)d=nth i xs d.
Proof.
 revert i;induction xs as[|a xs IH];intros[|i]I;cbn[length app nth]in*;
 try lia;try reflexivity;apply IH;lia.
Qed.
Lemma lookup_append_before{A:Type}(xs ys:list A)i:i<length xs ->
 nth_error(xs++ys)i=nth_error xs i.
Proof.
 revert i;induction xs as[|a xs IH];intros[|i]I;cbn[length app nth_error]in*;
 try lia;try reflexivity;apply IH;lia.
Qed.
Lemma geometry_mark_chain n m cap hs path ghosts log:
 stack_geometry n m cap hs path ghosts log ->forall j i,
 i<=j<length ghosts ->
 (ghost_mark(nth i ghosts empty_ghost)<=ghost_mark(nth j ghosts empty_ghost))%Z.
Proof.
 intros[Len[ND[Range[Depth Per]]]]j;induction j as[|j IH];intros i I.
 - assert(Eq:i=0)by lia;subst i;lia.
 - destruct(Nat.eq_dec i(S j))as[->|Ne];[lia|].
   pose proof(IH i ltac:(lia))as Order.
   pose proof(Per j(nth j ghosts empty_ghost)(lookup_bounded ghosts empty_ghost j ltac:(lia)))
   as[PB[Mark[Root[Anc Init]]]].
   destruct(Anc ltac:(lia))as[Wait[Chosen[Next Link]]];lia.
Qed.
Lemma pop_ancestor_snapshot n base log prefix g k:
 k<length prefix ->(0<=ghost_mark g<=Zlength log)%Z ->
 (forall i,i<length prefix ->
 (0<=ghost_mark(nth(S i)(prefix++[g])empty_ghost)<=ghost_mark g)%Z) ->
 frame_snapshot n base(popped_log g log)prefix k=
 frame_snapshot n base log(prefix++[g])k.
Proof.
 intros K Mark Marks;unfold frame_snapshot,popped_log.
 assert(OldLen:length(prefix++[g])=length prefix+1)by(rewrite app_length;reflexivity).
 rewrite OldLen.
 destruct(lt_dec(S k)(length prefix))as[Deep|Top].
 - destruct(lt_dec(S k)(length prefix+1))as[WasDeep|Bad];[|lia].
   rewrite <-(nth_append_before prefix[g]empty_ghost(S k)Deep).
   pose proof(Marks k K)as Bound.
   rewrite restore_retains_prefix by lia;reflexivity.
 - destruct(lt_dec(S k)(length prefix+1))as[WasDeep|Bad];[|lia].
   assert(Eq:S k=length prefix)by lia;rewrite Eq,nth_snoc_last;reflexivity.
Qed.
Lemma critical_ancestor_pop n hs base log parent_path prefix g q e k:
 length parent_path=length prefix ->k<length prefix ->
 (0<=ghost_mark g<=Zlength log)%Z ->
 (forall i,i<length prefix ->
 (0<=ghost_mark(nth(S i)(prefix++[g])empty_ghost)<=ghost_mark g)%Z) ->
 critical_at n hs base log(parent_path++[q])(prefix++[g])e k ->
 critical_at n hs base(popped_log g log)parent_path prefix e k.
Proof.
 intros Len K Mark Marks[gk[At Critical]].
 exists gk;split;[rewrite <-(lookup_append_before prefix[g]k K);exact At|].
 cbv zeta in Critical |- *.
 rewrite prefix_selected_push in Critical by lia.
 rewrite pop_ancestor_snapshot by assumption;exact Critical.
Qed.
Theorem pop_preserves_live_targets n hs ls cap seed base log parent_path prefix g q:
 length parent_path=length prefix ->(0<=ghost_mark g<=Zlength log)%Z ->
 (forall i,i<length prefix ->
 (0<=ghost_mark(nth(S i)(prefix++[g])empty_ghost)<=ghost_mark g)%Z) ->
 (forall e,minimum n hs ls e ->weight n e<=cap ->e seed=true ->
 ~critical_at n hs base log(parent_path++[q])(prefix++[g])e(length prefix)) ->
 target_stack_live n hs ls cap seed base log(parent_path++[q])(prefix++[g]) ->
 target_stack_live n hs ls cap seed base(popped_log g log)parent_path prefix.
Proof.
 intros Len Mark Marks NoLast Live e Min Within Hit.
 destruct(Live e Min Within Hit)as[k Critical].
 pose proof(critical_at_index _ _ _ _ _ _ _ _ Critical)as Index.
 assert(K:k<length prefix).
 { destruct(lt_dec k(length prefix));[assumption|].
   assert(Eq:k=length prefix)by(rewrite app_length in Index;cbn[length]in Index;lia).
   subst k;exfalso;apply(NoLast e Min Within Hit);exact Critical. }
 exists k;apply(critical_ancestor_pop n hs base log parent_path prefix g q e k);assumption.
Qed.
Theorem pop_preserves_live_with_geometry n m hs ls cap seed base log parent_path prefix g q:
 stack_geometry n m cap hs(parent_path++[q])(prefix++[g])log ->
 (forall e,minimum n hs ls e ->weight n e<=cap ->e seed=true ->
 ~critical_at n hs base log(parent_path++[q])(prefix++[g])e(length prefix)) ->
 target_stack_live n hs ls cap seed base log(parent_path++[q])(prefix++[g]) ->
 target_stack_live n hs ls cap seed base(popped_log g log)parent_path prefix.
Proof.
 intros Geo NoLast Live.
 pose proof Geo as Parts;unfold stack_geometry in Parts.
 destruct Parts as[Len[ND[Range[Depth Per]]]].
 assert(Last:(length prefix<length(prefix++[g]))%nat)by(rewrite app_length;cbn[length];lia).
 pose proof(Per(length prefix)g(old_last prefix g))as[PB[Mark Rest]].
 apply(pop_preserves_live_targets n hs ls cap seed base log parent_path prefix g q);
 try assumption.
 - rewrite !app_length in Len;cbn[length]in Len;lia.
 - intros i I.
   pose proof(geometry_marks n m cap hs(parent_path++[q])(prefix++[g])log Geo(S i)
   ltac:(rewrite app_length;cbn[length];lia))as M.
   pose proof(geometry_mark_chain n m cap hs(parent_path++[q])(prefix++[g])log Geo
   (length prefix)(S i)ltac:(rewrite app_length;cbn[length];lia))as Order.
   rewrite nth_snoc_last in Order;lia.
Qed.
Print Assumptions geometry_mark_chain.
Print Assumptions pop_preserves_live_with_geometry.
