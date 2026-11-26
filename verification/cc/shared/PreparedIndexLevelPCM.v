(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.floyd.reassoc_seq VerifDetected VerifChildVisit
 EnabledCall OverlapColumnState VerifSeedIndex SeedLoopModel PreparedRootStages
 PreparedDepthSpec PreparedIndexArena PreparedIndexGlobals PreparedSeedDispatch PreparedIndexRoot PreparedIndexSeedLoop
 PreparedMatrixPath PreparedPlainReachable PreparedInteriorReport PreparedIndexSeedCoverage
 PreparedPCMLeafVisit PreparedRecursiveCall PreparedPlainDescent LeafMatrix MinimumPrefix LevelSearch flag_level_ast.
From mathcomp Require Import all_ssreflect all_algebra.
#[local] Existing Instance VerifDetected.CompSpecs.
Set Implicit Arguments.
Unset Strict Implicit.
Local Open Scope ring_scope.
Local Delimit Scope Z_scope with coqZ.

Definition index_seed_names n:=literal_path (enum 'I_n).
Lemma number_of_seeds n:Zlength (@index_seed_names n)=Z.of_nat n.
Proof. rewrite /index_seed_names /literal_path Zlength_map Zlength_correct.
 change (Z.of_nat (size (enum 'I_n))=Z.of_nat n);by rewrite size_enum_ord. Qed.
Definition index_state n (i:Z):=Build_snapshot [::] (seen (Z.of_nat n) (i+1)%coqZ) Int64.zero Int64.zero Int64.zero.
Definition seeded_entry n c s cp bp:entry_domain:=fun g level trace blocks _ st xs=>
 g=geometry c /\ level=s /\ trace=cp /\ blocks=bp /\ reachable_prefix n st xs.

Lemma initialized_seed_admissible n c s cp bp i:(0<=i<Z.of_nat n)%coqZ ->
 seeded_entry n c s cp bp (geometry c) s cp bp 0%coqZ (index_state n i) [::Int.repr i].
Proof.
 move=>range;unfold seeded_entry;repeat split=>//.
 have small:(Z.to_nat i<n)%N by apply/ltP;lia.
 pose q:'I_n:=Ordinal small.
 have same:Z.of_nat q = i by rewrite /q /= Z2Nat.id;lia.
 rewrite -same;apply (@index_seed_is_reachable n q);reflexivity.
Qed.

Section Level.
Variables m n r k:nat.
Variables (H:'M['F_2]_(m,n)) (S:'M['F_2]_(r,n)) (G:'M['F_2]_(k,n)).
Let eligible:=fun (_:seq Integers.int) (_:'cV['F_2]_n)=>True.
Lemma every_seed_was_empty w:
 (Z.of_nat n<=Int.max_signed)%coqZ ->
 (forall i,(0<=i<Z.of_nat n)%coqZ -> exists tail,
   recursive_result H S G eligible w (index_state n i) [::Int.repr i] 0%coqZ tail) ->
 forall x,minimum H G x -> Z.of_nat #|LeafMatrix.support x|<>w.
Proof.
 move=>fits observed;apply (@exhausted_index_seeds_exclude_a_minimum m n r k H S G
    (fun q=>index_state n (Z.of_nat q)) (fun _=>[::]) fits (fun _=>Logic.eq_refl) w).
 move=>q;have bound:=elimT ltP (ltn_ord q).
 have [tail [complete [_ _]]]:=observed (Z.of_nat q) ltac:(lia).
 split;first exact complete.
 split;discriminate.
Qed.
End Level.

(* With null poll and policy pointers the public C level function selects
   exactly the prepared entry verified by the seed-loop proof. *)
Definition poll_off s:=field_at Tsh level_type [StructField _poll] nullval s.
Definition plain_level_call ph s gv rest:ident*funspec:=
 DECLARE _cc_run_level WITH u:unit
 PRE [tptr level_type,tptr (Tstruct _cc_level_policy noattr)]
 PROP((0<=root_count ph<=Int.max_signed)%coqZ) PARAMS(s;nullval) GLOBALS(gv)
 SEP(count_field ph s;rest;poll_off s)
 POST [tint] EX i:Z,EX v:Z,PROP(exhausted_before ph i;stop_at ph i v;(0<=v<=3)%coqZ)
 RETURN(Vint (Int.repr v)) SEP(after_stop ph i v;poll_off s).
Definition public_level_calls ph s gv rest:funspecs:=
 ltac:(let fs:=constr:([::index_root_call ph s gv rest]) in with_library flag_level_ast.prog fs).

Theorem null_policy_runs_verified_level ph s gv rest:
 semax_body prepared_vars (public_level_calls ph s gv rest) f_cc_run_level (plain_level_call ph s gv rest).
Proof.
 start_function1. start_function2. start_function3. unfold poll_off;Intros;reassoc_seq.
 forward;apply semax_if_seq;forward_if;[contradiction|forward];forward.
 apply semax_if_seq;forward_if;[contradiction|].
 forward_call tt;Intros code;destruct code as [i v];cbn [fst snd] in *.
 forward;Exists i v;unfold poll_off;entailer!;cancel;try apply derives_refl.
Qed.

Require Import PreparedObservedWitness.
Section Certificate.
Variables m n r k:nat.
Variables (H:'M['F_2]_(m,n)) (S:'M['F_2]_(r,n)) (G:'M['F_2]_(k,n)).
Variables (c:policy_state) (env:globals) (s cp bp base:Values.val) (stride target_weight:Z) (heap:node_storage) (rest:mpred).
Let names:=@index_seed_names n.
Let allow:=fun (_:seq Integers.int) (_:'cV['F_2]_n)=>True.
Let result:=recursive_report H S G allow.
Let valid:=stored_css_prefix H S.
Let states:=index_state n.
Let ph:=@phases c names s cp bp base stride target_weight heap result valid states.
Let admission:=seeded_entry n c s cp bp.
Hypotheses (bounded:(Z.of_nat n<=Int.max_signed)%coqZ) (target:(1<=target_weight<=Z.of_nat n)%coqZ)
 (plain:nested_policy (nested c)=nullval) (colroom:(Z.of_nat n<Zlength (column_offsets (geometry c)))%coqZ).
