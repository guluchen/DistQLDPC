(* Guard, body and increment of the two actual matrix-XOR scans. *)
Require Import VST.floyd.proofauto Coq.Arith.Wf_nat.
Require Import compcert.lib.Maps compcert.common.Events compcert.common.Smallstep compcert.cfrontend.Clight.
Require Import CCV.CCClightReads CCV.CCProtectedByteStores CCV.CCProtectedByteUpdates
 CCV.CCToggleControl CCV.CCToggleLayout CCV.CCToggleBody CCV.CCTerminateWeight CCV.ccv_core.
Import ListNotations. Open Scope Z_scope.
Lemma ts_increment_env le bp op bw ow q i:
 ts_env le bp op bw ow q i ->ts_env(PTree.set _i(Vint(Int.repr(i+1)))le)bp op bw ow q(i+1).
Proof.
 intros[[P[W Q]]I];unfold ts_env,ts_globals;
 repeat(first[rewrite PTree.gss|rewrite PTree.gso by discriminate]);repeat split;assumption.
Qed.
Lemma ts_increment_step ge le m k bp op bw ow q i:
 ts_env le bp op bw ow q i ->0<=i<Int.max_unsigned ->
 Clight.step2 ge(Clight.State f_toggle weight_increment k Clight.empty_env le m)E0
 (Clight.State f_toggle Sskip k Clight.empty_env(PTree.set _i(Vint(Int.repr(i+1)))le)m).
Proof.
 intros[[P[W Q]]I]Range;unfold Clight.step2,weight_increment.
 eapply Clight.step_set with(v:=Vint(Int.repr(i+1))).
 eapply Clight.eval_Ebinop with(v1:=Vint(Int.repr i))(v2:=Vint(Int.repr 1)).
 - apply Clight.eval_Etempvar;exact I.
 - apply Clight.eval_Econst_int.
 - change(Some(Vint(Int.add(Int.repr i)(Int.repr 1)))=Some(Vint(Int.repr(i+1)))).
   unfold Int.add;rewrite !Int.unsigned_repr by rep_lia;reflexivity.
Qed.
Lemma ts_probe_path ge bp op bw ow cells coP coW dp dw d rows n target matrix le m q i k:
 ts_data_layout ge bp op bw ow cells coP coW dp dw d rows n target matrix ->
 cp_reads m cells ->ts_env le bp op bw ow q i ->
 star Clight.step2 ge(Clight.State f_toggle(ts_loop d)k Clight.empty_env le m)E0
 (Clight.State f_toggle(Sifthenelse(uint_lt_expr _i(ts_bound d))Sskip Sbreak)
 (Kseq(ts_body d)(Kloop1(ts_iteration d)weight_increment k))Clight.empty_env
 (PTree.set(ts_bound d)(Vint(Int.repr rows))le)m).
Proof.
 intros Layout Reads Env.
 destruct(ts_layout_field_evaluations ge bp op bw ow cells coP coW dp dw d rows n target matrix le m q i
 Layout Reads Env)as[Rows Rest].
 unfold ts_loop,ts_iteration.
 weight_silent_step. apply Clight.step_loop.
 weight_silent_step. apply Clight.step_seq.
 weight_silent_step. apply Clight.step_seq.
 weight_silent_step. eapply Clight.step_set with(v:=Vint(Int.repr rows));exact Rows.
 weight_silent_step. apply Clight.step_skip_seq.
 apply star_refl.
Qed.
Lemma ts_guard_eval ge le m bp op bw ow q i d rows(flag:bool):
 ts_supported d ->ts_env le bp op bw ow q i ->0<=i<=Int.max_unsigned ->0<=rows<=Int.max_unsigned ->
 (if flag then i<rows else rows<=i) ->
 Clight.eval_expr ge Clight.empty_env(PTree.set(ts_bound d)(Vint(Int.repr rows))le)m
 (uint_lt_expr _i(ts_bound d))(Vint(if flag then Int.one else Int.zero)).
Proof.
 intros Supported[[P[W Q]]I]IR RR Order.
 destruct(ts_scratch_nonargs d(ts_bound d)Supported(or_introl eq_refl))as[NP[NW[NQ NI]]].
 apply(eval_uint_lt ge Clight.empty_env(PTree.set(ts_bound d)(Vint(Int.repr rows))le)m _i(ts_bound d)i rows flag);
 try assumption;[rewrite PTree.gso by congruence;exact I|apply PTree.gss].
