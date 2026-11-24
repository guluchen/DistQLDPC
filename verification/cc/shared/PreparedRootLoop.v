(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.floyd.reassoc_seq VST.zlist.list_solver.
Require Import VerifDetected SeedLoopModel PreparedSeedDispatch PreparedRootStages.
Require flag_level_ast.
Import flag_level_ast.
#[local] Existing Instance VerifDetected.CompSpecs.
Local Open Scope Z_scope.

(* All four return codes survive the loop. An interrupted seed cannot
   commit a block or turn a partial search into an EMPTY result. *)
Theorem body_prepared_root_control c s p a bits flip dfs:
 (forall {Espec:OracleKind} i,0<=i<root_count c ->
  @semax VerifDetected.CompSpecs Espec (func_tycontext f_cc_run_prepared_level prepared_vars (prepared_calls flip dfs) [])
   (before_root c s p a i bits) run_root (normal_ret_assert (EX r:Z,after_root c s p a i bits r))) ->
 (forall {Espec:OracleKind} i,0<=i<root_count c ->
  @semax VerifDetected.CompSpecs Espec (func_tycontext f_cc_run_prepared_level prepared_vars (prepared_calls flip dfs) [])
   (after_root c s p a i bits 0) close_block (normal_ret_assert (after_block c s p a i bits))) ->
 semax_body prepared_vars (prepared_calls flip dfs) f_cc_run_prepared_level (prepared_spec c s p a bits).
Proof.
 intros visit empty. start_function1. start_function2. start_function3. unfold seed_fields;Intros.
 reassoc_seq;apply semax_if_seq;forward_if;try solve [congruence|contradiction].
 do 2 forward. forward.
 forward_for_simple_bound (root_count c)
  (EX i:Z, PROP(exhausted_before c i)
   LOCAL(temp _s s;temp _policy p;temp _options (Vint bits);temp _count (Vint (Int.repr (root_count c))))
   SEP(seed_fields c p a;waiting c i)).
 - unfold seed_fields;entailer!;unfold exhausted_before;intros;lia.
 - assert (live:0<=i<root_count c) by lia.
   reassoc_seq;unfold seed_fields;Intros.
   rewrite live_seed_vector by lia;apply semax_if_seq;forward_if;try solve [congruence|contradiction].
   do 3 forward. forward.
   unfold_abbrev'.
   match goal with |- semax _ _ ?body _ =>
     apply (semax_unfold_seq (Ssequence run_root (Ssequence early_return close_block)) body eq_refl) end.
   eapply semax_seq'.
   { eapply semax_pre;[|apply (visit Espec i live)];unfold before_root,seed_loc,driver_loc,seed_fields;
     rewrite live_seed_vector by lia;entailer!;try apply derives_refl. }
   Intros r;unfold after_root,seed_loc,driver_loc;Intros.
   unfold early_return;apply semax_if_seq;forward_if.
   + forward;Exists i r;unfold after_stop,stop_at;destruct (Z.eq_dec r 0);[subst;congruence|].
     entailer!;try apply derives_refl;right;auto.
   + assert (zero:r=0) by rep_lia;subst r.
     eapply (semax_post (normal_ret_assert (after_block c s p a i bits))).
     5:{ eapply semax_pre;[|apply (empty Espec i live)];unfold after_root,seed_loc,driver_loc;
         entailer!;try apply derives_refl. }
     2,3: cbn [RA_break RA_continue normal_ret_assert];apply andp_left2;apply FF_left.
     2:{ intro v;cbn [RA_return normal_ret_assert];apply andp_left2;apply FF_left. }
     unfold POSTCONDITION,abbreviate;cbn [RA_normal normal_ret_assert loop1_ret_assert overridePost
       for_ret_assert frame_ret_assert function_body_ret_assert].
     unfold after_block,driver_loc;entailer!;try apply derives_refl;apply extend_exhaustion;assumption.
 - forward;Exists (root_count c) 0;unfold after_stop,stop_at;entailer!;try apply derives_refl;auto.
Qed.
