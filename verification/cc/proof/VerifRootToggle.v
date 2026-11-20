(* Actual root toggle call under full ownership and raw top scratch. *)
Require Import VST.floyd.proofauto.
Require Import CCV.ccv_core CCV.CCSearchSpecs CCV.CCSearchContext CCV.CCSearchFragments
 CCV.CCSearchHeap CCV.CCRawTopHeap CCV.CCRootArray CCV.CCRootInvariant CCV.CCAPIBridge
 CCV.VerifCoreToggle CCV.VerifPhaseOneTail CCV.VerifRootPreparation CCV.VerifToggle.
Import ListNotations. Open Scope Z_scope.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
Definition root_toggle_call:=search_fragment(seed_loop_path++
 [LoopBody;SeqNext;SeqNext;SeqNext;SeqFirst]).
Section Proof.
Context{Espec:OracleKind}.
Lemma block_root_toggle:forall sh a p tp rp cap seed budget rules top xs fs ys zs pk buf frames out s,
 readable_share sh ->legal_model a ->0<=seed<model_n a ->
 Zlength xs=model_n a ->Zlength ys=model_m a ->Zlength zs=model_l a ->
 Forall(fun z:Z=>z=0\/z=1)xs ->Forall(fun z:Z=>z=0\/z=1)ys ->Forall(fun z:Z=>z=0\/z=1)zs ->
 semax CCSearchContext.Delta
 (root_state_raw sh a p tp rp cap seed budget rules top xs fs ys zs pk buf frames out s)
 root_toggle_call
 (normal_ret_assert(root_state_raw sh a p tp rp cap seed budget rules top(chosen_xs seed xs)fs
 (chosen_ys(model_n a)(model_m a)seed(model_h a)ys)
 (chosen_ys(model_n a)(model_l a)seed(model_lg a)zs)pk buf frames out s)).
Proof.
 intros sh a p tp rp cap seed budget rules top xs fs ys zs pk buf frames out s
 SH Legal Seed XL YL ZL XB YB ZB.
 pose proof(legal_model_ranges a Legal)as[NR[MR[LR[KR[HP[LP GP]]]]]].
 assert(HL:Zlength(model_h a)=model_m a*model_n a)by(unfold legal_model in Legal;tauto).
 assert(LL:Zlength(model_lg a)=model_l a*model_n a)by(unfold legal_model in Legal;tauto).
 assert(HB:Forall(fun z:Z=>z=0\/z=1)(model_h a))by(unfold legal_model in Legal;tauto).
 assert(LB:Forall(fun z:Z=>z=0\/z=1)(model_lg a))by(unfold legal_model in Legal;tauto).
 unfold CCSearchContext.Delta;abbreviate_semax.
 let C:=eval cbv -[Int.repr]in root_toggle_call in
 lazymatch goal with|-semax ?D ?P _ ?R=>change(semax D P C R)end.
 unfold root_state_raw,search_heap_raw_top,problem_repr,workspace_fields.
 forward_call(ptr_problem p,ptr_workspace p,ptr_h p,ptr_lg p,ptr_selected p,ptr_syndrome p,
 ptr_logical_value p,sh,model_n a,model_m a,model_l a,seed,xs,ys,zs,model_h a,model_lg a).
 { cancel. }
 unfold root_state_raw,search_heap_raw_top,problem_repr,workspace_fields,chosen_xs,chosen_ys.
 entailer!;cancel.
Qed.
End Proof.
Print Assumptions block_root_toggle.