Qed.
Theorem ts_continue_path ge bp op bw ow cells areas sources coP coW dp dw d rows n target matrix le m q i k:
 ts_supported d ->ts_data_layout ge bp op bw ow cells coP coW dp dw d rows n target matrix ->
 ts_env le bp op bw ow q i ->0<=n<=Int.max_unsigned ->0<=rows<=Int.max_unsigned ->
 0<=q<n ->0<=rows*n<=Int.max_unsigned ->0<=i<rows ->
 rows<=cpa_size target ->rows*n<=cpa_size matrix ->
 In target areas ->In target sources ->In matrix sources ->
 cp_reads m cells ->cp_writables m areas ->cp_initialized m sources ->cp_separation cells areas ->
 exists le' m',ts_env le' bp op bw ow q(i+1) /\cp_reads m' cells /\cp_writables m' areas /\cp_initialized m' sources /\
 star Clight.step2 ge(Clight.State f_toggle(ts_loop d)k Clight.empty_env le m)E0
 (Clight.State f_toggle(ts_loop d)k Clight.empty_env le' m').
Proof.
 intros Supported Layout Env NR RR QR Product IR TargetSize MatrixSize InTarget InSource InMatrix
 Reads Writable Initialized Apart.
 pose proof(ts_scratch_env le bp op bw ow q i d(ts_bound d)(Vint(Int.repr rows))Supported(or_introl eq_refl)Env)as BoundEnv.
 destruct(actual_toggle_scan_body ge bp op bw ow cells areas sources coP coW dp dw d rows n target matrix
 (PTree.set(ts_bound d)(Vint(Int.repr rows))le)m q i(Kloop1(ts_iteration d)weight_increment k)
 Supported Layout BoundEnv NR RR QR Product IR TargetSize MatrixSize InTarget InSource InMatrix
 Reads Writable Initialized Apart)as[le1[m1[Env1[Reads1[Writable1[Initialized1 Body]]]]]].
 exists(PTree.set _i(Vint(Int.repr(i+1)))le1),m1;split;[apply ts_increment_env;exact Env1|].
 split;[exact Reads1|];split;[exact Writable1|];split;[exact Initialized1|].
 eapply star_trans.
 - apply(ts_probe_path ge bp op bw ow cells coP coW dp dw d rows n target matrix le m q i k);assumption.
 - weight_silent_step. { eapply Clight.step_ifthenelse with(v1:=Vint Int.one)(b:=true).
   + apply(ts_guard_eval ge le m bp op bw ow q i d rows true);try assumption;lia.
   + reflexivity. }
   weight_silent_step. apply Clight.step_skip_seq.
   eapply star_trans;[exact Body| |reflexivity].
   weight_silent_step. apply Clight.step_skip_or_continue_loop1;left;reflexivity.
   eapply star_step with(t1:=E0)(t2:=E0).
   + apply(ts_increment_step ge le1 m1 _ bp op bw ow q i Env1);lia.
   + weight_silent_step. apply Clight.step_skip_loop2.
     apply star_refl.
   + reflexivity.
 - reflexivity.
Qed.
Lemma ts_exit_path ge bp op bw ow cells coP coW dp dw d rows n target matrix le m q i k:
 ts_supported d ->ts_data_layout ge bp op bw ow cells coP coW dp dw d rows n target matrix ->
 ts_env le bp op bw ow q i ->0<=i<=Int.max_unsigned ->0<=rows<=Int.max_unsigned ->rows<=i ->cp_reads m cells ->
 star Clight.step2 ge(Clight.State f_toggle(ts_loop d)k Clight.empty_env le m)E0
 (Clight.State f_toggle Sskip k Clight.empty_env(PTree.set(ts_bound d)(Vint(Int.repr rows))le)m).
Proof.
 intros Supported Layout Env IR RR Done Reads.
 eapply star_trans.
 - apply(ts_probe_path ge bp op bw ow cells coP coW dp dw d rows n target matrix le m q i k);assumption.
 - weight_silent_step. { eapply Clight.step_ifthenelse with(v1:=Vint Int.zero)(b:=false).
   + apply(ts_guard_eval ge le m bp op bw ow q i d rows false);assumption.
   + reflexivity. }
   weight_silent_step. apply Clight.step_break_seq.
   weight_silent_step. apply Clight.step_break_loop1.
   apply star_refl.
 - reflexivity.
Qed.
Print Assumptions ts_continue_path.
Theorem ts_loop_terminates ge bp op bw ow cells areas sources coP coW dp dw d rows n target matrix q:
 ts_supported d ->ts_data_layout ge bp op bw ow cells coP coW dp dw d rows n target matrix ->
 0<=n<=Int.max_unsigned ->0<=rows<=Int.max_unsigned ->0<=q<n ->0<=rows*n<=Int.max_unsigned ->
 rows<=cpa_size target ->rows*n<=cpa_size matrix ->In target areas ->In target sources ->In matrix sources ->
 forall i,0<=i<=rows ->forall le m k,ts_env le bp op bw ow q i ->
 cp_reads m cells ->cp_writables m areas ->cp_initialized m sources ->cp_separation cells areas ->
 exists le' m',ts_env le' bp op bw ow q rows /\cp_reads m' cells /\cp_writables m' areas /\cp_initialized m' sources /\
 star Clight.step2 ge(Clight.State f_toggle(ts_loop d)k Clight.empty_env le m)E0
 (Clight.State f_toggle Sskip k Clight.empty_env le' m').
