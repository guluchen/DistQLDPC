(* Stack geometry after restoring and popping the top frame. Pure theorem;
   complete actual C main-loop refinement is not asserted here. *)
Require Import VST.floyd.proofauto VST.zlist.list_solver.
Require Import CCV.CCModel CCV.CCStackInvariant CCV.CCPopCoverage CCV.CCPushCoverage
 CCV.CCResumeCoverage CCV.CCResumeMemory CCV.CCSearchPhases CCV.CCFrameUpdates.
Import ListNotations. Open Scope nat_scope.
Theorem geometry_pop n m cap hs parent_path prefix g log q:
 stack_geometry n m cap hs(parent_path++[q])(prefix++[g])log ->
 stack_geometry n m cap hs parent_path prefix(popped_log g log).
Proof.
 intros Geo;pose proof Geo as Parts;unfold stack_geometry in Parts.
 destruct Parts as[Len[ND[Range[Depth Per]]]].
 assert(ParentLen:length parent_path=length prefix)by(rewrite !app_length in Len;cbn[length]in Len;lia).
 pose proof(Per(length prefix)g(old_last prefix g))as[PB[Mark Rest]].
 assert(PopLen:Zlength(popped_log g log)=ghost_mark g)
 by(unfold popped_log;autorewrite with sublist;lia).
 unfold stack_geometry;split;[assumption|].
 split;[apply path_nodup_snoc_inv in ND;tauto|].
 split;[apply Forall_app in Range;tauto|].
 split.
 - destruct parent_path as[|r tail];[left;reflexivity|right].
   rewrite app_length in Depth;cbn[length]in Depth |- *;lia.
 - intros k gk At.
   assert(K:k<length prefix)by(apply nth_error_Some;rewrite At;discriminate).
   assert(AtOld:nth_error(prefix++[g])k=Some gk)
   by(rewrite lookup_append_before by assumption;exact At).
   destruct(Per k gk AtOld)as[GB[GM[GR[GA GI]]]].
   assert(OldLookup:nth k(prefix++[g])empty_ghost=gk).
   { pose proof(lookup_bounded(prefix++[g])empty_ghost k
     ltac:(rewrite app_length;cbn[length];lia))as Lookup.
     rewrite AtOld in Lookup;inversion Lookup;reflexivity. }
   pose proof(geometry_mark_chain n m cap hs(parent_path++[q])(prefix++[g])log Geo
   (length prefix)k ltac:(rewrite app_length;cbn[length];lia))as Upper.
   rewrite OldLookup,nth_snoc_last in Upper.
   split;[assumption|split;[rewrite PopLen;lia|split;[assumption|split]]].
   + intros Deep.
     destruct(GA ltac:(rewrite app_length;cbn[length];lia))as[Wait[Chosen[Next Order]]].
     split;[assumption|split].
     * rewrite nth_append_before in Chosen by lia;assumption.
     * split;[assumption|rewrite nth_append_before in Order by assumption;exact Order].
   + intros Kind;destruct(GI Kind)as[R[Nx[C Odd]]].
     split;[assumption|split;[assumption|split;[assumption|]]].
     rewrite prefix_selected_push in Odd by lia;exact Odd.
Qed.
Print Assumptions geometry_pop.
