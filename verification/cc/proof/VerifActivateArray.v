(* Exact activation stores through a focused array cell, preserving all other
   frame cells and the row scratch cell. *)
Require Import VST.floyd.proofauto.
Require Import CCV.ccv_core CCV.CCSearchSpecs CCV.CCSearchContext CCV.CCSearchHeap
 CCV.CCActivateMemory CCV.CCFrameFields CCV.CCBlockFrame CCV.VerifActivateFrame.
Import ListNotations. Open Scope Z_scope.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
Section Proof.
Context{Espec:OracleKind}.
Lemma block_activate_array:forall fp rp n i(row:nat)(frames:list frame_value),
 Zlength frames=n ->0<=i<n ->0<=Z.of_nat row<=Int.max_signed ->
 semax CCSearchContext.Delta
 (PROP()LOCAL(temp _f(field_address0(tarray CCSearchSpecs.frame_type n)[ArraySubsc i]fp);
 lvar _row tuint rp)
 SEP(@data_at CCSearchSpecs.CompSpecs Tsh(tarray CCSearchSpecs.frame_type n)frames fp;
 @data_at CCSearchSpecs.CompSpecs Tsh tuint(Vint(Int.repr(Z.of_nat row)))rp))%assert
 zero_activate
 (normal_ret_assert
 (PROP()LOCAL(temp _f(field_address0(tarray CCSearchSpecs.frame_type n)[ArraySubsc i]fp);
 lvar _row tuint rp)
 SEP(@data_at CCSearchSpecs.CompSpecs Tsh(tarray CCSearchSpecs.frame_type n)
 (upd_Znth i frames(activate_raw(Znth i frames)row))fp;
 @data_at CCSearchSpecs.CompSpecs Tsh tuint(Vint(Int.repr(Z.of_nat row)))rp))%assert).
Proof.
 intros fp rp n i row frames Len I Row.
 set(cp:=field_address0(tarray CCSearchSpecs.frame_type n)[ArraySubsc i]fp).
 set(F:=(PROP()LOCAL()SEP(@frame_remainder CCSearchSpecs.CompSpecs Tsh n i frames fp))%assert).
 destruct(Znth i frames)as[r[nx[ch[mk ph]]]]eqn:Cell.
 eapply semax_post' with(R':=((PROP()LOCAL(temp _f cp;lvar _row tuint rp)
 SEP(@data_at CCSearchSpecs.CompSpecs Tsh CCSearchSpecs.frame_type(activate_raw(r,(nx,(ch,(mk,ph))))row)cp;
 @data_at CCSearchSpecs.CompSpecs Tsh tuint(Vint(Int.repr(Z.of_nat row)))rp))*F)%logic).
 2:{ eapply semax_pre with(P':=((PROP()LOCAL(temp _f cp;lvar _row tuint rp)
 SEP(@data_at CCSearchSpecs.CompSpecs Tsh CCSearchSpecs.frame_type(r,(nx,(ch,(mk,ph))))cp;
 @data_at CCSearchSpecs.CompSpecs Tsh tuint(Vint(Int.repr(Z.of_nat row)))rp))*F)%logic).
 { unfold F,cp.
 pose proof(@frame_array_focus CCSearchSpecs.CompSpecs Tsh n i frames fp Len I)as Focus.
 unfold CCFrameFields.frame_type in Focus;unfold CCSearchSpecs.frame_type;rewrite Focus;try rewrite Cell.
 go_lowerx;normalize;cancel. }
 apply semax_normal_block_frame.
 { unfold F;auto 50 with closed. }
 apply block_activate_frame;assumption.
 }
 apply andp_left2;unfold F,cp;go_lowerx;normalize.
 pose proof(@frame_array_reassemble CCSearchSpecs.CompSpecs Tsh n i frames fp(activate_raw(Znth i frames)row)Len I)as Join.
 unfold CCFrameFields.frame_type in Join;rewrite Cell in Join.
 unfold CCSearchSpecs.frame_type.
 lazymatch goal with|- _ |-- (?Actual * _) =>
 lazymatch type of Join with _ = ?Focused =>
 assert(ActualJoin:Actual=Focused)by exact Join;rewrite ActualJoin end end.
 cancel.
Qed.
End Proof.
Print Assumptions block_activate_array.