Proof.
 intros Supported Layout NR RR QR Product TargetSize MatrixSize InTarget InSource InMatrix.
 refine(well_founded_induction_type(well_founded_ltof Z(fun j=>Z.to_nat(rows-j))) _ _).
 intros i IH Range le m k Env Reads Writable Initialized Apart;destruct(Z_lt_dec i rows)as[Less|Done].
 - destruct(ts_continue_path ge bp op bw ow cells areas sources coP coW dp dw d rows n target matrix le m q i k
 Supported Layout Env NR RR QR Product ltac:(lia)TargetSize MatrixSize InTarget InSource InMatrix
 Reads Writable Initialized Apart)as[le1[m1[Env1[Reads1[Writable1[Initialized1 Prefix]]]]]].
 assert(Decrease:(Z.to_nat(rows-(i+1))<Z.to_nat(rows-i))%nat)by(apply Z2Nat.inj_lt;lia).
 destruct(IH(i+1)Decrease ltac:(lia)le1 m1 k Env1 Reads1 Writable1 Initialized1 Apart)
 as[le2[m2[Env2[Reads2[Writable2[Initialized2 Tail]]]]]].
 exists le2,m2;split;[exact Env2|];split;[exact Reads2|];split;[exact Writable2|];split;[exact Initialized2|].
 eapply star_trans;[exact Prefix|exact Tail|reflexivity].
 - assert(Eq:i=rows)by lia;subst i.
 exists(PTree.set(ts_bound d)(Vint(Int.repr rows))le),m;split.
 + apply(ts_scratch_env le bp op bw ow q rows d(ts_bound d)(Vint(Int.repr rows))Supported(or_introl eq_refl)Env).
 + split;[exact Reads|];split;[exact Writable|];split;[exact Initialized|].
   apply(ts_exit_path ge bp op bw ow cells coP coW dp dw d rows n target matrix le m q rows k);try assumption;lia.
Qed.
Lemma ts_env_globals le bp op bw ow q i:ts_env le bp op bw ow q i ->ts_globals le bp op bw ow q.
Proof. intros[Globals I];exact Globals. Qed.
Lemma ts_zero_index le bp op bw ow q:
 ts_globals le bp op bw ow q ->ts_env(PTree.set _i(Vint Int.zero)le)bp op bw ow q 0.
Proof.
 intros[P[W Q]];unfold ts_env,ts_globals;
 repeat(first[rewrite PTree.gss|rewrite PTree.gso by discriminate]);repeat split;assumption.
Qed.
Theorem ts_stage_terminates ge bp op bw ow cells areas sources coP coW dp dw d rows n target matrix q le m k:
 ts_supported d ->ts_data_layout ge bp op bw ow cells coP coW dp dw d rows n target matrix ->
 0<=n<=Int.max_unsigned ->0<=rows<=Int.max_unsigned ->0<=q<n ->0<=rows*n<=Int.max_unsigned ->
 rows<=cpa_size target ->rows*n<=cpa_size matrix ->In target areas ->In target sources ->In matrix sources ->
 ts_globals le bp op bw ow q ->cp_reads m cells ->cp_writables m areas ->cp_initialized m sources ->cp_separation cells areas ->
 exists le' m',ts_env le' bp op bw ow q rows /\cp_reads m' cells /\cp_writables m' areas /\cp_initialized m' sources /\
 star Clight.step2 ge(Clight.State f_toggle(ts_stage d)k Clight.empty_env le m)E0
 (Clight.State f_toggle Sskip k Clight.empty_env le' m').
Proof.
 intros Supported Layout NR RR QR Product TargetSize MatrixSize InTarget InSource InMatrix Globals Reads Writable Initialized Apart.
 destruct(ts_loop_terminates ge bp op bw ow cells areas sources coP coW dp dw d rows n target matrix q
 Supported Layout NR RR QR Product TargetSize MatrixSize InTarget InSource InMatrix 0 ltac:(lia)
 (PTree.set _i(Vint Int.zero)le)m k(ts_zero_index le bp op bw ow q Globals)Reads Writable Initialized Apart)
 as[le'[m'[Env'[Reads'[Writable'[Initialized' Loop]]]]]].
 exists le',m';split;[exact Env'|];split;[exact Reads'|];split;[exact Writable'|];split;[exact Initialized'|].
 unfold ts_stage.
 weight_silent_step. apply Clight.step_seq.
 weight_silent_step. apply Clight.step_set;apply Clight.eval_Econst_int.
 weight_silent_step. apply Clight.step_skip_seq.
 exact Loop.
Qed.
Print Assumptions ts_loop_terminates.
Print Assumptions ts_stage_terminates.
