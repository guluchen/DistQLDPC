(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.floyd.reassoc_seq VST.zlist.list_solver.
Require Import level_ast VerifDetected VerifOrbitBlock SeedLoopModel SeedOrbitStorage SeedStorageTransition
 SeedBlockView SeedBlockModel SeedColumnModel VerifSeedMove ActiveChildren SiblingCounters SeedCallFrame.
#[local] Existing Instance VerifDetected.CompSpecs.
Local Open Scope Z_scope.

Definition block_functions p owner fp:=
 (field_at Tsh (Tstruct _cc_level_policy noattr) [StructField _owner] owner p *
  field_at Tsh (Tstruct _cc_level_policy noattr) [StructField _block_done] fp p *
  weak_valid_pointer p * weak_valid_pointer fp * func_ptr' (snd exhausted_spec) fp)%logic.
Definition raw_offsets b:=map Int.unsigned (block_offsets b).
Definition raw_members b:=map Int.unsigned (block_members b).
Definition orbit_counts b i st:=scanned (block_at b i) (block_at b (i+1)) (raw_members b) (reference_counts (live_rows st)).
Definition after_counts b i st:=replace_counts st (orbit_counts b i st).
Definition after_exhaustion g b limits i st :=
 crossed_block g b limits (after_counts b i st) (block_at b i) (block_at b (i+1)).
Definition finish_loc s p i count := orbit_loc s p i ++ [temp _count (Vint (Int.repr count))].
Lemma root_context_adds_calls policies :
 tycontext_sub (func_tycontext f_cc_run_level Vprog [] []) (func_tycontext f_cc_run_level Vprog (RootG policies) []).
Proof.
 apply tycontext_sub_Gprog_nil;vm_compute;
 repeat (apply list_norepet_cons;[simpl;intuition congruence|]);apply list_norepet_nil.
Qed.
Lemma count_orbit_with_frame {Espec:OracleKind} policies s p b bp base i count (allocation:mpred):
 0<=i<Int.max_signed -> i+1<Zlength (block_offsets b) ->
 0<=block_at b i<=block_at b (i+1) -> block_at b (i+1)<=Zlength (block_members b) ->
 Zlength base<=Int.max_unsigned -> in_array (Zlength base) (raw_members b) ->
 semax (func_tycontext f_cc_run_level Vprog (RootG policies) [])
 (PROPx [] (LOCALx (finish_loc s p i count)
   (SEPx [orbit_mem s p (offset_addr b) (member_addr b) bp (raw_offsets b) (raw_members b) base;allocation])))
 actual_orbit
 (normal_ret_assert (PROPx [] (LOCALx (finish_loc s p i count)
   (SEPx [orbit_mem s p (offset_addr b) (member_addr b) bp (raw_offsets b) (raw_members b)
     (scanned (block_at b i) (block_at b (i+1)) (raw_members b) base);allocation])))).
Proof.
 intros ix room span slots cap indices;unfold finish_loc.
 eapply preserve_caller_store with (saved:=[temp _count (Vint (Int.repr count))]).
 - eapply semax_Delta_subsumption;[apply root_context_adds_calls|].
   unfold raw_offsets,raw_members in *;unfold block_at in *.
   pose proof (Int.unsigned_range_2 (Znth (i+1) (block_offsets b))) as end_fits.
   eapply semax_policy_orbit;try eassumption;rewrite ?Zlength_map,?Znth_map by lia;try reflexivity;lia.
 - unfold actual_orbit;auto 50 with closed.
Qed.

Theorem complete_empty_policy_orbit {Espec:OracleKind} policies s p owner fp a pa g b limits st i count (frame:mpred):
 isptr p -> isptr fp -> is_pointer_or_null owner -> 0<Zlength (block_members b) ->
 block_safe g b limits i (after_counts b i st) ->
 Zlength (reference_counts (live_rows st))<=Int.max_unsigned ->
 in_array (Zlength (reference_counts (live_rows st))) (raw_members b) ->
 semax (func_tycontext f_cc_run_level Vprog (RootG policies) [])
 (PROPx [] (LOCALx (finish_loc s p i count)
  (SEPx [search_arrays s p owner a pa g b limits st;block_functions p owner fp;frame]))) finish_orbit
 (normal_ret_assert (PROPx [] (LOCALx (finish_loc s p i count)
  (SEPx [search_arrays s p owner a pa g b limits (after_exhaustion g b limits i st);block_functions p owner fp;frame])))).
Proof.
 intros pp pf own members valid cap indices;pose proof valid as whole.
 destruct valid as [ix [room [span [slots scan]]]].
 unfold finish_orbit,finish_loc,orbit_loc,block_functions;abbreviate_semax;Intros;cbn [app];forward_if;try solve [subst p;contradiction].
 { destruct p;try contradiction;cbn [denote_tc_test_eq];apply andp_right;[entailer!|auto 40 with valid_pointer]. }
 eapply semax_seq'.
 { eapply semax_pre;[|apply (@count_orbit_with_frame Espec policies s p b (blocked_ptr a)
    (reference_counts (live_rows st)) i count (orbit_frame owner a pa g b limits st * block_functions p owner fp * frame)%logic)];
    try assumption.
   unfold finish_loc,orbit_loc,block_functions,raw_offsets,raw_members;cbn [app];rewrite search_owns_reference_counts by lia;entailer!;try cancel. }
 unfold finish_loc,orbit_loc,block_functions;cbn [app];Intros.
 set (next:=after_counts b i st).
 assert (hand:search_arrays s p owner a pa g b limits next =
   (orbit_frame owner a pa g b limits st *
    orbit_mem s p (offset_addr b) (member_addr b) (blocked_ptr a) (raw_offsets b) (raw_members b)
      (orbit_counts b i st))%logic).
 { rewrite search_owns_reference_counts by lia;unfold next,after_counts;rewrite orbit_fields_ignore_counts;reflexivity. }
 eapply semax_pre with (P':=PROPx [] (LOCALx (finish_loc s p i count)
  (SEPx [search_arrays s p owner a pa g b limits next;block_functions p owner fp;frame]))).
 { unfold finish_loc,orbit_loc,block_functions;cbn [app];rewrite hand;unfold orbit_counts;entailer!;try cancel. }
 unfold search_arrays,finish_loc,orbit_loc,block_functions;cbn [app];Intros.
 unfold_abbrev'. abbreviate_semax.
 forward;forward_if;try solve [subst fp;contradiction].
 { destruct fp;try contradiction;cbn [denote_tc_test_eq];apply andp_right;[entailer!|auto 40 with valid_pointer]. }
 do 2 forward.
 forward_call (owner,a,pa,g,b,limits,i,next);try solve [entailer!].
 unfold after_exhaustion,search_arrays,finish_loc,orbit_loc,block_functions;cbn [app];fold next;entailer!;try cancel.
Qed.
