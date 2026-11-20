(* Ghost-stack geometry for a fresh child push. Pure transition theorem; the
   complete actual C main-loop proof is still a separate obligation. *)
Require Import VST.floyd.proofauto.
Require Import CCV.CCModel CCV.CCFrameUpdates CCV.CCStackInvariant CCV.CCPushCoverage
 CCV.CCResumeCoverage CCV.CCResumeMemory CCV.CCSearchPhases.
Import ListNotations. Open Scope nat_scope.
Lemma pushed_lookup_cases prefix g q log k gnew:
 nth_error(pushed_records prefix g q log)k=Some gnew ->
 (k<length prefix /\nth_error(prefix++[g])k=Some gnew) \/
 (k=length prefix /\gnew=chosen_record g q) \/
 (k=S(length prefix) /\gnew=child_record log).
Proof.
 intros At.
 assert(Index:k<length(pushed_records prefix g q log))
 by(apply nth_error_Some;rewrite At;discriminate).
 assert(Len:length(pushed_records prefix g q log)=length prefix+2)
 by(unfold pushed_records;rewrite app_length;reflexivity).
 destruct(lt_dec k(length prefix))as[K|K].
 - left;split;[assumption|rewrite <-(pushed_lookup_before prefix g q log k K);assumption].
 - destruct(Nat.eq_dec k(length prefix))as[->|Ne].
   + rewrite pushed_parent_lookup in At;inversion At;right;left;auto.
   + assert(Eq:k=S(length prefix))by lia;subst k.
     rewrite pushed_child_lookup in At;inversion At;right;right;auto.
Qed.
Lemma nth_path_push_before path q i:i<length path ->
 nth i(path++[q])0=nth i path 0.
Proof.
 revert i;induction path as[|a path IH];intros[|i]I;cbn[length app nth]in*;
 try lia;try reflexivity;apply IH;lia.
Qed.
Theorem geometry_push n m cap hs path prefix g log q:
 ghost_phase g=1 ->q<n ->~In q path ->
 stack_geometry n m cap hs path(prefix++[g])log ->
 stack_geometry n m cap hs(path++[q])(pushed_records prefix g q log)log.
Proof.
 intros Phase Q Fresh[Len[ND[Range[Depth Per]]]].
 assert(PathLen:length path=S(length prefix))by(rewrite app_length in Len;cbn[length]in Len;lia).
 destruct(Per(length prefix)g(old_last prefix g))as[PB[Mark[Root[Anc Init]]]].
 destruct(Init(or_introl Phase))as[Row[Next[Cap Odd]]].
 assert(NewLen:length(pushed_records prefix g q log)=length prefix+2)
 by(unfold pushed_records;rewrite app_length;reflexivity).
 unfold stack_geometry.
 split;[rewrite app_length,NewLen;cbn[length];lia|].
 split;[apply path_nodup_snoc;assumption|].
 split;[apply Forall_app;split;[assumption|constructor;auto]|].
 split;[right;rewrite app_length;cbn[length];lia|].
 intros k gnew At.
 destruct(pushed_lookup_cases prefix g q log k gnew At)as[[K AtOld]|[[Eq Same]|[Eq Same]]].
 - destruct(Per k gnew AtOld)as[GB[GM[GR[GA GI]]]].
   split;[assumption|split;[assumption|split;[assumption|split]]].
   + intros Deep.
     assert(WasDeep:S k<length(prefix++[g]))by(rewrite app_length;cbn[length];lia).
     destruct(GA WasDeep)as[Wait[Chosen[NextG Order]]].
     split;[assumption|split].
     * rewrite nth_path_push_before by lia;assumption.
     * split;[assumption|rewrite pushed_mark_before by assumption;exact Order].
   + intros Kind;destruct(GI Kind)as[R[Nx[C O]]].
     split;[assumption|split;[assumption|split;[assumption|]]].
     rewrite prefix_selected_push by lia;assumption.
 - subst k gnew;cbn[chosen_record ghost_phase ghost_mark ghost_row ghost_next ghost_chosen].
   split;[lia|split;[exact Mark|split;[exact Root|split]]].
   + intros Deep;split;[reflexivity|split].
     * rewrite <-PathLen,nth_snoc_last;reflexivity.
     * split;[reflexivity|rewrite pushed_child_nth;cbn[child_record ghost_mark];lia].
   + intros Kind;split;[assumption|split;[lia|split;[assumption|]]].
     rewrite prefix_selected_push by lia;assumption.
 - subst k gnew;cbn[child_record ghost_phase ghost_mark ghost_row ghost_next ghost_chosen].
   split;[lia|split;[lia|split;[intros Bad;lia|split]]].
   + intros Deep;rewrite NewLen in Deep;lia.
   + intros[Bad|Bad];discriminate.
Qed.
Print Assumptions geometry_push.
