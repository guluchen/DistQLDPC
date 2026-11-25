(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.floyd.reassoc_seq VerifDetected
 VerifRowTally VerifMarkRow PreparedIndexCuts PreparedCallerLocals.
Require Import flag_level_ast.
Local Open Scope Z_scope.

Definition remember_row:=snd after_packed_check.
Definition first_row (branch r:Z):=if Z_lt_dec branch 0 then r else branch.
Definition row_registers (branch row:Z):=
 [temp _branch (Vint (Int.repr branch));temp _r (Vint (Int.repr row))].

Theorem compiled_remember {Espec:OracleKind} branch row (frame:mpred) :
 -1<=branch<=Int.max_signed ->
 semax (func_tycontext f_index_children Vprog [] [])
 (PROPx [] (LOCALx (row_registers branch row) (SEPx [frame])))
 remember_row (normal_ret_assert (PROPx []
 (LOCALx (row_registers (first_row branch row) row) (SEPx [frame])))).
Proof.
 intro fits. change remember_row with (Sifthenelse
   (Ebinop Olt (Etempvar _branch tint) (Econst_int (Int.repr 0) tint) tint)
   (Sset _branch (Etempvar _r tint)) Sskip).
 unfold row_registers,first_row.
 abbreviate_semax;forward_if;destruct Z_lt_dec;try solve [rep_lia];forward;entailer!.
Qed.

Lemma retain_index_locals {Espec:OracleKind} {CS:compspecs} D c P Q before after owned returned saved extra:
 closed_wrt_modvars c (LOCALx saved (SEPx extra)) ->
 semax D (PROPx P (LOCALx before (SEPx owned))) c
   (normal_ret_assert (PROPx Q (LOCALx after (SEPx returned)))) ->
 semax D (PROPx P (LOCALx (before++saved) (SEPx (owned++extra)))) c
   (normal_ret_assert (PROPx Q (LOCALx (after++saved) (SEPx (returned++extra))))).
Proof.
 intros stable body. pose proof (@semax_frame CS Espec D _ c _ _ stable body) as keep.
 rewrite frame_normal in keep. rewrite !separate_caller_env. exact keep.
Qed.

(* A clash with an existing packing mark is a successful scan step.
   It leaves both the packing and the stamp table alone and still
   remembers the first odd row. *)
Theorem compiled_clashing_row {Espec:OracleKind} s cp bp mp cols blocks marks lo hi stamp branch row depth packed :
 0<=lo<=hi -> hi<=Int.max_unsigned -> hi<=Zlength cols ->
 (forall j,lo<=j<hi -> Int.unsigned (Znth j cols)<Zlength blocks) ->
 Zlength marks=Zlength blocks -> -1<=branch<=Int.max_signed ->
 let pair:=counted blocks marks stamp cols lo hi in
 fst pair<>Int.zero -> snd pair<>Int.zero ->
 let mem:=tally_memory s cp bp mp cols blocks marks in
 let saved:=[temp _size (Vint (Int.repr depth));temp _packed (Vint (Int.repr packed))] in
 semax (func_tycontext f_index_children Vprog [] [])
 (PROPx [] (LOCALx (tally_loc s lo hi stamp (Int.zero,Int.zero)++row_registers branch row++saved) (SEPx [mem])))
 remaining_row (normal_ret_assert (PROPx []
 (LOCALx (row_registers (first_row branch row) row++saved) (SEPx [mem])))).
Proof.
 intros range cap bound indices extent branch_fits pair available clash mem saved.
 pose proof (@keep_tally_context Espec s cp bp mp cols blocks marks lo hi stamp (row_registers branch row++saved) []
   range cap bound indices extent ltac:(unfold tally_loop,row_registers,saved;cbn [app];auto 100 with closed)) as tally.
 rewrite real_tally_and_guard;eapply semax_seq';[exact tally|].
 fold pair;unfold tally_loc,no_free_guard,saved;abbreviate_semax.
 apply semax_if_seq;forward_if;[congruence|].
 change after_empty_count with
   (Ssequence (Sifthenelse (Eunop Onotbool (Etempvar _clash tuint) tint)
     (Ssequence packing_budget_guard (fst after_packed_check)) Sskip) remember_row).
 apply semax_if_seq;forward_if;[congruence|].
 pose proof (@retain_index_locals Espec VerifDetected.CompSpecs (func_tycontext f_index_children Vprog [] []) remember_row
  _ _ _ _ _ _ saved [] ltac:(unfold saved,remember_row,after_packed_check,after_empty_count,remaining_row;cbn [app];auto 100 with closed) (@compiled_remember Espec branch row mem branch_fits)) as last.
 eapply semax_pre;[|exact last].
 unfold row_registers,saved;cbn [app];entailer!;try apply derives_refl.
Qed.

Definition pack_registers s depth p :=
 [temp _s s;temp _size (Vint (Int.repr depth));temp _packed (Vint (Int.repr p))].
Definition stored_weight s w:=field_at Tsh level_type [StructField _w] (Vint (Int.repr w)) s.

Lemma pack_guard_continues {Espec:OracleKind} s w depth p:
 0<=depth<=w -> w<=Int.max_signed -> 0<=p -> p+1<=w-depth ->
 semax (func_tycontext f_index_children Vprog [] [])
 (PROPx [] (LOCALx (pack_registers s depth p) (SEPx [stored_weight s w])))
 packing_budget_guard (normal_ret_assert (PROPx []
  (LOCALx (pack_registers s depth (p+1)) (SEPx [stored_weight s w])))).
Proof.
 intros wd limit pos fits;unfold packing_budget_guard,pack_registers,stored_weight;
 abbreviate_semax;reassoc_seq;do 3 forward;forward_if;[exfalso;rep_lia|forward;entailer!].
Qed.

Definition block_part s bp blocks:=
 (field_at Tsh level_type [StructField _blk] bp s *
  data_at Tsh (tarray tuint (Zlength blocks)) (map Vint blocks) bp)%logic.

Lemma separate_mark_storage s cp bp mp cols blocks ms :
 tally_memory s cp bp mp cols blocks ms =
 (mark_memory s cp mp cols ms * block_part s bp blocks)%logic.
Proof. unfold tally_memory,mark_memory,block_part;apply pred_ext;cancel. Qed.

(* The no-clash row fits. C increments the count, paints its CSR entries
   with the stamp and records the first row. The postcondition retains the
   new count, branch and tag table for the next iteration. *)
Theorem compiled_add_row {Espec:OracleKind} s cp bp mp cols blocks ms lo hi stamp w depth p branch row :
 0<=lo<=hi -> hi<=Int.max_unsigned -> hi<=Zlength cols ->
 (forall j,lo<=j<hi -> Int.unsigned (Znth j cols)<Zlength blocks) -> Zlength ms=Zlength blocks ->
 0<=depth<=w -> w<=Int.max_signed -> 0<=p -> p+1<=w-depth -> -1<=branch<=Int.max_signed ->
 let pair:=counted blocks ms stamp cols lo hi in fst pair<>Int.zero -> snd pair=Int.zero ->
 let mem tags:=tally_memory s cp bp mp cols blocks tags in
 let regs step:=[temp _size (Vint (Int.repr depth));temp _packed (Vint (Int.repr step))] in
 let weight:=stored_weight s w in
 semax (func_tycontext f_index_children Vprog [] [])
 (PROPx [] (LOCALx (tally_loc s lo hi stamp (Int.zero,Int.zero)++row_registers branch row++regs p)
         (SEPx [mem ms;weight])))
 remaining_row (normal_ret_assert (PROPx []
   (LOCALx (row_registers (first_row branch row) row++regs (p+1))
    (SEPx [mem (marked stamp ms cols lo hi);weight])))).
Proof.
 intros slice limit bound indices extent wd signed pos fits branch_ok pair nonzero disjoint mem regs weight.
 set (rr:=row_registers branch row).
 pose proof (@keep_tally_context Espec s cp bp mp cols blocks ms lo hi stamp (rr++regs p) [weight]
  slice limit bound indices extent ltac:(unfold tally_loop,rr,row_registers,regs;cbn [app];auto 100 with closed)) as tally.
 rewrite real_tally_and_guard;eapply semax_seq';[exact tally|].
 fold pair;unfold tally_loc,no_free_guard;rewrite disjoint;abbreviate_semax.
 apply semax_if_seq;forward_if;[congruence|].
 change after_empty_count with (Ssequence (Sifthenelse (Eunop Onotbool (Etempvar _clash tuint) tint)
   (Ssequence packing_budget_guard mark_loop) Sskip) remember_row).
 apply semax_if_seq;forward_if;[|solve [discriminate|contradiction|exfalso;rep_lia]].
 match goal with |- semax _ _ (Ssequence (Ssequence ?head ?middle) ?rest) _ =>
   apply (semax_unfold_seq (Ssequence head (Ssequence middle rest)) (Ssequence (Ssequence head middle) rest) eq_refl) end.
 set (rowdata:=[temp _begin (Vint (Int.repr lo));temp _end (Vint (Int.repr hi));temp _stamp (Vlong stamp)]).
 pose proof (@retain_index_locals Espec VerifDetected.CompSpecs (func_tycontext f_index_children Vprog [] []) packing_budget_guard _ _ _ _ _ _
      (rowdata++rr) [mem ms] ltac:(unfold rowdata,rr,row_registers,packing_budget_guard;cbn [app];auto 100 with closed)
      (@pack_guard_continues Espec s w depth p wd signed pos fits)) as increment.
 eapply semax_seq'.
 - eapply semax_pre;[|exact increment]. unfold pack_registers,regs,rr,row_registers,rowdata,mem,weight;cbn [app];entailer!;cancel.
 - pose proof (@semax_mark_row Espec s cp mp cols ms lo hi stamp slice limit bound
        ltac:(intros j live;rewrite extent;apply indices;exact live)) as paint.
   pose proof (@retain_index_locals Espec VerifDetected.CompSpecs (func_tycontext f_index_children Vprog [] []) mark_loop _ _ _ _ _ _
      (rr++regs (p+1)) [block_part s bp blocks;weight]
      ltac:(unfold rr,row_registers,regs,mark_loop;cbn [app];auto 100 with closed) paint) as painted.
   eapply semax_seq'.
   + eapply semax_pre;[|exact painted]. unfold rr,row_registers,rowdata,mem,pack_registers,regs,mark_env,weight;cbn [app].
     rewrite separate_mark_storage;entailer!;cancel.
   + set (newmem:=mem (marked stamp ms cols lo hi)).
     pose proof (@retain_index_locals Espec VerifDetected.CompSpecs (func_tycontext f_index_children Vprog [] []) remember_row _ _ _ _ _ _
       (regs (p+1)) [weight] ltac:(unfold regs,remember_row,after_packed_check,after_empty_count,remaining_row;cbn [app];auto 100 with closed)
       (@compiled_remember Espec branch row newmem branch_ok)) as remember.
     eapply semax_pre;[|exact remember]. unfold rr,row_registers,regs,mark_env,newmem,mem,weight;cbn [app].
     rewrite separate_mark_storage;entailer!;cancel.
Qed.
