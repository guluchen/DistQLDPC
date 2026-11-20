(* Geometry of starting an exact odd-row scan from phase0. *)
Require Import VST.floyd.proofauto.
Require Import CCV.CCModel CCV.CCFunctional CCV.CCStackInvariant CCV.CCActivateCoverage CCV.CCFrameUpdates.
Import ListNotations. Open Scope nat_scope.
Lemma activation_lookup_cases prefix g row k gnew:
 nth_error(prefix++[activated_record g row])k=Some gnew ->
 (k<length prefix /\nth_error(prefix++[g])k=Some gnew) \/
 (k=length prefix /\gnew=activated_record g row).
Proof.
 intros At.
 assert(Index:k<length(prefix++[activated_record g row])).
 { apply nth_error_Some;rewrite At;discriminate. }
 destruct(lt_dec k(length prefix))as[K|K].
 - left;split;[assumption|rewrite <-(activation_before prefix g row k K);assumption].
 - assert(Eq:k=length prefix)by(rewrite app_length in Index;cbn[length]in Index;lia).
   subst k;rewrite old_last in At;inversion At;right;auto.
Qed.
Theorem geometry_activation n m cap hs path prefix g log row:
 row<m ->S(length prefix)<cap ->
 parity n(nth row hs zero_vector)(prefix_selected path(length prefix))=true ->
 stack_geometry n m cap hs path(prefix++[g])log ->
 stack_geometry n m cap hs path(prefix++[activated_record g row])log.
Proof.
 intros Row Room Odd[Len[ND[Range[Depth Per]]]].
 unfold stack_geometry;rewrite activation_length.
 split;[assumption|split;[assumption|split;[assumption|split;[assumption|]]]].
 intros k gnew At.
 destruct(activation_lookup_cases prefix g row k gnew At)as[[K AtOld]|[Eq Same]].
 - destruct(Per k gnew AtOld)as[PB[Mark[Root[Anc Init]]]].
   split;[assumption|split;[assumption|split;[assumption|split]]].
   + intros Deep;destruct(Anc Deep)as[Wait[Chosen[Next Order]]].
     split;[assumption|split;[assumption|split;[assumption|]]].
     rewrite activation_marks;assumption.
   + exact Init.
 - subst k gnew.
   destruct(Per(length prefix)g(old_last prefix g))as[PB[Mark[Root[Anc Init]]]].
   cbn[activated_record ghost_phase ghost_mark ghost_chosen ghost_next ghost_row].
   split;[lia|split;[assumption|split;[exact Root|split]]].
   + intros Deep;rewrite app_length in Deep;cbn[length]in Deep;lia.
   + intros Kind;repeat split;try assumption;lia.
Qed.
Print Assumptions geometry_activation.
