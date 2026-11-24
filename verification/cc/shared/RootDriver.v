(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto level_ast VerifDetected VerifChildVisit VerifRootCall
 EnabledCall SeedLoopModel SeedExecution PreparedSeed UniformSeedControl UniversalRootSearch
 SeedColumnModel OverlapColumnState VerifOrbitBlock ActualOrbitCommit SeedBlockView.
#[local] Existing Instance VerifDetected.CompSpecs.
Local Open Scope Z_scope.

Definition root_number e i:=Int.signed (Znth i (order e)).
Inductive reached e initial : Z -> root_state -> Prop :=
| first_seed : reached e initial 0 initial
| next_after_empty i x final tail left :
  reached e initial i x -> 0<=i<Zlength (order e) ->
  verdict e x (root_number e i)=0 ->
  returned_summary e x (root_number e i) final tail left ->
  reached e initial (i+1) (next_block e i (returned_state e x (root_number e i) final tail left)).
Definition observed e initial i r :=
 exists x, reached e initial i x /\ verdict e x (root_number e i)=r.
Definition left_root e initial i r y :=
 exists x final tail left, reached e initial i x /\ verdict e x (root_number e i)=r /\
   returned_summary e x (root_number e i) final tail left /\ y=returned_state e x (root_number e i) final tail left.
Definition schedule e initial := Build_root_phases (order e)
 (fun i=>EX x:root_state, !!(reached e initial i x) && seed_memory e x)
 (fun i r=>EX y:root_state, !!(left_root e initial i r y) && seed_memory e y)
 (observed e initial).

Definition callbacks_live e:=
 isptr (nested_policy (nested (policy e))) /\ isptr (done_address e) /\ is_pointer_or_null (callback_owner (policy e)).
Definition p_address e:=nested_policy (nested (policy e)).
Theorem verified_seed_driver e initial array :
 callbacks_live e -> 0<Zlength (block_members (orbits e)) ->
 (forall i x,0<=i<Zlength (order e) -> reached e initial i x -> visit_safe e x (root_number e i)) ->
 (forall i x,0<=i<Zlength (order e) -> left_root e initial i 0 x -> valid_orbit e i x) ->
 semax_body Vprog (all_roots (policy e)) f_cc_run_level
  (policy_root_spec (schedule e initial) (state_address e) (p_address e) array).
Proof.
 intros [pp [bf own]] members safe commit;apply body_for_every_root.
 - intros Espec i live;change (0<=i<Zlength (order e)) in live.
   unfold start_seed;cbn [schedule waiting];Intros x.
   match goal with H:reached e initial i x |- _=>pose proof (safe i x live H) as ok end.
   set (q:=root_number e i).
   eapply semax_post'.
   2:{ eapply semax_pre;[|apply (@physical_root_returns Espec e x q i
      (policy_seeds_at (schedule e initial) (p_address e) array) ok)].
     unfold root_loc,root_call_loc,selected_loc,outer_loc,root_count,q,root_number,p_address;
     cbn [schedule seed_order];rewrite Int.repr_signed;entailer!;try cancel. }
   Intros final tail left;Exists (verdict e x q).
   unfold post_visit,result_loc,selected_loc,outer_loc,root_loc,root_call_loc,root_count,p_address.
   cbn [schedule returned observation seed_order];Exists (returned_state e x q final tail left).
   unfold q,root_number;rewrite Int.repr_signed;entailer!;try cancel.
   split. { exists x;split;[assumption|reflexivity]. }
   exists x,final,tail,left;split;[assumption|];split;[reflexivity|];split;[exact H1|reflexivity].
 - intros Espec i live;change (0<=i<Zlength (order e)) in live.
   unfold post_visit;cbn [schedule returned observation];Intros y.
   match goal with H:left_root e initial i 0 y |- _=>pose proof (commit i y live H) as valid end.
   eapply semax_post'.
   2:{ eapply semax_pre;[|apply (@physical_block_advances Espec e y i
      (policy_seeds_at (schedule e initial) (p_address e) array) pp bf own members valid)].
     unfold orbit_driver_loc,finish_loc,orbit_loc,result_loc,selected_loc,outer_loc,root_count,p_address;
     cbn [app schedule seed_order];entailer!;try cancel. }
   unfold next_orbit,outer_loc,orbit_driver_loc,finish_loc,orbit_loc,root_count,p_address.
   cbn [app schedule waiting seed_order];Exists (next_block e i y);entailer!;try cancel.
   match goal with H:left_root e initial i 0 y |- _=>
     destruct H as [x [final [tail [left [prior [empty [trace ->]]]]]]];eapply next_after_empty;eassumption end.
Qed.
