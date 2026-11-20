(* Construct detectors from same-type stabilizer rows by GF(2) elimination.
   Rows may be dependent or zero. The input supplies no logical rows. *)
From Coq Require Import List Bool Arith Lia.
Require Import CCV.CCModel CCV.CCFunctional CCV.CCCache CCV.CCCSSBridge CCV.CCQuotientCertificate.
Import ListNotations.
Local Open Scope nat_scope.

Definition tabulate n (v:vector) := map v (seq 0 n).
Definition cached_vector n (v:vector) : vector :=
 let bits := tabulate n v in fun j => nth j bits false.
Lemma tabulate_at n v i : i<n -> nth i (tabulate n v) false = v i.
Proof.
 intro Hi;unfold tabulate. rewrite nth_indep with (d':=v 0) by (rewrite map_length,seq_length;lia).
 rewrite map_nth,seq_nth by lia. reflexivity.
Qed.
Lemma cached_dot n v e : parity n (cached_vector n v) e = parity n v e.
Proof.
 rewrite (qcert_parity_comm n _ e),(qcert_parity_comm n v e).
 apply parity_ext;apply tabulate_at.
Qed.

Definition restrict_detectors n (g:vector) (rows:list vector) :=
 let odd := filter (fun r=>parity n r g) rows in
 let even := filter (fun r=>negb (parity n r g)) rows in
 match odd with
 | [] => rows
 | pivot::rest => even ++ map (fun r=>cached_vector n (vxor r pivot)) rest
 end.

Lemma restrict_kernel n g rows e :
 kernel n (restrict_detectors n g rows) e <->
 kernel n rows e \/ kernel n rows (vxor e g).
Proof.
 unfold restrict_detectors.
 destruct (filter (fun r=>parity n r g) rows) as [|p tail] eqn:Odd.
 - assert (Even: forall r, In r rows -> parity n r g=false).
   { intros r Hr. destruct (parity n r g) eqn:B;[|reflexivity].
     assert (In r (filter (fun r=>parity n r g) rows)) by (apply filter_In;auto).
     rewrite Odd in H;contradiction. }
   split;[auto|intros [K|K];[exact K|]].
   intros r Hr;specialize (K r Hr);rewrite parity_xor,Even,xorb_false_r in K by assumption;exact K.
 - assert (Membership:forall r, In r (p::tail) <-> In r rows /\ parity n r g=true).
   { intro r;rewrite <-Odd,filter_In;tauto. }
   assert (Pivot:In p rows /\ parity n p g=true) by (apply Membership;left;reflexivity).
   assert (chars:kernel n
     (filter (fun r=>negb(parity n r g)) rows ++ map (fun r=>cached_vector n (vxor r p)) tail) e <->
     (forall r,In r rows ->parity n r g=false ->parity n r e=false) /\
     (forall r,In r tail ->parity n r e=parity n p e)).
   { split.
     - intro K;split.
       + intros r Hr B;apply K;apply in_or_app;left;apply filter_In;rewrite B;auto.
       + intros r Hr;specialize (K (cached_vector n (vxor r p)) ltac:(apply in_or_app;right;apply in_map_iff;exists r;auto)).
         rewrite cached_dot,qcert_parity_xor_left in K;destruct (parity n r e),(parity n p e);cbn in *;congruence.
     - intros [Even Equal] r Hr;apply in_app_or in Hr as [Hr|Hr].
       + apply filter_In in Hr as [H B];apply negb_true_iff in B;auto.
       + apply in_map_iff in Hr as [s [<- Hs]];rewrite cached_dot,qcert_parity_xor_left,Equal by assumption;apply xorb_nilpotent. }
   rewrite chars. split.
   + intros [Even Equal].
     assert (OddValue:forall r,In r rows ->parity n r g=true ->parity n r e=parity n p e).
     { intros r Hr B;assert(In r (p::tail)) by (apply Membership;auto).
       destruct H as [<-|Ht];auto. }
     destruct (parity n p e) eqn:E.
     * right;intros r Hr;rewrite parity_xor;destruct (parity n r g) eqn:B;[rewrite OddValue|rewrite Even];auto.
     * left;intros r Hr;destruct (parity n r g) eqn:B;auto.
   + intros [K|K].
     * split;intros r Hr;[intros;apply K;auto|].
       assert (In r rows /\ parity n r g=true) by (apply Membership;right;exact Hr).
       rewrite !K;tauto.
     * split.
       -- intros r Hr B;specialize(K r Hr);rewrite parity_xor,B,xorb_false_r in K;exact K.
       -- intros r Hr;assert (R:In r rows /\ parity n r g=true) by (apply Membership;right;exact Hr).
          destruct Pivot as [Hp Bp], R as [H B];pose proof(K p Hp) as P;specialize(K r H).
          rewrite parity_xor,Bp in P;rewrite parity_xor,B in K.
          destruct (parity n r e),(parity n p e);cbn in *;congruence.
Qed.

Lemma extend_rowspan n g rows e :
 rowspan n (g::rows) e <-> rowspan n rows e \/ rowspan n rows (vxor e g).
Proof.
 split.
 - intros [[|b bs][Len Eq]];[discriminate|].
   inversion Len as [L];destruct b.
   + right;exists bs;split;[exact L|]. intros i Hi;specialize (Eq i Hi).
     cbn [linear_combination] in Eq;unfold vxor in *;rewrite Eq.
     destruct (g i),(linear_combination rows bs i);reflexivity.
   + left;exists bs;auto.
 - intros [[bs [Len Eq]]|[bs [Len Eq]]].
   + exists (false::bs);cbn [linear_combination length];auto.
   + exists (true::bs);split;[cbn;congruence|].
     intros i Hi;specialize (Eq i Hi);cbn [linear_combination];unfold vxor in *.
     destruct (e i),(g i),(linear_combination rows bs i);cbn in *;congruence.
Qed.

Fixpoint pcm_detectors n (same:list vector) :list vector :=
 match same with
 | [] => map unit_vector (seq 0 n)
 | g::tail => restrict_detectors n g (pcm_detectors n tail)
 end.
Theorem detectors_characterize_rowspan n same e :
 kernel n (pcm_detectors n same) e <-> rowspan n same e.
Proof.
 revert e;induction same as [|g tail IH];intro e.
 - split.
   + intro K;exists [];split;[reflexivity|];intros i Hi.
     pose proof(K (unit_vector i) ltac:(apply in_map;apply in_seq;lia)) as B.
     rewrite qcert_parity_comm,parity_unit_inside in B by assumption;exact B.
   + intros [bs [Len Eq]] r Hr;apply in_map_iff in Hr as [i [<- Hi]].
     apply in_seq in Hi;rewrite qcert_parity_comm,parity_unit_inside by lia.
     apply Eq;lia.
 - cbn [pcm_detectors];rewrite restrict_kernel,extend_rowspan,!IH;tauto.
Qed.
Theorem pcm_logical_detectors n checks same : css_quotient n checks same (pcm_detectors n same).
Proof. intros e _;symmetry;apply detectors_characterize_rowspan. Qed.
Print Assumptions pcm_logical_detectors.
