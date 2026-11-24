(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto level_ast VerifDetected VerifChildVisit VerifRootCall
 EnabledCall SeedLoopModel SeedExecution PreparedSeed UniformSeedControl UniversalRootSearch
 SeedColumnModel OverlapColumnState VerifOrbitBlock ActualOrbitCommit SeedBlockView RootDriver PreparedSeedDispatch PreparedRootStages PreparedRootLoop PreparedRecursiveCall
 PreparedLevelStorage PreparedSeedResult PreparedRootOrbit.
Require flag_level_ast.
Import flag_level_ast.
#[local] Existing Instance VerifDetected.CompSpecs.
Local Open Scope Z_scope.

Inductive reached e (report:root_report) initial:Z -> root_state -> Prop :=
| first_seed:reached e report initial 0 initial
| next_after_empty i x final tail left:
  reached e report initial i x -> 0<=i<Zlength (order e) ->
  observed_return e report x (root_number e i) final tail left 0 ->
  reached e report initial (i+1) (next_block e i (returned_state e x (root_number e i) final tail left)).
Definition left_root e report initial i r y:=
 exists x final tail left, reached e report initial i x /\
 observed_return e report x (root_number e i) final tail left r /\ y=returned_state e x (root_number e i) final tail left.
Definition schedule e report initial:=Build_root_phases (order e)
 (fun i=>EX x:root_state, !!(reached e report initial i x) && PreparedLevelStorage.seed_memory e x)
 (fun i r=>EX y:root_state, !!(left_root e report initial i r y) && PreparedLevelStorage.seed_memory e y)
 (fun i r=>exists y,left_root e report initial i r y).

Theorem verified_prepared_driver e report initial array bits:
 Int.and bits Int.one<>Int.zero -> Int.and bits (Int.repr 16)<>Int.zero ->
 Int.and bits (Int.repr 32)<>Int.zero -> Int.and bits (Int.repr 64)<>Int.zero ->
 is_pointer_or_null (callback_owner (policy e)) -> 0<Zlength (block_members (orbits e)) ->
 (forall i x,0<=i<Zlength (order e) -> reached e report initial i x -> visit_safe e x (root_number e i)) ->
 (forall i x,0<=i<Zlength (order e) -> left_root e report initial i 0 x -> valid_orbit e i x) ->
 semax_body prepared_vars (RecG (policy e) report bits) f_cc_run_prepared_level
  (prepared_spec (schedule e report initial) (state_address e) (p_address e) array bits).
Proof.
 intros policy_bit overlap_bit seed_bit block_bit own members safe commit;apply body_prepared_root_control.
 - intros Espec i live;change (0<=i<Zlength (order e)) in live.
   unfold before_root;cbn [schedule waiting];Intros x.
   match goal with H:reached e report initial i x |- _=>pose proof (safe i x live H) as ok end.
   set (q:=root_number e i).
   eapply semax_post'.
   2:{ eapply semax_pre;[|apply (@PreparedSeedResult.physical_root_returns Espec e report x q i bits
      (seed_fields (schedule e report initial) (p_address e) array) seed_bit overlap_bit ok)].
     unfold root_loc,visit_loc,seed_loc,driver_loc,root_count,q,root_number,p_address;
     cbn [schedule seed_order];rewrite Int.repr_signed;entailer!;try cancel. }
   Intros final tail left r;Exists r.
   unfold after_root,seed_loc,driver_loc,root_loc,visit_loc,root_count,p_address.
   cbn [schedule returned observation seed_order];Exists (returned_state e x q final tail left).
   unfold q,root_number;rewrite Int.repr_signed;entailer!;try cancel.
   assert (leave:left_root e report initial i r (returned_state e x (root_number e i) final tail left)).
   { exists x,final,tail,left;split;[assumption|];split;[assumption|reflexivity]. }
   split;[eexists;exact leave|exact leave].
 - intros Espec i live;change (0<=i<Zlength (order e)) in live.
   unfold after_root;cbn [schedule returned observation];Intros y.
   match goal with H:left_root e report initial i 0 y |- _=>pose proof (commit i y live H) as valid end.
   eapply semax_post'.
   2:{ eapply semax_pre;[|apply (@PreparedLevelStorage.physical_block_advances Espec
      (snd (root_flip (policy e) bits)) (snd (root_dfs_spec (policy e) report bits)) e y i bits
      (seed_fields (schedule e report initial) (p_address e) array) policy_bit block_bit own members valid)].
     unfold orbit_driver_loc,orbit_with_flags,orbit_loc,seed_loc,driver_loc,root_count,p_address;
     cbn [app schedule seed_order];entailer!;try cancel. }
   unfold after_block,driver_loc,orbit_driver_loc,orbit_with_flags,orbit_loc,root_count,p_address.
   cbn [app schedule waiting seed_order];Exists (next_block e i y);entailer!;try cancel.
   match goal with H:left_root e report initial i 0 y |- _=>
     destruct H as [x [final [tail [left [prior [trace ->]]]]]];eapply next_after_empty;eassumption end.
Qed.
