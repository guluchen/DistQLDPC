(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto.
From mathcomp Require Import all_ssreflect all_algebra.
Require Import LeafMatrix MinimumPrefix LevelSearch VerifDetected VerifClosedPrefix PreparedSeedDispatch
 PreparedDepthSpec PreparedPackingVerdict PreparedInteriorReport PreparedCandidateSlice PreparedDFSRejected
 PreparedChoiceCall PreparedMatrixPath PreparedTerminalTrace PreparedPCMLeafVisit OverlapColumnState
 IndexPacking NativePackingScan ChargeBound.
Require flag_level_ast.
Import flag_level_ast.
#[local] Existing Instance VerifDetected.CompSpecs.
Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.
Local Open Scope ring_scope.
Local Delimit Scope Z_scope with coqZ.

Section Cut.
Variables m n r k checks:nat.
Variables (H:'M['F_2]_(m,n)) (S:'M['F_2]_(r,n)) (G:'M['F_2]_(k,n))
 (extra:'M['F_2]_(checks,n)) (inc:'I_checks->seq 'I_n) (ids:seq 'I_n) (remaining:nat)
 (st:snapshot) (qualified:seq Integers.int->'cV['F_2]_n->Prop)
 (before after:Values.val->mpred) (bp:Values.val).
Let depth:=Z.of_nat (size ids).
Let weight:=Z.of_nat (size ids+remaining)%N.
Let P:=[set a:'I_n | a \in ids].
Let active:=support (extra*m indicator P).
Let free:=@available_now n st.
Let counters:=blocked st.
Let blocks:mpred:=data_at Tsh (tarray tuint (Zlength counters)) (map Vint counters) bp.
Let loan_before:=fun o=>(blocks * before o)%logic.
Let loan_after:=fun o=>(blocks * after o)%logic.
Definition pruned_from_pcm:ident*funspec:=
 DECLARE _dfs WITH s:Values.val,policy:Values.val,budgets_ptr:Values.val,base:Values.val,owner:Values.val,
     cb:Values.val,odd:Z,stride:Z,nodes:int64,budgets:seq int64,bits:Integers.int,cp:Values.val,trace:seq Integers.int
 PRE [tptr level_type,tptr (Tstruct _cc_level_policy noattr),tint,tuint]
 PROP((1<=depth<=weight-2)%coqZ;(weight<=Int.max_signed)%coqZ;(0<odd<=Int.max_signed)%coqZ;
     (0<=stride<=Int.max_signed)%coqZ;(weight-depth<Zlength budgets)%coqZ;
     is_pointer_or_null policy;is_pointer_or_null owner;isptr base;
     Int.and bits Int.one<>Int.zero;Int.and bits (Int.repr 2)=Int.zero;Int.and bits (Int.repr 8)=Int.zero;
     active_prefix depth trace=literal_path ids;Zlength counters=Z.of_nat n)
 PARAMS(s;policy;Vint (Int.repr depth);Vint bits)
 SEP(visit_fields s budgets_ptr weight odd nodes budgets;candidate_fields s base stride;
     chooser_policy policy owner cb (chosen_empty depth odd loan_before loan_after);loan_before owner;
     terminal_trace s cp trace;field_at Tsh level_type [StructField _blk] bp s)
 POST [tint]
 PROP(recursive_result H S G qualified weight st (active_prefix depth trace) 0%coqZ trace)
 RETURN(Vint Int.zero)
 SEP(visit_fields s budgets_ptr weight odd (Int64.add nodes Int64.one) (bump budgets (weight-depth));
     candidate_fields s base stride;chooser_policy policy owner cb (chosen_empty depth odd loan_before loan_after);
     loan_after owner;terminal_trace s cp trace;field_at Tsh level_type [StructField _blk] bp s).

(* The blocked-qubit array is lent to the policy. The trace, trace
   address and block address are exactly the same upon return. *)
Theorem native_prune_excludes_compatible_minimum order stamp marks marked charges capacity:
 uniq ids -> (Z.of_nat n<=Int.max_signed)%coqZ ->
 (forall x:'cV['F_2]_n,H*m x=0 -> extra*m x=0) ->
 (forall j q,extra j q!=0 -> q \in inc j) ->
 (forall j,(Zlength (encoded inc j)<=Int.max_unsigned)%coqZ) -> @tags_for n stamp marks marked ->
 {subset order <= active} ->
 (forall q,q \in free -> (\sum_(j in active) load (neighbors inc) charges j q<=capacity)%N) ->
 (cpu_scan inc counters stamp remaining order marks 0=false \/ (remaining*capacity<\sum_(j in active) charges j)%N) ->
 semax_body prepared_vars nil f_dfs pruned_from_pcm.
Proof.
 move=>unique dims implied cover widths tags scanned charge rejected.
 eapply semax_body_funspec_sub;[exact:(body_dfs_rejected_choice loan_before loan_after)| |].
 - do_funspec_sub;destruct w as [[[[[[[[[[[[s policy] budget] base] owner] cb] odd] stride] nodes] budgets] bits] cp] trace].
   cbn [fst snd];normalize.
   Exists (s,policy,budget,base,owner,cb,weight,depth,odd,stride,nodes,budgets,bits)
      (terminal_trace s cp trace * field_at Tsh level_type [StructField _blk] bp s)%logic.
   apply andp_right;first by entailer!;cancel.
   apply prop_right;intro rho;normalize.
   have ok:=@failing_pack_or_charge_returns_empty m n r k checks H S G extra inc ids st order remaining
      qualified unique dims implied cover stamp marks marked charges capacity trace widths tags scanned charge rejected.
   fold weight in ok.
   match goal with h:active_prefix depth trace=literal_path ids |- _=>rewrite -h in ok end.
   entailer!;try cancel;apply derives_refl.
 - apply compute_list_norepet_e;vm_compute;reflexivity.
Qed.
End Cut.
