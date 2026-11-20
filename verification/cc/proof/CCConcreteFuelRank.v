(* The budget rank computed from the actual statistics word in CompCert
   memory. Defined-load/legal-counter premises are explicit. *)
Require Import VST.floyd.proofauto.
Require Import CCV.CCSearchSpecs CCV.CCFuelRank.
Open Scope Z_scope.
Definition memory_fuel_rank budget ps m:nat:=
 match Mem.loadv Mint32 m ps with
 |Some(Vint steps)=>Z.to_nat(budget-Int.unsigned steps)
 |_=>0%nat end.
Lemma memory_fuel_rank_represents budget ps m s:
 legal_stats budget s ->
 Mem.loadv Mint32 m ps=Some(Vint(Int.repr(stat_steps s))) ->
 memory_fuel_rank budget ps m=fuel_rank budget s.
Proof.
 intros Legal Load;unfold memory_fuel_rank,fuel_rank;rewrite Load.
 rewrite Int.unsigned_repr by(unfold legal_stats in Legal;lia);reflexivity.
Qed.
Theorem actual_counter_loads_decrease_rank budget ps before after m m':
 continuing_step budget before after ->
 Mem.loadv Mint32 m ps=Some(Vint(Int.repr(stat_steps before))) ->
 Mem.loadv Mint32 m' ps=Some(Vint(Int.repr(stat_steps after))) ->
 (memory_fuel_rank budget ps m'<memory_fuel_rank budget ps m)%nat.
Proof.
 intros Progress Before After;pose proof Progress as[LegalBefore[LegalAfter Mono]].
 rewrite(memory_fuel_rank_represents budget ps m before LegalBefore Before),
 (memory_fuel_rank_represents budget ps m' after LegalAfter After).
 apply continuing_step_rank;exact Progress.
Qed.
Print Assumptions actual_counter_loads_decrease_rank.
