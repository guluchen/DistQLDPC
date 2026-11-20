(* Concrete fuel survives VST memory extension and ghost-only updates. The
   full jsafeN/fancy-update/semax adequacy argument is still separate. *)
Require Import VST.floyd.proofauto.
Require Import VST.veric.juicy_mem VST.veric.juicy_extspec.
Require Import CCV.CCSearchSpecs CCV.CCFuelRank CCV.CCConcreteFuelRank CCV.CCStatsLoad.
Open Scope Z_scope.
Local Transparent Mem.load.
Lemma mem_sub_defined_load m1 m2 chunk b ofs v:
 mem_sub m1 m2 ->Mem.load chunk m1 b ofs=Some v ->Mem.load chunk m2 b ofs=Some v.
Proof.
 intros[Contents[Blocks Permissions]]Load.
 pose proof(Mem.load_valid_access m1 chunk b ofs v Load)as Valid.
 assert(Valid2:Mem.valid_access m2 chunk b ofs Readable).
 { destruct Valid as[Range Align];split;[|exact Align].
   intros pos Inside;apply Permissions;apply Range;exact Inside. }
 unfold Mem.load in Load|-*.
 rewrite pred_dec_true in Load by exact Valid.
 rewrite pred_dec_true by exact Valid2.
 rewrite <-Contents;exact Load.
Qed.
Lemma mem_sub_defined_loadv m1 m2 chunk ptr v:
 mem_sub m1 m2 ->Mem.loadv chunk m1 ptr=Some v ->Mem.loadv chunk m2 ptr=Some v.
Proof.
 intros Sub Load;destruct ptr;cbn[Mem.loadv]in *;try discriminate;
 eapply mem_sub_defined_load;eassumption.
Qed.
Theorem memory_fuel_rank_mem_sub budget ptr m1 m2 word:
 mem_sub m1 m2 ->Mem.loadv Mint32 m1 ptr=Some(Vint word) ->
 memory_fuel_rank budget ptr m2=memory_fuel_rank budget ptr m1.
Proof.
 intros Sub Load;unfold memory_fuel_rank.
 rewrite Load,(mem_sub_defined_loadv m1 m2 Mint32 ptr(Vint word)Sub Load);reflexivity.
Qed.
Theorem memory_fuel_rank_ghost_update budget ptr jm jm':
 jm_update jm jm' ->memory_fuel_rank budget ptr(m_dry jm')=memory_fuel_rank budget ptr(m_dry jm).
Proof. intros[Dry Rest];rewrite Dry;reflexivity. Qed.
Theorem framed_owned_stats_rank_decreases budget b ofs before after
 (R R':mpred)(jm jm':juicy_mem)world world':
 continuing_step budget before after ->
 predicates_hered.app_pred((stats_repr(Vptr b ofs)before*R)%logic)(m_phi jm) ->
 predicates_hered.app_pred((stats_repr(Vptr b ofs)after*R')%logic)(m_phi jm') ->
 mem_sub(m_dry jm)world ->mem_sub(m_dry jm')world' ->
 (memory_fuel_rank budget(Vptr b ofs)world'<memory_fuel_rank budget(Vptr b ofs)world)%nat.
Proof.
 intros Progress Old New SubOld SubNew.
 apply(actual_counter_loads_decrease_rank budget(Vptr b ofs)before after world world').
 - exact Progress.
 - eapply mem_sub_defined_loadv;[exact SubOld|exact(stats_repr_steps_load b ofs before R jm Old)].
 - eapply mem_sub_defined_loadv;[exact SubNew|exact(stats_repr_steps_load b ofs after R' jm' New)].
Qed.
Print Assumptions memory_fuel_rank_mem_sub.
Print Assumptions framed_owned_stats_rank_decreases.
