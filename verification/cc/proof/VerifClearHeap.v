(* Actual clear call in the root loop, framed by complete search ownership.
   No claim about the enclosing search/seed loops is made here. *)
Require Import VST.floyd.proofauto.
Require Import CCV.ccv_core CCV.CCSearchSpecs CCV.CCSearchContext CCV.CCSearchFragments
 CCV.CCSearchHeap CCV.CCAPIBridge CCV.VerifClear CCV.VerifToggle.
Import ListNotations. Open Scope Z_scope.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
#[export] Instance ClearHeapPreserve:change_composite_env VerifClear.CompSpecs CCSearchSpecs.CompSpecs.
 make_cs_preserve VerifClear.CompSpecs CCSearchSpecs.CompSpecs.
Defined.
Definition root_clear_call:=search_fragment(seed_loop_path++[LoopBody;SeqNext;SeqFirst]).
Section Proof.
Context{Espec:OracleKind}.
Lemma block_clear_heap:forall sh a p tp rp top xs fs ys zs pk buf frames out s,
 readable_share sh ->legal_model a ->Zlength xs=model_n a ->Zlength fs=model_n a ->
 Zlength ys=model_m a ->Zlength zs=model_l a ->Zlength pk=model_n a ->Zlength out=model_n a ->
 semax CCSearchContext.Delta
 (PROP()LOCAL(temp _p(ptr_problem p);temp _w(ptr_workspace p);temp _out(ptr_out p))
 SEP(search_heap sh a p tp rp top xs fs ys zs pk buf frames out s))%assert
 root_clear_call
 (normal_ret_assert
 (PROP()LOCAL(temp _p(ptr_problem p);temp _w(ptr_workspace p);temp _out(ptr_out p))
 SEP(search_heap sh a p tp rp top(Zrepeat 0(model_n a))(Zrepeat 0(model_n a))
 (Zrepeat 0(model_m a))(Zrepeat 0(model_l a))(Zrepeat 0(model_n a))buf frames
 (Zrepeat 0(model_n a))s))%assert).
Proof.
 intros sh a p tp rp top xs fs ys zs pk buf frames out s SH Legal XL FL YL ZL PL OL.
 pose proof(legal_model_ranges a Legal)as[NR[MR[LR[KR[HP[LP GP]]]]]].
 assert(M:0<=model_m a<=Int.max_signed).
 { assert(0<model_n a)by lia;split;[lia|nia]. }
 assert(L:0<=model_l a<=Int.max_signed).
 { assert(0<model_n a)by lia;split;[lia|nia]. }
 unfold CCSearchContext.Delta;abbreviate_semax.
 let C:=eval cbv -[Int.repr]in root_clear_call in
 lazymatch goal with|-semax ?D ?P _ ?R=>change(semax D P C R)end.
 unfold search_heap,problem_repr,workspace_fields. Intros.
 forward_call(ptr_problem p,ptr_workspace p,ptr_out p,ptr_selected p,ptr_forbidden p,
 ptr_packed p,ptr_syndrome p,ptr_logical_value p,sh,model_n a,model_m a,model_l a,
 tbytes xs,tbytes fs,tbytes pk,tbytes out,tbytes ys,tbytes zs).
 { unfold tbytes;rewrite !Zlength_map;repeat split;assumption. }
 unfold search_heap,problem_repr,workspace_fields,tbytes,Zrepeat.
 rewrite !map_repeat. entailer!;cancel.
Qed.
End Proof.
Print Assumptions block_clear_heap.
