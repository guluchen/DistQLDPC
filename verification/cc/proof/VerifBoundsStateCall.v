(* Actual bounds call preserving every phase0 caller register. *)
Require Import VST.floyd.proofauto.
Require Import CCV.ccv_core CCV.CCSearchSpecs CCV.CCSearchContext CCV.CCSearchFragments
 CCV.CCSearchMemory CCV.CCSearchHeap CCV.CCRowHeap CCV.CCJournalArray CCV.CCRootArray
 CCV.CCBlockFrame CCV.CCAPIBridge CCV.CCBoundsArray CCV.CCBoundsPolicy CCV.CCPhaseZeroStats
 CCV.VerifZeroRemaining CCV.VerifLeafStateCall CCV.VerifBoundsHeap.
Import ListNotations. Open Scope Z_scope.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
Definition bounds_state_result sh a p tp rp cap seed budget rules s path log buf xs ys zs(pk:list Z)frames(Bad:Prop):assert:=
 (EX ret:Z,EX newrow:Z,EX newpk:list Z,EX pc:Z,EX cc:Z,
 !!((ret=0\/ret=1)/\(ret=0 ->Bad)/\0<=newrow<=model_m a /\
 (ret=1 ->(newrow=model_m a <->odd_count(model_m a)ys=0))/\
 (ret=1 ->newrow<model_m a ->Znth newrow ys<>0)/\
 Zlength newpk=model_n a /\Forall(fun z:Z=>z=0\/z=1)newpk /\
 stat_pack s<=pc<=stat_pack s+1 /\stat_charge s<=cc<=stat_charge s+1)&&
 local(locald_denote(temp _t'5(Vint(Int.repr ret))))&&
 zero_row_state sh a p tp rp cap seed budget rules(bounds_stats s pc cc)path log buf xs ys zs newpk frames newrow 0)%logic.
Section Proof.
Context{Espec:OracleKind}.
Lemma block_bounds_state_call:forall sh a p tp rp cap seed budget rules s path log buf xs ys zs pk frames row(Bad:Prop),
 readable_share sh ->legal_model a ->0<=cap-Z.of_nat(length path)<=model_n a ->
 Zlength xs=model_n a ->Zlength(journal_bitmap(root_mask(model_n a)seed)log)=model_n a ->
 Zlength ys=model_m a ->Zlength pk=model_n a ->Forall(fun z:Z=>z=0\/z=1)xs ->
 Forall(fun z:Z=>z=0\/z=1)(journal_bitmap(root_mask(model_n a)seed)log) ->
 Forall(fun z:Z=>z=0\/z=1)ys ->0<=row<=Int.max_unsigned ->
 0<=stat_pack s<Int.max_unsigned ->0<=stat_charge s<Int.max_unsigned ->
 bounds_policy(model_n a)(model_m a)(model_h a)xs(journal_bitmap(root_mask(model_n a)seed)log)ys
 (cap-Z.of_nat(length path))Bad ->
 semax CCSearchContext.Delta
 (zero_row_state sh a p tp rp cap seed budget rules s path log buf xs ys zs pk frames row 0)
 zero_bounds_call(normal_ret_assert(bounds_state_result sh a p tp rp cap seed budget rules s path log buf xs ys zs pk frames Bad)).
Proof.
 intros sh a p tp rp cap seed budget rules s path log buf xs ys zs pk frames row Bad
 SH Legal Rem XL FL YL PKL XB FB YB Row PC CC Policy.
 pose proof(legal_model_ranges a Legal)as[NR[MR[LR[KR[HP Rest]]]]].
 assert(HL:Zlength(model_h a)=model_m a*model_n a)by(unfold legal_model in Legal;tauto).
 assert(HB:Forall(fun z:Z=>z=0\/z=1)(model_h a))by(unfold legal_model in Legal;tauto).
 pose(F:=leaf_caller_frame a p cap seed budget rules path).
 eapply semax_post'.
 2:{ eapply semax_pre with(P':=((PROP()LOCAL(temp _p(ptr_problem p);temp _w(ptr_workspace p);temp _stats(ptr_stats p);
 temp _remaining(Vint(Int.repr(cap-Z.of_nat(length path))));temp _rules(Vint(Int.repr rules));
 lvar _top tuint tp;lvar _row tuint rp)
 SEP(row_heap sh a p tp rp(Zlength log)row xs(journal_bitmap(root_mask(model_n a)seed)log)
 ys zs pk buf frames(Zrepeat 0(model_n a))s))*F)%logic).
 { unfold zero_row_state,F,leaf_caller_frame;go_lowerx;normalize;cancel;
 try(apply andp_right;[apply prop_right;tauto|cancel]). }
 apply semax_normal_block_frame.
 { unfold F,leaf_caller_frame,zero_bounds_call;auto 50 with closed. }
 exact(block_bounds_heap sh a p tp rp(Zlength log)row(cap-Z.of_nat(length path))(Int.repr rules)
 xs(journal_bitmap(root_mask(model_n a)seed)log)ys zs pk buf frames(Zrepeat 0(model_n a))s Bad
 SH NR MR HP Rem HL XL FL YL PKL HB XB FB YB Row PC CC Policy).
 }
 apply andp_left2;unfold bounds_state_result,F,leaf_caller_frame.
 Intros ret newrow newpk pc cc. Exists ret newrow newpk pc cc.
 unfold zero_row_state;go_lowerx;normalize;cancel;
 try(apply andp_right;[apply prop_right;tauto|cancel]).
Qed.
End Proof.
Print Assumptions block_bounds_state_call.
