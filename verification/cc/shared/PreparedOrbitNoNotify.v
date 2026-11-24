(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.floyd.reassoc_seq VST.zlist.list_solver.
Require Import VerifDetected VerifOrbitBlock VerifSeedMove ClightSelect SiblingCounters ActiveChildren
 SeedColumnModel SeedPolicyView SeedBlockModel SeedBlockView SeedOrbitStorage SeedStorageTransition
 SeedCallFrame ActualOrbitCommit PreparedSeedDispatch PreparedOverlapCalls PreparedRootStages PreparedRootOrbit.
Require flag_level_ast.
Import flag_level_ast.
#[local] Existing Instance VerifDetected.CompSpecs.
Local Open Scope Z_scope.
Theorem prepared_orbit_without_notification {Espec:OracleKind} flip dfs s p owner a pa g b limits st i count bits (frame:mpred):
 Int.and bits Int.one<>Int.zero -> Int.and bits (Int.repr 64)=Int.zero -> 0<Zlength (block_members b) ->
 0<=i<Int.max_signed -> i+1<Zlength (block_offsets b) ->
 0<=block_at b i<=block_at b (i+1) -> block_at b (i+1)<=Zlength (block_members b) ->
 Zlength (reference_counts (live_rows st))<=Int.max_unsigned ->
 in_array (Zlength (reference_counts (live_rows st))) (raw_members b) ->
 semax (func_tycontext f_cc_run_prepared_level prepared_vars (prepared_calls flip dfs) [])
 (PROPx [] (LOCALx (orbit_with_flags s p i count bits)
  (SEPx [search_arrays s p owner a pa g b limits st;frame]))) close_block
 (normal_ret_assert (PROPx [] (LOCALx (orbit_with_flags s p i count bits)
  (SEPx [search_arrays s p owner a pa g b limits (after_counts b i st);frame])))).
Proof.
 intros have_policy disabled members ix room span slots cap indices.
 unfold close_block,orbit_with_flags,orbit_loc;abbreviate_semax;Intros;cbn [app];forward_if;try solve [congruence|contradiction].
 eapply semax_seq'.
 { eapply semax_pre;[|apply (@prepared_count_frame Espec flip dfs s p b (blocked_ptr a)
    (reference_counts (live_rows st)) i count bits (orbit_frame owner a pa g b limits st * frame)%logic)];
    try assumption.
   unfold orbit_with_flags,orbit_loc,raw_offsets,raw_members;cbn [app];rewrite search_owns_reference_counts by lia;entailer!;try cancel. }
 unfold orbit_with_flags,orbit_loc;cbn [app];Intros.
 set (next:=after_counts b i st).
 assert (hand:search_arrays s p owner a pa g b limits next =
   (orbit_frame owner a pa g b limits st *
    orbit_mem s p (offset_addr b) (member_addr b) (blocked_ptr a) (raw_offsets b) (raw_members b)
      (orbit_counts b i st))%logic).
 { rewrite search_owns_reference_counts by lia;unfold next,after_counts;rewrite orbit_fields_ignore_counts;reflexivity. }
 eapply semax_pre with (P':=PROPx [] (LOCALx (orbit_with_flags s p i count bits)
  (SEPx [search_arrays s p owner a pa g b limits next;frame]))).
 { unfold orbit_with_flags,orbit_loc;cbn [app];rewrite hand;unfold orbit_counts;entailer!;try cancel. }
 unfold orbit_with_flags,orbit_loc;cbn [app];Intros;unfold_abbrev';abbreviate_semax.
 forward_if;try solve [congruence|contradiction];forward;unfold orbit_with_flags,orbit_loc;cbn [app];fold next;entailer!;try apply derives_refl.
Qed.
