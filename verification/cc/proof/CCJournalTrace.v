Require Import VST.floyd.proofauto.
Require Import CCV.CCModel CCV.CCFunctional CCV.CCJournal CCV.CCRepresentation CCV.CCJournalArray CCV.VerifForbid CCV.VerifToggle.
Open Scope Z_scope.
Definition root_clear base log :=forall q,In q (nat_journal log) ->decode base q=false.
Definition journal_trace n base log (buf:list val) :=
 0<=Zlength log<=n /\ Forall(fun q:Z=>0<=q<n) log /\ NoDup(nat_journal log) /\
 root_clear base log /\ Zlength buf=n /\ undo_prefix log buf.
Definition pushed_log n base log q :=
 if fresh_push (journal_bitmap base log) q (Zlength log) n then log++[q] else log.
Definition pushed_buffer n base log buf q :=
 if fresh_push (journal_bitmap base log) q (Zlength log) n then upd_Znth (Zlength log) buf (Vint(Int.repr q)) else buf.
Lemma pushed_bitmap n base log q : journal_bitmap base (pushed_log n base log q)=
 if fresh_push (journal_bitmap base log) q (Zlength log) n then upd_Znth q (journal_bitmap base log) 1 else journal_bitmap base log.
Proof. unfold pushed_log;destruct(fresh_push _ _ _ _);[apply journal_bitmap_push|reflexivity]. Qed.
Lemma pushed_top n base log q : Zlength(pushed_log n base log q)=
 if fresh_push (journal_bitmap base log) q (Zlength log) n then Zlength log+1 else Zlength log.
Proof. unfold pushed_log;destruct(fresh_push _ _ _ _);autorewrite with sublist;reflexivity. Qed.
Theorem forbid_trace_step n base log buf q : 0<=n ->Zlength base=n ->journal_trace n base log buf ->0<=q<n ->
 forbid_result (journal_bitmap base log) q (Zlength log) n=1 /\
 journal_trace n base (pushed_log n base log q) (pushed_buffer n base log buf q).
Proof.
 intros N Len [Top [Range [ND [Clear [BufLen Prefix]]]]] Q.
 destruct(Z.eq_dec (Znth q (journal_bitmap base log)) 0) as [F|F].
 - destruct(journal_fresh_capacity n base log q N Len Range ND Q F) as [Cap [NDnew BaseQ]].
   assert(Push:fresh_push (journal_bitmap base log) q (Zlength log) n=true).
   { unfold fresh_push;repeat if_tac;try lia;reflexivity. }
   split.
   + unfold forbid_result;repeat if_tac;try lia;reflexivity.
   + unfold pushed_log,pushed_buffer;rewrite Push;unfold journal_trace.
     repeat split.
     * autorewrite with sublist;lia.
     * autorewrite with sublist;lia.
     * apply Forall_app;split;[assumption|constructor;[assumption|constructor]].
     * assumption.
     * unfold root_clear;rewrite nat_journal_push;intros a [<-|Ha];[assumption|apply Clear;assumption].
     * rewrite upd_Znth_Zlength by lia;lia.
     * apply (undo_prefix_push log buf n q);[lia|assumption|assumption].
 - assert(Push:fresh_push (journal_bitmap base log) q (Zlength log) n=false).
   { unfold fresh_push;repeat if_tac;try contradiction;reflexivity. }
   split.
   + unfold forbid_result;repeat if_tac;try contradiction;reflexivity.
   + unfold pushed_log,pushed_buffer;rewrite Push;unfold journal_trace;tauto.
Qed.
Definition allowed_extension (old cur:list Z) (Allowed:Z->Prop) :=
 exists added,cur=old++added /\ Forall Allowed added.
Lemma allowed_extension_refl old Allowed : allowed_extension old old Allowed.
Proof. exists [];rewrite app_nil_r;split;[reflexivity|constructor]. Qed.
Lemma allowed_extension_push old cur Allowed q : allowed_extension old cur Allowed ->Allowed q ->
 allowed_extension old (cur++[q]) Allowed.
Proof.
 intros [added [E All]] Aq;exists(added++[q]);split.
 - rewrite E,app_assoc;reflexivity.
 - apply Forall_app;split;[assumption|constructor;[assumption|constructor]].
Qed.
Lemma allowed_extension_forbid n base old log q Allowed :
 allowed_extension old log Allowed ->Allowed q ->
 allowed_extension old (pushed_log n base log q) Allowed.
Proof. intros H A;unfold pushed_log;destruct(fresh_push _ _ _ _);[apply allowed_extension_push|];assumption. Qed.
Lemma journal_bitmap_app base old added : journal_bitmap base (old++added)=journal_bitmap (journal_bitmap base old) added.
Proof. unfold journal_bitmap;apply fold_left_app. Qed.
Theorem bitmap_extension_avoids n base old added target : Zlength base=n ->
 Forall(fun q:Z=>0<=q<n) old ->Forall(fun q:Z=>0<=q<n) added ->
 avoids (Z.to_nat n) target (decode(journal_bitmap base old)) ->
 (forall q,In q added ->target(Z.to_nat q)=false) ->
 avoids (Z.to_nat n) target (decode(journal_bitmap base (old++added))).
Proof.
 intros Len Rold Radd Avoid Safe i Hi New;rewrite journal_bitmap_app in New.
 rewrite (journal_bitmap_decode n (journal_bitmap base old) added) in New
  by (try assumption;apply journal_bitmap_length with (n:=n);assumption).
 unfold forbidden in New;apply orb_true_iff in New;destruct New as [Old|Added].
 - apply Avoid;assumption.
 - apply memberb_spec in Added;unfold nat_journal in Added;apply in_rev in Added;apply in_map_iff in Added.
   destruct Added as [q [E Hin]];subst i;apply Safe;assumption.
Qed.
Print Assumptions forbid_trace_step.
Print Assumptions bitmap_extension_avoids.
