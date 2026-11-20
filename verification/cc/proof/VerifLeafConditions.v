(* Exact short-circuit leaf-enabling prefix. No owned memory is touched. *)
Require Import VST.floyd.proofauto.
Require Import CCV.ccv_core CCV.CCSearchSpecs CCV.CCSearchContext CCV.CCSearchFragments.
Import ListNotations. Open Scope Z_scope.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
Definition zero_leaf_conditions:=search_fragment(phase_zero_path++
 [SeqNext;SeqNext;SeqNext;SeqNext;SeqNext;SeqNext;SeqNext;SeqFirst;SeqFirst]).
Definition leaf_condition_input remaining rules:assert:=
 (PROP()LOCAL(temp _finish(Vint(Int.repr 0));temp _remaining(Vint(Int.repr remaining));
 temp _rules(Vint(Int.repr rules)))SEP())%assert.
Definition leaf_condition_output remaining rules:assert:=
 (EX enabled:bool,PROP(enabled=true ->remaining=1)
 LOCAL(temp _finish(Vint(Int.repr 0));temp _remaining(Vint(Int.repr remaining));
 temp _rules(Vint(Int.repr rules));temp _t'8(Vint(Int.repr(if enabled then 1 else 0))))SEP())%assert.
Section Proof.
Context{Espec:OracleKind}.
Lemma block_leaf_conditions:forall remaining rules,
 0<=remaining<=Int.max_unsigned ->
 semax CCSearchContext.Delta(leaf_condition_input remaining rules)
 zero_leaf_conditions(normal_ret_assert(leaf_condition_output remaining rules)).
Proof.
 intros remaining rules Range.
 unfold CCSearchContext.Delta;abbreviate_semax.
 unfold leaf_condition_input.
 let C:=eval cbv -[Int.repr]in zero_leaf_conditions in
 lazymatch goal with|-semax ?D ?P _ ?R=>change(semax D P C R)end.
 destruct(Z.eq_dec remaining 1)as[One|Other].
 - subst remaining.
   apply semax_if_seq. forward_if.
   2:{ contradiction. }
   forward.
   forward_if.
   2:{ discriminate. }
   destruct(Int.eq(Int.repr(Z.land rules 4))(Int.repr 0))eqn:Flag.
   + forward. unfold leaf_condition_output. Exists false. entailer!. rewrite Flag. reflexivity.
   + forward. unfold leaf_condition_output. Exists true. entailer!. rewrite Flag. reflexivity.
 - assert(Ne:Int.repr remaining<>Int.repr 1).
   { intro E;pose proof(f_equal Int.unsigned E)as Bad.
     rewrite !Int.unsigned_repr in Bad by rep_lia;lia. }
   apply semax_if_seq. forward_if.
   2:{ contradiction. }
   forward.
   forward_if.
   { unfold zeq in H0;destruct(Z.eq_dec remaining 1)as[E|E];[contradiction|cbn in H0;discriminate]. }
   forward. unfold leaf_condition_output. Exists false. entailer!.
Qed.
End Proof.
Print Assumptions block_leaf_conditions.
