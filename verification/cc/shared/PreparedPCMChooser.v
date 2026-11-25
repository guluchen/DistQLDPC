(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VerifDetected EpochFreshness VerifLowestBit
 PreparedIndexWords PreparedIndexSweep PreparedIndexWhile PreparedIndexFinish PreparedIndexEpoch
 PreparedIndexTables PreparedIndexChooser VerifGather RowGather RowTally.
Require Import PreparedIndexSweepPCM PreparedIndexIteration PreparedIndexBitBody WordScan.
Local Open Scope Z_scope.

Definition scan_marks result:=match result with
 | AllBits _ _ tags | EmptyRow tags | TooManyRows tags=>tags end.

(* A cut returns the marks from before its row; a completed row can
   overwrite cells, but every overwrite lies within the allocated array. *)
Section Extent.
Variables (offsets:list Z) (cols blocks:list int) (stamp:int64) (dep w:Z).
Let safe:=safe_index_row offsets cols blocks.
Let valid:=row_state_ok blocks dep w.

Lemma word_marks_extent wi bits b p ms:
 Forall (fun i=>safe (64*wi+i)) bits -> valid b p ms ->
 Zlength (scan_marks (scan_bits offsets cols blocks stamp wi dep w bits b p ms))=Zlength blocks.
Proof.
 intros guarded;revert b p ms;induction guarded as [|i bits good tail ih];intros b p ms ok.
 - exact (proj2 (proj2 ok)).
 - cbn [scan_bits]. destruct (run_row _ _ _ _ _ _ _ _) as [| |q next] eqn:step;
     [exact (proj2 (proj2 ok))|exact (proj2 (proj2 ok))|].
   apply ih. exact (step_stays_in_range offsets cols blocks stamp dep w (64*wi+i) b p ms q next good ok step).
Qed.

Lemma sweep_marks_extent wi plan b p ms:
 Forall safe (physical_order wi plan) -> valid b p ms ->
 Zlength (scan_marks (sweep offsets cols blocks stamp dep w wi plan b p ms))=Zlength blocks.
Proof.
 revert wi b p ms;induction plan as [|bits later ih];intros wi b p ms safe_rows ok.
 - exact (proj2 (proj2 ok)).
 - change (Forall safe (map (Z.add (64*wi)) bits ++ physical_order (wi+1) later)) in safe_rows.
   apply Forall_app in safe_rows;destruct safe_rows as [first more].
   assert (guard:Forall (fun i=>safe (64*wi+i)) bits).
   { apply Forall_forall;intros i found;rewrite Forall_forall in first;apply first;apply in_map;exact found. }
   pose proof (word_marks_extent wi bits b p ms guard ok) as room.
   cbn [sweep];destruct (scan_bits offsets cols blocks stamp wi dep w bits b p ms) as [b' p' tags|tags|tags] eqn:word.
   + apply ih;[exact more|]. eapply exhausted_bits_valid;[exact guard|exact ok|exact word].
   + exact room.
   + exact room.
Qed.
End Extent.

From mathcomp Require Import all_ssreflect all_algebra.
Require Import NativePackingScan LeafMatrix SparseFlipBits SparseSyndrome IndexRowBridge
 PreparedIndexAdmission PreparedResidualIndex PreparedRowCoverage flag_level_ast.
#[local] Existing Instance VerifDetected.CompSpecs.
Set Implicit Arguments.
Unset Strict Implicit.
Local Delimit Scope Z_scope with coqZ.
Local Open Scope ring_scope.

(* The recursive caller needs the identity of the physical odd row,
   including the exact order of its free entries. For either early exit
   the smaller certificate is sufficient: no extension fits the budget. *)
Definition selection_origin m n (rows:'I_m->seq 'I_n) (H:'M['F_2]_(m,n))
 (prefix:'cV['F_2]_n) (free:{set 'I_n}) budget offsets cols blocks result : Prop :=
 match result with
 | AllBits index _ _ => exists row:'I_m,
    index=Z.of_nat row /\ (H*m prefix) row 0!=0 /\
    output_columns offsets cols blocks result=free_row blocks (encoded rows row)
 | _ => no_completion H prefix free budget
 end.

Section Matrix.
Variables m n:nat.
Variables (rows:'I_m->seq 'I_n) (H:'M['F_2]_(m,n)) (prefix:'cV['F_2]_n)
 (free:{set 'I_n}) (blocks cols:seq Integers.int) (offsets:seq Z) (budget:nat) (dep w:Z).
Variables (words:seq int64) (count:Z) (marks:seq int64) (last:int64) (old:seq Integers.int).
Hypotheses (m_fits:(Z.of_nat m<=Int.max_signed)%coqZ) (n_fits:(0<Z.of_nat n<=Int.max_signed)%coqZ)
 (available:forall q:'I_n,Znth (Z.of_nat q) blocks=Int.zero <-> q \in free)
 (block_width:Zlength blocks=Z.of_nat n) (mark_width:Zlength marks=Z.of_nat n)
 (covers:forall r q,H r q!=0 -> q \in rows r) (distinct:forall r,uniq (rows r))
 (offset_count:Zlength offsets=(Z.of_nat m+1)%coqZ)
 (csr:forall r:'I_m,let a:=Znth (Z.of_nat r) offsets in let b:=Znth (Z.of_nat r+1)%coqZ offsets in
    (0<=a<=b)%coqZ /\ (b<=Int.max_unsigned)%coqZ /\ (b<=Zlength cols)%coqZ /\ sublist a b cols=encoded rows r)
 (remaining:(w-dep)%coqZ=Z.of_nat budget)
 (stored:stores_odd (words,count) (support (H*m prefix))) (padding:clear_padding (Z.of_nat m) words) (live:(0<count)%coqZ)
 (capacity:forall r:'I_m,(Znth (Z.of_nat r+1)%coqZ offsets-Znth (Z.of_nat r) offsets<=Zlength old)%coqZ)
 (buffer_signed:(Zlength old<=Int.max_signed)%coqZ).

Let stamp:=Int64.repr (advance_tag false (Int64.unsigned last)).
Let initial:=after_tags false (Int64.unsigned last) marks.
Let picks:=output_columns offsets cols blocks.

(* The statement covers execution from the function's parameter storage
   through its return. The candidate buffer is quantified at entry, so this
   also covers reuse of the same scratch space between recursive calls. *)
Theorem physical_index_origin_and_extent {Espec:OracleKind} gv sh s sp op cp bp mp children nc pk:
 readable_share sh -> (1<=dep<=w)%coqZ -> (w<=Int.max_signed)%coqZ ->
 (Zlength words<=Int.max_signed)%coqZ ->
 exists result,
 semax (func_tycontext f_index_children Vprog index_calls nil)
   (initial_index gv sh s sp op cp bp mp children offsets cols blocks dep w words nc pk old last marks)
   (fn_body f_index_children)
   (frame_ret_assert (after_selection gv sh s sp op cp bp mp children offsets cols blocks w words nc pk old result)
      (fun _:environ=>counters_header s (Zlength marks) stamp)) /\
 selection_origin rows H prefix free budget offsets cols blocks result /\
 Zlength (scan_marks result)=Zlength marks.
Proof.
 move=> readable depth signed words_fit.
 have unsigned:(Z.of_nat n<=Int.max_unsigned)%coqZ by
   change Int.max_unsigned with 4294967295%coqZ;change Int.max_signed with 2147483647%coqZ in n_fits;lia.
 have width (r:'I_m):(Zlength (encoded rows r)<=Int.max_unsigned)%coqZ.
 { have [range [top [extent encoded_as]]]:=csr r;rewrite -encoded_as Zlength_sublist;lia. }
 pose set_of_marks:=[set q:'I_n | Int64.eq (@Znth int64 ltac:(typeclasses eauto) (Z.of_nat q) initial) stamp].
 have markset:@tags_for n stamp initial set_of_marks.
 { split;first by rewrite /initial after_length mark_width.
   move=>q;rewrite /set_of_marks inE;split;[move=> ->;apply Int64.eq_true|apply Int64.same_if_eq]. }
 have [plan [result [run [exact_result [checked meaning]]]]]:=
   @compiled_sweep_from_pcm m n rows H prefix free blocks cols offsets stamp budget dep w words count initial
     set_of_marks m_fits unsigned available block_width covers width offset_count csr remaining markset stored
     padding live Espec gv sh s sp op cp bp mp nc pk readable depth signed words_fit.
 exists result;split.
 - rewrite exact_result;apply:(@full_index_from_scan Espec gv sh s sp op cp bp mp children offsets cols blocks dep w
     words nc pk old last marks plan);first by rewrite mark_width.
   + by rewrite -/stamp -/initial -exact_result.
   + move=>r p tags eqr;fold stamp initial in eqr;rewrite -exact_result in eqr;rewrite eqr in meaning.
     case:meaning=>first [rs [_ [dark [-> _]]]].
     split;last exact:capacity.
     eapply physical_rows_are_safe; eassumption.
   + exact:buffer_signed.
 - have size_ok:Zlength (scan_marks result)=Zlength marks.
   { rewrite exact_result mark_width -block_width;apply sweep_marks_extent.
     - apply Forall_forall=> j inside.
       have decoded:=@plan_traces_words 0 words plan run.
       have [_ valid]:=@word_scan_physical_rows m words count (support (H*m prefix)) stored padding _ decoded.
       have [r [-> _]]:=proj1 (valid _) inside.
       eapply physical_rows_are_safe;eassumption.
     - unfold row_state_ok;rewrite /initial after_length mark_width block_width.
       repeat split;try lia;unfold Int.max_signed;lia. }
   split;last exact size_ok.
   clear size_ok.
   case:result exact_result checked meaning=>[r p tags|tags|tags] exact_result checked meaning.
   + case:meaning=>first [rs [_ [dark [eqr _]]]].
     have [_ [_ [_ image]]]:=csr first.
     exists first;split=> //;split.
     * by move:dark;rewrite /support inE.
     * by rewrite eqr /output_columns /gathered image.
   + exact meaning.
   + exact meaning.
Qed.

Theorem physical_index_origin {Espec:OracleKind} gv sh s sp op cp bp mp children nc pk:
 readable_share sh -> (1<=dep<=w)%coqZ -> (w<=Int.max_signed)%coqZ ->
 (Zlength words<=Int.max_signed)%coqZ ->
 exists result,
 semax (func_tycontext f_index_children Vprog index_calls nil)
   (initial_index gv sh s sp op cp bp mp children offsets cols blocks dep w words nc pk old last marks)
   (fn_body f_index_children)
   (frame_ret_assert (after_selection gv sh s sp op cp bp mp children offsets cols blocks w words nc pk old result)
      (fun _:environ=>counters_header s (Zlength marks) stamp)) /\
 selection_origin rows H prefix free budget offsets cols blocks result.
Proof.
 move=>readable depth signed words_fit.
 have [result [checked [origin _]]]:=@physical_index_origin_and_extent Espec gv sh s sp op cp bp mp children nc pk
   readable depth signed words_fit.
 by exists result.
Qed.

Theorem complete_physical_index_children {Espec:OracleKind} gv sh s sp op cp bp mp children nc pk:
 readable_share sh -> (1<=dep<=w)%coqZ -> (w<=Int.max_signed)%coqZ ->
 (Zlength words<=Int.max_signed)%coqZ ->
 exists result,
 semax (func_tycontext f_index_children Vprog index_calls nil)
   (initial_index gv sh s sp op cp bp mp children offsets cols blocks dep w words nc pk old last marks)
   (fn_body f_index_children)
   (frame_ret_assert (after_selection gv sh s sp op cp bp mp children offsets cols blocks w words nc pk old result)
      (fun _:environ=>counters_header s (Zlength marks) stamp)) /\
 List.NoDup (map Int.unsigned (picks result)) /\
 (forall target:'cV['F_2]_n,support prefix \subset support target -> H*m target=0 ->
   support target :\: support prefix \subset free -> (#|support target :\: support prefix|<=budget)%N ->
   exists q:'I_n,q \in support target :\: support prefix /\ List.In (Z.of_nat q) (map Int.unsigned (picks result))).
Proof.
 move=>readable depth signed words_fit.
 have unsigned:(Z.of_nat n<=Int.max_unsigned)%coqZ by
   change Int.max_unsigned with 4294967295%coqZ;change Int.max_signed with 2147483647%coqZ in n_fits;lia.
 have [result [run origin]]:=@physical_index_origin Espec gv sh s sp op cp bp mp children nc pk readable depth signed words_fit.
 exists result;split=> //.
 clear run;case:result origin=>[r p tags|tags|tags] origin.
 - case:origin=>first [_ [active row_as_written]].
   rewrite /picks row_as_written;split.
   + exact:(@emitted_unique n (rows first) blocks free unsigned available (distinct first)).
   + move=>target sub closed choices room.
     exact (@odd_candidate_buffer_hits m n H prefix target first (rows first) blocks free unsigned available
       (@covers first) sub closed active choices).
 - split;first constructor.
   move=>target included annihilated allowed within. exfalso. exact (@origin target included annihilated allowed within).
 - split;first constructor.
   move=>target included annihilated allowed within. exfalso. exact (@origin target included annihilated allowed within).
Qed.
End Matrix.
