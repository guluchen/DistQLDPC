(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VerifDetected VerifChildVisit EnabledCall OverlapColumnState
 VerifSeedIndex PreparedSeedDispatch SeedLoopModel PreparedRootStages PreparedDepthSpec PreparedBudgetContract
 PreparedPlainDescent PreparedIndexGlobals PreparedIndexRoot PreparedIndexSeedCall
 PreparedRecursiveCall PreparedWitnessRegister PreparedIndexArena flag_level_ast.
#[local] Existing Instance VerifDetected.CompSpecs.
Local Open Scope Z_scope.

Section Seeds.
Variables (c:policy_state) (names:list int) (gv:globals) (s cp bp base:val) (stride w:Z)
 (heap:node_storage) (entry:entry_domain) (report:budget_report) (witness:Z->list int->Prop)
 (state:Z->snapshot).
Let n:=Zlength names.
Let arena:=live_arena base stride n 1.
Let rec_heap:=weight_bounded_rows base stride n heap.
Let calls:=prepared_calls (snd (depth_flip c heap Int.zero))
  (snd (index_dfs_using_globals gv entry rec_heap report witness Int.zero)).
Definition seed_storage i path count written:=
 (child_fields s cp bp w (seen n i) path * seed_counter s count *
   heap s [] * arena * witness_register s written)%logic.
Definition seed_ready i:mpred:=
 EX path:list int,EX count:int64,EX saved:int,
 !!(Zlength path=n) && seed_storage i path count saved.
Definition reported_seed i r tail:=report w (geometry c) (state i) [Int.repr i] r tail.
Definition seed_done i r:mpred:=
 EX tail:list int,EX count:int64,EX previous:int,EX written:int,
 !!(Zlength tail=n /\ reported_seed i r tail /\ witness_at_limit w previous r written tail /\
    (witness_status r -> witness (Int.signed written) tail)) && seed_storage i tail count written.
Definition observed_seed i r:=exists tail,reported_seed i r tail.
Definition phases:=Build_root_phases names seed_ready seed_done observed_seed.
Variables (rest:mpred).
Hypotheses (initialize:count_field phases s*rest |-- seed_ready 0)
 (cap:n<=Int.max_signed) (weight:1<=w<=n) (plain:nested_policy (nested c)=nullval)
 (colroom:n<Zlength (column_offsets (geometry c)))
 (blocks:forall i,0<=i<n -> blocked (state i)=seen n (i+1))
 (admit_seed:forall i,0<=i<n -> entry (geometry c) s cp bp w (state i) [Int.repr i]).

Theorem initialized_index_level:
 semax_body prepared_vars calls f_cc_run_prepared_level (index_root_call phases s gv rest).
Proof.
 eapply body_index_root_control;[exact initialize| |].
 - intros Espec i inside;change (0<=i<n) in inside.
   unfold ready_to_visit;change (waiting phases i) with (seed_ready i);unfold seed_ready,seed_storage.
   Intros path count saved.
   eapply semax_post_flipped.
   + eapply semax_pre;[|exact (@visit_native_seed c phases gv s cp bp base stride w heap entry report witness Espec i
      (state i) path saved count inside cap weight ltac:(lia) plain ltac:(lia) (blocks i inside) (admit_seed i inside))].
     apply andp_left2;apply derives_refl.
   + cbn [RA_normal normal_ret_assert];Intros tail r written;Exists r.
     unfold seed_returned;change (returned phases i r) with (seed_done i r);unfold seed_done,seed_storage,root_call_regs,root_regs.
     Exists tail (Int64.add count Int64.one) saved written;entailer!;try cancel;try apply derives_refl.
     unfold observation,phases,observed_seed;exists tail;assumption.
   + cbn [RA_break normal_ret_assert];apply andp_left2;apply FF_left.
   + cbn [RA_continue normal_ret_assert];apply andp_left2;apply FF_left.
   + intro v;cbn [RA_return normal_ret_assert];apply andp_left2;apply FF_left.
 - intros Espec i inside;change (0<=i<n) in inside.
   unfold seed_returned;change (returned phases i 0) with (seed_done i 0).
   unfold seed_done,seed_storage;Intros tail count previous written.
   assert (path_width:Zlength tail=n) by assumption.
   set (frame:=(@field_at VerifDetected.CompSpecs Tsh level_type [StructField level_ast._w] (Vint (Int.repr w)) s *
       @field_at VerifDetected.CompSpecs Tsh level_type [StructField level_ast._cur] cp s *
       @data_at VerifDetected.CompSpecs Tsh (tarray tint n) (map Vint tail) cp *
       seed_counter s count * heap s [] * arena * witness_register s written)%logic).
   eapply semax_post_flipped.
   + eapply semax_pre;[|exact (@commit_exhausted_index Espec phases s gv
       (snd (depth_flip c heap Int.zero)) (snd (index_dfs_using_globals gv entry rec_heap report witness Int.zero))
       bp i frame inside cap)].
     unfold frame,child_fields,seed_blocks,root_call_regs,root_regs;rewrite seen_length by lia;rewrite path_width;entailer!;cancel;try apply derives_refl.
   + cbn [RA_normal normal_ret_assert];unfold advanced.
     change (waiting phases (i+1)) with (seed_ready (i+1));unfold seed_ready,seed_storage.
     unfold frame,child_fields,seed_blocks,root_regs.
     Exists tail count written;rewrite seen_length by lia;rewrite path_width;entailer!;cancel;try apply derives_refl.
   + cbn [RA_break normal_ret_assert];apply andp_left2;apply FF_left.
   + cbn [RA_continue normal_ret_assert];apply andp_left2;apply FF_left.
   + intro v;cbn [RA_return normal_ret_assert];apply andp_left2;apply FF_left.
Qed.
End Seeds.
