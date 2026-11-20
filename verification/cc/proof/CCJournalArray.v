(* Array-to-logical journal bridge; C restore/forbid bodies are proved separately. *)
Require Import VST.floyd.proofauto VST.zlist.list_solver.
Require Import CCV.CCJournal CCV.CCRepresentation CCV.CCFunctional CCV.VerifToggle CCV.VerifRestore.
Open Scope Z_scope.
Lemma decode_update xs q v : 0<=q<Zlength xs ->forall i:nat,
 decode (upd_Znth q xs v) i=if Nat.eqb i (Z.to_nat q) then (v=?1) else decode xs i.
Proof.
 intros Q i;destruct(Nat.lt_ge_cases i (Z.to_nat(Zlength xs))) as [I|I].
 - rewrite !decode_at_nat.
   assert(IZ:0<=Z.of_nat i<Zlength xs).
   { apply Nat2Z.inj_lt in I;rewrite Z2Nat.id in I by apply Zlength_nonneg;lia. }
   destruct(Nat.eqb i (Z.to_nat q)) eqn:E.
   + apply Nat.eqb_eq in E;subst i;rewrite Z2Nat.id by lia;rewrite upd_Znth_same by lia;reflexivity.
   + assert(Ne:q<>Z.of_nat i).
     { intro X;apply Nat.eqb_neq in E;apply E;rewrite X,Nat2Z.id;reflexivity. }
     rewrite upd_Znth_diff by lia;reflexivity.
 - assert(L:Z.to_nat(Zlength xs)=length xs) by (rewrite Zlength_correct,Nat2Z.id;reflexivity).
   assert(U:length(upd_Znth q xs v)=length xs).
   { apply Nat2Z.inj;rewrite <- !Zlength_correct;rewrite upd_Znth_Zlength by lia;reflexivity. }
   assert(E:Nat.eqb i (Z.to_nat q)=false).
   { apply Nat.eqb_neq;assert(Z.to_nat q<Z.to_nat(Zlength xs))%nat by (apply Z2Nat.inj_lt;lia);lia. }
   rewrite E;unfold decode;rewrite !nth_overflow by (rewrite ?U;lia);reflexivity.
Qed.
Lemma decode_set_one xs q : 0<=q<Zlength xs ->forall i,
 decode (upd_Znth q xs 1) i=setbit (decode xs) (Z.to_nat q) i.
Proof. intros Q i;rewrite decode_update by assumption;unfold setbit;destruct(Nat.eqb i (Z.to_nat q));reflexivity. Qed.
Lemma decode_set_zero xs q : 0<=q<Zlength xs ->forall i,
 decode (upd_Znth q xs 0) i=clearbit (decode xs) (Z.to_nat q) i.
Proof. intros Q i;rewrite decode_update by assumption;unfold clearbit;destruct(Nat.eqb i (Z.to_nat q));reflexivity. Qed.
Definition journal_bitmap (base log:list Z) :=fold_left (fun a q=>upd_Znth q a 1) log base.
Definition nat_journal (log:list Z) :=rev(map Z.to_nat log).
Lemma journal_bitmap_push base log q : journal_bitmap base (log++[q])=upd_Znth q (journal_bitmap base log) 1.
Proof. unfold journal_bitmap;rewrite fold_left_app;reflexivity. Qed.
Lemma nat_journal_push log q : nat_journal(log++[q])=Z.to_nat q::nat_journal log.
Proof. unfold nat_journal;rewrite map_app,rev_app_distr;reflexivity. Qed.
Lemma journal_bitmap_length n base log : Zlength base=n -> Forall(fun q:Z=>0<=q<n) log ->Zlength(journal_bitmap base log)=n.
Proof.
 unfold journal_bitmap;revert base;induction log;intros base Hlen Range;[assumption|].
 inversion Range;subst;simpl;apply IHlog;[rewrite upd_Znth_Zlength by lia;lia|assumption].
Qed.
Lemma journal_bitmap_bits base log : Forall(fun z:Z=>z=0 \/ z=1) base ->
 Forall(fun z:Z=>z=0 \/ z=1) (journal_bitmap base log).
Proof.
 unfold journal_bitmap;revert base;induction log;intros base B;simpl;[assumption|].
 apply IHlog;apply Forall_upd_Znth;[assumption|right;reflexivity].
Qed.
Theorem journal_bitmap_decode n base log : Zlength base=n ->Forall(fun q:Z=>0<=q<n) log ->
 forall i,decode(journal_bitmap base log) i=forbidden (decode base) (nat_journal log) i.
Proof.
 intros Len;induction log using rev_ind;intros Range i.
 - unfold journal_bitmap,nat_journal,forbidden,memberb;simpl;destruct(decode base i);reflexivity.
 - apply Forall_app in Range;destruct Range as [Range Last].
   assert(Q:0<=x<n) by (inversion Last;assumption).
   rewrite journal_bitmap_push,decode_set_one by (rewrite (journal_bitmap_length n base log) by assumption;lia).
   rewrite nat_journal_push,push_forbidden_pointwise;unfold setbit.
   destruct(Nat.eqb i (Z.to_nat x));[reflexivity|apply IHlog;assumption].
