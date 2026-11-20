(* Exact overlap call with all caller locals and the dynamic journal retained. *)
Require Import VST.floyd.proofauto.
Require Import CCV.ccv_core CCV.CCSearchSpecs CCV.CCSearchContext CCV.CCSearchFragments
 CCV.CCSearchMemory CCV.CCSearchHeap CCV.CCRowHeap CCV.CCJournalArray CCV.CCJournalTrace CCV.CCRootArray
 CCV.CCBlockFrame CCV.CCAPIBridge CCV.CCOverlapArray
 CCV.VerifZeroRemaining CCV.VerifLeafStateCall CCV.VerifOverlapHeap.
Import ListNotations. Open Scope Z_scope.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
Definition overlap_state_result sh a p tp rp cap seed budget rules s path log xs ys zs pk frames row(Bad:Prop)(Allowed:Z->Prop):assert:=
 (EX ret:Z,EX lognew:list Z,EX bufnew:list val,
 !!((ret=0\/ret=1)/\(ret=0 ->Bad)/\
 journal_trace(model_n a)(root_mask(model_n a)seed)lognew bufnew /\allowed_extension log lognew Allowed)&&
 local(locald_denote(temp _ov(Vint(Int.repr ret))))&&
 zero_row_state sh a p tp rp cap seed budget rules s path lognew bufnew xs ys zs pk frames row 0)%logic.
Section Proof.
Context{Espec:OracleKind}.
Lemma block_overlap_state_call:forall sh a p tp rp cap seed budget rules s path log buf xs ys zs pk frames row
 (Bad:Prop)(Allowed:Z->Prop),
 readable_share sh ->legal_model a ->Zlength(root_mask(model_n a)seed)=model_n a ->Zlength xs=model_n a ->
 Forall(fun z:Z=>z=0\/z=1)(root_mask(model_n a)seed) ->Forall(fun z:Z=>z=0\/z=1)xs ->
 journal_trace(model_n a)(root_mask(model_n a)seed)log buf ->
 overlap_policy(model_n a)(model_k a)xs(model_g a)Bad Allowed ->
 semax CCSearchContext.Delta
 (zero_row_state sh a p tp rp cap seed budget rules s path log buf xs ys zs pk frames row 0)
 zero_overlap_call
 (normal_ret_assert(overlap_state_result sh a p tp rp cap seed budget rules s path log xs ys zs pk frames row Bad Allowed)).
Proof.
 intros sh a p tp rp cap seed budget rules s path log buf xs ys zs pk frames row Bad Allowed
 SH Legal BL XL BB XB Trace Policy.
 pose proof(legal_model_ranges a Legal)as[NR[MR[LR[KR[HP[LP GP]]]]]].
 assert(GL:Zlength(model_g a)=model_k a*model_n a)by(unfold legal_model in Legal;tauto).
 assert(GB:Forall(fun z:Z=>z=0\/z=1)(model_g a))by(unfold legal_model in Legal;tauto).
 pose(F:=leaf_caller_frame a p cap seed budget rules path).
 eapply semax_post'.
 2:{ eapply semax_pre with(P':=((PROP()LOCAL(temp _p(ptr_problem p);temp _w(ptr_workspace p);
 lvar _top tuint tp;lvar _row tuint rp)
 SEP(row_heap sh a p tp rp(Zlength log)row xs(journal_bitmap(root_mask(model_n a)seed)log)
 ys zs pk buf frames(Zrepeat 0(model_n a))s))*F)%logic).
 { unfold zero_row_state,F,leaf_caller_frame;go_lowerx;normalize;cancel;
 try(apply andp_right;[apply prop_right;tauto|cancel]). }
 apply semax_normal_block_frame.
 { unfold F,leaf_caller_frame,zero_overlap_call;auto 50 with closed. }
 exact(block_overlap_heap sh a p tp rp row(root_mask(model_n a)seed)xs ys zs pk log buf frames
 (Zrepeat 0(model_n a))s Bad Allowed SH NR KR GP BL XL GL BB XB GB Trace Policy).
 }
 apply andp_left2;unfold overlap_state_result,F,leaf_caller_frame.
 Intros ret lognew bufnew. Exists ret lognew bufnew.
 unfold zero_row_state;go_lowerx;normalize;cancel;
 try(apply andp_right;[apply prop_right;tauto|cancel]).
Qed.
End Proof.
Print Assumptions block_overlap_state_call.
