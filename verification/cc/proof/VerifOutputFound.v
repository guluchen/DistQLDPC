(* Actual copy-and-return-FOUND branch. Good must be established by its caller;
   this file does not infer kernel/logical properties from arbitrary bytes. *)
Require Import VST.floyd.proofauto.
Require Import CCV.ccv_core CCV.CCSearchContext CCV.CCSearchFragments
 CCV.VerifOutputCopy CCV.CCBlockReturn.
Import ListNotations. Open Scope Z_scope.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
Definition found_branch_path:=phase_zero_path++
 [SeqNext;SeqNext;SeqNext;SeqNext;SeqFirst;SeqNext;SeqNext;ThenBranch;SeqFirst;SeqNext;ThenBranch].
Definition found_branch:=search_fragment found_branch_path.
Lemma found_branch_layout:found_branch=Ssequence VerifOutputCopy.output_copy
 (Sreturn(Some(Econst_int(Int.repr 1)tint))).
Proof. reflexivity. Qed.
Section Proof.
Context{Espec:OracleKind}.
Lemma block_output_found:forall sh pp wp sp op n xs os(Good:Prop),
 Good ->readable_share sh ->0<=n<=Int.max_signed ->Zlength xs=n ->Zlength os=n ->
 Forall(fun z:Z=>z=0\/z=1)xs ->
 semax CCSearchContext.Delta
 (PROP()LOCAL(temp _p pp;temp _w wp;temp _out op)
 SEP(copy_memory sh pp wp sp op n xs os))%assert
 found_branch
 (function_body_ret_assert tint
 (PROP(Good)LOCAL(temp ret_temp(Vint(Int.repr 1)))
 SEP(copy_memory sh pp wp sp op n xs xs))%assert).
Proof.
 intros sh pp wp sp op n xs os Good Fact SH N Xlen Olen Bits.
 rewrite found_branch_layout.
 eapply semax_seq' with(P':=copy_result sh pp wp sp op n xs).
 - apply(block_output_copy sh pp wp sp op n xs os);assumption.
 - unfold CCSearchContext.Delta;abbreviate_semax.
   unfold copy_result.
   eapply semax_pre;[|apply semax_return].
   unfold POSTCONDITION,abbreviate. change(ret_type Delta)with tint.
   cbn[tc_expropt cast_expropt RA_return function_body_ret_assert liftx bind_ret].
   unfold liftx. cbn[eval_expr]. unfold bind_ret. go_lowerx. normalize.
   apply andp_right.
   { apply prop_right;unfold_lift;rewrite eval_id_same;repeat split;congruence. }
   apply derives_refl.
Qed.
End Proof.
Print Assumptions block_output_found.
