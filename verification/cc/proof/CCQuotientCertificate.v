(* Finite GF(2) quotient-completeness certificate. A row identity
   I = A H + B L + G^T C certifies ker H intersect ker L = rowspan G.
   The Gaussian producer need not be trusted; acceptance is checked here.
   This file does not implement or verify a C parser/certificate checker. *)
From Coq Require Import Bool List Arith Lia.
Require Import CCV.CCModel CCV.CCFunctional CCV.CCCache CCV.CCCSSBridge.
Import ListNotations. Open Scope nat_scope.
Lemma qcert_parity_comm n a b:parity n a b=parity n b a.
Proof. induction n;cbn[parity];[reflexivity|rewrite IHn,andb_comm;reflexivity]. Qed.
Lemma qcert_parity_xor_left n a b e:
 parity n(vxor a b)e=xorb(parity n a e)(parity n b e).
Proof.
 rewrite(qcert_parity_comm n(vxor a b)e),parity_xor.
 rewrite(qcert_parity_comm n e a),(qcert_parity_comm n e b);reflexivity.
Qed.
Lemma qcert_zero_dot n e:parity n zero_vector e=false.
Proof. induction n;cbn[parity zero_vector];[reflexivity|exact IHn]. Qed.
Lemma qcert_lc_zero n rows bs e:kernel n rows e ->
 parity n(linear_combination rows bs)e=false.
Proof.
 revert bs;induction rows as[|h hs IH];intros[|b bs]K;cbn[linear_combination];try apply qcert_zero_dot.
 destruct b.
 - rewrite qcert_parity_xor_left,(K h(or_introl eq_refl)),IH.
   + reflexivity.
   + intros h' InH;apply K;right;exact InH.
 - apply IH;intros h' InH;apply K;right;exact InH.
Qed.
Lemma qcert_transpose n same dual e i:length dual=length same ->
 parity n(linear_combination dual(map(fun g=>g i)same))e=
 linear_combination same(map(fun c=>parity n c e)dual)i.
Proof.
 revert dual;induction same as[|g gs IH];intros[|d ds]Len;cbn[length]in Len;try discriminate.
 - apply qcert_zero_dot.
 - cbn[linear_combination map].
   pose proof(IH ds ltac:(lia))as Rest.
   destruct(g i)eqn:G.
   + rewrite qcert_parity_xor_left,Rest.
     destruct(parity n d e)eqn:P;cbn[linear_combination map];rewrite ?P;unfold vxor;cbn;rewrite ?G;reflexivity.
   + rewrite Rest. destruct(parity n d e)eqn:P;cbn[linear_combination map];rewrite ?P;unfold vxor;cbn;rewrite ?G;reflexivity.
Qed.
Record quotient_certificate := {
 qcert_hcoeffs:list(list bool);
 qcert_lcoeffs:list(list bool);
 qcert_dual:list vector
}.
Definition qcert_row h l same c i:=
 vxor(linear_combination h(nth i(qcert_hcoeffs c)[]))
 (vxor(linear_combination l(nth i(qcert_lcoeffs c)[]))
 (linear_combination(qcert_dual c)(map(fun g=>g i)same))).
Definition qcert_rows_ok n h l same c:=forall i,i<n ->forall j,j<n ->
 qcert_row h l same c i j=unit_vector i j.
Theorem qcert_reconstruct n h l same c:
 length(qcert_dual c)=length same ->qcert_rows_ok n h l same c ->
 forall e,kernel n h e ->kernel n l e ->rowspan n same e.
Proof.
 intros Len Rows e KH KL.
 exists(map(fun d=>parity n d e)(qcert_dual c));split;[rewrite map_length;exact Len|].
 intros i I.
 assert(Eq:parity n(qcert_row h l same c i)e=parity n(unit_vector i)e).
 { rewrite(qcert_parity_comm n(qcert_row h l same c i)e),
   (qcert_parity_comm n(unit_vector i)e).
   apply parity_ext;intros j J;apply Rows;assumption. }
 rewrite(qcert_parity_comm n(unit_vector i)e),parity_unit_inside in Eq by assumption.
 unfold qcert_row in Eq;rewrite !qcert_parity_xor_left in Eq.
 rewrite(qcert_lc_zero n h(nth i(qcert_hcoeffs c)[])e KH),
 (qcert_lc_zero n l(nth i(qcert_lcoeffs c)[])e KL)in Eq.
 cbn[xorb]in Eq.
 rewrite(qcert_transpose n same(qcert_dual c)e i Len)in Eq.
 symmetry;exact Eq.
