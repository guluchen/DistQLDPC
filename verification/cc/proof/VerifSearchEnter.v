(* Actual while-iteration entry prefix under the nonexhausted fuel guard.
   The exhausted return and complete while invariant remain separate. *)
Require Import VST.floyd.proofauto.
Require Import CCV.ccv_core CCV.CCSearchSpecs CCV.CCSearchContext CCV.CCSearchFragments.
Import ListNotations. Open Scope Z_scope.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
Definition iteration_piece path:=match statement_at path search_main_iteration with
 Some s=>s|None=>Sskip end.
Definition enter_guard:=iteration_piece[SeqFirst].
Definition enter_step:=iteration_piece[SeqNext;SeqFirst].
Definition enter_reload:=iteration_piece[SeqNext;SeqNext;SeqFirst].
Definition enter_finish:=iteration_piece[SeqNext;SeqNext;SeqNext;SeqFirst].
Definition iteration_rest:=iteration_piece[SeqNext;SeqNext;SeqNext;SeqNext].
Definition iteration_enter:=Ssequence enter_guard(Ssequence enter_step(Ssequence enter_reload enter_finish)).
Lemma enter_actual_layout:search_main_iteration=
 Ssequence enter_guard(Ssequence enter_step(Ssequence enter_reload(Ssequence enter_finish iteration_rest))).
Proof. reflexivity. Qed.
Definition enter_memory sh wp fp sp n steps frames:mpred:=
 (field_at Tsh CCSearchSpecs.stats_type[StructField _steps](Vint(Int.repr steps))sp*
  field_at sh CCSearchSpecs.workspace_type[StructField _frames]fp wp*
  data_at Tsh(tarray CCSearchSpecs.frame_type n)frames fp)%logic.
Definition enter_result sh wp fp sp n depth budget steps frames:assert:=
 (PROP()LOCAL(temp _w wp;temp _stats sp;temp _budget(Vint(Int.repr budget));
  temp _depth(Vint(Int.repr depth));temp _f(offset_val(20*(depth-1))fp);temp _finish(Vint Int.zero))
 SEP(enter_memory sh wp fp sp n(steps+1)frames))%assert.
Section Proof.
Context{Espec:OracleKind}.
Lemma block_search_enter:forall sh wp fp sp n depth budget steps frames,
 readable_share sh ->0<n ->20*n<=Int.max_signed ->1<=depth<=n ->
 0<=steps<budget ->budget<=Int.max_unsigned ->Zlength frames=n ->
 semax CCSearchContext.Delta
 (PROP()LOCAL(temp _w wp;temp _stats sp;temp _budget(Vint(Int.repr budget));
  temp _depth(Vint(Int.repr depth)))
 SEP(enter_memory sh wp fp sp n steps frames))%assert
 iteration_enter(normal_ret_assert(enter_result sh wp fp sp n depth budget steps frames)).
Proof.
 intros sh wp fp sp n depth budget steps frames SH N Size Depth Steps Budget Len.
 unfold CCSearchContext.Delta;abbreviate_semax.
 let C:=eval cbv -[Int.repr]in iteration_enter in
 lazymatch goal with|-semax ?D ?P _ ?R=>change(semax D P C R)end.
 unfold enter_memory. Intros. forward. forward_if.
 { lia. }
 forward. forward. forward. forward. forward.
 unfold enter_result,enter_memory;entailer!.
Qed.
End Proof.
Print Assumptions block_search_enter.
