(* Actual phase0 output-copy loop. This is a block proof, not whole search. *)
Require Import VST.floyd.proofauto.
Require Import CCV.ccv_core CCV.CCSearchContext CCV.CCSearchFragments CCV.CCPackedArray CCV.VerifToggle.
Import ListNotations. Open Scope Z_scope.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
Definition problem_type:=Tstruct _ccv_problem noattr.
Definition workspace_type:=Tstruct _ccv_workspace noattr.
Definition output_copy_path:=phase_zero_path++
 [SeqNext;SeqNext;SeqNext;SeqNext;SeqFirst;SeqNext;SeqNext;ThenBranch;SeqFirst;SeqNext;ThenBranch;SeqFirst].
Definition output_copy:=search_fragment output_copy_path.
Lemma output_copy_is_actual:statement_at output_copy_path(fn_body ccv_core.f_search)=Some output_copy.
Proof. reflexivity. Qed.
Lemma output_copy_shape:exists a b c,output_copy=Ssequence a(Sloop b c).
Proof. eexists;eexists;eexists;reflexivity. Qed.
Definition copy_memory sh pp wp sp op n xs os:mpred:=
 (field_at sh problem_type[StructField _n](Vint(Int.repr n))pp*
  field_at sh workspace_type[StructField _selected]sp wp*
  data_at Tsh(tarray tuchar n)(tbytes xs)sp*
  data_at Tsh(tarray tuchar n)(tbytes os)op)%logic.
Definition copy_result sh pp wp sp op n xs:assert:=
 (PROP()LOCAL(temp _p pp;temp _w wp;temp _out op)
 SEP(copy_memory sh pp wp sp op n xs xs))%assert.
Section Proof.
Context{Espec:OracleKind}.
Lemma block_output_copy:forall sh pp wp sp op n xs os,
 readable_share sh ->0<=n<=Int.max_signed ->Zlength xs=n ->Zlength os=n ->
 Forall(fun z:Z=>z=0\/z=1)xs ->
 semax CCSearchContext.Delta
 (PROP()LOCAL(temp _p pp;temp _w wp;temp _out op)
 SEP(copy_memory sh pp wp sp op n xs os))%assert
 output_copy(normal_ret_assert(copy_result sh pp wp sp op n xs)).
Proof.
 intros sh pp wp sp op n xs os SH N Xlen Olen Bits.
 assert(Full:blend os xs n=xs)by(unfold blend;list_solve).
 unfold CCSearchContext.Delta;abbreviate_semax.
 let C:=eval cbv -[Int.repr]in output_copy in
 lazymatch goal with|-semax ?D ?P _ ?R=>change(semax D P C R)end.
 unfold copy_memory. Intros. forward.
 forward_loop
 (EX i:Z,PROP(0<=i<=n)
 LOCAL(temp _p pp;temp _w wp;temp _out op;temp _i(Vint(Int.repr i)))
 SEP(copy_memory sh pp wp sp op n xs(blend os xs i)))%assert
 break:(copy_result sh pp wp sp op n xs).
 { Exists 0. unfold copy_memory;entailer!;rewrite blend_start;cancel. }
 { Intros i. unfold copy_memory. Intros. forward. forward_if.
   { forward.
     assert(B:Znth i xs=0\/Znth i xs=1)by(apply (proj1(Forall_Znth _ _)Bits);lia).
     unfold tbytes;forward.
     { destruct B as[B|B];rewrite B;entailer!. }
     forward. forward. Exists(i+1). unfold copy_memory,tbytes;entailer!.
     rewrite <-blend_step by lia.
     rewrite <-upd_Znth_map by(rewrite blend_length;lia).
     destruct B as[B|B];rewrite B;simpl;cancel.
   }
   { assert(E:i=n)by lia;subst i. forward.
     unfold copy_result,copy_memory. rewrite Full;entailer!;cancel. }
 }
Qed.
End Proof.
Print Assumptions block_output_copy.
