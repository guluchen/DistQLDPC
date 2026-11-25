(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VerifDetected VerifLowestBit VerifRowTally
 PreparedIndexWordStep PreparedIndexCuts PreparedIndexAdvance PreparedIndexIteration
 LowestWord WordScan flag_level_ast.
Local Open Scope Z_scope.

Lemma index_context_with_bit :
 tycontext_sub (func_tycontext f_index_children Vprog [] [])
  (func_tycontext f_index_children Vprog LowGprog []).
Proof.
 apply tycontext_sub_Gprog_nil;vm_compute;
 repeat (apply list_norepet_cons;[simpl;intuition congruence|]);apply list_norepet_nil.
Qed.

Section Bit.
Context {Espec:OracleKind}.
Variables (gv:globals) (sh:share) (s op cp bp mp:val) (offsets:list Z)
 (cols blocks:list int) (stamp:int64) (wi dep w:Z) (nc pk:int64).
Definition word_locals word branch p:=
 [temp _wi (Vint (Int.repr wi));temp _odd (Vlong word);gvars gv;
  temp _s s;temp _stamp (Vlong stamp);temp _branch (Vint (Int.repr branch));
  temp _packed (Vint (Int.repr p));temp _size (Vint (Int.repr dep))].
Definition word_heap ms a b:=
 [lookup_bytes gv sh; offsets_heap s op offsets; tally_memory s cp bp mp cols blocks ms;
  stored_weight s w;statistics s a b].
Definition scanning word branch p ms:=PROPx [] (LOCALx (word_locals word branch p) (SEPx (word_heap ms nc pk))).
Definition cut_word ms a b:=function_body_ret_assert tint
 (PROPx [] (LOCALx [temp ret_temp (Vint Int.zero)] (SEPx (word_heap ms a b)))).
Definition bit_out word branch row ms result :=
 match result with
 | NoCandidate=>cut_word ms (Int64.add nc Int64.one) pk
 | PackingExceeded=>cut_word ms nc (Int64.add pk Int64.one)
 | ContinueRow p tags=>normal_ret_assert (scanning (clear word) (first_row branch row) p tags)
 end.

(* The body of while (odd), including the call, offset loads, two CSR loops,
   mark writes and both early function returns, shares one state contract. *)
Theorem compiled_active_bit word bit branch packed ms :
 let row:=64*wi+trailing bit in
 let lo:=Znth row offsets in let hi:=Znth (row+1) offsets in
 readable_share sh -> Int64.unsigned word=Z.pos bit ->
 0<=wi -> 0<=row<Int.max_signed -> row+1<Zlength offsets ->
 0<=lo<=hi -> hi<=Int.max_unsigned -> hi<=Zlength cols ->
 (forall j,lo<=j<hi->Int.unsigned (Znth j cols)<Zlength blocks) ->
 Zlength ms=Zlength blocks -> 1<=dep<=w -> w<=Int.max_signed ->
 0<=packed<=w-dep -> -1<=branch<=Int.max_signed ->
 semax (func_tycontext f_index_children Vprog LowGprog []) (scanning word branch packed ms)
 active_word_iteration (bit_out word branch row ms (run_row blocks ms stamp cols lo hi packed (w-dep))).
Proof.
 intros row lo hi readable live wi_ok fit table slice limit bound indices extent depth_ok weight_ok pack_ok branch_ok.
 set (loopvars:=[temp _packed (Vint (Int.repr packed));temp _size (Vint (Int.repr dep));
                 temp _branch (Vint (Int.repr branch))]).
 set (owner:=[temp _s s;temp _stamp (Vlong stamp)]).
 set (wordvars:=[temp _wi (Vint (Int.repr wi));temp _odd (Vlong (clear word));gvars gv]).
 set (extra:=[tally_memory s cp bp mp cols blocks ms;stored_weight s w;statistics s nc pk]).
 pose proof (@compiled_word_step Espec gv sh wi word bit readable live wi_ok ltac:(lia)) as decode.
 pose proof (@retain_index_locals Espec VerifDetected.CompSpecs (func_tycontext f_index_children Vprog LowGprog []) row_arithmetic _ _ _ _ _ _
    (loopvars++owner) (offsets_heap s op offsets::extra)
    ltac:(unfold loopvars,owner,extra,row_arithmetic,active_word_iteration;cbn [app];auto 100 with closed) decode) as keepbit.
 eapply arithmetic_offsets_scan.
 - eapply semax_pre;[|exact keepbit].
   unfold scanning,word_locals,word_heap,loopvars,owner,extra;cbn [app];entailer!;cancel.
 - pose proof (@compiled_row_offsets Espec s op offsets row stamp fit table) as bounds.
   pose proof (@retain_index_locals Espec VerifDetected.CompSpecs (func_tycontext f_index_children Vprog LowGprog []) open_offsets _ _ _ _ _ _
    (loopvars++wordvars) (lookup_bytes gv sh::extra)
    ltac:(unfold loopvars,wordvars,extra,open_offsets,row_tests,active_word_iteration;cbn [app];auto 100 with closed) bounds) as kept.
   eapply semax_pre;[|exact kept]. unfold loopvars,owner,wordvars,extra,row;cbn [app];entailer!;cancel.
 - pose proof (@compiled_row_outcome Espec s cp bp mp cols blocks stamp lo hi dep w row branch packed nc pk
       slice limit bound indices depth_ok weight_ok pack_ok branch_ok ms extent) as step.
   eapply semax_Delta_subsumption;[exact index_context_with_bit|].
   pose proof (@semax_frame VerifDetected.CompSpecs Espec (func_tycontext f_index_children Vprog [] []) _ remaining_row _ (LOCALx (owner++wordvars)
     (SEPx [lookup_bytes gv sh;offsets_heap s op offsets]))
     ltac:(unfold owner,wordvars,remaining_row;cbn [app];auto 150 with closed) step) as framed.
   eapply semax_post_flipped.
   + eapply semax_pre;[|exact framed]. rewrite <-PreparedCallerLocals.separate_caller_env.
     unfold tally_loc,row_registers,owner,wordvars,loopvars,extra,lo,hi;cbn [app];entailer!;cancel.
   + destruct (run_row _ _ _ _ _ _ _ _) as [| |p tags];cbn [bit_out iteration_result RA_normal frame_ret_assert
       function_body_ret_assert normal_ret_assert cut_word];try solve [normalize].
     unfold scanning,word_locals,word_heap,owner,wordvars,row_registers;cbn [app];
       rewrite <-PreparedCallerLocals.separate_caller_env;cbn [app];entailer!;cancel.
   + destruct (run_row _ _ _ _ _ _ _ _);cbn [bit_out iteration_result cut_word RA_break frame_ret_assert
       function_body_ret_assert normal_ret_assert];normalize.
   + destruct (run_row _ _ _ _ _ _ _ _);cbn [bit_out iteration_result cut_word RA_continue frame_ret_assert
       function_body_ret_assert normal_ret_assert];normalize.
   + intro opt;destruct (run_row _ _ _ _ _ _ _ _);cbn [bit_out iteration_result cut_word RA_return frame_ret_assert
       function_body_ret_assert normal_ret_assert];try solve [normalize].
     all: unfold bind_ret;destruct opt as [v|];[|normalize].
     all: unfold word_heap,owner,wordvars;cbn [app];go_lowerx;normalize;try cancel;try tauto;try apply derives_refl.
Qed.
End Bit.
