(* Stack geometry across a pending-child resume. Pure transition theorem;
   not a whole C body or total-correctness theorem. *)
Require Import VST.floyd.proofauto.
Require Import CCV.CCModel CCV.CCStackInvariant CCV.CCFrameUpdates.
Import ListNotations. Open Scope nat_scope.
Lemma resume_lookup_cases prefix g k gnew:
 nth_error(prefix++[resumed_record g])k=Some gnew ->
 (k<length prefix /\nth_error(prefix++[g])k=Some gnew) \/
 (k=length prefix /\gnew=resumed_record g).
Proof.
 intros At.
 assert(Index:k<length(prefix++[resumed_record g])).
 { apply nth_error_Some;rewrite At;discriminate. }
 destruct(lt_dec k(length prefix))as[K|K].
 - left;split;[assumption|rewrite <-resume_before by assumption;assumption].
 - assert(Eq:k=length prefix)by(rewrite app_length in Index;cbn[length]in Index;lia).
   subst k;rewrite resume_last in At;inversion At;right;auto.
Qed.
Theorem geometry_resume n m cap hs path prefix g old new:
 ghost_phase g=2 ->(Zlength old<=Zlength new)%Z ->
 stack_geometry n m cap hs path(prefix++[g])old ->
 stack_geometry n m cap hs path(prefix++[resumed_record g])new.
Proof.
 intros Phase Growth[Len[ND[Range[Depth Per]]]].
 unfold stack_geometry;rewrite resume_length.
 split;[assumption|split;[assumption|split;[assumption|split;[assumption|]]]].
 intros k gnew At.
 destruct(resume_lookup_cases prefix g k gnew At)as[[K AtOld]|[Eq Same]].
 - destruct(Per k gnew AtOld)as[PB[Mark[Root[Anc Init]]]].
   split;[assumption|split;[lia|split;[assumption|split]]].
   + intros Deep;destruct(Anc Deep)as[Wait[Chosen[Next Order]]].
     split;[assumption|split;[assumption|split;[assumption|]]].
     rewrite resume_marks;assumption.
   + exact Init.
 - subst k gnew.
   destruct(Per(length prefix)g(old_last prefix g))as[PB[Mark[Root[Anc Init]]]].
   cbn[resumed_record ghost_phase ghost_mark ghost_chosen ghost_next ghost_row].
   split;[lia|split;[lia|split;[exact Root|split]]].
   + intros Deep;rewrite app_length in Deep;cbn[length]in Deep;lia.
   + intros Kind;apply Init;right;exact Phase.
Qed.
Print Assumptions resume_lookup_cases.
Print Assumptions geometry_resume.
