(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto.
From mathcomp Require Import all_ssreflect all_algebra.
Require Import level_ast VerifDetected VerifClosesBody VerifLookup HashLookup HashProbe
  LeafMatrix LevelSearch ClosureMatrix SyndromeHash NativeLeafChoice LeafAPI PCMLeafAPI
  TableFlow TableCoverage TableMembers BuiltLookup BucketPipeline BuiltPCM
  VerifClosedPrefix VerifOneLeft VerifFlipBody VerifPolicyStep.
Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.
Local Open Scope ring_scope.
Local Delimit Scope Z_scope with coqZ.

Section Constructed.
Variables m n k:nat.
Variables (H:'M['F_2]_(m,n)) (L:'M['F_2]_(k,n)) (P F:{set 'I_n}).
Variables (v:close_view) (physical:'I_n -> seq 'I_m) (rowkey:'I_m -> int64).
Variables (ks:seq int64) (mask key:int64) (cap bits:Z) (tab links:seq Z) (blk:seq Integers.int).
Let b:=table_book ks mask key tab links blk.
Let rows:=support (H *m indicator P).
Let odd:=Z.of_nat #|rows|.
Hypothesis built : history ks mask cap (-1)%coqZ tab links.
Hypothesis npos : (0<Zlength ks)%coqZ.
Hypothesis length_ok : Zlength ks=Z.of_nat n.
Hypothesis room : (Zlength ks<cap)%coqZ.
Hypothesis period : cap=(2^bits)%coqZ.
Hypothesis index_bits : (0<=bits<64)%coqZ.
Hypothesis mask_bits : mask=Int64.repr (Z.ones bits).
Hypothesis disj : [disjoint F & P].
Hypothesis blocks : forall q:'I_n, Znth (Z.of_nat q) blk=Int.zero <-> q \in F.
Hypothesis columns : forall q:'I_n, @layout m n k H L (indicator P) q (physical q) v.
Hypothesis target_key : key=signature rowkey rows.
Hypothesis column_keys : forall q:'I_n, Znth (Z.of_nat q) ks=signature rowkey (support (col q H)).

Let depth:=Z.of_nat #|P|.
Variable policy:Values.val.
Variable enabled:bool.

(* In the physical entry, depth, odd count, key and acceptance all refer
   to the same input PCM and the same selected and free qubits. *)
Definition built_policy_step : ident * funspec :=
 DECLARE _dfs
 WITH s:Values.val,bp:Values.val,cp:Values.val,p:lookup_ptrs,
      counts:list int64,path:list Integers.int,nodes:int64,leaves:int64,saved:Integers.int
 PRE [tptr level_type,tptr policy_type,tint]
   PROP((1<=depth<Int.max_signed)%coqZ; (0<odd<=Int.max_signed)%coqZ;
     (1<Zlength counts)%coqZ; (depth<Zlength path)%coqZ;
     (enabled=true -> Z.testbit (1-odd)%coqZ 0=false); book_safe b v odd)
   PARAMS(s;policy;Vint (Int.repr depth))
   SEP(one_left_fields s bp cp (depth+1) counts path nodes leaves saved;
       close_mem Tsh s odd v;book_mem s b p;policy_gate policy enabled)
 POST [tint] EX a:Z, PROP(leaf_answer (pcm_completion H L P F) (Z.of_nat n) a)
   RETURN(Vint (Int.repr (final_pick a)))
   SEP(one_left_fields s bp cp (depth+1) (bump counts 1) (last_path depth a path)
     (Int64.add nodes Int64.one) (Int64.add leaves Int64.one) (last_size (depth+1) a saved);
       close_mem Tsh s odd v;book_mem s b p;policy_gate policy enabled).

Lemma constructed_policy_refines : funspec_sub
  (snd (policy_step (pcm_completion H L P F) policy enabled)) (snd built_policy_step).
Proof.
  destruct (@constructor_pcm_image m n k H L P F v physical rowkey ks mask key cap bits tab links blk
    built npos length_ok room period index_bits mask_bits disj blocks columns target_key column_keys) as [qs image].
  do_funspec_sub.
  destruct w as [[[[[[[[s bp]cp]p]counts]path]nodes]leaves]saved];cbn [fst snd];normalize.
  Exists (s,bp,cp,p,b,v,odd,qs,depth,counts,path,nodes,leaves,saved) emp;apply andp_right.
  - entailer!;cancel.
  - apply prop_right;intros rho';normalize.
    match goal with h:leaf_answer _ _ ?a |- _ => Exists a end.
    change (extent b=Z.of_nat n) in length_ok;rewrite <-length_ok;entailer!;cancel.
Qed.
Theorem body_constructed_policy_step :
  semax_body Vprog (PolicyStepGprog (pcm_completion H L P F) policy enabled) f_dfs built_policy_step.
Proof.
  eapply semax_body_funspec_sub;[apply body_policy_search_step|apply constructed_policy_refines|].
  vm_compute;repeat(apply list_norepet_cons;[simpl;intuition congruence|]);apply list_norepet_nil.
Qed.
End Constructed.
