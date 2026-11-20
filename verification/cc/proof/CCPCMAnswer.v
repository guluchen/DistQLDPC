(* Serializable result of the two checked half queries. Each position with
   either Pauli component set contributes one to the physical weight. *)
Require Import VST.floyd.proofauto.
Require Import CCV.CCModel CCV.CCRepresentation CCV.CCSearchSpecs CCV.CCCSSResultBridge
 CCV.CCPCMDetectors CCV.CCPCMInput CCV.CCPCMPair CCV.CCRawCSS.
Inductive pcm_answer := OutOfBudget | NoLogical | Exact (d:nat) (x z:list bool).
Definition serialize_pair n (a:answer (vector*vector)) :=
 match a with unresolved=>OutOfBudget | empty=>NoLogical
 | found (x,z)=>Exact (mixed_weight n x z) (tabulate n x) (tabulate n z) end.
Definition finish_pcm n rx ox rz oz :=
 serialize_pair n (join_halves n (read_half rx ox) (read_half rz oz)).
Theorem exact_report_from_pcm q ax az rx rz ox oz dx dz :
 prepare_pcm_half q=Some ax ->prepare_pcm_half (swap_half q)=Some az ->
 css_distance_result ax (same_rows q) rx ox dx ->
 css_distance_result az (same_rows(swap_half q)) rz oz dz ->
 let n:=Z.to_nat(width q) in let hx:=same_rows q in let hz:=check_rows q in
 match finish_pcm n rx ox rz oz with
 |OutOfBudget=>True |NoLogical=>~exists x z,mixed_logical n hx hz x z
 |Exact d bx bz=>exists x z,bx=tabulate n x /\ bz=tabulate n z /\ mixed_logical n hx hz x z /\
  d=mixed_weight n x z /\ forall u v,mixed_logical n hx hz u v ->(d<=mixed_weight n u v)%nat
 end.
Proof.
 intros X Z A B n hx hz;pose proof(raw_css_distance_correct q ax az rx rz ox oz dx dz X Z A B) as C.
 fold n hx hz in C;unfold finish_pcm;destruct (join_halves n (read_half rx ox)(read_half rz oz)) as [| |[u v]];
 cbn [serialize_pair pair_sound] in *;try tauto.
 exists u,v;tauto.
Qed.
Print Assumptions exact_report_from_pcm.
