(* Actual first-odd-syndrome scan with full caller ownership and exact row
   certificate. This is a phase0 prefix, not the complete search body. *)
Require Import VST.floyd.proofauto.
Require Import CCV.ccv_core CCV.CCSearchSpecs CCV.CCSearchContext CCV.CCRowHeap
 CCV.CCRowScanHeap CCV.CCBlockFrame CCV.VerifSearchRow.
Import ListNotations. Open Scope Z_scope.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
Definition row_scan_heap_frame sh a p tp fp cap seed budget rules depth top remaining
 xs fs ys zs pk buf frames out s:assert:=
 (PROP()LOCAL(temp _f fp;temp _depth(Vint(Int.repr depth));temp _finish(Vint Int.zero);
 temp _cap(Vint(Int.repr cap));temp _seed(Vint(Int.repr seed));temp _budget(Vint(Int.repr budget));
 temp _rules(Vint(Int.repr rules));temp _out(ptr_out p);temp _stats(ptr_stats p);
 temp _remaining(Vint(Int.repr remaining));lvar _top tuint tp)
 SEP(row_scan_extra sh a p tp top xs fs ys zs pk buf frames out s))%assert.
Definition row_scan_heap_result sh a p tp rp fp cap seed budget rules depth top remaining
 xs fs ys zs pk buf frames out s:assert:=
 (EX row:Z,
 PROP(0<=row<=model_m a;forall j,0<=j<row ->Znth j ys=0;
 row<model_m a ->Znth row ys=1)
 LOCAL(temp _p(ptr_problem p);temp _w(ptr_workspace p);temp _f fp;
 temp _depth(Vint(Int.repr depth));temp _finish(Vint Int.zero);
 temp _cap(Vint(Int.repr cap));temp _seed(Vint(Int.repr seed));temp _budget(Vint(Int.repr budget));
 temp _rules(Vint(Int.repr rules));temp _out(ptr_out p);temp _stats(ptr_stats p);
 temp _remaining(Vint(Int.repr remaining));lvar _top tuint tp;lvar _row tuint rp)
 SEP(row_heap sh a p tp rp top row xs fs ys zs pk buf frames out s))%assert.
Section Proof.
Context{Espec:OracleKind}.
Lemma block_row_scan_heap:forall sh a p tp rp fp cap seed budget rules depth top remaining
 xs fs ys zs pk buf frames out s,
 readable_share sh ->0<=model_m a<=Int.max_signed ->Zlength ys=model_m a ->
 Forall(fun z:Z=>z=0\/z=1)ys ->
 semax CCSearchContext.Delta
 (PROP()LOCAL(temp _p(ptr_problem p);temp _w(ptr_workspace p);temp _f fp;
 temp _depth(Vint(Int.repr depth));temp _finish(Vint Int.zero);
 temp _cap(Vint(Int.repr cap));temp _seed(Vint(Int.repr seed));temp _budget(Vint(Int.repr budget));
 temp _rules(Vint(Int.repr rules));temp _out(ptr_out p);temp _stats(ptr_stats p);
 temp _remaining(Vint(Int.repr remaining));lvar _top tuint tp;lvar _row tuint rp)
 SEP(row_heap sh a p tp rp top(model_m a)xs fs ys zs pk buf frames out s))%assert
 row_scan
 (normal_ret_assert(row_scan_heap_result sh a p tp rp fp cap seed budget rules depth top remaining
 xs fs ys zs pk buf frames out s)).
Proof.
 intros sh a p tp rp fp cap seed budget rules depth top remaining xs fs ys zs pk buf frames out s
 SH M Len Bits.
 set(F:=row_scan_heap_frame sh a p tp fp cap seed budget rules depth top remaining
 xs fs ys zs pk buf frames out s).
 eapply semax_post' with(R':=(row_result sh(ptr_problem p)(ptr_workspace p)(ptr_syndrome p)rp
 (model_m a)ys*F)%logic).
 2:{ eapply semax_pre with(P':=((PROP()LOCAL(temp _p(ptr_problem p);temp _w(ptr_workspace p);
 lvar _row tuint rp)
 SEP(row_memory sh(ptr_problem p)(ptr_workspace p)(ptr_syndrome p)rp(model_m a)ys(model_m a)))*F)%logic).
 { unfold F,row_scan_heap_frame;rewrite row_heap_scan_split;go_lowerx;normalize;cancel.
 apply andp_right;[apply prop_right;tauto|cancel]. }
 apply semax_normal_block_frame.
 { unfold F,row_scan_heap_frame,row_scan;auto 50 with closed. }
 apply block_search_row;assumption.
 }
 apply andp_left2. unfold row_result,F,row_scan_heap_frame,row_scan_heap_result.
 go_lowerx;normalize.
 match goal with H:0<= ?r <=model_m a |- _=>Exists r end.
 rewrite row_heap_scan_split. normalize;cancel.
 apply andp_right;[apply prop_right;tauto|cancel].
Qed.
End Proof.
Print Assumptions block_row_scan_heap.
