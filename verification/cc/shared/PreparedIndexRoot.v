(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.floyd.reassoc_seq VerifDetected
 SeedLoopModel PreparedRootStages PreparedSeedDispatch flag_level_ast.
#[local] Existing Instance VerifDetected.CompSpecs.
Local Open Scope Z_scope.

Section IndexRoots.
Variables (c:root_phases) (s:val) (gv:globals) (flip dfs:funspec).
Let calls:=prepared_calls flip dfs.
Definition count_field:=field_at Tsh level_type [StructField _n] (Vint (Int.repr (root_count c))) s.
Definition root_regs i:=temp _options (Vint Int.zero)::temp _i (Vint (Int.repr i))::
 temp _s s::temp _policy nullval::temp _count (Vint (Int.repr (root_count c)))::gvars gv::nil.
Definition root_call_regs i:=temp _q (Vint (Int.repr i))::root_regs i.
Definition ready_to_visit i:=PROPx [] (LOCALx (root_call_regs i) (SEPx [waiting c i])).
Definition seed_returned i r:=PROPx [0<=r<=3;observation c i r]
 (LOCALx (temp _result (Vint (Int.repr r))::root_call_regs i) (SEPx [returned c i r])).
Definition advanced i:=PROPx [] (LOCALx (root_regs i) (SEPx [waiting c (i+1)])).
Variable remaining:mpred.
Definition index_root_call:ident*funspec:=
 DECLARE _cc_run_prepared_level WITH u:unit
 PRE [tptr level_type,tptr (Tstruct _cc_level_policy noattr),tuint]
 PROP(0<=root_count c<=Int.max_signed) PARAMS(s;nullval;Vint Int.zero) GLOBALS(gv)
 SEP(count_field;remaining)
 POST [tint] EX i:Z,EX r:Z,PROP(exhausted_before c i;stop_at c i r;0<=r<=3)
 RETURN(Vint (Int.repr r)) SEP(after_stop c i r).

Theorem body_index_root_control:
 (count_field*remaining |-- waiting c 0) ->
 (forall {Espec:OracleKind} i,0<=i<root_count c ->
  @semax VerifDetected.CompSpecs Espec (func_tycontext f_cc_run_prepared_level prepared_vars calls [])
   (ready_to_visit i) run_root (normal_ret_assert (EX r:Z,seed_returned i r))) ->
 (forall {Espec:OracleKind} i,0<=i<root_count c ->
  @semax VerifDetected.CompSpecs Espec (func_tycontext f_cc_run_prepared_level prepared_vars calls [])
   (seed_returned i 0) close_block (normal_ret_assert (advanced i))) ->
 semax_body prepared_vars calls f_cc_run_prepared_level index_root_call.
Proof.
 intros initialize visit empty. start_function1. start_function2. start_function3.
 unfold count_field in *;Intros;reassoc_seq.
 apply semax_if_seq;forward_if;try solve [congruence|contradiction].
 forward. forward. forward.
 forward_for_simple_bound (root_count c)
  (EX i:Z,PROP(exhausted_before c i)
   LOCAL(temp _s s;temp _policy nullval;temp _options (Vint Int.zero);temp _count (Vint (Int.repr (root_count c)));gvars gv)
   SEP(waiting c i)).
 - sep_apply initialize;entailer!;unfold exhausted_before;intros;lia.
 - assert (live:0<=i<root_count c) by lia.
   reassoc_seq;apply semax_if_seq;forward_if;try solve [congruence|contradiction].
   forward. forward.
   unfold_abbrev'.
   match goal with |- semax _ _ ?body _ =>
      apply (semax_unfold_seq (Ssequence run_root (Ssequence early_return close_block)) body eq_refl) end.
   eapply semax_seq'.
   { eapply semax_pre;[|apply (visit Espec i live)].
     unfold ready_to_visit,root_call_regs,root_regs;entailer!;try apply derives_refl. }
   Intros r;unfold seed_returned,root_call_regs,root_regs;Intros.
   unfold early_return;apply semax_if_seq;forward_if.
   + forward;Exists i r;unfold after_stop,stop_at;destruct (Z.eq_dec r 0);[subst;congruence|].
     entailer!;try apply derives_refl;right;auto.
   + assert (zero:r=0) by rep_lia;subst r.
     eapply (semax_post (normal_ret_assert (advanced i))).
     5:{ eapply semax_pre;[|apply (empty Espec i live)].
         unfold seed_returned,root_call_regs,root_regs;entailer!;try apply derives_refl. }
     2,3: cbn [RA_break RA_continue normal_ret_assert];apply andp_left2;apply FF_left.
     2:{ intro v;cbn [RA_return normal_ret_assert];apply andp_left2;apply FF_left. }
     unfold POSTCONDITION,abbreviate;cbn [RA_normal normal_ret_assert loop1_ret_assert overridePost
       for_ret_assert frame_ret_assert function_body_ret_assert].
     unfold advanced,root_regs;entailer!;try apply derives_refl;apply extend_exhaustion;assumption.
 - forward;Exists (root_count c) 0;unfold after_stop,stop_at;entailer!;try apply derives_refl;auto.
Qed.
End IndexRoots.

Require Import VerifSeedIndex.
(* Only an exhausted seed is permanently excluded. The same blocked array
   is lent to DFS, restored on return, then advanced by exactly one cell. *)
Theorem commit_exhausted_index {Espec:OracleKind} c s gv flip dfs bp i (frame:mpred):
 let n:=root_count c in 0<=i<n -> n<=Int.max_signed ->
 semax (func_tycontext f_cc_run_prepared_level prepared_vars (prepared_calls flip dfs) [])
   (PROPx [] (LOCALx (root_call_regs c s gv i) (SEPx [seed_blocks s bp n i;frame])))
   close_block
   (normal_ret_assert (PROPx [] (LOCALx (root_regs c s gv i) (SEPx [seed_blocks s bp n (i+1);frame])))).
Proof.
 intros n inside fit;unfold close_block,root_call_regs,root_regs,seed_blocks;abbreviate_semax;Intros.
 assert (free:Znth i (seen n i)=Int.zero).
 { rewrite seen_cell by lia;destruct (Z_lt_dec i i);[lia|reflexivity]. }
 assert (size:Zlength (seen n i)=n) by (apply seen_length;lia).
 forward_if;[contradiction|].
 forward. forward. forward. rewrite free. forward.
 rewrite upd_Znth_map,put_seed by lia;entailer!;try apply derives_refl.
Qed.
