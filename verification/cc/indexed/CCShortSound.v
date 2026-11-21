(* SPDX-License-Identifier: GPL-3.0-or-later *)
From Coq Require Import List Bool Arith ZArith Lia.
Require Import CCV.CCModel CCV.CCFunctional CCV.CCCSSBridge CCV.CCQuotientCertificate.
Import ListNotations.
Local Open Scope nat_scope.

Definition add_all hs := fold_right vxor zero_vector hs.
Lemma all_neutral n hs e : kernel n hs e -> parity n (add_all hs) e=false.
Proof.
 induction hs as [|h t IH];intro K.
 - apply qcert_zero_dot.
 - cbn [add_all fold_right]. rewrite qcert_parity_comm,parity_xor.
   rewrite (qcert_parity_comm n e h), (qcert_parity_comm n e (fold_right vxor zero_vector t)).
   rewrite K by (left;reflexivity). apply IH.
   intros r R;apply K;right;exact R.
Qed.
Lemma ones_parity n e : parity n (fun _=>true) e=Nat.odd(weight n e).
Proof.
 induction n as [|n IH];[reflexivity|].
 cbn [parity weight];rewrite IH.
 destruct (e n);cbn [andb];[rewrite Nat.add_1_r,Nat.odd_succ,Nat.negb_odd|rewrite Nat.add_0_r];reflexivity.
Qed.
Theorem odd_columns_even_weight n hs e :
 (forall i,i<n -> add_all hs i=true) ->kernel n hs e ->Nat.odd(weight n e)=false.
Proof.
 intros Col K;rewrite <-ones_parity.
 rewrite qcert_parity_comm,(parity_ext n e (fun _=>true) (add_all hs)) by (intros;symmetry;apply Col;auto).
 rewrite qcert_parity_comm;now apply all_neutral.
Qed.

(* Fingerprints live in the XOR group. A table may return true on additional
   sums or collide arbitrarily. Only membership of all short repairs is needed. *)
Section Filter.
 Variable A:Type.
 Variable key:A->Z.
 Variable present:Z->bool.
 Definition signature (xs:list A) := fold_right (fun j v=>Z.lxor (key j) v) 0%Z xs.
 Hypothesis inserted : forall xs,length xs<=2 ->present (signature xs)=true.
 Lemma remove_key xs q : In q xs ->exists rest,
   length xs=S(length rest) /\ signature xs=Z.lxor (key q) (signature rest).
 Proof.
  induction xs as [|h t IH];[contradiction|];intros [<-|I].
  - exists t;split;reflexivity.
  - destruct (IH I) as [u [L S]]. exists (h::u);split;[simpl;lia|].
    change (Z.lxor (key h) (signature t)=Z.lxor (key q) (Z.lxor (key h) (signature u))). rewrite S.
    rewrite <-!Z.lxor_assoc,(Z.lxor_comm (key h) (key q));reflexivity.
 Qed.
 Lemma residual xs q : In q xs -> exists rest,length xs=S(length rest) /\
   Z.lxor (signature xs)(key q)=signature rest.
 Proof.
  intro I;destruct (remove_key xs q I) as [r [L E]];exists r;split;auto.
  rewrite E,(Z.lxor_comm _ (key q)),<-Z.lxor_assoc,Z.lxor_nilpotent,Z.lxor_0_l;reflexivity.
 Qed.
 Definition three (row:list A) sig :=
  existsb (fun q=>present(Z.lxor sig (key q))) row.
 Theorem three_keeps xs row : length xs<=3 ->
  (exists q, In q xs /\ In q row) -> three row (signature xs)=true.
 Proof.
  intros L [q [I R]];unfold three;apply existsb_exists;exists q;split;auto.
  destruct (residual _ _ I) as [u [N ->]];apply inserted;lia.
 Qed.
 (* None means that removing q closes the physical syndrome; otherwise the
    chosen odd row has to meet every remaining repair. This hypothesis refers
    to physical parity, and places no injectivity requirement on key. *)
 Variable nextrow:A->option(list A).
 Definition four (row:list A) sig :=
  existsb (fun q=>match nextrow q with None=>true|Some r=>three r (Z.lxor sig(key q)) end) row.
 Theorem four_keeps xs row : length xs<=4 ->
  (exists q,In q row /\ exists u,length xs=S(length u) /\ Z.lxor(signature xs)(key q)=signature u /\
    (forall r,nextrow q=Some r->exists j,In j u /\In j r)) ->
  four row (signature xs)=true.
 Proof.
  intros L [q [I [u [N [Sig Odd]]]]];unfold four;apply existsb_exists;exists q;split;auto.
  destruct(nextrow q)as[r|]eqn:R;auto. rewrite Sig. apply three_keeps;[lia|apply Odd;reflexivity].
 Qed.
End Filter.
Print Assumptions odd_columns_even_weight.
Print Assumptions three_keeps.
Print Assumptions four_keeps.

(* When every column has odd check degree, a kernel word has even weight.
   In that half it suffices to exclude weights strictly below d-1 for even d. *)
Definition parity_limit n hs d :=
  match d with
  | 0 => 0
  | S k => if Nat.odd k && forallb (add_all hs) (seq 0 n) then k else S k
  end.

Theorem parity_limit_sound n hs d e :
  kernel n hs e -> parity_limit n hs d <= weight n e -> d <= weight n e.
Proof.
  intros K; destruct d as [|k]; [simpl; lia|].
  cbn [parity_limit]; destruct (_ && _)%bool eqn:E; [|auto].
  apply andb_true_iff in E as [Odd All].
  assert (Even : Nat.odd (weight n e) = false).
  { eapply odd_columns_even_weight; [|exact K].
    intros i I. apply forallb_forall with (x:=i) in All; [exact All|apply in_seq;lia]. }
  intro Lower; destruct (Nat.eq_dec (weight n e) k) as [Eq|Ne]; [congruence|lia].
Qed.
Print Assumptions parity_limit_sound.

(* Any supplied check is either an original row or the zero row. Even
   incomplete advice consequently preserves every possible original word. *)
Definition advised_rows (hs:list vector) (order:list nat) :=
  match order with [] => hs | _ => map (fun i=>nth i hs zero_vector) order end.
Lemma kernel_advised_rows n hs order e :
  kernel n hs e -> kernel n (advised_rows hs order) e.
Proof.
  intros K; destruct order as [|i tail]; [exact K|].
  unfold advised_rows; fold (map (fun j=>nth j hs zero_vector) (i::tail)).
  intros h H; apply in_map_iff in H as [j [<- _]].
  destruct (lt_dec j (length hs)) as [B|B]; [apply K; now apply nth_In|].
  rewrite nth_overflow by lia; apply qcert_zero_dot.
Qed.
