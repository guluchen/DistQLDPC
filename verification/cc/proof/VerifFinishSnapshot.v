(* Actual child-completion C block restores a protected parent snapshot.
   This local composition does not prove the complete search invariant. *)
Require Import VST.floyd.proofauto VST.zlist.list_solver.
Require Import CCV.ccv_core CCV.CCSearchSpecs CCV.CCSearchContext
 CCV.VerifSearchFinish CCV.CCJournalSnapshots CCV.CCJournalTrace
 CCV.CCJournalArray CCV.CCRepresentation CCV.VerifRestore CCV.CCFunctional.
Import ListNotations. Open Scope Z_scope.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
Section Proof.
Context{Espec:OracleKind}.
Lemma block_finish_parent_snapshot:
 forall sh wp fp up tp fr n depth base old added buf target,
 readable_share sh ->0<n<=Int.max_signed ->0<depth<=n ->
 Zlength base=n ->Forall(fun z:Z=>z=0\/z=1)base ->
 journal_trace n base(old++added)buf ->
 avoids(Z.to_nat n)target(decode(journal_bitmap base old)) ->
 semax CCSearchContext.Delta
 (PROP()LOCAL(temp _w wp;temp _f fr;temp _depth(Vint(Int.repr depth));lvar _top tuint tp)
  SEP(finish_memory sh wp fp up tp fr n(Zlength(old++added))(Zlength old)
        (journal_bitmap base(old++added))(old++added)))%assert
 finish_body
 (normal_ret_assert
  (PROP(avoids(Z.to_nat n)target(decode(journal_bitmap base old)))
   LOCAL(temp _w wp;temp _f fr;temp _depth(Vint(Int.repr(depth-1)));lvar _top tuint tp)
   SEP(finish_memory sh wp fp up tp fr n(Zlength old)(Zlength old)
      (journal_bitmap base old)(old++added)))%assert).
Proof.
 intros sh wp fp up tp fr n depth base old added buf target SH N Depth Len Bits Trace Avoid.
 assert(Range:Forall(fun q:Z=>0<=q<n)(old++added))by(exact(proj1(proj2 Trace))).
 assert(Top:0<=Zlength(old++added)<=n)by(exact(proj1 Trace)).
 assert(Mark:0<=Zlength old<=Zlength(old++added)).
 { rewrite Zlength_app;pose proof(Zlength_nonneg old);pose proof(Zlength_nonneg added);lia. }
 assert(ExactF:restored(journal_bitmap base(old++added))(old++added)(Zlength old)(Zlength(old++added))=
   journal_bitmap base old).
 { rewrite(journal_restore_bitmap_exact n base(old++added)buf(Zlength old))by assumption.
   replace(sublist 0(Zlength old)(old++added))with old by list_solve;reflexivity. }
 eapply semax_post' with(R':=
  (PROP()LOCAL(temp _w wp;temp _f fr;temp _depth(Vint(Int.repr(depth-1)));lvar _top tuint tp)
   SEP(finish_memory sh wp fp up tp fr n(Zlength old)(Zlength old)
     (restored(journal_bitmap base(old++added))(old++added)(Zlength old)(Zlength(old++added)))
     (old++added)))%assert).
 - rewrite ExactF;entailer!.
 - apply block_search_finish;try assumption;try lia.
   + apply journal_bitmap_length;assumption.
   + apply journal_bitmap_bits;assumption.
Qed.
End Proof.
Print Assumptions block_finish_parent_snapshot.
