(* Lift an upper witness and two checked lower bounds to the mixed CSS
   distance of the original two parity-check matrices. *)
Require Import VST.floyd.proofauto.
Require Import CCV.CCModel CCV.CCFunctional CCV.CCCSSBridge CCV.CCCSSResultBridge
 CCV.CCRepresentation CCV.CCSearchSpecs CCV.CCPCMInput CCV.CCRawCSS CCV.CCPCMPair
 CCV.CCPCMFast CCV.CCPCMDetectors CCV.CCPCMAnswer CCWideHalf CCWideDual.
Require Import CCWideCached CCShortSound.
Import ListNotations. Local Open Scope nat_scope. Local Open Scope bool_scope.

Definition witness_test n hs ls w :=
  forallb (fun r=>negb (parity n r w)) hs && existsb (fun r=>parity n r w) ls.
Lemma witness_test_sound n hs ls w : witness_test n hs ls w=true -> good n hs ls w.
Proof.
  unfold witness_test;rewrite andb_true_iff,forallb_forall,existsb_exists.
  intros [H L];split;[eapply logical_positive;exact L|];split;[|exact L].
  intros r R;apply negb_true_iff;apply H;exact R.
Qed.
Definition sliced_h a:=cached_vectors (model_n a) (model_m a) (model_h a).
Definition sliced_l a:=cached_vectors (model_n a) (model_l a) (model_lg a).
Definition ordered_lower n hs ls d adv ids :=
  let rows:=advised_rows hs ids in
  lower_test n rows ls (parity_limit n rows d) adv.
Lemma ordered_lower_sound n hs ls d adv ids e :
  ordered_lower n hs ls d adv ids=true -> good n hs ls e -> d<=weight n e.
Proof.
  intros Checked [Pos [Ker Log]]; apply (kernel_advised_rows n hs ids e) in Ker.
  eapply parity_limit_sound; [exact Ker|]. eapply lower_test_sound; [exact Checked|].
  repeat split; assumption.
Qed.
Definition packed_report n ax az (x_side:bool) (ws:list bool) adv (p inv rx rz:list nat) :=
  let w:=fun i=>nth i ws false in
  let sx:=sliced_h ax in let lx:=sliced_l ax in
  let sz:=sliced_h az in let lz:=sliced_l az in
  let d:=weight n w in
  if (length ws=?n) &&
     (if x_side then witness_test n sx lx w else witness_test n sz lz w) &&
     ordered_lower n sx lx d adv rx && (dual_check n sx lx sz lz p inv || ordered_lower n sz lz d adv rz)
  then Some (serialize_pair n (if x_side then found (w,zero_vector) else found (zero_vector,w)))
  else None.

Lemma prepared_good q a (P:prepare_pcm_half q=Some a) e :
 good (Z.to_nat(width q)) (sliced_h a) (sliced_l a) e <->
 css_logical (Z.to_nat(width q)) (check_rows q) (same_rows q) e.
Proof.
  destruct (prepare_pcm_contract q a P) as [_ [Quot _]].
  apply prep_components in P as [_ [_ [_ ->]]].
  unfold sliced_h,sliced_l;rewrite !cached_vectors_correct,!sliced_vectors_correct.
  apply good_iff_css_logical;exact Quot.
Qed.

Theorem packed_report_from_pcm q ax az x_side ws adv p inv rx rz answer :
 prepare_pcm_half q=Some ax ->prepare_pcm_half(swap_half q)=Some az ->
 packed_report (Z.to_nat(width q)) ax az x_side ws adv p inv rx rz=Some answer ->
 let n:=Z.to_nat(width q) in let hx:=same_rows q in let hz:=check_rows q in
 match answer with
 | Exact d bx bz =>exists x z,bx=tabulate n x /\ bz=tabulate n z /\ mixed_logical n hx hz x z /\
   d=mixed_weight n x z /\ forall u v,mixed_logical n hx hz u v->d<=mixed_weight n u v
 | _=>False end.
Proof.
  intros X Z;unfold packed_report;set(n:=Z.to_nat(width q));set(w:=fun i=>nth i ws false).
  destruct (_ && _ && _ && _)%bool eqn:T;[|discriminate].
  rewrite !andb_true_iff in T;destruct T as [[[_ Upper] LX] LZ].
  pose proof(prepared_good q ax X) as GX.
  pose proof(prepared_good (swap_half q) az Z) as GZ.
  fold n in GX;change (forall e,good n (sliced_h az) (sliced_l az) e <->
    css_logical n (same_rows q) (check_rows q) e) in GZ.
  assert (BoundX:forall e,good n (sliced_h ax) (sliced_l ax) e->weight n w<=weight n e).
  { intro e; eapply ordered_lower_sound; exact LX. }
  assert (Min:forall u v,mixed_logical n (same_rows q) (check_rows q) u v ->
                          weight n w<=mixed_weight n u v).
  { intros u v [U [V [A|B]]];destruct(weight_union n u v) as [WU WV].
    - pose proof(BoundX u (proj2 (GX u) (conj U A)));lia.
    - pose proof(proj2 (GZ v) (conj V B)) as GoodZ.
      apply orb_true_iff in LZ as [Dual|Direct].
      + destruct(dual_transports _ _ _ _ _ _ _ Dual v GoodZ) as [GoodX Eq].
        pose proof(BoundX _ GoodX);lia.
      + pose proof (ordered_lower_sound _ _ _ _ _ _ _ Direct GoodZ);lia. }
  destruct x_side;intros [= <-];cbn [serialize_pair].
  - apply witness_test_sound in Upper;apply GX in Upper as [K NS].
    exists w,zero_vector;repeat split;try reflexivity;try assumption;try apply zero_kernel;
      try (left;exact NS);rewrite (proj1(pure_weights n w));exact Min.
  - apply witness_test_sound in Upper;apply GZ in Upper as [K NS].
    exists zero_vector,w;repeat split;try reflexivity;try assumption;try apply zero_kernel;
      try (right;exact NS);rewrite (proj2(pure_weights n w));exact Min.
Qed.
Print Assumptions packed_report_from_pcm.
