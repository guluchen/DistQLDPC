(* Exact phase0 leaf call with full ownership. Preserves the forbidden journal
   and all framed state, and exposes the verified candidate hit/miss fact. *)
Require Import VST.floyd.proofauto.
Require Import CCV.ccv_core CCV.CCSearchSpecs CCV.CCSearchContext CCV.CCSearchFragments
 CCV.CCRowHeap CCV.CCLeaf CCV.CCAPIBridge CCV.VerifLeaf CCV.VerifToggle CCV.VerifPhaseOneTail.
Import ListNotations. Open Scope Z_scope.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
#[export] Instance LeafHeapPreserve:change_composite_env VerifLeaf.CompSpecs CCSearchSpecs.CompSpecs.
 make_cs_preserve VerifLeaf.CompSpecs CCSearchSpecs.CompSpecs.
Qed.
Definition zero_leaf_call:=search_fragment(phase_zero_path++
 [SeqNext;SeqNext;SeqNext;SeqNext;SeqNext;SeqNext;SeqNext;SeqFirst;SeqNext;ThenBranch;SeqFirst;SeqFirst]).
Lemma zero_leaf_call_not_skip:zero_leaf_call<>Sskip.
Proof. discriminate. Qed.
Section Proof.
Context{Espec:OracleKind}.
Lemma block_leaf_heap:forall sh a p tp rp top row xs fs ys zs pk buf frames out s,
 readable_share sh ->legal_model a ->Zlength xs=model_n a ->Zlength fs=model_n a ->
 Zlength ys=model_m a ->Zlength zs=model_l a ->
 Forall(fun z:Z=>z=0\/z=1)xs ->Forall(fun z:Z=>z=0\/z=1)fs ->
 Forall(fun z:Z=>z=0\/z=1)ys ->Forall(fun z:Z=>z=0\/z=1)zs ->
 semax CCSearchContext.Delta
 (PROP()LOCAL(temp _p(ptr_problem p);temp _w(ptr_workspace p);lvar _top tuint tp;lvar _row tuint rp)
 SEP(row_heap sh a p tp rp top row xs fs ys zs pk buf frames out s))%assert
 zero_leaf_call
 (normal_ret_assert
 (EX hit:bool,EX chosen:Z,
 PROP(if hit then 0<=chosen<model_n a /\
 leaf_candidate(model_n a)(model_m a)(model_l a)xs fs ys zs(model_h a)(model_lg a)chosen=true
 else forall q,0<=q<model_n a ->
 leaf_candidate(model_n a)(model_m a)(model_l a)xs fs ys zs(model_h a)(model_lg a)q=false)
 LOCAL(temp _p(ptr_problem p);temp _w(ptr_workspace p);
 temp _t'6(Vint(Int.repr(if hit then 1 else 0)));lvar _top tuint tp;lvar _row tuint rp)
 SEP(row_heap sh a p tp rp top row(if hit then chosen_xs chosen xs else xs)fs
 (if hit then chosen_ys(model_n a)(model_m a)chosen(model_h a)ys else ys)
 (if hit then chosen_ys(model_n a)(model_l a)chosen(model_lg a)zs else zs)
 pk buf frames out s))%assert).
Proof.
 intros sh a p tp rp top row xs fs ys zs pk buf frames out s SH Legal XL FL YL ZL XB FB YB ZB.
 pose proof(legal_model_ranges a Legal)as[NR[MR[LR[KR[HP[LP Rest]]]]]].
 destruct Legal as[DimN[DimM[DimL[DimK[HL[LL[GL[HB[LB[GB Meta]]]]]]]]]].
 unfold CCSearchContext.Delta;abbreviate_semax.
 let C:=eval cbv -[Int.repr]in zero_leaf_call in
 lazymatch goal with|-semax ?D ?P _ ?R=>change(semax D P C R)end.
 unfold row_heap,search_core_heap,problem_repr,workspace_fields.
 forward_call(ptr_problem p,ptr_workspace p,ptr_h p,ptr_lg p,ptr_selected p,ptr_forbidden p,
 ptr_syndrome p,ptr_logical_value p,sh,model_n a,model_m a,model_l a,xs,fs,ys,zs,model_h a,model_lg a).
 { cancel. }
 Intros result. destruct result as[hit chosen];cbn[fst snd]in*.
 Exists hit chosen.
 unfold row_heap,search_core_heap,problem_repr,workspace_fields,chosen_xs,chosen_ys.
 destruct hit;go_lowerx;normalize;cancel.
 apply andp_right;[apply prop_right;tauto|cancel].
Qed.
End Proof.
Print Assumptions block_leaf_heap.
