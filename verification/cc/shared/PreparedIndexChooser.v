(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VerifDetected VerifLowestBit VerifEpoch EpochFreshness VerifRowTally
 PreparedIndexWordStep PreparedIndexAdvance PreparedIndexIteration PreparedIndexBitBody PreparedIndexWhile
 PreparedIndexSweep PreparedIndexFinish PreparedIndexEpoch flag_level_ast.
#[local] Existing Instance VerifDetected.CompSpecs.
Local Open Scope Z_scope.

Definition remaining_storage gv sh s sp op cp bp children offsets cols blocks w words nc pk old :=
 (syndrome_memory s sp words * lookup_bytes gv sh * offsets_heap s op offsets *
  field_at Tsh level_type [StructField _rq] cp s * data_at Tsh (tarray tuint (Zlength cols)) (map Vint cols) cp *
  field_at Tsh level_type [StructField _blk] bp s * data_at Tsh (tarray tuint (Zlength blocks)) (map Vint blocks) bp *
  stored_weight s w * statistics s nc pk * child_storage children old)%logic.

Definition initial_index gv sh s sp op cp bp mp children offsets cols blocks dep w words nc pk old last ms:=
 PROPx [] (LOCALx (index_locals gv s children dep)
    (SEPx [counters_header s (Zlength ms) last;
           chooser_storage gv sh s sp op cp bp mp children offsets cols blocks w words ms nc pk old])).

Section Chooser.
Context {Espec:OracleKind}.
Variables (gv:globals) (sh:share) (s sp op cp bp mp children:val) (offsets:list Z)
  (cols blocks:list int) (dep w:Z) (words:list int64) (nc pk:int64) (old:list int)
  (last:int64) (marks:list int64).
Let n:=Zlength marks.
Let stamp:=Int64.repr (advance_tag false (Int64.unsigned last)).
Let tags:=after_tags false (Int64.unsigned last) marks.
Let D:=func_tycontext f_index_children Vprog index_calls [].
Let G:=func_tycontext f_index_children Vprog LowGprog [].
Let input:=initial_index gv sh s sp op cp bp mp children offsets cols blocks dep w words nc pk old last marks.
Let post answer:=frame_ret_assert (after_selection gv sh s sp op cp bp mp children offsets cols blocks w words nc pk old answer)
                                   (fun _:environ=>counters_header s n stamp).

Theorem full_index_from_scan plan :
 let answer:=sweep offsets cols blocks stamp dep w 0 plan (-1) 0 tags in
 0<n<=Int.max_signed ->
 semax G (sweep_entry offsets cols blocks stamp dep w gv sh s sp op cp bp mp words nc pk (-1) 0 tags)
   all_words (sweep_post offsets cols blocks stamp dep w gv sh s sp op cp bp mp words nc pk answer) ->
 (forall row p ms,answer=AllBits row p ms -> safe_index_row offsets cols blocks row /\
    Znth (row+1) offsets-Znth row offsets<=Zlength old) ->
 Zlength old<=Int.max_signed ->
 semax D input (fn_body f_index_children) (post answer).
Proof.
 intros answer size checked justified room.
 pose proof (@begin_index_at_epoch Espec s mp marks last gv children dep size) as start.
 cbn zeta in start;fold n stamp tags in start.
 set (rest:=remaining_storage gv sh s sp op cp bp children offsets cols blocks w words nc pk old).
 pose proof (@semax_frame' Espec VerifDetected.CompSpecs _ _ _ _ _ _ _ _ rest start) as enter.
 eapply index_sections.
 - eapply semax_pre;[|exact enter].
   unfold input,initial_index,chooser_storage,tally_memory,rest,remaining_storage,tag_storage,index_locals,n;
     go_lowerx;normalize;cancel.
 - eapply semax_Delta_subsumption;[exact bit_context_in_chooser|].
   pose proof (@compiled_scan_then_emit Espec gv sh s sp op cp bp mp children offsets cols blocks stamp dep w
      words nc pk old plan (-1) 0 tags checked justified room) as scan.
   cbn zeta in scan;fold answer in scan.
   pose proof (@semax_frame VerifDetected.CompSpecs Espec G _ scan_then_emit _ (fun _:environ=>counters_header s n stamp)
       ltac:(hnf;intros;auto) scan) as execute.
   eapply semax_pre;[|exact execute].
   unfold sweep_entry,word_heap,rest,remaining_storage,tag_storage,tally_memory,index_locals,started_regs;
      go_lowerx;normalize;cancel.
 all: apply andp_right;[apply prop_right;unfold liftx in *;simpl in *;intuition|cancel].
Qed.
End Chooser.
