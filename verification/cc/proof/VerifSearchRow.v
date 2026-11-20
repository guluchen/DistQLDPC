(* Actual phase0 first-nonzero-syndrome loop. Whole search remains separate. *)
Require Import VST.floyd.proofauto.
Require Import CCV.ccv_core CCV.CCSearchContext CCV.CCSearchFragments CCV.VerifToggle.
Import ListNotations. Open Scope Z_scope.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
Definition problem_type:=Tstruct _ccv_problem noattr.
Definition workspace_type:=Tstruct _ccv_workspace noattr.
Definition row_scan_path:=phase_zero_path++[SeqNext;SeqNext;SeqNext;SeqFirst].
Definition row_scan:=search_fragment row_scan_path.
Lemma row_scan_is_actual:statement_at row_scan_path(fn_body ccv_core.f_search)=Some row_scan.
Proof. reflexivity. Qed.
Lemma row_scan_shape:exists a b c,row_scan=Ssequence a(Sloop b c).
Proof. eexists;eexists;eexists;reflexivity. Qed.
Definition row_memory sh pp wp yp rp m ys row :mpred:=
 (field_at sh problem_type[StructField _checks](Vint(Int.repr m))pp*
  field_at sh workspace_type[StructField _syndrome]yp wp*
  data_at sh(tarray tuchar m)(tbytes ys)yp*
  data_at Tsh tuint(Vint(Int.repr row))rp)%logic.
Definition row_result sh pp wp yp rp m ys :assert:=
 (EX row:Z,PROP(0<=row<=m;forall j,0<=j<row ->Znth j ys=0;row<m ->Znth row ys=1)
 LOCAL(temp _p pp;temp _w wp;lvar _row tuint rp)
 SEP(row_memory sh pp wp yp rp m ys row))%assert.
Section Proof.
Context{Espec:OracleKind}.
Lemma block_search_row:forall sh pp wp yp rp m ys,
 readable_share sh ->0<=m<=Int.max_signed ->Zlength ys=m ->
 Forall(fun z:Z=>z=0\/z=1)ys ->
 semax CCSearchContext.Delta
 (PROP()LOCAL(temp _p pp;temp _w wp;lvar _row tuint rp)
 SEP(row_memory sh pp wp yp rp m ys m))%assert
 row_scan(normal_ret_assert(row_result sh pp wp yp rp m ys)).
Proof.
 intros sh pp wp yp rp m ys SH M Len Bits.
 unfold CCSearchContext.Delta;abbreviate_semax.
 let C:=eval cbv -[Int.repr]in row_scan in
 lazymatch goal with|-semax ?D ?P _ ?R=>change(semax D P C R)end.
 unfold row_memory. Intros. forward.
 forward_loop
 (EX i:Z,PROP(0<=i<=m;forall j,0<=j<i ->Znth j ys=0)
  LOCAL(temp _p pp;temp _w wp;lvar _row tuint rp;temp _i(Vint(Int.repr i)))
  SEP(row_memory sh pp wp yp rp m ys m))%assert
 break:(row_result sh pp wp yp rp m ys).
 { Exists 0. unfold row_memory;entailer!. }
 { Intros i. unfold row_memory. Intros.
   forward. forward_if.
   { forward.
     assert(B:Znth i ys=0\/Znth i ys=1)by(apply (proj1(Forall_Znth _ _)Bits);lia).
     unfold tbytes;forward.
     { destruct B as[B|B];rewrite B;entailer!. }
     forward_if.
     { forward. forward. unfold row_result. Exists i.
       unfold row_memory,tbytes;entailer!. }
     { forward. Exists(i+1).
       unfold row_memory,tbytes;entailer!.
       intros j J;destruct(Z.eq_dec j i)as[->|Ne];[assumption|apply H0;lia]. }
   }
   { assert(E:i=m)by lia;subst i. forward.
     unfold row_result. Exists m. unfold row_memory;entailer!. }
 }
Qed.
End Proof.
Print Assumptions block_search_row.
