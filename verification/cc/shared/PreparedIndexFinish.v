(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.floyd.reassoc_seq VerifDetected
 VerifLowestBit VerifRowTally VerifGather PreparedIndexSweep PreparedIndexWhile
 PreparedIndexBitBody PreparedIndexAdvance PreparedIndexIteration PreparedIndexWordStep
 PreparedIndexGather RowGather ClightSelect flag_level_ast.
#[local] Existing Instance VerifDetected.CompSpecs.
Local Open Scope Z_scope.

Definition follows_word_loop (st:statement):=
 match st with Ssequence words _ => counts_on _wi words | _=>false end.
Definition scan_then_emit:statement:=ltac:(native_fragment follows_word_loop f_index_children).
Definition finish_index:=match scan_then_emit with Ssequence _ tail=>tail | _=>Sskip end.
Lemma scan_and_finish:scan_then_emit=Ssequence all_words finish_index.
Proof. reflexivity. Qed.

Definition child_storage children buffer:=
 data_at Tsh (tarray tuint (Zlength buffer)) (map Vint buffer) children.
Definition chooser_storage gv sh s sp op cp bp mp children offsets cols blocks w words tags nc pk buffer:=
 (syndrome_memory s sp words * lookup_bytes gv sh * offsets_heap s op offsets *
  tally_memory s cp bp mp cols blocks tags * stored_weight s w * statistics s nc pk *
  child_storage children buffer)%logic.
Definition output_columns offsets cols blocks result:=
 match result with
 | AllBits row _ _=>gathered blocks cols (Znth row offsets) (Znth (row+1) offsets)
 | _=>nil
 end.
Definition after_selection gv sh s sp op cp bp mp children offsets cols blocks w words nc pk old result:=
 let heap:=chooser_storage gv sh s sp op cp bp mp children offsets cols blocks w words in
 match result with
 | AllBits row packed ms=>let picks:=output_columns offsets cols blocks result in
   function_body_ret_assert tint (PROP() LOCAL(temp ret_temp (Vint (Int.repr (Zlength picks))))
                                  SEP(heap ms nc pk (filled picks old)))%assert
 | EmptyRow ms=>function_body_ret_assert tint (PROP() LOCAL(temp ret_temp (Vint Int.zero))
                                  SEP(heap ms (Int64.add nc Int64.one) pk old))%assert
 | TooManyRows ms=>function_body_ret_assert tint (PROP() LOCAL(temp ret_temp (Vint Int.zero))
                                  SEP(heap ms nc (Int64.add pk Int64.one) old))%assert
 end.

Section Finish.
Context {Espec:OracleKind}.
Variables (gv:globals) (sh:share) (s sp op cp bp mp children:val)
 (offsets:list Z) (cols blocks:list int) (stamp:int64) (dep w:Z) (words:list int64) (nc pk:int64) (old:list int).
Let out:=after_selection gv sh s sp op cp bp mp children offsets cols blocks w words nc pk old.
Let entering b p ms:=(sweep_entry offsets cols blocks stamp dep w gv sh s sp op cp bp mp words nc pk b p ms *
    LOCALx [temp _children children] (SEPx [child_storage children old]))%logic.
Let G:=func_tycontext f_index_children Vprog LowGprog [].

Theorem emit_after_sweep row packed tags :
 safe_index_row offsets cols blocks row ->
 Znth (row+1) offsets - Znth row offsets <= Zlength old ->
 Zlength old<=Int.max_signed ->
 semax G (entering row packed tags) finish_index (out (AllBits row packed tags)).
Proof.
 intros [fit [off [slice [limit [room indices]]]]] capacity cap.
 set (lo:=Znth row offsets);set (hi:=Znth (row+1) offsets).
 set (picks:=gathered blocks cols lo hi).
 set (rest:=(syndrome_memory s sp words * lookup_bytes gv sh *
     @field_at VerifDetected.CompSpecs Tsh level_type [StructField _mark] mp s *
     @data_at VerifDetected.CompSpecs Tsh (tarray tulong (Zlength tags)) (map Vlong tags) mp *
     stored_weight s w * statistics s nc pk)%logic).
 pose proof (@compiled_index_emit Espec s op cp bp children offsets cols blocks old row lo hi fit off
    eq_refl eq_refl slice limit room capacity cap indices) as gather.
 cbn zeta in gather.
 pose proof (@semax_frame VerifDetected.CompSpecs Espec _ _ index_emit _ (fun _:environ=>rest)
    ltac:(hnf;intros;auto) gather) as framed.
 eapply semax_Delta_subsumption;[apply index_context_with_bit|].
 eapply semax_pre with (P':= (PROP() LOCAL(temp _s s;temp _children children;
    temp _branch (Vint (Int.repr row)))
    SEP(gather_mem s op cp bp children offsets cols blocks old;rest))%assert).
 { unfold entering,sweep_entry,rest,gather_mem,child_storage,word_heap,offsets_heap,tally_memory.
   go_lowerx;normalize;cancel. }
 change finish_index with (Ssequence
   (Sifthenelse (Ebinop Olt (Etempvar _branch tint) (Econst_int (Int.repr 0) tint) tint)
     (Sreturn (Some (Econst_int (Int.repr 0) tint))) Sskip)
   (Ssequence (Sset _count__1 (Econst_int (Int.repr 0) tint)) index_emit)).
 abbreviate_semax;apply semax_if_seq;forward_if;[exfalso;rep_lia|].
 eapply semax_seq' with (P':=PROPx [] (LOCALx (gather_loc s children row 0)
   (SEPx [gather_mem s op cp bp children offsets cols blocks old;rest]))).
 - forward;unfold gather_loc;entailer!.
 - eapply semax_post_flipped.
   + eapply semax_pre;[|exact framed]. unfold gather_loc;go_lowerx;normalize;cancel.
   + cbn [RA_normal frame_ret_assert function_body_ret_assert];normalize.
   + cbn [RA_break frame_ret_assert function_body_ret_assert];normalize.
   + cbn [RA_continue frame_ret_assert function_body_ret_assert];normalize.
   + intro v;try unfold POSTCONDITION,abbreviate;unfold out,after_selection,output_columns.
     cbn [RA_return frame_ret_assert function_body_ret_assert];unfold bind_ret;destruct v;[|normalize].
     unfold chooser_storage,gather_mem,child_storage,rest,offsets_heap,tally_memory,lo,hi;
       go_lowerx;normalize;try cancel;try tauto;try apply derives_refl.
     all: try (unfold liftx,local,SEPx in *;cbn;normalize;apply andp_right;[apply prop_right;intuition congruence|cancel]).
