(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.floyd.reassoc_seq.
Require Import VerifDetected PreparedSeedDispatch PreparedChildCall PreparedSiblingRestore
 PreparedSampling PreparedReturnTrace ClightSelect.
Require flag_level_ast.
Import flag_level_ast.
#[local] Existing Instance VerifDetected.CompSpecs.
Local Open Scope Z_scope.

(* Identify the entire suffix in the Clight source, starting at the
   child loop. This equality checks that no statement between the
   loops and the return was dropped during decomposition. *)
Definition from_children (s:statement):=match s with
 | Ssequence outer (Ssequence undo rest) =>
    andb (counts_on _i outer) (andb (counts_on _i__1 undo) (returning_scan rest))
 | _=>false end.
Definition search_finish:statement:=ltac:(native_fragment from_children f_dfs).
Lemma suffix_code:search_finish = Ssequence search_children (Ssequence undo_children finish_scan).
Proof. reflexivity. Qed.

Lemma select_ret_assert {A:Type} {Espec:OracleKind} D pre c (posts:A->ret_assert) (a:A):
 semax D pre c (posts a) -> semax D pre c (existential_ret_assert posts).
Proof.
 intro proven;eapply semax_post_flipped;[exact proven| | | |];
   try match goal with |- forall vl:option val,_ => intro vl end;
   apply andp_left2;intro rho;cbn [existential_ret_assert RA_normal RA_break RA_continue RA_return];
   apply exp_right with a;apply derives_refl.
Qed.

(* The existential witness may contain the restored snapshot, trace, result and
   row index returned by the sibling loop. Every heap fact indexed by
   it survives the C return, including the physical witness. *)
Theorem finish_after_siblings {A:Type} {Espec:OracleKind} D pre ptr (klass:Integers.int) t1 t2
 (code:A->Z) (evidence:A->Prop) (heap:A->mpred):
 tycontext_sub (func_tycontext f_dfs prepared_vars [] []) D ->
 Int.signed klass<0 ->
 semax D pre (Ssequence search_children undo_children)
 (normal_ret_assert (EX a:A,PROP(evidence a)
    LOCAL(lvar _sample sample_type ptr;temp _result (Vint (Int.repr (code a))))
    SEP(sample_data ptr klass t1 t2;heap a))) ->
 semax D pre search_finish
 (existential_ret_assert (fun a:A=>function_body_ret_assert tint
   (PROP(evidence a) LOCAL(temp ret_temp (Vint (Int.repr (code a))))
     SEP(data_at_ Tsh sample_type ptr;heap a)))).
Proof.
 intros stronger disabled loop;rewrite suffix_code.
 apply (semax_unfold_seq (Ssequence (Ssequence search_children undo_children) finish_scan)
   (Ssequence search_children (Ssequence undo_children finish_scan)) eq_refl).
 eapply semax_seq';[exact loop|];Intros a.
 match goal with h:evidence a |- _ => pose proof h as valid end.
 apply (@select_ret_assert A Espec _ _ _ _ a).
 eapply semax_post_flipped.
 - eapply semax_Delta_subsumption;[exact stronger|].
   exact (@unsampled_returns_trace Espec ptr klass t1 t2 (code a) (heap a) disabled).
 - simpl;normalize.
 - simpl;normalize.
 - simpl;normalize.
 - intros [v|];intro rho;simpl;normalize;entailer!.
   unfold liftx,PROPx;cbn;normalize;apply andp_left2;apply derives_refl.
Qed.