Qed.
Theorem qcert_quotient n h l same c:
 length(qcert_dual c)=length same ->
 Forall(fun g=>kernel n h g /\kernel n l g)same ->qcert_rows_ok n h l same c ->
 css_quotient n h same l.
Proof.
 intros Len Trivial Rows e KH;split.
 - intros Span;apply(rowspan_kernel n l same e);[|exact Span].
   apply Forall_forall;intros g InG.
   rewrite Forall_forall in Trivial;exact(proj2(Trivial g InG)).
 - intros KL;apply(qcert_reconstruct n h l same c Len Rows e KH KL).
Qed.
Print Assumptions qcert_quotient.

Definition qcert_shape_check (n:nat)(h l same:list vector)(c:quotient_certificate):=
 Nat.eqb(length(qcert_hcoeffs c))n &&
 (Nat.eqb(length(qcert_lcoeffs c))n &&
 (Nat.eqb(length(qcert_dual c))(length same) &&
 (forallb(fun bs=>Nat.eqb(length bs)(length h))(qcert_hcoeffs c) &&
 forallb(fun bs=>Nat.eqb(length bs)(length l))(qcert_lcoeffs c)))).
Definition qcert_shape (n:nat)(h l same:list vector)(c:quotient_certificate):=
 length(qcert_hcoeffs c)=n /\length(qcert_lcoeffs c)=n /\
 length(qcert_dual c)=length same /\
 Forall(fun bs=>length bs=length h)(qcert_hcoeffs c) /\
 Forall(fun bs=>length bs=length l)(qcert_lcoeffs c).
Lemma qcert_shape_sound n h l same c:qcert_shape_check n h l same c=true ->qcert_shape n h l same c.
Proof.
 unfold qcert_shape_check,qcert_shape;intros OK;rewrite !andb_true_iff in OK.
 destruct OK as[HN[LN[DN[HC LC]]]].
 apply Nat.eqb_eq in HN;apply Nat.eqb_eq in LN;apply Nat.eqb_eq in DN.
 rewrite forallb_forall in HC;rewrite forallb_forall in LC.
 repeat split;try assumption.
 - apply Forall_forall;intros bs InB;apply Nat.eqb_eq;exact(HC bs InB).
 - apply Forall_forall;intros bs InB;apply Nat.eqb_eq;exact(LC bs InB).
Qed.
Definition qcert_rows_check n h l same c:=
 forallb(fun i=>forallb(fun j=>Bool.eqb(qcert_row h l same c i j)(unit_vector i j))
 (seq 0 n))(seq 0 n).
Lemma qcert_rows_sound n h l same c:qcert_rows_check n h l same c=true ->qcert_rows_ok n h l same c.
Proof.
 unfold qcert_rows_check,qcert_rows_ok;intros Rows i I j J.
 rewrite forallb_forall in Rows;specialize(Rows i ltac:(apply in_seq;lia)).
 rewrite forallb_forall in Rows;specialize(Rows j ltac:(apply in_seq;lia)).
 rewrite Bool.eqb_true_iff in Rows;exact Rows.
Qed.
Definition qcert_trivial_check n h l same:=
 forallb(fun g=>negb(existsb(fun r=>parity n r g)h) &&
 negb(existsb(fun r=>parity n r g)l))same.
Lemma qcert_trivial_sound n h l same:qcert_trivial_check n h l same=true ->
 Forall(fun g=>kernel n h g /\kernel n l g)same.
Proof.
 unfold qcert_trivial_check;intros T;rewrite forallb_forall in T.
 apply Forall_forall;intros g InG;specialize(T g InG).
 apply andb_true_iff in T as[TH TL];apply negb_true_iff in TH;apply negb_true_iff in TL.
 split;intros r InR.
 - exact(existsb_parity_false n h g TH r InR).
 - exact(existsb_parity_false n l g TL r InR).
Qed.
Definition check_quotient_certificate n h l same c:=
 qcert_shape_check n h l same c &&(qcert_rows_check n h l same c &&qcert_trivial_check n h l same).
