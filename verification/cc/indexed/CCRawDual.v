(* SPDX-License-Identifier: GPL-3.0-or-later
 * Check arbitrary proposed column involutions and row images on the raw PCM.
 * A checked X result then covers both halves, for every matrix width. *)
Require Import VST.floyd.proofauto.
Require Import CCV.CCModel CCV.CCFunctional CCV.CCCSSBridge CCV.CCCSSResultBridge CCV.CCRepresentation
 CCV.CCSearchSpecs CCV.CCQuotientCertificate CCV.CCPCMDetectors CCV.CCPCMLayout CCV.CCPCMFast
 CCV.CCPCMInput CCV.CCPCMPair CCV.CCRawCSS CCV.CCPCMAnswer CCV.CCOrbit CCV.CCPackedOrbit CCCompactPrepare.
Import ListNotations. Local Open Scope nat_scope. Local Open Scope bool_scope.

Fixpoint bit_equal (xs ys:list bool) :=
 match xs,ys with [],[]=>true|x::t,y::u=>Bool.eqb x y && bit_equal t u|_,_=>false end.
Lemma bit_equal_sound xs ys : bit_equal xs ys=true ->xs=ys.
Proof. revert ys;induction xs as [|x t IH];intros [|y u] E;try discriminate;auto.
 destruct x,y;cbn in E;try discriminate;f_equal;auto. Qed.
Definition row_image p (row:list bool) := map (fun i=>nth i row false) p.
Fixpoint cover_rows p (src dst:list(list bool)) ix :=
 match src,ix with [],[]=>true | r::rs,j::js=>
 (j <? length dst) && bit_equal (row_image p r) (nth j dst []) && cover_rows p rs dst js
 |_,_=>false end.
Definition covers n p (src dst:list vector) :=
 forall r, In r src -> exists t,In t dst /\ forall i,i<n -> perm_vector n p r i=t i.
Lemma row_image_tab n p r : coordinates n p ->
 row_image p (tabulate n r)=tabulate n (perm_vector n p r).
Proof. intro P;rewrite tab_perm by (apply perm_length;auto). unfold row_image.
 apply map_ext_in; intros i I;apply tabulate_at.
 assert (In i (seq 0 n)) by (eapply Permutation_in;[exact P|exact I]).
 apply in_seq in H;lia. Qed.
Lemma cover_sound n p hs gs ix : coordinates n p ->
 cover_rows p (map (tabulate n) hs) (map (tabulate n) gs) ix=true ->covers n p hs gs.
Proof.
 intro P;revert ix;induction hs as [|h hs IH];intros [|j js] C r R;try discriminate;try contradiction.
 cbn [map cover_rows] in C;rewrite !andb_true_iff,Nat.ltb_lt,map_length in C.
 destruct C as [[J Eq] More];destruct R as [<-|R];[|eapply IH;eauto].
 exists (nth j gs zero_vector);split;[apply nth_In;lia|].
 apply bit_equal_sound in Eq;rewrite row_image_tab in Eq by exact P.
 rewrite (nth_indep _ _ (tabulate n zero_vector)) in Eq by (rewrite map_length;lia).
 rewrite map_nth in Eq.
 intros i I;apply (f_equal (fun xs=>nth i xs false)) in Eq;now rewrite !tabulate_at in Eq by lia.
Qed.
Definition raw_dual_check q p forward backward :=
 let w:=width q in let n:=Z.to_nat w in
 let h:=fast_rows w (check_count q) (checks q) in
 let g:=fast_rows w (same_count q) (same_bytes q) in
 indices_ok n p p && cover_rows p h g forward && cover_rows p g h backward.
Lemma perm_kernel n p src dst e : coordinates n p -> inverse_at n p p ->
 covers n p dst src ->kernel n src e ->kernel n dst (perm_vector n p e).
Proof.
 intros P Inv Cover K g G;destruct(Cover g G) as [h [H E]].
 rewrite <-(orbit_parity n p g (perm_vector n p e) P).
 erewrite (parity_ext n (perm_vector n p g) _ e).
 2:{ intros i I;unfold perm_vector;rewrite Inv by exact I;reflexivity. }
 rewrite qcert_parity_comm,(parity_ext n e _ h E),qcert_parity_comm;apply K;assumption.