Lemma empty_complete_level i:exhausted_before ph i -> stop_at ph i 0%coqZ ->
 forall x,minimum H G x -> Z.of_nat #|LeafMatrix.support x|<>target_weight.
Proof.
 move=>empty [[end_i _]|[_ [bad _]]];last by case bad.
 apply (@every_seed_was_empty m n r k H S G target_weight bounded)=>j inside.
 apply (empty j);move:end_i;rewrite /root_count /ph /phases /= number_of_seeds=>->;exact inside.
Qed.

Definition certified_index_level:ident*funspec:=
 DECLARE _cc_run_prepared_level WITH u:unit
 PRE [tptr level_type,tptr (Tstruct _cc_level_policy noattr),tuint]
 PROP((0<=root_count ph<=Int.max_signed)%coqZ) PARAMS(s;nullval;Vint Int.zero) GLOBALS(env)
 SEP(count_field ph s;rest)
 POST [tint] EX i:Z,EX code:Z,
 PROP(exhausted_before ph i;stop_at ph i code;(0<=code<=3)%coqZ;
    code=0%coqZ -> forall x,minimum H G x -> Z.of_nat #|LeafMatrix.support x|<>target_weight)
 RETURN(Vint (Int.repr code)) SEP(after_stop ph i code).

Lemma certified_from_seed_reports:funspec_sub (snd (index_root_call ph s env rest)) (snd certified_index_level).
Proof.
 do_funspec_sub;destruct w;normalize;Exists emp;apply andp_right.
 - entailer!;try cancel.
 - apply prop_right;intro rho;normalize;Exists x x0.
   have outcome:x0=0%coqZ -> forall v,minimum H G v -> Z.of_nat #|LeafMatrix.support v|<>target_weight.
   { move=>zero;subst x0;apply empty_complete_level with (i:=x);assumption. }
   entailer!;try cancel;apply derives_refl.
Qed.

Theorem raw_pcm_prepared_weight:
 (count_field ph s * rest |-- waiting ph 0%coqZ) ->
 let rec_heap:=weight_bounded_rows base stride (Zlength names) heap in
 let calls:=prepared_calls (snd (depth_flip c heap Int.zero))
   (snd (index_dfs_using_globals env admission rec_heap result valid Int.zero)) in
 semax_body prepared_vars calls f_cc_run_prepared_level certified_index_level.
Proof.
 move=>init rec_heap calls;eapply semax_body_funspec_sub.
 - exact (@initialized_index_level c names env s cp bp base stride target_weight heap admission result valid states rest
     init ltac:(rewrite number_of_seeds;exact bounded) ltac:(rewrite number_of_seeds;exact target)
     plain ltac:(rewrite number_of_seeds;exact colroom)
     ltac:(move=>i inside;by rewrite number_of_seeds)
     ltac:(move=>i;rewrite number_of_seeds;apply initialized_seed_admissible)).
 - exact certified_from_seed_reports.
 - apply compute_list_norepet_e;vm_compute;reflexivity.
Qed.
End Certificate.
