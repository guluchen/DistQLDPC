(* Concrete immutable metadata for the two actual matrix XOR scans. *)
Require Import VST.floyd.proofauto.
Require Import compcert.lib.Maps compcert.cfrontend.Clight.
Require Import CCV.CCClightReads CCV.CCProtectedByteStores CCV.CCProtectedFieldReads CCV.CCToggleControl CCV.ccv_core.
Import ListNotations. Open Scope Z_scope.
Definition ts_globals le bp op bw ow q:Prop:=
 PTree.get _p le=Some(Vptr bp op) /\PTree.get _w le=Some(Vptr bw ow) /\PTree.get _q le=Some(Vint(Int.repr q)).
Definition ts_env le bp op bw ow q i:Prop:=ts_globals le bp op bw ow q /\PTree.get _i le=Some(Vint(Int.repr i)).
Definition ts_supported d:Prop:=d=syndrome_scan \/d=logical_scan.
Definition ts_scratch d:list ident:=
 [ts_bound d;ts_dest d;ts_readptr d;ts_old d;ts_matrixptr d;ts_stride d;ts_bit d].
Record ts_data_layout(ge:Clight.genv)(bp:block)(op:ptrofs)(bw:block)(ow:ptrofs)
 (cells:list protected_read_cell)(coP coW:composite)(dp dw:ident->Z)
 (d:toggle_scan_descriptor)(rows n:Z)(target matrix:writable_byte_area):Prop:={
 tdl_problem:PTree.get _ccv_problem(Clight.genv_cenv ge)=Some coP;
 tdl_workspace:PTree.get _ccv_workspace(Clight.genv_cenv ge)=Some coW;
 tdl_rows_offset:Ctypes.field_offset ge(ts_rows d)(co_members coP)=Errors.OK(dp(ts_rows d),Full);
 tdl_stride_offset:Ctypes.field_offset ge _n(co_members coP)=Errors.OK(dp _n,Full);
 tdl_target_offset:Ctypes.field_offset ge(ts_target_field d)(co_members coW)=Errors.OK(dw(ts_target_field d),Full);
 tdl_matrix_offset:Ctypes.field_offset ge(ts_matrix_field d)(co_members coP)=Errors.OK(dp(ts_matrix_field d),Full);
 tdl_rows_cell:In {|cpr_chunk:=Mint32;cpr_block:=bp;cpr_offset:=Ptrofs.add op(Ptrofs.repr(dp(ts_rows d)));cpr_value:=Vint(Int.repr rows)|}cells;
 tdl_stride_cell:In {|cpr_chunk:=Mint32;cpr_block:=bp;cpr_offset:=Ptrofs.add op(Ptrofs.repr(dp _n));cpr_value:=Vint(Int.repr n)|}cells;
 tdl_target_cell:In {|cpr_chunk:=Mptr;cpr_block:=bw;cpr_offset:=Ptrofs.add ow(Ptrofs.repr(dw(ts_target_field d)));cpr_value:=Vptr(cpa_block target)(cpa_offset target)|}cells;
 tdl_matrix_cell:In {|cpr_chunk:=Mptr;cpr_block:=bp;cpr_offset:=Ptrofs.add op(Ptrofs.repr(dp(ts_matrix_field d)));cpr_value:=Vptr(cpa_block matrix)(cpa_offset matrix)|}cells
}.
Lemma ts_scratch_nonargs d r:ts_supported d ->In r(ts_scratch d) ->
 r<>_p /\r<>_w /\r<>_q /\r<>_i.
Proof.
 intros[Eq|Eq]Member;subst d;vm_compute in *;intuition congruence.
Qed.
Lemma ts_scratch_env le bp op bw ow q i d r v:
 ts_supported d ->In r(ts_scratch d) ->ts_env le bp op bw ow q i ->
 ts_env(PTree.set r v le)bp op bw ow q i.
Proof.
 intros Supported Member[[P[W Q]]I];destruct(ts_scratch_nonargs d r Supported Member)as[NP[NW[NQ NI]]].
 unfold ts_env,ts_globals;rewrite !PTree.gso by congruence;repeat split;assumption.
Qed.
Lemma ts_layout_field_evaluations ge bp op bw ow cells coP coW dp dw d rows n target matrix le m q i:
 ts_data_layout ge bp op bw ow cells coP coW dp dw d rows n target matrix ->
 cp_reads m cells ->ts_env le bp op bw ow q i ->
 Clight.eval_expr ge Clight.empty_env le m(struct_field_expr _p _ccv_problem(ts_rows d)tuint)(Vint(Int.repr rows)) /\
 Clight.eval_expr ge Clight.empty_env le m(struct_field_expr _p _ccv_problem _n tuint)(Vint(Int.repr n)) /\
 Clight.eval_expr ge Clight.empty_env le m(ts_target d)(Vptr(cpa_block target)(cpa_offset target)) /\
 Clight.eval_expr ge Clight.empty_env le m(ts_matrix d)(Vptr(cpa_block matrix)(cpa_offset matrix)).
Proof.
 intros[Problem Workspace RowOffset StrideOffset TargetOffset MatrixOffset RowCell StrideCell TargetCell MatrixCell]
 Reads[[P[W Q]]I];split.
 - apply(protected_field_eval ge Clight.empty_env le m _p _ccv_problem(ts_rows d)tuint coP(dp(ts_rows d))Mint32
 bp op(Vint(Int.repr rows))cells);try assumption;reflexivity.
 - split.
   + apply(protected_field_eval ge Clight.empty_env le m _p _ccv_problem _n tuint coP(dp _n)Mint32
     bp op(Vint(Int.repr n))cells);try assumption;reflexivity.
   + split.
     * apply(protected_field_eval ge Clight.empty_env le m _w _ccv_workspace(ts_target_field d)(tptr tuchar)
       coW(dw(ts_target_field d))Mptr bw ow(Vptr(cpa_block target)(cpa_offset target))cells);try assumption;reflexivity.
     * apply(protected_field_eval ge Clight.empty_env le m _p _ccv_problem(ts_matrix_field d)(tptr tuchar)
       coP(dp(ts_matrix_field d))Mptr bp op(Vptr(cpa_block matrix)(cpa_offset matrix))cells);try assumption;reflexivity.
Qed.
Print Assumptions ts_layout_field_evaluations.
