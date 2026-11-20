(* Syntax-preserving templates for the actual core-toggle selected-bit update
   and the two row-major matrix XOR scans. No whole-function totality yet. *)
Require Import VST.floyd.proofauto.
Require Import compcert.lib.Maps compcert.cfrontend.Clight.
Require Import CCV.CCClightReads CCV.CCMatrixByteReads CCV.CCByteXorExpressions
 CCV.CCTerminateWeight CCV.ccv_core.
Import ListNotations. Open Scope Z_scope.
Record toggle_scan_descriptor:Type:={
 ts_rows:ident;ts_target_field:ident;ts_matrix_field:ident;
 ts_bound:ident;ts_dest:ident;ts_readptr:ident;ts_old:ident;
 ts_matrixptr:ident;ts_stride:ident;ts_bit:ident}.
Definition ts_target d:=struct_field_expr _w _ccv_workspace(ts_target_field d)(tptr tuchar).
Definition ts_matrix d:=struct_field_expr _p _ccv_problem(ts_matrix_field d)(tptr tuchar).
Definition ts_body d:=Ssequence(Sset(ts_dest d)(ts_target d))
 (Ssequence(Sset(ts_readptr d)(ts_target d))
 (Ssequence(Sset(ts_old d)(uchar_index_expr(ts_readptr d)_i))
 (Ssequence(Sset(ts_matrixptr d)(ts_matrix d))
 (Ssequence(Sset(ts_stride d)(struct_field_expr _p _ccv_problem _n tuint))
 (Ssequence(Sset(ts_bit d)(matrix_byte_expr(ts_matrixptr d)_i(ts_stride d)_q))
 (Sassign(uchar_index_expr(ts_dest d)_i)(byte_xor_expr(ts_old d)(ts_bit d)))))))).
Definition ts_iteration d:=Ssequence
 (Ssequence(Sset(ts_bound d)(struct_field_expr _p _ccv_problem(ts_rows d)tuint))
 (Sifthenelse(uint_lt_expr _i(ts_bound d))Sskip Sbreak))(ts_body d).
Definition ts_loop d:=Sloop(ts_iteration d)weight_increment.
Definition ts_stage d:=Ssequence(Sset _i(Econst_int(Int.repr 0)tuint))(ts_loop d).
Definition syndrome_scan:toggle_scan_descriptor:={|
 ts_rows:=_checks;ts_target_field:=_syndrome;ts_matrix_field:=_h;
 ts_bound:=_t'14;ts_dest:=_t'8;ts_readptr:=_t'9;ts_old:=_t'10;
 ts_matrixptr:=_t'11;ts_stride:=_t'12;ts_bit:=_t'13|}.
Definition logical_scan:toggle_scan_descriptor:={|
 ts_rows:=_logical_rows;ts_target_field:=_logical_value;ts_matrix_field:=_logical;
 ts_bound:=_t'7;ts_dest:=_t'1;ts_readptr:=_t'2;ts_old:=_t'3;
 ts_matrixptr:=_t'4;ts_stride:=_t'5;ts_bit:=_t'6|}.
Definition toggle_selected:=Ssequence
 (Sset _t'15(struct_field_expr _w _ccv_workspace _selected(tptr tuchar)))
 (Ssequence(Sset _t'16(struct_field_expr _w _ccv_workspace _selected(tptr tuchar)))
 (Ssequence(Sset _t'17(uchar_index_expr _t'16 _q))
 (Sassign(uchar_index_expr _t'15 _q)(byte_flip_expr _t'17)))).
Lemma actual_toggle_two_scans:fn_body f_toggle=
 Ssequence toggle_selected(Ssequence(ts_stage syndrome_scan)(ts_stage logical_scan)).
Proof. reflexivity. Qed.
Definition ts_identifiers d:list ident:=
 [_p;_w;_q;_i;ts_bound d;ts_dest d;ts_readptr d;ts_old d;ts_matrixptr d;ts_stride d;ts_bit d].
Lemma syndrome_scan_distinct:list_norepet(ts_identifiers syndrome_scan).
Proof. vm_compute;repeat(apply list_norepet_cons;[simpl;intuition congruence|]);apply list_norepet_nil. Qed.
Lemma logical_scan_distinct:list_norepet(ts_identifiers logical_scan).
Proof. vm_compute;repeat(apply list_norepet_cons;[simpl;intuition congruence|]);apply list_norepet_nil. Qed.
Print Assumptions actual_toggle_two_scans.
