(* Strict concrete fuel descent from VST-owned before/after states. This
   does not assert that an arbitrary finite Clight path satisfies those
   ownership postconditions; semax/operational adequacy remains separate. *)
Require Import VST.floyd.proofauto.
Require Import VST.veric.juicy_mem.
Require Import CCV.CCSearchSpecs CCV.CCSearchHeap CCV.CCFuelRank
 CCV.CCConcreteFuelRank CCV.CCStatsLoad.
Open Scope Z_scope.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
Local Transparent mpred.
Theorem owned_stats_counter_rank_decreases budget b ofs before after
 (R R':mpred)(jm jm':juicy_mem):
 continuing_step budget before after ->
 predicates_hered.app_pred((stats_repr(Vptr b ofs)before*R)%logic)(m_phi jm) ->
 predicates_hered.app_pred((stats_repr(Vptr b ofs)after*R')%logic)(m_phi jm') ->
 (memory_fuel_rank budget(Vptr b ofs)(m_dry jm')<
  memory_fuel_rank budget(Vptr b ofs)(m_dry jm))%nat.
Proof.
 intros Progress Old New.
 apply(actual_counter_loads_decrease_rank budget(Vptr b ofs)before after(m_dry jm)(m_dry jm'));
 [exact Progress|exact(stats_repr_steps_load b ofs before R jm Old)|
 exact(stats_repr_steps_load b ofs after R' jm' New)].
Qed.
Lemma search_heap_owns_counter sh a p tp rp top xs fs ys zs pk buf frames out s:
 search_heap sh a p tp rp top xs fs ys zs pk buf frames out s |--stats_repr(ptr_stats p)s*TT.
Proof. unfold search_heap;cancel;apply TT_right. Qed.
Theorem owned_predicates_counter_rank_decreases budget b ofs before after
 (P Q:mpred)(jm jm':juicy_mem):
 P |--stats_repr(Vptr b ofs)before*TT ->
 Q |--stats_repr(Vptr b ofs)after*TT ->
 continuing_step budget before after ->
 predicates_hered.app_pred P(m_phi jm) ->predicates_hered.app_pred Q(m_phi jm') ->
 (memory_fuel_rank budget(Vptr b ofs)(m_dry jm')<
  memory_fuel_rank budget(Vptr b ofs)(m_dry jm))%nat.
Proof.
 intros OldView NewView Progress Old New.
 rewrite derives_eq in OldView,NewView.
 apply(owned_stats_counter_rank_decreases budget b ofs before after TT TT jm jm');
 [exact Progress|apply OldView;exact Old|apply NewView;exact New].
Qed.
Theorem search_heap_counter_load sh a p tp rp top xs fs ys zs pk buf frames out s
 b ofs(jm:juicy_mem):
 ptr_stats p=Vptr b ofs ->
 predicates_hered.app_pred(search_heap sh a p tp rp top xs fs ys zs pk buf frames out s)(m_phi jm) ->
 Mem.loadv Mint32(m_dry jm)(ptr_stats p)=Some(Vint(Int.repr(stat_steps s))).
Proof.
 intros Pointer Owned.
 pose proof(search_heap_owns_counter sh a p tp rp top xs fs ys zs pk buf frames out s)as View.
 rewrite derives_eq in View;specialize(View(m_phi jm)Owned).
 rewrite Pointer in View|-*.
 exact(stats_repr_steps_load b ofs s TT jm View).
Qed.
Print Assumptions owned_stats_counter_rank_decreases.
Print Assumptions search_heap_counter_load.
