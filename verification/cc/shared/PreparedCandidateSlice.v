(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VerifDetected ClightSelect PreparedSeedDispatch.
Require flag_level_ast.
Import flag_level_ast.
#[local] Existing Instance VerifDetected.CompSpecs.
Local Open Scope Z_scope.

Definition read_candidates (s:statement):=match s with
 | Ssequence (Sset _ (Efield _ fld _)) (Ssequence _ (Sset dest _)) =>andb (Pos.eqb fld _cand) (Pos.eqb dest _children)
 | _=>false end.
Definition child_slice:statement:=ltac:(native_fragment read_candidates f_dfs).
Definition candidate_fields s base stride:=
 (field_at Tsh level_type [StructField _cand] base s *
  field_at Tsh level_type [StructField _maxrow] (Vint (Int.repr stride)) s)%logic.

Lemma word_offset_fits depth stride: 0<=depth<=Int.max_signed -> 0<=stride<=Int.max_signed ->
 0<=4*(depth*stride)<=Ptrofs.max_unsigned.
Proof. change Int.max_signed with 2147483647;change Ptrofs.max_unsigned with 18446744073709551615;nia. Qed.

Theorem actual_child_slice {Espec:OracleKind} s base stride depth (frame:mpred):
 0<=depth<=Int.max_signed -> 0<=stride<=Int.max_signed -> isptr base ->
 semax (func_tycontext f_dfs prepared_vars [] [])
 (PROP() LOCAL(temp _s s;temp _size (Vint (Int.repr depth))) SEP(candidate_fields s base stride;frame))
 child_slice (normal_ret_assert (PROP()
  LOCAL(temp _children (offset_val (4*(depth*stride)) base);temp _s s;temp _size (Vint (Int.repr depth)))
  SEP(candidate_fields s base stride;frame))).
Proof.
 intros d k ptr;unfold child_slice,candidate_fields;abbreviate_semax;Intros.
 do 3 forward;entailer!;destruct base;try contradiction;cbn;f_equal.
Qed.

(* Only the indexed prefix is borrowed by a recursive frame. Adjacent
   call depths cannot overwrite each other's candidates. *)
Lemma disjoint_live_slices d e stride count_d count_e:
 0<=d<e -> 0<=count_d<=stride -> 0<=count_e<=stride ->
 forall i j,0<=i<count_d -> 0<=j<count_e -> d*stride+i<e*stride+j.
Proof. intros;nia. Qed.
