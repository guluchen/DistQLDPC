(* Actual core matrix-XOR loop body, with concrete row-major reads and byte
   store. Control-loop/function composition is proved separately. *)
Require Import VST.floyd.proofauto.
Require Import compcert.lib.Maps compcert.common.Events compcert.common.Smallstep compcert.cfrontend.Clight.
Require Import CCV.CCClightReads CCV.CCClightLvalues CCV.CCClightStores
 CCV.CCProtectedByteStores CCV.CCProtectedByteUpdates CCV.CCProtectedFieldReads
 CCV.CCMatrixByteReads CCV.CCByteXorExpressions CCV.CCToggleControl CCV.CCToggleLayout
 CCV.CCTerminateWeight CCV.ccv_core.
Import ListNotations. Open Scope Z_scope.
Definition tb_dest le d target:=PTree.set(ts_dest d)(Vptr(cpa_block target)(cpa_offset target))le.
Definition tb_readptr le d target:=PTree.set(ts_readptr d)(Vptr(cpa_block target)(cpa_offset target))(tb_dest le d target).
Definition tb_old le d target va:=PTree.set(ts_old d)(Vint va)(tb_readptr le d target).
Definition tb_matrixptr le d target va matrix:=PTree.set(ts_matrixptr d)(Vptr(cpa_block matrix)(cpa_offset matrix))(tb_old le d target va).
Definition tb_stride le d target va matrix n:=PTree.set(ts_stride d)(Vint(Int.repr n))(tb_matrixptr le d target va matrix).
Definition tb_bit le d target va matrix n vb:=PTree.set(ts_bit d)(Vint vb)(tb_stride le d target va matrix n).
Ltac tb_different:=match goal with H:ts_supported ?desc|-_=>destruct H as[Eq|Eq];subst desc;discriminate end.
Ltac tb_registers:=unfold tb_bit,tb_stride,tb_matrixptr,tb_old,tb_readptr,tb_dest;
 repeat(first[rewrite PTree.gss|rewrite PTree.gso by tb_different]);first[assumption|reflexivity].
Theorem actual_toggle_scan_body ge bp op bw ow cells areas sources coP coW dp dw d rows n target matrix le m q i k:
 ts_supported d ->ts_data_layout ge bp op bw ow cells coP coW dp dw d rows n target matrix ->
 ts_env le bp op bw ow q i ->0<=n<=Int.max_unsigned ->0<=rows<=Int.max_unsigned ->
 0<=q<n ->0<=rows*n<=Int.max_unsigned ->0<=i<rows ->
 rows<=cpa_size target ->rows*n<=cpa_size matrix ->
 In target areas ->In target sources ->In matrix sources ->
 cp_reads m cells ->cp_writables m areas ->cp_initialized m sources ->cp_separation cells areas ->
 exists le' m',ts_env le' bp op bw ow q i /\cp_reads m' cells /\cp_writables m' areas /\cp_initialized m' sources /\
 star Clight.step2 ge(Clight.State f_toggle(ts_body d)k Clight.empty_env le m)E0
 (Clight.State f_toggle Sskip k Clight.empty_env le' m').
