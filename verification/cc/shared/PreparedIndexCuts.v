(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.floyd.reassoc_seq VerifDetected ClightSelect ClightNested.
Require Import flag_level_ast.
Local Open Scope Z_scope.

Definition tests_empty_count (stmt:statement) :=
 match stmt with
 | Sifthenelse (Eunop Onotbool (Etempvar id _) _) _ _ => Pos.eqb id _count
 | _=>false end.
Definition no_free_guard:statement:=ltac:(native_while_fragment tests_empty_count f_index_children).

Definition starts_packed_increment (stmt:statement) :=
 match stmt with
 | Ssequence (Ssequence (Sset _ (Ecast (Ebinop Oadd (Etempvar a _) _ _) _)) (Sset b _)) _ =>
   (Pos.eqb a _packed && Pos.eqb b _packed)%bool
 | _=>false end.
Definition packing_budget_guard:statement:=ltac:(native_while_fragment starts_packed_increment f_index_children).

Ltac constant_return :=
 eapply semax_pre;[|apply semax_return];apply andp_right;[entailer!|];
 match goal with post:=_ : ret_assert |- _ => unfold post,abbreviate end;
 cbn [RA_return function_body_ret_assert liftx cast_expropt id ret_type];
 simpl liftx;go_lowerx;entailer!;unfold liftx;cbn;try solve [entailer!|auto|cancel].

(* The zero-count exit increments only its 64-bit statistics field. *)
Theorem compiled_no_free_cut {Espec:OracleKind} s visits (frame:mpred) :
 semax (func_tycontext f_index_children Vprog [] [])
 (PROP() LOCAL(temp _s s;temp _count (Vint Int.zero))
  SEP(field_at Tsh level_type [StructField _nocand] (Vlong visits) s;frame))
 no_free_guard (function_body_ret_assert tint
  (PROP() LOCAL(temp ret_temp (Vint Int.zero))
   SEP(field_at Tsh level_type [StructField _nocand] (Vlong (Int64.add visits Int64.one)) s;frame)))%assert.
Proof.
 unfold no_free_guard;abbreviate_semax;forward_if.
 2: solve [discriminate|contradiction|congruence|exfalso;rep_lia].
 reassoc_seq;do 2 forward;constant_return.
Qed.

(* This is the actual prefix ++packed, subtraction and comparison.
   The bounds also discharge signed C overflow at the increment. *)
Theorem compiled_packing_cut {Espec:OracleKind} s visits w depth packed (frame:mpred):
 0<=depth<=w -> w<=Int.max_signed -> 0<=packed<Int.max_signed ->
 w-depth<packed+1 ->
 semax (func_tycontext f_index_children Vprog [] [])
 (PROP() LOCAL(temp _s s;temp _size (Vint (Int.repr depth));temp _packed (Vint (Int.repr packed)))
  SEP(field_at Tsh level_type [StructField _w] (Vint (Int.repr w)) s;
      field_at Tsh level_type [StructField _packprune] (Vlong visits) s;frame))
 packing_budget_guard (function_body_ret_assert tint
  (PROP() LOCAL(temp ret_temp (Vint Int.zero))
   SEP(field_at Tsh level_type [StructField _w] (Vint (Int.repr w)) s;
       field_at Tsh level_type [StructField _packprune] (Vlong (Int64.add visits Int64.one)) s;frame)))%assert.
Proof.
 intros wd limit packed_ok cut.
 unfold packing_budget_guard;abbreviate_semax;reassoc_seq;do 3 forward.
 forward_if;[|rep_lia].
 reassoc_seq;do 2 forward;constant_return.
Qed.

Require Import VerifRowTally RowTally.
Definition no_free_analysis (stmt:statement) :=
 match stmt with
 | Ssequence loop (Ssequence guard _) =>
   (counts_on _i loop && tests_empty_count guard)%bool
 | _=>false end.
Definition remaining_row:statement:=ltac:(native_while_fragment no_free_analysis f_index_children).
Definition after_empty_count:=match remaining_row with Ssequence _ (Ssequence _ tail)=>tail | _=>Sskip end.
Lemma real_tally_and_guard:
 remaining_row=Ssequence tally_loop (Ssequence no_free_guard after_empty_count).
Proof. reflexivity. Qed.

(* Starting before the actual CSR loop, run the tally, test the value
   it produced and return. The unreachable marking code needs no contract. *)
Theorem compiled_count_then_cut {Espec:OracleKind} s cp bp mp cols blocks marks lo hi stamp visits :
 0<=lo<=hi -> hi<=Int.max_unsigned -> hi<=Zlength cols ->
 (forall j,lo<=j<hi -> Int.unsigned (Znth j cols)<Zlength blocks) ->
 Zlength marks=Zlength blocks ->
 fst (counted blocks marks stamp cols lo hi)=Int.zero ->
 let memory:=tally_memory s cp bp mp cols blocks marks in
 let counter v:=field_at Tsh level_type [StructField _nocand] (Vlong v) s in
 semax (func_tycontext f_index_children Vprog [] [])
   (PROPx [] (LOCALx (tally_loc s lo hi stamp (Int.zero,Int.zero)) (SEPx [counter visits;memory])))
   remaining_row (function_body_ret_assert tint
    (PROP() LOCAL(temp ret_temp (Vint Int.zero))
     SEP(counter (Int64.add visits Int64.one);memory)))%assert.
Proof.
 intros range limit fits indices extent empty memory counter.
 rewrite real_tally_and_guard.
 pose proof (@semax_row_tally Espec s cp bp mp cols blocks marks lo hi stamp
              range limit fits indices extent) as tally.
 eapply semax_seq'.
 - pose proof (@semax_frame' Espec VerifDetected.CompSpecs _ _ _ _ _ _ _ _ (counter visits) tally) as framed.
   exact framed.
 - eapply semax_seq with (Q:=FF);[|apply semax_ff].
   eapply semax_pre;[|exact (@compiled_no_free_cut Espec s visits memory)].
   unfold tally_loc,counter,memory;rewrite empty;entailer!.
Qed.

Require Import PreparedCallerLocals.

(* Framing only locals the tally cannot write lets the following guard
   read the original depth and number of disjoint rows. *)
Lemma keep_tally_context {Espec:OracleKind} s cp bp mp cols blocks marks lo hi stamp
 (saved:list localdef) (extra:list mpred):
 0<=lo<=hi -> hi<=Int.max_unsigned -> hi<=Zlength cols ->
 (forall j,lo<=j<hi -> Int.unsigned (Znth j cols)<Zlength blocks) ->
 Zlength marks=Zlength blocks ->
 closed_wrt_modvars tally_loop (LOCALx saved (SEPx extra)) ->
 let mem:=tally_memory s cp bp mp cols blocks marks in
 semax (func_tycontext f_index_children Vprog [] [])
 (PROPx [] (LOCALx (tally_loc s lo hi stamp (Int.zero,Int.zero)++saved) (SEPx ([mem]++extra))))
 tally_loop (normal_ret_assert (PROPx []
   (LOCALx (tally_loc s lo hi stamp (counted blocks marks stamp cols lo hi)++saved)
   (SEPx ([mem]++extra))))).
Proof.
 intros range limit fits indices extent stable mem.
 pose proof (@semax_row_tally Espec s cp bp mp cols blocks marks lo hi stamp
        range limit fits indices extent) as checked.
 pose proof (@semax_frame VerifDetected.CompSpecs Espec _ _ _ _ _ stable checked) as keep.
 rewrite frame_normal in keep. rewrite !separate_caller_env. exact keep.
Qed.

Definition after_packed_check:=
 match after_empty_count with
 | Ssequence (Sifthenelse _ (Ssequence _ mark_rows) Sskip) remember => (mark_rows,remember)
 | _=>(Sskip,Sskip) end.

Theorem compiled_tally_over_budget {Espec:OracleKind} s cp bp mp cols blocks marks lo hi stamp
 visits w depth p :
 0<=lo<=hi -> hi<=Int.max_unsigned -> hi<=Zlength cols ->
 (forall j,lo<=j<hi -> Int.unsigned (Znth j cols)<Zlength blocks) ->
 Zlength marks=Zlength blocks -> 0<=depth<=w -> w<=Int.max_signed -> 0<=p<Int.max_signed ->
 w-depth<p+1 ->
 let pair:=counted blocks marks stamp cols lo hi in
 fst pair<>Int.zero -> snd pair=Int.zero ->
 let mem:=tally_memory s cp bp mp cols blocks marks in
 let saved:=[temp _size (Vint (Int.repr depth));temp _packed (Vint (Int.repr p))] in
 let extra v:=[field_at Tsh level_type [StructField _w] (Vint (Int.repr w)) s;
              field_at Tsh level_type [StructField _packprune] (Vlong v) s] in
 semax (func_tycontext f_index_children Vprog [] [])
 (PROPx [] (LOCALx (tally_loc s lo hi stamp (Int.zero,Int.zero)++saved) (SEPx ([mem]++extra visits))))
 remaining_row (function_body_ret_assert tint
   (PROPx [] (LOCALx [temp ret_temp (Vint Int.zero)] (SEPx (extra (Int64.add visits Int64.one)++[mem]))))).
Proof.
 intros range cap bound valid extent wd limit count_ok excess pair nonempty disjoint mem saved extra.
 pose proof (@keep_tally_context Espec s cp bp mp cols blocks marks lo hi stamp saved (extra visits)
   range cap bound valid extent ltac:(unfold tally_loop,saved,extra;auto 100 with closed)) as scanned.
 rewrite real_tally_and_guard; eapply semax_seq';[exact scanned|].
 fold pair. unfold no_free_guard,tally_loc;rewrite disjoint;abbreviate_semax.
 apply semax_if_seq;forward_if;[congruence|].
 change after_empty_count with
   (Ssequence (Sifthenelse (Eunop Onotbool (Etempvar _clash tuint) tint)
     (Ssequence packing_budget_guard (fst after_packed_check)) Sskip) (snd after_packed_check)).
 apply semax_if_seq;forward_if;[|solve [discriminate|contradiction|exfalso;rep_lia]].
 match goal with |- semax _ _ (Ssequence (Ssequence ?head ?middle) ?rest) _ =>
   apply (semax_unfold_seq (Ssequence head (Ssequence middle rest)) (Ssequence (Ssequence head middle) rest) eq_refl)
 end.
 eapply semax_seq with (Q:=FF);[|apply semax_ff].
 eapply semax_pre;[|exact (@compiled_packing_cut Espec s visits w depth p mem wd limit count_ok excess)].
 unfold extra,saved;cbn [app];entailer!;cancel.
 all: try tauto; try apply derives_refl.
Qed.
