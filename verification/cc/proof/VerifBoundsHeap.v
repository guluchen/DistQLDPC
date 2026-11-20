(* Exact native bounds call under full search ownership. Keeps complementary
   shares for the three read-only arrays and updates only scratch/counters.
   The caller must instantiate the mathematical pruning policy. *)
Require Import VST.floyd.proofauto.
Require Import CCV.ccv_core CCV.CCSearchSpecs CCV.CCSearchContext CCV.CCSearchFragments
 CCV.CCRowHeap CCV.CCReadBorrow CCV.CCStatsFields CCV.CCPhaseZeroStats CCV.CCBoundsArray CCV.CCBoundsPolicy
 CCV.VerifBounds CCV.VerifToggle.
Import ListNotations. Open Scope Z_scope.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
#[export] Instance BoundsHeapPreserve:change_composite_env VerifBounds.CompSpecs CCSearchSpecs.CompSpecs.
 make_cs_preserve VerifBounds.CompSpecs CCSearchSpecs.CompSpecs.
Qed.
Definition zero_bounds_call:=search_fragment(phase_zero_path++
 [SeqNext;SeqNext;SeqNext;SeqNext;SeqNext;SeqNext;SeqFirst;SeqFirst;ThenBranch;SeqFirst]).
Lemma zero_bounds_call_not_skip:zero_bounds_call<>Sskip.
Proof. discriminate. Qed.
Section Proof.
Context{Espec:OracleKind}.
Lemma block_bounds_heap:forall sh a p tp rp top row remaining rules xs fs ys zs pk buf frames out s(Bad:Prop),
 readable_share sh ->0<model_n a<=Int.max_signed ->0<=model_m a ->
 model_m a*model_n a<=Int.max_signed ->0<=remaining<=model_n a ->
 Zlength(model_h a)=model_m a*model_n a ->Zlength xs=model_n a ->Zlength fs=model_n a ->
 Zlength ys=model_m a ->Zlength pk=model_n a ->
 Forall(fun z:Z=>z=0\/z=1)(model_h a) ->Forall(fun z:Z=>z=0\/z=1)xs ->
 Forall(fun z:Z=>z=0\/z=1)fs ->Forall(fun z:Z=>z=0\/z=1)ys ->
 0<=row<=Int.max_unsigned ->0<=stat_pack s<Int.max_unsigned ->0<=stat_charge s<Int.max_unsigned ->
 bounds_policy(model_n a)(model_m a)(model_h a)xs fs ys remaining Bad ->
 semax CCSearchContext.Delta
 (PROP()LOCAL(temp _p(ptr_problem p);temp _w(ptr_workspace p);temp _stats(ptr_stats p);
 temp _remaining(Vint(Int.repr remaining));temp _rules(Vint rules);lvar _top tuint tp;lvar _row tuint rp)
 SEP(row_heap sh a p tp rp top row xs fs ys zs pk buf frames out s))%assert
 zero_bounds_call
 (normal_ret_assert
 (EX ret:Z,EX newrow:Z,EX newpk:list Z,EX pc:Z,EX cc:Z,
 PROP(ret=0\/ret=1;ret=0 ->Bad;0<=newrow<=model_m a;
 ret=1 ->(newrow=model_m a <->odd_count(model_m a)ys=0);
 ret=1 ->newrow<model_m a ->Znth newrow ys<>0;
 Zlength newpk=model_n a;Forall(fun z:Z=>z=0\/z=1)newpk;
 stat_pack s<=pc<=stat_pack s+1;stat_charge s<=cc<=stat_charge s+1)
 LOCAL(temp _p(ptr_problem p);temp _w(ptr_workspace p);temp _stats(ptr_stats p);
 temp _remaining(Vint(Int.repr remaining));temp _rules(Vint rules);
 temp _t'5(Vint(Int.repr ret));lvar _top tuint tp;lvar _row tuint rp)
 SEP(row_heap sh a p tp rp top newrow xs fs ys zs newpk buf frames out(bounds_stats s pc cc)))%assert).
Proof.
 intros sh a p tp rp top row remaining rules xs fs ys zs pk buf frames out s Bad
 SH N M Extent Rem HL XL FL YL PKL HB XB FB YB Row PC CC Policy.
 assert(PKBytes:Zlength(tbytes pk)=model_n a)by(unfold tbytes;rewrite Zlength_map;assumption).
 unfold CCSearchContext.Delta;abbreviate_semax.
 let C:=eval cbv -[Int.repr]in zero_bounds_call in
 lazymatch goal with|-semax ?D ?P _ ?R=>change(semax D P C R)end.
 unfold row_heap,search_core_heap,problem_repr,workspace_fields.
 rewrite stats_repr_fields;unfold stats_fields.
 rewrite(read_share_split sh(tarray tuchar(model_n a))(tbytes xs)(ptr_selected p)).
 rewrite(read_share_split sh(tarray tuchar(model_n a))(tbytes fs)(ptr_forbidden p)).
 rewrite(read_share_split sh(tarray tuchar(model_m a))(tbytes ys)(ptr_syndrome p)).
 forward_call(ptr_problem p,ptr_workspace p,ptr_h p,ptr_selected p,ptr_forbidden p,
 ptr_syndrome p,ptr_packed p,rp,ptr_stats p,sh,model_n a,model_m a,remaining,rules,
 model_h a,xs,fs,ys,tbytes pk,((row,stat_pack s),stat_charge s),Bad).
 { cancel. }
 Intros result. destruct result as[[[[ret newrow]newpk]pc]cc];cbn[fst snd]in*.
 Exists ret newrow newpk pc cc.
 unfold row_heap,search_core_heap,problem_repr,workspace_fields.
 rewrite stats_repr_fields;unfold stats_fields.
 cbn[bounds_stats stat_steps stat_nodes stat_pack stat_charge stat_overlap].
 rewrite(read_share_split sh(tarray tuchar(model_n a))(tbytes xs)(ptr_selected p)).
 rewrite(read_share_split sh(tarray tuchar(model_n a))(tbytes fs)(ptr_forbidden p)).
 rewrite(read_share_split sh(tarray tuchar(model_m a))(tbytes ys)(ptr_syndrome p)).
 entailer!;cancel.
Qed.
End Proof.
Print Assumptions block_bounds_heap.
