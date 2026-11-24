(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.floyd.reassoc_seq VerifDetected VerifChildVisit EnabledCall
 OverlapView OverlapSharedBlocks OverlapColumnState SiblingCounters ClightSelect PreparedSeedDispatch
 PreparedChoiceCall PreparedSampling PreparedOwnerFields PreparedSampleOwnerReturn PreparedCallerLocals
 PreparedInitializeScan PreparedSelectedReturn.
Require flag_level_ast.
Import flag_level_ast.
#[local] Existing Instance VerifDetected.CompSpecs.
Local Open Scope Z_scope.

Definition choice_field c cb spec:=
 function_field (field_at Tsh (Tstruct _cc_level_policy noattr) [StructField _choose_children]
    cb (nested_policy (nested c))) cb spec.
Lemma lend_choice_field c cb spec s cp w path st:
 (enabled_memory c s cp w path st * choice_field c cb spec =
    chooser_policy (nested_policy (nested c)) (callback_owner c) cb spec *
    dormant_overlap c s cp w path st)%logic.
Proof.
 unfold enabled_memory,choice_field,dormant_overlap.
 rewrite sepcon_assoc, (borrow_choice_owner c cb spec);apply pred_ext;cancel.
Qed.

Definition before_choice c s child ptr depth bits:=
 choice_loc s (nested_policy (nested c)) ptr depth bits++[temp _children child].
Definition chooser_tail (statement_:statement):=match statement_ with
 | Ssequence choice rest=>andb (invokes_choice choice) (after_choice rest)
 | _=>false end.
Definition choose_search_return:statement:=ltac:(native_fragment chooser_tail f_dfs).

(* The C++ callback owns one candidate row. The index, length, contents,
   overlap context and sample pointer it returns are precisely the input
   to the following C subtree. The owner field is lent only once. *)
Theorem select_actual_candidate_row {Espec:OracleKind} c s child ptr depth bits odd cp w path st cb n P Q
 (frame:mpred):
 Int.and bits Int.one<>Int.zero -> is_pointer_or_null (callback_owner c) -> isptr ptr ->
 let counter:=field_at Tsh level_type [StructField _nodd] (Vint (Int.repr odd)) s in
 let owner:=callback_owner c in let spec:=choose_callback depth odd child n P Q in let fn:=choice_field c cb spec in
 semax (func_tycontext f_dfs prepared_vars [] [])
 (PROPx [] (LOCALx (before_choice c s child ptr depth bits)
   (SEPx [counter;P owner ptr;(enabled_memory c s cp w path st * fn)%logic;frame])))
 choose_count (normal_ret_assert (EX xs:list Z, PROPx [Zlength xs<=Int.max_signed;NoDup xs;in_array n xs]
  (LOCALx (chosen_loc c s child depth (Zlength xs) bits ptr)
    (SEPx [counter;child_array child xs;Q owner ptr xs;(enabled_memory c s cp w path st * fn)%logic;frame])))).
Proof.
 intros use own live counter owner spec fn.
 pose (policy:=chooser_policy (nested_policy (nested c)) owner cb spec).
 pose (rest:=(dormant_overlap c s cp w path st * frame)%logic).
 pose (loc:=choice_loc s (nested_policy (nested c)) ptr depth bits).
 pose (save:=[temp _children child]).
 assert (stable:closed_wrt_modvars choose_count (LOCALx save (SEPx [])))
    by (unfold choose_count,save;auto 100 with closed).
 pose proof (@keep_caller_locals_for_answer (list Z) Espec VerifDetected.CompSpecs
  (func_tycontext f_dfs prepared_vars [] []) choose_count [] loc
  [counter;policy;P owner ptr;rest] save [] (fun xs=>[Zlength xs<=Int.max_signed;NoDup xs;in_array n xs])
  (fun xs=>temp _count (Vint (Int.repr (Zlength xs)))::loc)
  (fun xs=>[counter;policy;child_array child xs;Q owner ptr xs;rest]) stable
  (@choose_from_owner Espec s (nested_policy (nested c)) owner cb ptr depth odd bits child n P Q rest use own live)) as select_row.
 eapply semax_post'.
 2:{ eapply semax_pre;[|exact select_row];unfold before_choice,fn;rewrite lend_choice_field.
     unfold save,loc,policy,rest,choice_loc;cbn [app];entailer!;try cancel;apply derives_refl. }
 Intros xs;Exists xs;unfold chosen_loc,fn;rewrite lend_choice_field.
 unfold save,loc,policy,rest,choice_loc;cbn [app];entailer!;try cancel;apply derives_refl.
Qed.

Theorem from_policy_choice {Espec:OracleKind} D pre (middle:environ->mpred) post:
 semax D pre choose_count (normal_ret_assert middle) -> semax D middle selected_subtree post ->
 semax D pre choose_search_return post.
Proof. intros pick use;change choose_search_return with (Ssequence choose_count selected_subtree);eapply semax_seq';eassumption. Qed.
