(* Exact phase0 overlap call and result assignment under the complete owned
   search heap. Its caller still composes the reject/counter/finish branches. *)
Require Import VST.floyd.proofauto.
Require Import CCV.ccv_core CCV.CCSearchSpecs CCV.CCSearchContext CCV.CCSearchFragments
 CCV.CCRowHeap CCV.CCJournalArray CCV.CCJournalTrace CCV.CCOverlapArray CCV.VerifOverlap
 CCV.VerifToggle.
Import ListNotations. Open Scope Z_scope.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
#[export] Instance OverlapHeapPreserve:change_composite_env VerifOverlap.CompSpecs CCSearchSpecs.CompSpecs.
 make_cs_preserve VerifOverlap.CompSpecs CCSearchSpecs.CompSpecs.
Qed.
Definition zero_overlap_call:=search_fragment(phase_zero_path++
 [SeqNext;SeqNext;SeqNext;SeqNext;SeqNext;SeqFirst;SeqNext;ThenBranch;SeqFirst]).
Lemma zero_overlap_call_not_skip:zero_overlap_call<>Sskip.
Proof. discriminate. Qed.
Section Proof.
Context{Espec:OracleKind}.
Lemma block_overlap_heap:forall sh a p tp rp row base xs ys zs pk log buf frames out s
 (Bad:Prop)(Allowed:Z->Prop),
 readable_share sh ->0<model_n a<=Int.max_signed ->0<=model_k a ->
 model_k a*model_n a<=Int.max_signed ->Zlength base=model_n a ->Zlength xs=model_n a ->
 Zlength(model_g a)=model_k a*model_n a ->
 Forall(fun z:Z=>z=0\/z=1)base ->Forall(fun z:Z=>z=0\/z=1)xs ->
 Forall(fun z:Z=>z=0\/z=1)(model_g a) ->journal_trace(model_n a)base log buf ->
 overlap_policy(model_n a)(model_k a)xs(model_g a)Bad Allowed ->
 semax CCSearchContext.Delta
 (PROP()LOCAL(temp _p(ptr_problem p);temp _w(ptr_workspace p);lvar _top tuint tp;lvar _row tuint rp)
 SEP(row_heap sh a p tp rp(Zlength log)row xs(journal_bitmap base log)ys zs pk buf frames out s))%assert
 zero_overlap_call
 (normal_ret_assert
 (EX ret:Z,EX lognew:list Z,EX bufnew:list val,
 PROP(ret=0\/ret=1;ret=0 ->Bad;journal_trace(model_n a)base lognew bufnew;
 allowed_extension log lognew Allowed)
 LOCAL(temp _p(ptr_problem p);temp _w(ptr_workspace p);temp _ov(Vint(Int.repr ret));
 lvar _top tuint tp;lvar _row tuint rp)
 SEP(row_heap sh a p tp rp(Zlength lognew)row xs(journal_bitmap base lognew)ys zs pk bufnew frames out s))%assert).
Proof.
 intros sh a p tp rp row base xs ys zs pk log buf frames out s Bad Allowed
 SH N K Extent BL XL GL BB XB GB Trace Policy.
 unfold CCSearchContext.Delta;abbreviate_semax.
 let C:=eval cbv -[Int.repr]in zero_overlap_call in
 lazymatch goal with|-semax ?D ?P _ ?R=>change(semax D P C R)end.
 unfold row_heap,search_core_heap,problem_repr,workspace_fields.
 forward_call(ptr_problem p,ptr_workspace p,tp,ptr_g p,ptr_selected p,ptr_forbidden p,
 ptr_undo p,sh,model_n a,model_k a,base,xs,model_g a,log,buf,Bad,Allowed).
 { cancel. }
 Intros result. destruct result as[[ret lognew]bufnew];cbn[fst snd]in*. forward.
 Exists ret lognew bufnew.
 unfold row_heap,search_core_heap,problem_repr,workspace_fields;entailer!;cancel.
Qed.
End Proof.
Print Assumptions block_overlap_heap.