Qed.
Lemma detector_annihilates n rows g : In g (pcm_detectors n rows) -> kernel n rows g.
Proof. intros G h H;pose proof(generator_in_span n rows h H) as S.
 apply detectors_characterize_rowspan in S;rewrite qcert_parity_comm;apply S;exact G. Qed.
Lemma raw_transport n p hx hz e :
 coordinates n p ->inverse_at n p p ->covers n p hz hx ->covers n p hx hz ->
 css_logical n hx hz e ->css_logical n hz hx (perm_vector n p e).
Proof.
 intros P Inv A B [K Not];split;[eapply perm_kernel;eauto|].
 intro Span;apply Not;apply detectors_characterize_rowspan;intros g G.
 pose proof(detector_annihilates n hz g G) as Kg.
 pose proof(perm_kernel n p hz hx g P Inv B Kg) as KP.
 pose proof(span_dot n hx (perm_vector n p e)(perm_vector n p g) Span KP) as D.
 rewrite orbit_parity in D by exact P. rewrite qcert_parity_comm;exact D.
Qed.
Lemma check_facts q p a b : raw_dual_check q p a b=true ->
 let n:=Z.to_nat(width q) in coordinates n p /\ inverse_at n p p /\
 covers n p (check_rows q)(same_rows q) /\covers n p (same_rows q)(check_rows q).
Proof.
 unfold raw_dual_check;rewrite !andb_true_iff,!fast_rows_eq,!sliced_vectors_correct.
 intros [[I A] B];destruct (inverse_checked _ _ _ I) as [P Inv].
 split;[exact P|]. split;[exact Inv|]. split;[exact (cover_sound _ _ _ _ a P A)|exact (cover_sound _ _ _ _ b P B)].
Qed.
Definition finish_dual n ret out :=
 serialize_pair n (match read_half ret out with
 |unresolved=>unresolved | empty=>empty |found e=>found(e,zero_vector) end).
Theorem dual_report_exact q ax ret out d p a b : prepare_pcm_half q=Some ax ->
 css_distance_result ax (same_rows q) ret out d ->raw_dual_check q p a b=true ->
 let n:=Z.to_nat(width q) in let hx:=same_rows q in let hz:=check_rows q in
 match finish_dual n ret out with
 | OutOfBudget=>True | NoLogical=>~exists x z,mixed_logical n hx hz x z
 | Exact w bx bz=>exists x z,bx=tabulate n x /\ bz=tabulate n z /\mixed_logical n hx hz x z /\
  w=mixed_weight n x z /\ forall u v,mixed_logical n hx hz u v->w<=mixed_weight n u v
 end.
Proof.
 intros X S Gate n hx hz;pose proof(proj1(raw_half_answer q ax ret out d X S)) as Half.
 destruct(check_facts _ _ _ _ Gate) as [P [Inv [A B]]];fold n hx hz in P, Inv, A, B, Half.
 unfold finish_dual;destruct(read_half ret out)as[| |e];cbn [half_sound serialize_pair] in *;auto.
 - intros [u [v [Ku [Kv [Nu|Nv]]]]];apply Half.
   + exists u;split;assumption.
   + exists (perm_vector n p v);apply(raw_transport n p hx hz);auto. split;assumption.
 - destruct Half as [[K NS] Min]. exists e,zero_vector;repeat split;try reflexivity;try assumption;
   try apply zero_kernel;try (left;exact NS).
   intros u v [Ku [Kv [Nu|Nv]]];rewrite (proj1(pure_weights n e));destruct(weight_union n u v)as[U V].
   + specialize(Min u (conj Ku Nu));lia.
   + pose proof(raw_transport n p hx hz v P Inv A B (conj Kv Nv)) as T.
     specialize(Min _ T);rewrite orbit_weight in Min by exact P;lia.
Qed.
Print Assumptions dual_report_exact.