Theorem check_quotient_certificate_sound n h l same c:
 check_quotient_certificate n h l same c=true ->
 Forall(kernel n h)same /\css_quotient n h same l.
Proof.
 unfold check_quotient_certificate;intros OK;rewrite !andb_true_iff in OK.
 destruct OK as[Shape[Rows Trivial]].
 pose proof(qcert_shape_sound n h l same c Shape)as[HN[LN[DN[HC LC]]]].
 pose proof(qcert_rows_sound n h l same c Rows)as R.
 pose proof(qcert_trivial_sound n h l same Trivial)as T.
 split.
 - apply Forall_forall;intros g InG;rewrite Forall_forall in T;exact(proj1(T g InG)).
 - apply(qcert_quotient n h l same c DN T R).
Qed.
Definition qcert_pair:=vxor(unit_vector 0)(unit_vector 1).
Definition qcert_pair_certificate:quotient_certificate:=
 {| qcert_hcoeffs := [[];[]]; qcert_lcoeffs := [[false];[true]]; qcert_dual := [unit_vector 0] |}.
Example qcert_self_orthogonal_example:
 check_quotient_certificate 2 [] [qcert_pair] [qcert_pair] qcert_pair_certificate=true.
Proof. vm_compute;reflexivity. Qed.
Definition qcert_bad_certificate:quotient_certificate:=
 {| qcert_hcoeffs := [[]]; qcert_lcoeffs := [[false]]; qcert_dual := [] |}.
Example qcert_incomplete_detector_rejected:
 check_quotient_certificate 1 [] [zero_vector] [] qcert_bad_certificate=false.
Proof. vm_compute;reflexivity. Qed.
(* A metadata-only mutant would accept this wrong detector matrix. *)
Example qcert_missing_identity_mutant_caught:
 (qcert_shape_check 1 [] [zero_vector] [] qcert_bad_certificate &&
 qcert_trivial_check 1 [] [zero_vector] [])=true.
Proof. vm_compute;reflexivity. Qed.
Example qcert_zero_detector_is_not_complete:~css_quotient 1 [] [] [zero_vector].
Proof.
 intros Q.
 assert(KH:kernel 1 [] (unit_vector 0))by(intros r InR;contradiction).
 assert(KL:kernel 1 [zero_vector](unit_vector 0)).
 { intros r[Eq|No];[subst r;apply qcert_zero_dot|contradiction]. }
 pose proof(proj2(Q(unit_vector 0)KH)KL)as[bs[Len Eq]].
 specialize(Eq 0 ltac:(lia));cbn[unit_vector linear_combination zero_vector]in Eq;discriminate.
Qed.
Definition qcert_nontrivial_stab_certificate:quotient_certificate:=
 {| qcert_hcoeffs := [[]]; qcert_lcoeffs := [[false]]; qcert_dual := [unit_vector 0] |}.
Example qcert_nontrivial_stabilizer_rejected:
 check_quotient_certificate 1 [] [unit_vector 0] [unit_vector 0]
 qcert_nontrivial_stab_certificate=false.
Proof. vm_compute;reflexivity. Qed.
Example qcert_missing_triviality_mutant_caught:
 (qcert_shape_check 1 [] [unit_vector 0] [unit_vector 0] qcert_nontrivial_stab_certificate &&
 qcert_rows_check 1 [] [unit_vector 0] [unit_vector 0] qcert_nontrivial_stab_certificate)=true.
Proof. vm_compute;reflexivity. Qed.
Example qcert_bad_annihilator_is_not_complete:~css_quotient 1 [] [unit_vector 0] [unit_vector 0].
Proof.
 intros Q.
 assert(KH:kernel 1 [] (unit_vector 0))by(intros r InR;contradiction).
 assert(Span:rowspan 1 [unit_vector 0](unit_vector 0)).
 { exists[true];split;[reflexivity|]. intros i I;cbn[linear_combination vxor zero_vector].
   assert(i=0)by lia;subst i;vm_compute;reflexivity. }
 pose proof(proj1(Q(unit_vector 0)KH)Span)as KL.
 specialize(KL(unit_vector 0)(or_introl eq_refl));vm_compute in KL;discriminate.
Qed.
Print Assumptions check_quotient_certificate_sound.
