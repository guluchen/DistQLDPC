(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.floyd.reassoc_seq VerifDetected VerifEpoch EpochFreshness
 VerifLowestBit PreparedIndexFinish PreparedArenaContext flag_level_ast.
#[local] Existing Instance VerifDetected.CompSpecs.
Local Open Scope Z_scope.

Definition index_calls:funspecs:=ltac:(with_library flag_level_ast.prog [next_tag_spec;lowest_spec]).
Lemma bit_context_in_chooser:
 tycontext_sub (func_tycontext f_index_children Vprog LowGprog [])
               (func_tycontext f_index_children Vprog index_calls []).
Proof.
 apply tycontext_sub_i99;split;[variable_map_sub|].
 compare_function_maps LowGprog index_calls.
 repeat (apply Forall_cons;[apply subsumespec_refl|]);apply Forall_nil.
Qed.

Definition begin_index:statement:=ltac:(
 let body:=eval cbv beta iota zeta delta [fn_body f_index_children] in (fn_body f_index_children) in
 lazymatch body with
 | Ssequence ?call (Ssequence ?store (Ssequence ?packed (Ssequence ?branch _))) =>
     exact (Ssequence call (Ssequence store (Ssequence packed branch)))
 end).
Lemma index_sections {Espec:OracleKind} D P Q R :
 semax D P begin_index (normal_ret_assert Q) ->
 semax D Q scan_then_emit R -> semax D P (fn_body f_index_children) R.
Proof.
 intros init scan;apply (semax_unfold_seq (Ssequence begin_index scan_then_emit) (fn_body f_index_children) eq_refl).
 eapply semax_seq';eassumption.
Qed.

Definition counters_header s n stamp:=
 (field_at Tsh level_type [StructField _n] (Vint (Int.repr n)) s *
  field_at Tsh level_type [StructField _stamp] (Vlong stamp) s)%logic.
Definition tag_storage s mp tags:=
 (field_at Tsh level_type [StructField _mark] mp s *
  data_at Tsh (tarray tulong (Zlength tags)) (map Vlong tags) mp)%logic.
Definition index_locals gv s children dep:=
 [temp _s s;temp _children children;temp _size (Vint (Int.repr dep));gvars gv].
Definition started_regs stamp:=
 [temp _stamp (Vlong stamp);temp _packed (Vint Int.zero);temp _branch (Vint (Int.repr (-1)))].

Theorem begin_index_at_epoch {Espec:OracleKind} s mp old last gv children dep :
 let n:=Zlength old in let stamp:=Int64.repr (advance_tag false (Int64.unsigned last)) in
 let ms:=after_tags false (Int64.unsigned last) old in
 0<n<=Int.max_signed ->
 semax (func_tycontext f_index_children Vprog index_calls [])
 (PROPx [] (LOCALx (index_locals gv s children dep) (SEPx [counters_header s n last;tag_storage s mp old])))
 begin_index (normal_ret_assert (PROPx [] (LOCALx (started_regs stamp++index_locals gv s children dep)
   (SEPx [counters_header s n stamp;tag_storage s mp ms])))).
Proof.
 intros n stamp ms positive;unfold begin_index,index_locals,started_regs,counters_header,tag_storage.
 cbn [app];abbreviate_semax;reassoc_seq;Intros.
 assert_PROP (is_pointer_or_null mp) as valid_marks by entailer!.
 forward.
 forward.
 forward.
 rewrite <-(Int64.repr_unsigned last) at 1.
 forward_call (Int64.unsigned last,mp,old).
 - unfold n in *;rewrite parity_storage_nonempty by lia;entailer!;try rep_lia.
 - rewrite parity_storage_nonempty by (rewrite after_length;lia).
   do 4 forward;entailer!;try apply derives_refl.
Qed.