Qed.

(* The scan can return from any inner iteration. Only ordinary exit
   reaches the final gather; its row is justified by the PCM theorem. *)
Theorem compiled_scan_then_emit plan b p ms :
 let result:=sweep offsets cols blocks stamp dep w 0 plan b p ms in
 semax G (sweep_entry offsets cols blocks stamp dep w gv sh s sp op cp bp mp words nc pk b p ms)
   all_words (sweep_post offsets cols blocks stamp dep w gv sh s sp op cp bp mp words nc pk result) ->
 (forall row count tags,result=AllBits row count tags ->
   safe_index_row offsets cols blocks row /\ Znth (row+1) offsets-Znth row offsets<=Zlength old) ->
 Zlength old<=Int.max_signed ->
 semax G (entering b p ms) scan_then_emit (out result).
Proof.
 intros result checked rows_fit cap;rewrite scan_and_finish.
 pose proof (@semax_frame VerifDetected.CompSpecs Espec G _ all_words _
   (LOCALx [temp _children children] (SEPx [child_storage children old]))
   ltac:(unfold all_words;auto 150 with closed) checked) as framed.
 destruct result as [row count tags|tags|tags] eqn:E.
 - destruct (rows_fit row count tags eq_refl) as [safe room].
   cbn [sweep_post] in framed;rewrite frame_normal in framed.
   eapply semax_seq';[exact framed|exact (emit_after_sweep row count tags safe room cap)].
 - eapply semax_seq with (Q:=FF);[|apply semax_ff].
   eapply semax_post_flipped;[exact framed|..].
   1-3: cbn [sweep_post RA_normal RA_break RA_continue frame_ret_assert function_body_ret_assert overridePost];normalize.
   intro v;unfold out,after_selection;cbn [sweep_post RA_return frame_ret_assert function_body_ret_assert overridePost];
    unfold bind_ret;destruct v;[|normalize].
   unfold chooser_storage,word_heap;go_lowerx;normalize;try cancel;try tauto;try apply derives_refl.
 - eapply semax_seq with (Q:=FF);[|apply semax_ff].
   eapply semax_post_flipped;[exact framed|..].
   1-3: cbn [sweep_post RA_normal RA_break RA_continue frame_ret_assert function_body_ret_assert overridePost];normalize.
   intro v;unfold out,after_selection;cbn [sweep_post RA_return frame_ret_assert function_body_ret_assert overridePost];
    unfold bind_ret;destruct v;[|normalize].
   unfold chooser_storage,word_heap;go_lowerx;normalize;try cancel;try tauto;try apply derives_refl.
Qed.
End Finish.
