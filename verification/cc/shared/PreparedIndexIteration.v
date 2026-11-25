(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VerifDetected VerifRowTally VerifMarkRow
 PreparedIndexCuts PreparedIndexAdvance PreparedIndexWordStep RowTally.
Require Import flag_level_ast.
Local Open Scope Z_scope.

(* All four outcomes refer to the same borrowed C storage. In particular
   an early return gives the caller both statistics counters, and a
   continuing row gives the next iteration the actual updated marks. *)
Inductive row_result :=
| NoCandidate
| PackingExceeded
| ContinueRow (packed:Z) (marks:list int64).

Definition run_row blocks marks stamp cols lo hi p budget :=
 let values:=counted blocks marks stamp cols lo hi in
 if Int.eq (fst values) Int.zero then NoCandidate
 else if Int.eq (snd values) Int.zero then
   if Z_lt_dec budget (p+1) then PackingExceeded
   else ContinueRow (p+1) (marked stamp marks cols lo hi)
 else ContinueRow p marks.

Definition statistics s nc pk:=
 (field_at Tsh level_type [StructField _nocand] (Vlong nc) s *
  field_at Tsh level_type [StructField _packprune] (Vlong pk) s)%logic.

Section Row.
Context {Espec:OracleKind}.
Variables (s cp bp mp:val) (cols blocks:list int) (stamp:int64) (lo hi depth w row branch p:Z)
 (nocand packcuts:int64).
Let rowmem ms:=tally_memory s cp bp mp cols blocks ms.
Let weight:=stored_weight s w.
Let registers p:=[temp _size (Vint (Int.repr depth));temp _packed (Vint (Int.repr p))].
Let input ms:=PROPx [] (LOCALx (tally_loc s lo hi stamp (Int.zero,Int.zero)++
    row_registers branch row++registers p) (SEPx [rowmem ms;weight;statistics s nocand packcuts])).
Let terminal ms nc pk:=function_body_ret_assert tint
  (PROP() LOCAL(temp ret_temp (Vint Int.zero)) SEP(rowmem ms;weight;statistics s nc pk))%assert.
Let normal p ms:=normal_ret_assert (PROPx [] (LOCALx (row_registers (first_row branch row) row++registers p)
  (SEPx [rowmem ms;weight;statistics s nocand packcuts]))).
Definition iteration_result ms kind:=match kind with
 | NoCandidate=>terminal ms (Int64.add nocand Int64.one) packcuts
 | PackingExceeded=>terminal ms nocand (Int64.add packcuts Int64.one)
 | ContinueRow p' ms'=>normal p' ms'
 end.

Hypotheses (slice:0<=lo<=hi) (capacity:hi<=Int.max_unsigned) (within:hi<=Zlength cols)
 (indices:forall j,lo<=j<hi->Int.unsigned (Znth j cols)<Zlength blocks)
 (depth_ok:1<=depth<=w) (weight_ok:w<=Int.max_signed) (packing_ok:0<=p<=w-depth)
 (branch_ok: -1<=branch<=Int.max_signed).

Lemma row_with_no_candidates ms :
 Zlength ms=Zlength blocks -> fst (counted blocks ms stamp cols lo hi)=Int.zero ->
 semax (func_tycontext f_index_children Vprog [] []) (input ms) remaining_row (iteration_result ms NoCandidate).
Proof.
 intros extent absent.
 pose proof (@compiled_count_then_cut Espec s cp bp mp cols blocks ms lo hi stamp nocand
       slice capacity within indices extent absent) as cut.
 unfold iteration_result,terminal,input. cbn zeta in cut.
 eapply semax_post_flipped.
 - eapply semax_pre;[|exact (@semax_frame VerifDetected.CompSpecs Espec _ _ _ _
    (fun _:environ=>(weight * field_at Tsh level_type [StructField _packprune] (Vlong packcuts) s)%logic)
    ltac:(hnf;intros;auto) cut)].
   unfold rowmem,weight,statistics,registers,tally_loc,row_registers;cbn [app];go_lowerx;normalize;cancel.
 - cbn [RA_normal frame_ret_assert function_body_ret_assert];normalize.
 - cbn [RA_break frame_ret_assert function_body_ret_assert];normalize.
 - cbn [RA_continue frame_ret_assert function_body_ret_assert];normalize.
 - intro opt;cbn [RA_return frame_ret_assert function_body_ret_assert].
   unfold bind_ret;destruct opt as [v|];[|normalize].
   unfold rowmem,statistics;go_lowerx;normalize;try cancel;try tauto;try apply derives_refl.
Qed.

Lemma row_exceeds_budget ms :
 Zlength ms=Zlength blocks -> fst (counted blocks ms stamp cols lo hi)<>Int.zero ->
 snd (counted blocks ms stamp cols lo hi)=Int.zero -> w-depth<p+1 ->
 semax (func_tycontext f_index_children Vprog [] []) (input ms) remaining_row (iteration_result ms PackingExceeded).
Proof.
 intros extent nonempty disjoint over.
 pose proof (@compiled_tally_over_budget Espec s cp bp mp cols blocks ms lo hi stamp packcuts w depth p
      slice capacity within indices extent ltac:(lia) weight_ok ltac:(lia) over nonempty disjoint) as cut.
 unfold iteration_result,terminal,input;cbn zeta in cut.
 eapply semax_post_flipped.
 - eapply semax_pre;[|exact (@semax_frame VerifDetected.CompSpecs Espec _ _ _ _
     (fun _:environ=>field_at Tsh level_type [StructField _nocand] (Vlong nocand) s)
     ltac:(hnf;intros;auto) cut)].
   unfold rowmem,weight,statistics,registers,tally_loc,row_registers,stored_weight;cbn [app];go_lowerx;normalize;cancel.
 - cbn [RA_normal frame_ret_assert function_body_ret_assert];normalize.
 - cbn [RA_break frame_ret_assert function_body_ret_assert];normalize.
 - cbn [RA_continue frame_ret_assert function_body_ret_assert];normalize.
 - intro opt;cbn [RA_return frame_ret_assert function_body_ret_assert].
   unfold bind_ret;destruct opt as [v|];[|normalize].
   unfold rowmem,statistics,weight,stored_weight;go_lowerx;normalize;try cancel;try tauto;try apply derives_refl.
Qed.

Lemma continue_after_clash ms:
 Zlength ms=Zlength blocks -> fst (counted blocks ms stamp cols lo hi)<>Int.zero ->
 snd (counted blocks ms stamp cols lo hi)<>Int.zero ->
 semax (func_tycontext f_index_children Vprog [] []) (input ms) remaining_row
      (iteration_result ms (ContinueRow p ms)).
Proof.
 intros extent nonempty clash.
 pose proof (@compiled_clashing_row Espec s cp bp mp cols blocks ms lo hi stamp branch row depth p
    slice capacity within indices extent branch_ok nonempty clash) as step.
 cbn zeta in step;unfold iteration_result,input,normal.
 pose proof (@semax_frame' Espec VerifDetected.CompSpecs _ _ _ _ _ _ _ _ (weight * statistics s nocand packcuts)%logic step) as keep.
 eapply semax_post';[|eapply semax_pre;[|exact keep]].
 all: unfold rowmem,tally_loc,row_registers,registers;cbn [app];entailer!;cancel.
Qed.

Lemma continue_after_mark ms:
 Zlength ms=Zlength blocks -> fst (counted blocks ms stamp cols lo hi)<>Int.zero ->
 snd (counted blocks ms stamp cols lo hi)=Int.zero -> p+1<=w-depth ->
 semax (func_tycontext f_index_children Vprog [] []) (input ms) remaining_row
   (iteration_result ms (ContinueRow (p+1) (marked stamp ms cols lo hi))).
Proof.
 intros extent nonempty disjoint room.
 pose proof (@compiled_add_row Espec s cp bp mp cols blocks ms lo hi stamp w depth p branch row
  slice capacity within indices extent ltac:(lia) weight_ok ltac:(lia) room branch_ok nonempty disjoint) as step.
 cbn zeta in step;unfold iteration_result,input,normal.
 pose proof (@semax_frame' Espec VerifDetected.CompSpecs _ _ _ _ _ _ _ _ (statistics s nocand packcuts) step) as keep.
 eapply semax_post';[|eapply semax_pre;[|exact keep]].
 all: unfold rowmem,weight,tally_loc,row_registers,registers;cbn [app];entailer!;cancel.
Qed.

Theorem compiled_row_outcome ms :
 Zlength ms=Zlength blocks ->
 semax (func_tycontext f_index_children Vprog [] []) (input ms) remaining_row
   (iteration_result ms (run_row blocks ms stamp cols lo hi p (w-depth))).
Proof.
 intro extent;unfold run_row.
 remember (counted blocks ms stamp cols lo hi) as pair.
 destruct (Int.eq (fst pair) Int.zero) eqn:N.
 - apply row_with_no_candidates;[exact extent|rewrite <- Heqpair;apply Int.same_if_eq;exact N].
 - assert (nonempty:fst (counted blocks ms stamp cols lo hi)<>Int.zero).
   { rewrite <-Heqpair;intro same;rewrite same,Int.eq_true in N;discriminate. }
   destruct (Int.eq (snd pair) Int.zero) eqn:C.
   + assert (disjoint:snd (counted blocks ms stamp cols lo hi)=Int.zero)
       by (rewrite <-Heqpair;apply Int.same_if_eq;exact C).
     destruct Z_lt_dec.
     * apply row_exceeds_budget;assumption.
     * apply continue_after_mark;try assumption;lia.
   + apply continue_after_clash;try assumption.
     rewrite <-Heqpair;intro same;rewrite same,Int.eq_true in C;discriminate.
Qed.
End Row.

From mathcomp Require Import all_ssreflect all_algebra.
Require Import PreparedIndexAdmission NativePackingScan LeafMatrix IndexRowBridge.
Set Implicit Arguments.
Unset Strict Implicit.
Local Open Scope ring_scope.
Local Delimit Scope Z_scope with coqZ.

Section History.
Variables m n:nat.
Variables (rows:'I_m -> seq 'I_n) (blocks:seq Integers.int) (stamp:int64) (budget:nat).
Let reached:=@reaches_row m n rows blocks stamp budget.

Lemma append_reached a ms p b tags q c final last :
 reached a ms p b tags q -> reached b tags q c final last ->
 reached a ms p c final last.
Proof.
 move=> head;elim:head c final last=>[start marks k|r rs before count tail after k live clash path ih
  |r rs before count tail after k live clear fits path ih] c final last next.
 - exact next.
 - apply passed_clash=> //;exact:ih next.
 - eapply added_row;try eassumption;exact:ih next.
Qed.

Variables (H:'M['F_2]_(m,n)) (prefix:'cV['F_2]_n) (free:{set 'I_n}).
Hypotheses (cap:(Z.of_nat n<=Int.max_unsigned)%coqZ)
 (avail:forall q:'I_n,Znth (Z.of_nat q) blocks=Int.zero <-> q \in free)
 (cover:forall r q,H r q!=0 -> q \in rows r)
 (width:forall r,(Zlength (encoded rows r)<=Int.max_unsigned)%coqZ).

(* The post-state selected by compiled_row_outcome itself either justifies
   returning zero or establishes the invariant at the next physical row. *)
Theorem iteration_preserves_pcm first rest initial marked_set r tail ms p cols lo hi :
 @tags_for n stamp initial marked_set ->
 {subset first::rest <= support (H*m prefix)} ->
 reached (first::rest) initial 0 (r::tail) ms p ->
 sublist lo hi cols=encoded rows r ->
 match run_row blocks ms stamp cols lo hi (Z.of_nat p) (Z.of_nat budget) with
 | NoCandidate | PackingExceeded => no_completion H prefix free budget
 | ContinueRow value tags => exists q, value=Z.of_nat q /\
       reached (first::rest) initial 0 tail tags q /\ (q<=budget)%N
 end.
Proof.
 move=> tags odd history image.
 have pair_eq:counted blocks ms stamp cols lo hi=
      (Int.repr (Zlength (free_row blocks (encoded rows r))),flag (row_clash blocks ms stamp (encoded rows r))).
 { unfold counted;rewrite image.
   change (Int.zero,Int.zero) with (Int.repr 0,flag false).
   by rewrite row_tally ?Z.add_0_l //. }
 rewrite /run_row pair_eq /=.
 case eq0:(Int.eq (Int.repr (Zlength (free_row blocks (encoded rows r)))) Int.zero).
 - eapply (@cut_at_reached_row m n H prefix rows free blocks stamp budget);try eassumption.
   left;by rewrite /count_nonzero eq0.
 - have live:count_nonzero rows blocks r by rewrite /count_nonzero eq0.
   case clash:(row_clash blocks ms stamp (encoded rows r)).
   + change (exists q, Z.of_nat p=Z.of_nat q /\ reached (first::rest) initial 0 tail ms q /\ (q<=budget)%N).
     exists p;split=> //;split;last exact:count_within_budget history (leq0n _).
     eapply append_reached;[exact history|apply passed_clash=> //;constructor].
   + cbn [flag]. change (Int.eq Int.zero Int.zero) with true.
     cbn iota.
     destruct (Z_lt_dec (Z.of_nat budget) (Z.of_nat p+1)%coqZ) as [bound|bound] eqn:decision.
     * eapply (@cut_at_reached_row m n H prefix rows free blocks stamp budget);try eassumption.
       right;split=> //;split=> //;apply/ltP;lia.
     * have room:(p.+1<=budget)%N by apply/leP;lia.
       exists p.+1;split;first lia.
       split=> //;rewrite /marked image.
       eapply append_reached;[exact history|apply added_row=> //;constructor].
Qed.
End History.
