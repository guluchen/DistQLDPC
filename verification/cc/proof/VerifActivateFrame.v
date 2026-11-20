(* Exact phase0 row/next/phase stores, retaining every other frame field and
   the owned row scratch cell. Not the whole phase0 caller. *)
Require Import VST.floyd.proofauto.
Require Import CCV.ccv_core CCV.CCSearchSpecs CCV.CCSearchContext CCV.CCSearchFragments
 CCV.CCActivateMemory CCV.CCFrameShape CCV.CCFrameJoin.
Import ListNotations. Open Scope Z_scope.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
Definition zero_activate:=search_fragment(phase_zero_path++
 [SeqNext;SeqNext;SeqNext;SeqNext;SeqNext;SeqNext;SeqNext;SeqNext;ThenBranch]).
Lemma zero_activate_not_skip:zero_activate<>Sskip.
Proof. discriminate. Qed.
Section Proof.
Context{Espec:OracleKind}.
Lemma block_activate_frame:forall fp rp(row:nat)r nx ch mk ph,
 0<=Z.of_nat row<=Int.max_signed ->
 semax CCSearchContext.Delta
 (PROP()LOCAL(temp _f fp;lvar _row tuint rp)
 SEP(data_at Tsh CCSearchSpecs.frame_type(r,(nx,(ch,(mk,ph))))fp;
 data_at Tsh tuint(Vint(Int.repr(Z.of_nat row)))rp))%assert
 zero_activate
 (normal_ret_assert
 (PROP()LOCAL(temp _f fp;lvar _row tuint rp)
 SEP(data_at Tsh CCSearchSpecs.frame_type(activate_raw(r,(nx,(ch,(mk,ph))))row)fp;
 data_at Tsh tuint(Vint(Int.repr(Z.of_nat row)))rp))%assert).
Proof.
 intros fp rp row r nx ch mk ph Row.
 unfold CCSearchContext.Delta;abbreviate_semax.
 let C:=eval cbv -[Int.repr]in zero_activate in
 lazymatch goal with|-semax ?D ?P _ ?R=>change(semax D P C R)end.
 rewrite frame_data_at_fields;unfold frame_fields. Intros.
 forward. forward. forward. forward.
 unfold activate_raw;cbn[fst snd].
 rewrite frame_data_at_fields;unfold frame_fields;entailer!.
Qed.
End Proof.
Print Assumptions block_activate_frame.
