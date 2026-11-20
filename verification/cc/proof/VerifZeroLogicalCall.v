(* Actual phase0 logical-cache call under complete search ownership. The
   complementary share is retained and rejoined after the read-only call. *)
Require Import VST.floyd.proofauto.
Require Import CCV.ccv_core CCV.CCSearchSpecs CCV.CCSearchContext CCV.CCSearchFragments
 CCV.CCRowHeap CCV.CCReadBorrow CCV.VerifToggle CCV.VerifNontrivial.
Import ListNotations. Open Scope Z_scope.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
#[export] Instance NontrivialHeapPreserve:change_composite_env VerifNontrivial.CompSpecs CCSearchSpecs.CompSpecs.
 make_cs_preserve VerifNontrivial.CompSpecs CCSearchSpecs.CompSpecs.
Qed.
Definition zero_logical_call:=search_fragment(phase_zero_path++
 [SeqNext;SeqNext;SeqNext;SeqNext;SeqFirst;SeqNext;SeqNext;ThenBranch;SeqFirst;SeqFirst]).
Lemma zero_logical_call_layout:zero_logical_call=Scall(Some _t'1)
 (Evar _nontrivial(Tfunction(Tcons(tptr(Tstruct _ccv_problem noattr))
 (Tcons(tptr(Tstruct _ccv_workspace noattr))Tnil))tint cc_default))
 [Etempvar _p(tptr(Tstruct _ccv_problem noattr));
 Etempvar _w(tptr(Tstruct _ccv_workspace noattr))].
Proof. reflexivity. Qed.
Section Proof.
Context{Espec:OracleKind}.
Lemma block_zero_logical_call:forall sh a p tp rp top row xs fs ys zs pk buf frames out s,
 readable_share sh ->Zlength zs=model_l a ->model_l a<=Int.max_signed ->
 Forall(fun z:Z=>z=0\/z=1)zs ->
 semax CCSearchContext.Delta
 (PROP()LOCAL(temp _p(ptr_problem p);temp _w(ptr_workspace p))
 SEP(row_heap sh a p tp rp top row xs fs ys zs pk buf frames out s))%assert
 zero_logical_call
 (normal_ret_assert
 (PROP()LOCAL(temp _p(ptr_problem p);temp _w(ptr_workspace p);
 temp _t'1(Vint(Int.repr(if has_nonzero zs then 1 else 0))))
 SEP(row_heap sh a p tp rp top row xs fs ys zs pk buf frames out s))%assert).
Proof.
 intros sh a p tp rp top row xs fs ys zs pk buf frames out s SH Len Bound Bits.
 unfold CCSearchContext.Delta;abbreviate_semax. rewrite zero_logical_call_layout.
 unfold row_heap,search_core_heap,problem_repr,workspace_fields.
 rewrite(read_share_split sh(tarray tuchar(model_l a))(tbytes zs)(ptr_logical_value p)).
 forward_call(ptr_problem p,ptr_workspace p,ptr_logical_value p,sh,zs).
 { rewrite Len. change(lbytes zs)with(tbytes zs). cancel. }
 unfold row_heap,search_core_heap,problem_repr,workspace_fields.
 rewrite(read_share_split sh(tarray tuchar(model_l a))(tbytes zs)(ptr_logical_value p)).
 rewrite Len. change(lbytes zs)with(tbytes zs). entailer!;cancel.
Qed.
End Proof.
Print Assumptions block_zero_logical_call.