Qed.
Lemma nat_journal_range n log : 0<=n ->Forall(fun q:Z=>0<=q<n) log ->
 forall q,In q (nat_journal log) ->(q<Z.to_nat n)%nat.
Proof.
 intros N Range q Hq;unfold nat_journal in Hq;apply in_rev in Hq;apply in_map_iff in Hq.
 destruct Hq as [x [E Hin]];subst q;apply Forall_forall with (x:=x) in Range;[|assumption].
 apply Z2Nat.inj_lt;lia.
Qed.
Theorem journal_fresh_capacity n base log q :
 0<=n ->Zlength base=n ->Forall(fun a:Z=>0<=a<n) log ->NoDup(nat_journal log) ->
 0<=q<n ->Znth q (journal_bitmap base log)=0 ->
 Zlength log<n /\ NoDup(nat_journal(log++[q])) /\ decode base (Z.to_nat q)=false.
Proof.
 intros N Len Range ND Q Fresh.
 assert(D:decode(journal_bitmap base log) (Z.to_nat q)=false).
 { unfold decode;rewrite <- (nonnegative_lookup q (journal_bitmap base log)) by lia;rewrite Fresh;reflexivity. }
 rewrite (journal_bitmap_decode n base log Len Range) in D.
 assert(QN:(Z.to_nat q<Z.to_nat n)%nat) by (apply Z2Nat.inj_lt;lia).
 destruct(fresh_push_fits (Z.to_nat n) (decode base) (nat_journal log) (Z.to_nat q)
   ND (nat_journal_range n log N Range) QN D) as [Bound NDnew].
 split.
 - unfold nat_journal in Bound;rewrite rev_length,map_length in Bound;apply Nat2Z.inj_lt in Bound.
   rewrite Z2Nat.id in Bound by assumption;rewrite <- Zlength_correct in Bound;assumption.
 - split;[rewrite nat_journal_push;assumption|apply fresh_journal in D;tauto].
Qed.
Definition undo_prefix (log:list Z) (buf:list val) :=sublist 0 (Zlength log) buf=tbytes log.
Lemma undo_prefix_push log buf n q : 0<=Zlength log<n ->Zlength buf=n ->undo_prefix log buf ->
 undo_prefix (log++[q]) (upd_Znth (Zlength log) buf (Vint(Int.repr q))).
Proof. intros;unfold undo_prefix,tbytes in *;list_solve. Qed.
Lemma decode_zero_indices n xs removed : Zlength xs=n ->Forall(fun q:Z=>0<=q<n) removed ->
 forall i,decode (zero_indices xs removed) i=clear_many (decode xs) (map Z.to_nat removed) i.
Proof.
 unfold zero_indices;revert xs;induction removed as [|q tail IH];intros xs Len Range i;simpl;[reflexivity|].
 inversion Range;subst;rewrite (IH (upd_Znth q xs 0)).
 - eapply clear_many_ext;intros j;apply decode_set_zero;lia.
 - rewrite upd_Znth_Zlength by lia;lia.
 - assumption.
Qed.
Lemma nat_journal_split log mark : 0<=mark<=Zlength log ->
 nat_journal log=map Z.to_nat (rev(sublist mark (Zlength log) log))++nat_journal(sublist 0 mark log).
Proof.
 intros M;unfold nat_journal.
 assert(S:log=sublist 0 mark log++sublist mark (Zlength log) log).
 { rewrite <- (sublist_split 0 mark (Zlength log) log) by lia;autorewrite with sublist;reflexivity. }
 rewrite S at 1;rewrite map_app,rev_app_distr,map_rev;reflexivity.
Qed.
Theorem journal_restore_decode n base log mark :
 Zlength base=n ->Forall(fun q:Z=>0<=q<n) log ->NoDup(nat_journal log) ->
 (forall q,In q (nat_journal log) ->decode base q=false) ->0<=mark<=Zlength log ->
 forall i,decode(restored (journal_bitmap base log) log mark (Zlength log)) i=
 forbidden (decode base) (nat_journal(sublist 0 mark log)) i.
Proof.
 intros Len Range ND Base M i;unfold restored.
 rewrite (decode_zero_indices n (journal_bitmap base log) (rev(sublist mark (Zlength log) log)))
  by (try (apply journal_bitmap_length with (n:=n);assumption);apply Forall_rev;apply Forall_sublist;assumption).
 rewrite (clear_many_ext _ (forbidden (decode base) (nat_journal log))).
 - rewrite (nat_journal_split log mark M) at 1.
   apply restore_mark_exact.
   + rewrite <- (nat_journal_split log mark M);assumption.
   + rewrite <- (nat_journal_split log mark M);assumption.
 - intros j;apply (journal_bitmap_decode n base log);assumption.
Qed.
Print Assumptions journal_fresh_capacity.
Print Assumptions journal_restore_decode.
