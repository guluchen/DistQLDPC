(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.floyd.reassoc_seq VST.zlist.list_solver.
Require Import level_ast VerifDetected SeedLoopModel.
Local Open Scope Z_scope.

(* The two remaining premises describe precisely the root visit with its
   callbacks, and the orbit blocking performed after an EMPTY result. *)
Theorem body_policy_seed_control c s p a policies:
 (forall {Espec:OracleKind} i,0<=i<root_count c ->
  @semax VerifDetected.CompSpecs Espec (func_tycontext f_cc_run_level Vprog (RootG policies) []) (start_seed c s p a i) visit_and_restore
   (normal_ret_assert (EX r:Z,post_visit c s p a i r))) ->
 (forall {Espec:OracleKind} i,0<=i<root_count c ->
  @semax VerifDetected.CompSpecs Espec (func_tycontext f_cc_run_level Vprog (RootG policies) []) (post_visit c s p a i 0) finish_orbit
   (normal_ret_assert (next_orbit c s p a i))) ->
 semax_body Vprog (RootG policies) f_cc_run_level (policy_root_spec c s p a).
Proof.
 intros visit empty. start_function1. start_function2. start_function3. unfold policy_seeds_at;Intros.
 reassoc_seq;apply semax_if_seq;forward_if;try solve [subst p;contradiction].
 { destruct p;try contradiction;cbn [denote_tc_test_eq];apply andp_right;[entailer!|auto 40 with valid_pointer]. }
 do 2 forward. forward.
 forward_for_simple_bound (root_count c)
  (EX i:Z, PROP(exhausted_before c i)
   LOCAL(temp _s s;temp _policy p;temp _count (Vint (Int.repr (root_count c))))
   SEP(policy_seeds_at c p a;waiting c i)).
 - unfold policy_seeds_at;entailer!;unfold exhausted_before;intros;lia.
 - assert (live:0<=i<root_count c) by lia.
   reassoc_seq;unfold policy_seeds_at;Intros.
   rewrite live_seed_vector by lia;apply semax_if_seq;forward_if;try solve [subst p;contradiction].
   { destruct p;try contradiction;cbn [denote_tc_test_eq];apply andp_right;[entailer!|auto 40 with valid_pointer]. }
   do 3 forward. forward.
   unfold_abbrev'.
   match goal with |- semax _ _ ?body _ =>
     apply (semax_unfold_seq (Ssequence visit_and_restore (Ssequence return_on_hit finish_orbit)) body eq_refl) end.
   eapply semax_seq'.
   { eapply semax_pre;[|apply (visit Espec i live)];unfold start_seed,selected_loc,outer_loc,policy_seeds_at;
     rewrite live_seed_vector by lia;entailer!;try apply derives_refl. }
   Intros r;unfold post_visit,result_loc,selected_loc,outer_loc;Intros.
   unfold return_on_hit;apply semax_if_seq;forward_if.
   + forward;Exists i r;unfold after_stop,stop_at;destruct (Z.eq_dec r 0);[subst;congruence|].
     entailer!;try apply derives_refl;right;auto.
   + assert (zero:r=0) by rep_lia;subst r.
     eapply (semax_post (normal_ret_assert (next_orbit c s p a i))).
     5:{ eapply semax_pre;[|apply (empty Espec i live)];unfold post_visit,result_loc,selected_loc,outer_loc;
         entailer!;try apply derives_refl. }
     2,3: cbn [RA_break RA_continue normal_ret_assert];apply andp_left2;apply FF_left.
     2:{ intro v;cbn [RA_return normal_ret_assert];apply andp_left2;apply FF_left. }
     unfold POSTCONDITION,abbreviate;cbn [RA_normal normal_ret_assert loop1_ret_assert overridePost
       for_ret_assert frame_ret_assert function_body_ret_assert].
     unfold next_orbit,outer_loc;entailer!;try apply derives_refl;apply extend_exhaustion;assumption.
 - forward;Exists (root_count c) 0;unfold after_stop,stop_at;entailer!;try apply derives_refl;auto.
Qed.
