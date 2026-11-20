(* Total finite-path composition for the actual CompCert Clight step2
   relation. This is a conditional operational rule, not a proof that every
   segment/helper of the frozen CC program terminates. *)
Require Import VST.floyd.proofauto.
Require Import Coq.Arith.Wf_nat.
Require Import compcert.common.Smallstep compcert.cfrontend.Clight.
Section RankedSegments.
Variable ge:Clight.genv.
Variables Inv Done:Clight.state->Prop.
Variable rank:Clight.state->nat.
Definition finite_segment_obligation:Prop:=forall start,Inv start ->
 (exists t finish,star Clight.step2 ge start t finish /\Done finish) \/
 (exists t next,star Clight.step2 ge start t next /\Inv next /\(rank next<rank start)%nat).
Theorem ranked_clight_segments_terminate:
 finite_segment_obligation ->forall start,Inv start ->
 exists t finish,star Clight.step2 ge start t finish /\Done finish.
Proof.
 intros Segments.
 refine(well_founded_induction_type(well_founded_ltof Clight.state rank) _ _).
 intros start IH Valid.
 destruct(Segments start Valid)as[Finished|[t[next[Path[Next Lower]]]]].
 - exact Finished.
 - destruct(IH next Lower Next)as[u[finish[Tail Final]]].
   exists(List.app t u),finish;split;[eapply star_trans;eauto|exact Final].
Qed.
End RankedSegments.
Print Assumptions ranked_clight_segments_terminate.
