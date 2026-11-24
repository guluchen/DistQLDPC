(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.floyd.reassoc_seq VST.zlist.list_solver.
Require Import VerifDetected VerifOrbitBlock VerifSeedMove ClightSelect SiblingCounters ActiveChildren
 SeedColumnModel SeedPolicyView SeedBlockModel SeedBlockView SeedOrbitStorage SeedStorageTransition
 SeedCallFrame ActualOrbitCommit PreparedSeedDispatch PreparedOverlapCalls PreparedRootStages.
Require flag_level_ast.
Import flag_level_ast.
#[local] Existing Instance VerifDetected.CompSpecs.
Local Open Scope Z_scope.
Definition member_scan:statement:=ltac:(native_fragment orbit_loop f_cc_run_prepared_level).
Definition orbit_with_flags s p i count bits:=orbit_loc s p i ++ [temp _count (Vint (Int.repr count));temp _options (Vint bits)].
Theorem count_prepared_members {Espec:OracleKind} flip dfs s p starts blocks bp offsets qs base i lo hi:
 0<=i<Int.max_signed -> i+1<Zlength offsets -> Znth i offsets=lo -> Znth (i+1) offsets=hi ->
 0<=lo<=hi -> hi<=Zlength qs -> hi<=Int.max_unsigned -> Zlength base<=Int.max_unsigned ->
 in_array (Zlength base) qs ->
 semax (func_tycontext f_cc_run_prepared_level prepared_vars (prepared_calls flip dfs) [])
  (PROPx nil (LOCALx (orbit_loc s p i) (SEPx [orbit_mem s p starts blocks bp offsets qs base])))
  member_scan
  (normal_ret_assert (PROPx nil (LOCALx (orbit_loc s p i)
     (SEPx [orbit_mem s p starts blocks bp offsets qs (scanned lo hi qs base)])))).
Proof.
 intros ix offsets_len lo_eq hi_eq bounds live cap block_cap indices.
 unfold member_scan,orbit_loc;abbreviate_semax;reassoc_seq.
 unfold orbit_mem;Intros;do 2 forward.
 forward_loop
  (EX j:Z, PROP(lo<=j<=hi)
   LOCAL(temp _j (Vint (Int.repr j));temp _s s;temp _policy p;temp _i (Vint (Int.repr i)))
   SEP(orbit_mem s p starts blocks bp offsets qs (scanned lo j qs base)))%assert
 break: (PROPx nil (LOCALx (orbit_loc s p i) (SEPx [orbit_mem s p starts blocks bp offsets qs (scanned lo hi qs base)])))%assert.
 - Exists lo;unfold orbit_mem,scanned;rewrite sublist_nil by lia;rewrite ?lo_eq;entailer!;try apply derives_refl.
 - Intros j. pose proof (@scanned_length lo j qs base indices) as rowlength.
   unfold orbit_mem;Intros;do 2 (forward;try solve [entailer!;change (Int.signed Int.one) with 1;change Int.min_signed with (-2147483648);lia]).
   rewrite hi_eq;forward_if.
   + assert (within:lo<=j<hi) by rep_lia.
     assert (valid:0<=Znth j qs<Zlength base) by
       (apply Forall_forall with (x:=Znth j qs) in indices;[exact indices|apply Znth_In;lia]).
     assert (uq:Int.unsigned (Int.repr (Znth j qs))=Znth j qs) by (apply Int.unsigned_repr;lia).
     do 8 forward. forward.
     Exists (j+1);unfold orbit_mem;rewrite scanned_next by lia;unfold adjust.
     rewrite upd_Znth_Zlength,upd_Znth_map by lia;rewrite ?uq;entailer!.
   + assert (j=hi) by rep_lia;subst;forward;unfold orbit_loc,orbit_mem;entailer!.
 - unfold orbit_loc;entailer!;try apply derives_refl.
Qed.

Lemma prepared_count_frame {Espec:OracleKind} flip dfs s p b bp base i count bits (allocation:mpred):
 0<=i<Int.max_signed -> i+1<Zlength (block_offsets b) ->
 0<=block_at b i<=block_at b (i+1) -> block_at b (i+1)<=Zlength (block_members b) ->
 Zlength base<=Int.max_unsigned -> in_array (Zlength base) (raw_members b) ->
 semax (func_tycontext f_cc_run_prepared_level prepared_vars (prepared_calls flip dfs) [])
 (PROPx [] (LOCALx (orbit_with_flags s p i count bits)
   (SEPx [orbit_mem s p (offset_addr b) (member_addr b) bp (raw_offsets b) (raw_members b) base;allocation])))
 member_scan
 (normal_ret_assert (PROPx [] (LOCALx (orbit_with_flags s p i count bits)
   (SEPx [orbit_mem s p (offset_addr b) (member_addr b) bp (raw_offsets b) (raw_members b)
     (scanned (block_at b i) (block_at b (i+1)) (raw_members b) base);allocation])))).
Proof.
 intros ix room span slots cap indices;unfold orbit_with_flags.
 eapply preserve_caller_store with (saved:=[temp _count (Vint (Int.repr count));temp _options (Vint bits)]).
 - unfold raw_offsets,raw_members in *;unfold block_at in *.
   pose proof (Int.unsigned_range_2 (Znth (i+1) (block_offsets b))) as end_fits.
   eapply count_prepared_members;try eassumption;rewrite ?Zlength_map,?Znth_map by lia;try reflexivity;lia.
 - unfold member_scan;auto 50 with closed.
Qed.

Theorem prepared_complete_orbit {Espec:OracleKind} flip dfs s p owner fp a pa g b limits st i count bits (frame:mpred):
 Int.and bits Int.one<>Int.zero -> Int.and bits (Int.repr 64)<>Int.zero -> is_pointer_or_null owner -> 0<Zlength (block_members b) ->
 block_safe g b limits i (after_counts b i st) ->
 Zlength (reference_counts (live_rows st))<=Int.max_unsigned ->
 in_array (Zlength (reference_counts (live_rows st))) (raw_members b) ->
 semax (func_tycontext f_cc_run_prepared_level prepared_vars (prepared_calls flip dfs) [])
 (PROPx [] (LOCALx (orbit_with_flags s p i count bits)
  (SEPx [search_arrays s p owner a pa g b limits st;done_fields p owner fp;frame]))) close_block
 (normal_ret_assert (PROPx [] (LOCALx (orbit_with_flags s p i count bits)
  (SEPx [search_arrays s p owner a pa g b limits (after_exhaustion g b limits i st);done_fields p owner fp;frame])))).
Proof.
 intros have_policy notify own members valid cap indices;pose proof valid as whole.
 destruct valid as [ix [room [span [slots scan]]]].
 unfold close_block,orbit_with_flags,orbit_loc,done_fields;abbreviate_semax;Intros;cbn [app];forward_if;try solve [congruence|contradiction].
 eapply semax_seq'.
 { eapply semax_pre;[|apply (@prepared_count_frame Espec flip dfs s p b (blocked_ptr a)
    (reference_counts (live_rows st)) i count bits (orbit_frame owner a pa g b limits st * done_fields p owner fp * frame)%logic)];
    try assumption.
   unfold orbit_with_flags,orbit_loc,done_fields,raw_offsets,raw_members;cbn [app];rewrite search_owns_reference_counts by lia;entailer!;try cancel. }
 unfold orbit_with_flags,orbit_loc,done_fields;cbn [app];Intros.
 set (next:=after_counts b i st).
 assert (hand:search_arrays s p owner a pa g b limits next =
   (orbit_frame owner a pa g b limits st *
    orbit_mem s p (offset_addr b) (member_addr b) (blocked_ptr a) (raw_offsets b) (raw_members b)
      (orbit_counts b i st))%logic).
 { rewrite search_owns_reference_counts by lia;unfold next,after_counts;rewrite orbit_fields_ignore_counts;reflexivity. }
 eapply semax_pre with (P':=PROPx [] (LOCALx (orbit_with_flags s p i count bits)
  (SEPx [search_arrays s p owner a pa g b limits next;done_fields p owner fp;frame]))).
 { unfold orbit_with_flags,orbit_loc,done_fields;cbn [app];rewrite hand;unfold orbit_counts;entailer!;try cancel. }
 unfold search_arrays,orbit_with_flags,orbit_loc,done_fields;cbn [app];Intros.
 unfold_abbrev'. abbreviate_semax.
 forward_if;try solve [congruence|contradiction];do 2 (forward;try solve [entailer!]).
 forward_call (owner,a,pa,g,b,limits,i,next);try solve [entailer!].
 unfold after_exhaustion,search_arrays,orbit_with_flags,orbit_loc,done_fields;cbn [app];fold next;entailer!;try cancel.
Qed.
