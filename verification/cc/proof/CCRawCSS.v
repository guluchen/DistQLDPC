(* Raw CSS pair to the combined distance contract. *)
Require Import VST.floyd.proofauto.
Require Import CCV.CCModel CCV.CCCSSBridge CCV.CCRepresentation CCV.CCSearchSpecs CCV.CCCSSResultBridge
 CCV.CCPCMInput CCV.CCPCMPair.
Local Open Scope Z_scope.

Definition swap_half q := {| width:=width q;check_count:=same_count q;same_count:=check_count q;
 checks:=same_bytes q; same_bytes:=checks q |}.
Definition read_half (ret:Z)(out:list Z) : answer vector :=
 if ret =? 1 then found(decode out) else if ret =? 0 then empty else unresolved.
Lemma raw_half_answer q a ret out d :
 prepare_pcm_half q=Some a -> css_distance_result a (same_rows q) ret out d ->
 half_sound (Z.to_nat(width q)) (check_rows q) (same_rows q) (read_half ret out) /\
 (ret=1 -> d=Z.of_nat(weight (Z.to_nat(width q))(decode out))).
Proof.
 rewrite prep_components;intros [_[_[_ ->]]] [[-> [_ D]]|[[-> [_[_ E]]]|[-> [M D]]]];
 split;cbn [read_half half_sound];try easy.
Qed.
Theorem raw_css_distance_correct q ax az rx rz ox oz dx dz :
 prepare_pcm_half q=Some ax -> prepare_pcm_half (swap_half q)=Some az ->
 css_distance_result ax (same_rows q) rx ox dx ->
 css_distance_result az (same_rows (swap_half q)) rz oz dz ->
 pair_sound (Z.to_nat(width q)) (same_rows q) (check_rows q)
  (join_halves (Z.to_nat(width q)) (read_half rx ox)(read_half rz oz)).
Proof.
 intros X Z A B;apply combine_pcm_halves.
 - exact (proj1(raw_half_answer q ax rx ox dx X A)).
 - exact (proj1(raw_half_answer (swap_half q) az rz oz dz Z B)).
Qed.
Print Assumptions raw_css_distance_correct.
