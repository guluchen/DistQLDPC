(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.floyd.reassoc_seq VerifDetected VerifChildVisit EnabledCall
 ClightSelect PreparedSeedDispatch PreparedSampling PreparedCandidateSlice PreparedCandidateArena
 PreparedChoiceCall PreparedChooseReturn.
Require flag_level_ast.
Import flag_level_ast.
#[local] Existing Instance VerifDetected.CompSpecs.
Local Open Scope Z_scope.

Definition nonterminal_search:statement:=ltac:(native_fragment sample_prefix f_dfs).
Definition sample_and_slice:=Ssequence init_sample child_slice.
Lemma interior_code_is_contiguous P Q D {Espec:OracleKind}:
 semax D P (Ssequence sample_and_slice choose_search_return) Q -> semax D P nonterminal_search Q.
Proof.
 intros search;apply (semax_unfold_seq (Ssequence sample_and_slice choose_search_return) nonterminal_search eq_refl);exact search.
Qed.

(* Before the first choice, the local record is uninitialized and the
   depth-specific candidate pointer has not been computed. Relate both
   to the actual C objects, keeping their neighboring memory as a frame. *)
Theorem set_up_nonterminal_frame {Espec:OracleKind} c s base stride depth bits ptr (frame:mpred):
 0<=depth<=Int.max_signed -> 0<=stride<=Int.max_signed -> isptr base ->
 let p:=nested_policy (nested c) in
 semax (func_tycontext f_dfs prepared_vars [] [])
 (PROP() LOCAL(temp _s s;temp _size (Vint (Int.repr depth));temp _options (Vint bits);temp _policy p;
    lvar _sample sample_type ptr) SEP(data_at_ Tsh sample_type ptr;candidate_fields s base stride;frame))
 sample_and_slice (normal_ret_assert (PROPx [] (LOCALx (before_choice c s (row_pointer base stride depth) ptr depth bits)
   (SEPx [sample_data ptr (Int.repr (-1)) Float.zero Float.zero;candidate_fields s base stride;frame])))).
Proof.
 intros bound step live p;unfold sample_and_slice,init_sample,child_slice,sample_data,sample_type,
     candidate_fields,before_choice,choice_loc,row_pointer;cbn [app];abbreviate_semax;reassoc_seq.
 Intros;do 6 forward;entailer!;destruct base;try contradiction;cbn;f_equal.
Qed.

(* The continuation starts with the borrowing protocol for the actual
   policy and the scratch row at the current depth. An early return or
   recursive branch in that continuation uses the caller's postcondition. *)
Theorem nonterminal_entry_from_stack {Espec:OracleKind} D c s base stride depth bits ptr (frame:mpred) R:
 tycontext_sub (func_tycontext f_dfs prepared_vars [] []) D ->
 0<=depth<=Int.max_signed -> 0<=stride<=Int.max_signed -> isptr base ->
 semax D (PROPx [] (LOCALx (before_choice c s (row_pointer base stride depth) ptr depth bits)
   (SEPx [sample_data ptr (Int.repr (-1)) Float.zero Float.zero;candidate_fields s base stride;frame])))
   choose_search_return R ->
 semax D
 (PROP() LOCAL(temp _s s;temp _size (Vint (Int.repr depth));temp _options (Vint bits);
    temp _policy (nested_policy (nested c));lvar _sample sample_type ptr)
   SEP(data_at_ Tsh sample_type ptr;candidate_fields s base stride;frame)) nonterminal_search R.
Proof.
 intros bigger bound step live cont;apply interior_code_is_contiguous;eapply semax_seq';[|exact cont].
 eapply semax_Delta_subsumption;[exact bigger|apply set_up_nonterminal_frame;assumption].
Qed.