Proof.
 intros Supported Layout Env NR RR QR Product IR TargetSize MatrixSize InTarget InSource InMatrix
 Reads Writable Initialized Apart;pose proof Env as[[P[W Q]]I].
 pose proof Layout as[CompP CompW OffRows OffN OffTarget OffMatrix CellRows CellN CellTarget CellMatrix].
 pose proof(matrix_index_in_array rows n i q IR QR Product)as[IndexRange IndexUnsigned].
 destruct(Initialized target InSource i ltac:(lia))as[va ReadA].
 destruct(Initialized matrix InMatrix(i*n+q)ltac:(lia))as[vb ReadB].
 destruct(protected_byte_value_store m cells areas sources target i(Int.zero_ext 8(Int.xor va vb))
 Reads Writable Initialized Apart InTarget ltac:(lia))as[m'[Store[Reads'[Writable' Initialized']]]].
 exists(tb_bit le d target va matrix n vb),m';split.
 - unfold ts_env,ts_globals;repeat split;tb_registers.
 - split;[exact Reads'|];split;[exact Writable'|];split;[exact Initialized'|].
 unfold ts_body.
 weight_silent_step. apply Clight.step_seq.
 weight_silent_step. eapply Clight.step_set with(v:=Vptr(cpa_block target)(cpa_offset target)).
 { apply(protected_field_eval ge Clight.empty_env le m _w _ccv_workspace(ts_target_field d)(tptr tuchar)
 coW(dw(ts_target_field d))Mptr bw ow(Vptr(cpa_block target)(cpa_offset target))cells);try assumption;reflexivity. }
 weight_silent_step. apply Clight.step_skip_seq.
 weight_silent_step. apply Clight.step_seq.
 weight_silent_step. eapply Clight.step_set with(v:=Vptr(cpa_block target)(cpa_offset target)).
 { apply(protected_field_eval ge Clight.empty_env(tb_dest le d target)m _w _ccv_workspace(ts_target_field d)(tptr tuchar)
 coW(dw(ts_target_field d))Mptr bw ow(Vptr(cpa_block target)(cpa_offset target))cells);try assumption;[tb_registers|reflexivity]. }
 weight_silent_step. apply Clight.step_skip_seq.
 weight_silent_step. apply Clight.step_seq.
 weight_silent_step. eapply Clight.step_set with(v:=Vint va).
 { apply(eval_uchar_index ge Clight.empty_env(tb_readptr le d target)m(ts_readptr d)_i
 (cpa_block target)(cpa_offset target)i va);[tb_registers|tb_registers|lia|exact ReadA]. }
 weight_silent_step. apply Clight.step_skip_seq.
 weight_silent_step. apply Clight.step_seq.
 weight_silent_step. eapply Clight.step_set with(v:=Vptr(cpa_block matrix)(cpa_offset matrix)).
 { apply(protected_field_eval ge Clight.empty_env(tb_old le d target va)m _p _ccv_problem(ts_matrix_field d)(tptr tuchar)
 coP(dp(ts_matrix_field d))Mptr bp op(Vptr(cpa_block matrix)(cpa_offset matrix))cells);try assumption;[tb_registers|reflexivity]. }
 weight_silent_step. apply Clight.step_skip_seq.
 weight_silent_step. apply Clight.step_seq.
 weight_silent_step. eapply Clight.step_set with(v:=Vint(Int.repr n)).
 { apply(protected_field_eval ge Clight.empty_env(tb_matrixptr le d target va matrix)m _p _ccv_problem _n tuint
 coP(dp _n)Mint32 bp op(Vint(Int.repr n))cells);try assumption;[tb_registers|reflexivity]. }
 weight_silent_step. apply Clight.step_skip_seq.
 weight_silent_step. apply Clight.step_seq.
 weight_silent_step. eapply Clight.step_set with(v:=Vint vb).
 { apply(eval_matrix_byte ge Clight.empty_env(tb_stride le d target va matrix n)m(ts_matrixptr d)_i(ts_stride d)_q
 (cpa_block matrix)(cpa_offset matrix)i n q vb);try(tb_registers);try assumption;lia. }
 weight_silent_step. apply Clight.step_skip_seq.
 weight_silent_step. { apply(defined_assignment_step ge f_toggle k Clight.empty_env(tb_bit le d target va matrix n vb)m
 (uchar_index_expr(ts_dest d)_i)(byte_xor_expr(ts_old d)(ts_bit d))(cpa_block target)(cp_position target i)
 Mint8unsigned(Vint(Int.xor va vb))(Vint(Int.zero_ext 8(Int.xor va vb)))m').
 - apply(lvalue_uchar_index ge Clight.empty_env(tb_bit le d target va matrix n vb)m(ts_dest d)_i
 (cpa_block target)(cpa_offset target)i);try(tb_registers);lia.
 - apply(eval_byte_xor ge Clight.empty_env(tb_bit le d target va matrix n vb)m(ts_old d)(ts_bit d)va vb);tb_registers.
 - reflexivity.
 - reflexivity.
 - exact Store. }
 unfold tb_bit,tb_stride,tb_matrixptr,tb_old,tb_readptr,tb_dest;apply star_refl.
Qed.
Print Assumptions actual_toggle_scan_body.
