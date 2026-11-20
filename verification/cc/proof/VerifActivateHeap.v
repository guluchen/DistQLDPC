(* Exact activation stores under the complete initialized search heap. The
   actual surrounding phase0 decisions remain separate. *)
Require Import VST.floyd.proofauto.
Require Import CCV.ccv_core CCV.CCSearchSpecs CCV.CCSearchContext CCV.CCRowHeap
 CCV.CCSearchHeap CCV.CCActivateHeap CCV.CCActivateMemory CCV.CCBlockFrame
 CCV.VerifActivateFrame CCV.VerifActivateArray.
Import ListNotations. Open Scope Z_scope.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
Definition activate_full_frame sh a p tp(rp:val)cap seed budget rules depth top xs fs ys zs pk buf out s:assert:=
 (PROP()LOCAL(temp _p(ptr_problem p);temp _w(ptr_workspace p);temp _out(ptr_out p);
 temp _stats(ptr_stats p);temp _cap(Vint(Int.repr cap));temp _seed(Vint(Int.repr seed));
 temp _budget(Vint(Int.repr budget));temp _rules(Vint(Int.repr rules));
 temp _depth(Vint(Int.repr depth));temp _finish(Vint Int.zero);lvar _top tuint tp)
 SEP(activate_heap_extra sh a p tp top xs fs ys zs pk buf out s))%assert.
Definition activated_full_heap sh a p tp rp cap seed budget rules depth top i row xs fs ys zs pk buf frames out s:assert:=
 (PROP()LOCAL(temp _p(ptr_problem p);temp _w(ptr_workspace p);temp _out(ptr_out p);
 temp _stats(ptr_stats p);temp _cap(Vint(Int.repr cap));temp _seed(Vint(Int.repr seed));
 temp _budget(Vint(Int.repr budget));temp _rules(Vint(Int.repr rules));
 temp _depth(Vint(Int.repr depth));temp _finish(Vint Int.zero);
 temp _f(field_address0(tarray CCSearchSpecs.frame_type(model_n a))[ArraySubsc i](ptr_frames p));
 lvar _top tuint tp;lvar _row tuint rp)
 SEP(row_heap sh a p tp rp top(Z.of_nat row)xs fs ys zs pk buf
 (upd_Znth i frames(activate_raw(Znth i frames)row))out s))%assert.
Section Proof.
Context{Espec:OracleKind}.
Lemma block_activate_heap:forall sh a p tp rp cap seed budget rules depth top i(row:nat)
 xs fs ys zs pk buf frames out s,
 Zlength frames=model_n a ->0<=i<model_n a ->0<=Z.of_nat row<=Int.max_signed ->
 semax CCSearchContext.Delta
 (PROP()LOCAL(temp _p(ptr_problem p);temp _w(ptr_workspace p);temp _out(ptr_out p);
 temp _stats(ptr_stats p);temp _cap(Vint(Int.repr cap));temp _seed(Vint(Int.repr seed));
 temp _budget(Vint(Int.repr budget));temp _rules(Vint(Int.repr rules));
 temp _depth(Vint(Int.repr depth));temp _finish(Vint Int.zero);
 temp _f(field_address0(tarray CCSearchSpecs.frame_type(model_n a))[ArraySubsc i](ptr_frames p));
 lvar _top tuint tp;lvar _row tuint rp)
 SEP(row_heap sh a p tp rp top(Z.of_nat row)xs fs ys zs pk buf frames out s))%assert
 zero_activate
 (normal_ret_assert(activated_full_heap sh a p tp rp cap seed budget rules depth top i row
 xs fs ys zs pk buf frames out s)).
Proof.
 intros sh a p tp rp cap seed budget rules depth top i row xs fs ys zs pk buf frames out s Len I Row.
 set(F:=activate_full_frame sh a p tp rp cap seed budget rules depth top xs fs ys zs pk buf out s).
 set(cp:=field_address0(tarray CCSearchSpecs.frame_type(model_n a))[ArraySubsc i](ptr_frames p)).
 eapply semax_post' with(R':=((PROP()LOCAL(temp _f cp;lvar _row tuint rp)
 SEP(@data_at CCSearchSpecs.CompSpecs Tsh(tarray CCSearchSpecs.frame_type(model_n a))
 (upd_Znth i frames(activate_raw(Znth i frames)row))(ptr_frames p);
 @data_at CCSearchSpecs.CompSpecs Tsh tuint(Vint(Int.repr(Z.of_nat row)))rp))*F)%logic).
 2:{ eapply semax_pre with(P':=((PROP()LOCAL(temp _f cp;lvar _row tuint rp)
 SEP(@data_at CCSearchSpecs.CompSpecs Tsh(tarray CCSearchSpecs.frame_type(model_n a))frames(ptr_frames p);
 @data_at CCSearchSpecs.CompSpecs Tsh tuint(Vint(Int.repr(Z.of_nat row)))rp))*F)%logic).
 { unfold F,cp,activate_full_frame;rewrite row_heap_activate_split;go_lowerx;normalize;cancel.
 apply andp_right;[apply prop_right;tauto|cancel]. }
 apply semax_normal_block_frame.
 { unfold F,activate_full_frame,zero_activate;auto 50 with closed. }
 unfold cp;apply block_activate_array;assumption.
 }
 apply andp_left2;unfold F,cp,activate_full_frame,activated_full_heap.
 go_lowerx;normalize;rewrite row_heap_activate_split;normalize;cancel.
Qed.
End Proof.
Print Assumptions block_activate_heap.
