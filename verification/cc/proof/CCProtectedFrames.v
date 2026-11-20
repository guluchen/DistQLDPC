(* Critical ancestor snapshots survive arbitrary divergent descendant work.
   Pure invariant lemmas; actual full Clight stack refinement remains open. *)
Require Import VST.floyd.proofauto VST.zlist.list_solver.
Require Import CCV.CCModel CCV.CCCriticalFrame CCV.CCRepresentation
 CCV.CCJournalArray CCV.CCJournalTrace CCV.CCJournalSnapshots CCV.VerifRestore.
Open Scope Z_scope.
Definition critical_snapshot n base log mark h e s next:=
 critical_frame(Z.to_nat n)h e s
 (decode(journal_bitmap base(sublist 0 mark log)))next.
Lemma extension_retains_prefix (old new:list Z)mark Allowed:
 allowed_extension old new Allowed ->0<=mark<=Zlength old ->
 sublist 0 mark new=sublist 0 mark old.
Proof. intros[added[-> All]]Mark;list_solve. Qed.
Lemma restore_retains_prefix (log:list Z)protected restored_to:
 0<=protected<=restored_to ->restored_to<=Zlength log ->
 sublist 0 protected(sublist 0 restored_to log)=sublist 0 protected log.
Proof. intros;list_solve. Qed.
Theorem critical_ancestor_append n base old new mark h e s next Allowed:
 allowed_extension old new Allowed ->0<=mark<=Zlength old ->
 critical_snapshot n base old mark h e s next ->
 critical_snapshot n base new mark h e s next.
Proof.
 intros Ext Mark Critical;unfold critical_snapshot in *.
 rewrite(extension_retains_prefix old new mark Allowed Ext Mark);assumption.
Qed.
Theorem critical_ancestor_deeper_pop n base log mark restored_to h e s next:
 0<=mark<=restored_to ->restored_to<=Zlength log ->
 critical_snapshot n base log mark h e s next ->
 critical_snapshot n base(sublist 0 restored_to log)mark h e s next.
Proof.
 intros Mark Bound Critical;unfold critical_snapshot in *.
 rewrite restore_retains_prefix by assumption;assumption.
Qed.
Theorem critical_parent_exposed_after_restore n base log buf mark h e s next:
 Zlength base=n ->Forall(fun z:Z=>z=0\/z=1)base ->
 journal_trace n base log buf ->0<=mark<=Zlength log ->
 critical_snapshot n base log mark h e s next ->
 critical_frame(Z.to_nat n)h e s
 (decode(restored(journal_bitmap base log)log mark(Zlength log)))next.
Proof.
 intros Len Bits Trace Mark Critical.
 rewrite(journal_restore_bitmap_exact n base log buf mark Len Bits Trace Mark).
 exact Critical.
Qed.
Print Assumptions critical_ancestor_append.
Print Assumptions critical_ancestor_deeper_pop.
Print Assumptions critical_parent_exposed_after_restore.
