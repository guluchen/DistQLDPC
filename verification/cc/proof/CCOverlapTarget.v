(* Interpret the checked generic C overlap postcondition for a fixed target.
   The C search caller must still instantiate this in its own VST proof. *)
Require Import VST.floyd.proofauto.
Require Import CCV.CCModel CCV.CCJournalArray CCV.CCFunctional CCV.CCRepresentation CCV.CCJournalTrace CCV.CCOverlapArray CCV.CCOverlap.
Open Scope Z_scope.
Theorem overlap_post_preserves_target n base xs old new oldbuf newbuf ret e :
 Zlength base=n ->journal_trace n base old oldbuf ->journal_trace n base new newbuf ->
 allowed_extension old new (fun q=>subset (Z.to_nat n) (decode xs) e ->e(Z.to_nat q)=false) ->
 (ret=0 \/ ret=1) ->(ret=0 ->~subset (Z.to_nat n) (decode xs) e) ->
 compatible (Z.to_nat n) e (decode xs) (decode(journal_bitmap base old)) ->
 ret=1 /\ compatible (Z.to_nat n) e (decode xs) (decode(journal_bitmap base new)).
Proof.
 intros Len OldTrace NewTrace [added [E All]] Ret Reject [Sub Avoid];subst new.
 assert(One:ret=1) by (destruct Ret as [Req|Req];[exfalso;apply(Reject Req);assumption|assumption]).
 assert(Rold:Forall(fun q:Z=>0<=q<n) old) by (unfold journal_trace in OldTrace;tauto).
 assert(Rnew:Forall(fun q:Z=>0<=q<n) (old++added)) by (unfold journal_trace in NewTrace;tauto).
 apply Forall_app in Rnew;destruct Rnew as [_ Radd].
 split;[assumption|split;[assumption|]].
 apply (bitmap_extension_avoids n base old added e);try assumption.
 intros q Hin;apply Forall_forall with (x:=q) in All;[apply All;assumption|assumption].
Qed.
Print Assumptions overlap_post_preserves_target.
