(* Protected parent snapshots during arbitrary descendant work.
   Uses the checked actual restore model; C search refinement remains separate. *)
Require Import VST.floyd.proofauto VST.zlist.list_solver.
Require Import CCV.CCModel CCV.CCFunctional CCV.CCRepresentation CCV.CCJournalArray CCV.CCJournalTrace CCV.VerifRestore CCV.VerifToggle.
Open Scope Z_scope.
Lemma binary_decode_equal xs ys : Zlength xs=Zlength ys ->
 Forall(fun z:Z=>z=0 \/z=1)xs ->Forall(fun z:Z=>z=0 \/z=1)ys ->
 (forall i,(i<Z.to_nat(Zlength xs))%nat ->decode xs i=decode ys i) ->xs=ys.
Proof.
 intros Len XB YB Eq;apply Znth_eq_ext;[assumption|];intros i I.
 assert(IN:(Z.to_nat i<Z.to_nat(Zlength xs))%nat)by(apply Z2Nat.inj_lt;lia).
 pose proof(Eq(Z.to_nat i)IN)as Same;rewrite !decode_at_nat,Z2Nat.id in Same by lia.
 assert(X:Znth i xs=0 \/Znth i xs=1)by(apply Forall_Znth;auto).
 assert(Y:Znth i ys=0 \/Znth i ys=1)by(apply Forall_Znth;auto;lia).
 rewrite <-(encode_bit _ X),<-(encode_bit _ Y);f_equal;exact Same.
Qed.
Theorem journal_trace_prefix n base log buf mark :
 Zlength base=n ->journal_trace n base log buf ->0<=mark<=Zlength log ->
 journal_trace n base(sublist 0 mark log)buf.
Proof.
 intros Len [Top [Range [ND [Clear [Buf Prefix]]]]] Mark.
 assert(PLen:Zlength(sublist 0 mark log)=mark)by(autorewrite with sublist;lia).
 assert(PR:Forall(fun q:Z=>0<=q<n)(sublist 0 mark log))by(apply Forall_sublist;assumption).
 pose proof(nat_journal_split log mark Mark)as Split.
 assert(PND:NoDup(nat_journal(sublist 0 mark log))).
 { rewrite Split in ND;apply NoDup_app in ND;tauto. }
 assert(PC:root_clear base(sublist 0 mark log)).
 { intros q Hin;apply Clear;rewrite Split;apply in_or_app;right;assumption. }
 assert(PP:undo_prefix(sublist 0 mark log)buf).
 { unfold undo_prefix,tbytes in *;list_solve. }
 unfold journal_trace;rewrite PLen;repeat split;try assumption;lia.
Qed.
Theorem journal_restore_bitmap_exact n base log buf mark :
 Zlength base=n ->Forall(fun z:Z=>z=0 \/z=1)base ->
 journal_trace n base log buf ->0<=mark<=Zlength log ->
 restored(journal_bitmap base log)log mark(Zlength log)=journal_bitmap base(sublist 0 mark log).
Proof.
 intros Len Bits Trace Mark;destruct Trace as[Top [Range [ND [Clear [Buf Prefix]]]]].
 assert(PR:Forall(fun q:Z=>0<=q<n)(sublist 0 mark log))by(apply Forall_sublist;assumption).
 assert(BLen:Zlength(journal_bitmap base log)=n)by(apply(journal_bitmap_length n base log);assumption).
 assert(PLen:Zlength(journal_bitmap base(sublist 0 mark log))=n)by(apply(journal_bitmap_length n base(sublist 0 mark log));assumption).
 assert(RLen:Zlength(restored(journal_bitmap base log)log mark(Zlength log))=n)by(apply restored_length;assumption).
 apply binary_decode_equal;try lia.
 - unfold restored;apply zero_indices_bits;apply journal_bitmap_bits;assumption.
 - apply journal_bitmap_bits;assumption.
 - intros i I.
   rewrite(journal_restore_decode n base log mark Len Range ND Clear Mark i).
   rewrite(journal_bitmap_decode n base(sublist 0 mark log)Len PR);reflexivity.
Qed.
Lemma protected_prefix_after_pop (old added:list Z) mark :
 Zlength old<=mark<=Zlength(old++added) ->
 sublist 0(Zlength old)(sublist 0 mark(old++added))=old.
Proof. intros;list_solve. Qed.
Theorem restore_parent_avoids_target n base old added buf target :
 Zlength base=n ->Forall(fun z:Z=>z=0 \/z=1)base ->
 journal_trace n base(old++added)buf ->
 avoids(Z.to_nat n)target(decode(journal_bitmap base old)) ->
 avoids(Z.to_nat n)target(decode(restored(journal_bitmap base(old++added))(old++added)(Zlength old)(Zlength(old++added)))).
Proof.
 intros Len Bits Trace Avoid.
 rewrite(journal_restore_bitmap_exact n base(old++added)buf(Zlength old))by(try assumption;rewrite Zlength_app;pose proof(Zlength_nonneg old);pose proof(Zlength_nonneg added);lia).
 replace(sublist 0(Zlength old)(old++added))with old by(list_solve).
 assumption.
Qed.
Print Assumptions journal_trace_prefix.
Print Assumptions journal_restore_bitmap_exact.
Print Assumptions restore_parent_avoids_target.
