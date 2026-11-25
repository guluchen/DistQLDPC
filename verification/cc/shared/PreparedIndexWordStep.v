(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.floyd.reassoc_seq VerifDetected
 ClightSelect ClightNested VerifLowestBit LowestWord WordScan CSRWordTraversal.
Require Import flag_level_ast.
Local Open Scope Z_scope.

Definition begins_lowest_bit (st:statement):=
 match st with
 | Ssequence (Ssequence (Scall _ (Evar fn _) _) (Sset row _)) (Ssequence (Sset word _) _) =>
   (Pos.eqb fn _cc_lowest_bit && Pos.eqb row _r && Pos.eqb word _odd)%bool
 | _=>false end.
Definition active_word_iteration:statement:=ltac:(native_while_fragment begins_lowest_bit f_index_children).
Definition row_arithmetic:=
 match active_word_iteration with Ssequence row (Ssequence clear _) => Ssequence row clear | _=>Sskip end.
Definition row_tests:=
 match active_word_iteration with Ssequence _ (Ssequence _ tests)=>tests | _=>Sskip end.
Lemma row_iteration_sections {Espec:OracleKind} D P Q R:
 semax D P row_arithmetic (normal_ret_assert Q) -> semax D Q row_tests R ->
 semax D P active_word_iteration R.
Proof.
 intros first next. apply (semax_unfold_seq (Ssequence row_arithmetic row_tests) active_word_iteration eq_refl).
 eapply semax_seq';eassumption.
Qed.

Definition lookup_bytes gv sh:=data_at sh (tarray tuchar 64) (map byteval positions) (gv _bit_position).
Theorem compiled_word_step {Espec:OracleKind} gv sh wi word p:
 readable_share sh -> Int64.unsigned word=Z.pos p ->
 0<=wi -> 64*wi+trailing p<=Int.max_signed ->
 semax (func_tycontext f_index_children Vprog LowGprog [])
 (PROP() LOCAL(temp _wi (Vint (Int.repr wi));temp _odd (Vlong word);gvars gv)
  SEP(lookup_bytes gv sh)) row_arithmetic
 (normal_ret_assert
  (PROP() LOCAL(temp _wi (Vint (Int.repr wi));temp _r (Vint (Int.repr (64*wi+trailing p)));
                temp _odd (Vlong (clear word));gvars gv)
   SEP(lookup_bytes gv sh)))%assert.
Proof.
 intros readable live wi_pos row_fits.
 destruct (lowest_bit_correct word p live) as [bit _].
 unfold row_arithmetic,active_word_iteration,lookup_bytes;abbreviate_semax;reassoc_seq.
 forward_call (gv,word,p,sh);try solve [entailer!].
 forward;try solve [rep_lia]. forward;entailer!;try solve [f_equal;rep_lia].
Qed.

(* On success the C expression consumes precisely the first transition
   in the well-founded bit scan; no hypothesis on its proposed row is used. *)
Theorem c_bit_transition {Espec:OracleKind} gv sh wi word p rest:
 readable_share sh -> Int64.unsigned word=Z.pos p ->
 0<=wi -> 64*wi+trailing p<=Int.max_signed -> scan_word (clear word) rest ->
 scan_word word (trailing p::rest) /\ Int64.unsigned (clear word)<Int64.unsigned word /\
 semax (func_tycontext f_index_children Vprog LowGprog [])
 (PROP() LOCAL(temp _wi (Vint (Int.repr wi));temp _odd (Vlong word);gvars gv)
  SEP(lookup_bytes gv sh)) row_arithmetic
 (normal_ret_assert
  (PROP() LOCAL(temp _wi (Vint (Int.repr wi));temp _r (Vint (Int.repr (64*wi+trailing p)));
                temp _odd (Vlong (clear word));gvars gv)
   SEP(lookup_bytes gv sh)))%assert.
Proof.
 intros readable live pos fits tail;split;[econstructor;eassumption|].
 split;[apply clear_smaller;lia|apply compiled_word_step;assumption].
Qed.

Require Import PreparedIndexCuts VerifRowTally.
Definition open_offsets:=
 match row_tests with
 | Ssequence count (Ssequence clash (Ssequence lo (Ssequence hi _))) =>
   Ssequence count (Ssequence clash (Ssequence lo hi))
 | _=>Sskip end.

Lemma arithmetic_offsets_scan {Espec:OracleKind} D P after_bit after_offsets terminal:
 semax D P row_arithmetic (normal_ret_assert after_bit) ->
 semax D after_bit open_offsets (normal_ret_assert after_offsets) ->
 semax D after_offsets remaining_row terminal ->
 semax D P active_word_iteration terminal.
Proof.
 intros bit bounds scan;apply row_iteration_sections with (Q:=after_bit);[exact bit|].
 apply (semax_unfold_seq (Ssequence open_offsets remaining_row) row_tests eq_refl).
 eapply semax_seq';eassumption.
Qed.

Definition offsets_heap s op (offsets:list Z) :=
 (field_at Tsh level_type [StructField _rstart] op s *
  data_at Tsh (tarray tuint (Zlength offsets)) (map (fun z=>Vint (Int.repr z)) offsets) op)%logic.

Theorem compiled_row_offsets {Espec:OracleKind} s op offsets r stamp :
 0<=r<Int.max_signed -> r+1<Zlength offsets ->
 semax (func_tycontext f_index_children Vprog LowGprog [])
  (PROP() LOCAL(temp _s s;temp _r (Vint (Int.repr r));temp _stamp (Vlong stamp))
   SEP(offsets_heap s op offsets))
  open_offsets (normal_ret_assert (PROPx [] (LOCALx
    (temp _r (Vint (Int.repr r))::tally_loc s (Znth r offsets) (Znth (r+1) offsets) stamp (Int.zero,Int.zero))
    (SEPx [offsets_heap s op offsets])))).
Proof.
 intros fit room;unfold open_offsets,row_tests,active_word_iteration,offsets_heap,tally_loc;
 abbreviate_semax;reassoc_seq.
 Intros;do 6 forward;entailer!.
Qed.

From mathcomp Require Import all_ssreflect.
Require Import PreparedIndexWords SparseSyndrome SparseFlipBits.
Set Implicit Arguments.
Local Delimit Scope Z_scope with coqZ.

(* The signed expression computing the C row number is in range even
   when the last allocated word has unused bits. Its result is an odd
   physical row, so the following load of offsets[r+1] is also in range
   for an array with one terminal offset. *)
Theorem word_step_on_physical_scan {Espec:OracleKind} m words count (odd:{set 'I_m}) raw
 (gv:globals) sh wi word p rest (offsets:list Z) :
 stores_odd (words,count) odd ->
 (forall j,(Z.of_nat m<=j<64*Zlength words)%coqZ -> syndrome_bit words j=false) ->
 row_order 0 words raw -> (Z.of_nat m<=Int.max_signed)%coqZ ->
 Zlength offsets=(Z.of_nat m+1)%coqZ ->
 readable_share sh -> Int64.unsigned word=Z.pos p -> (0<=wi)%coqZ ->
 List.In (64*wi+trailing p)%coqZ raw -> scan_word (clear word) rest ->
 exists r:'I_m,(64*wi+trailing p)%coqZ=Z.of_nat r /\ r \in odd /\
 (Z.of_nat r+1<Zlength offsets)%coqZ /\ scan_word word (trailing p::rest) /\
 semax (func_tycontext f_index_children Vprog LowGprog nil)
  (PROP() LOCAL(temp _wi (Vint (Int.repr wi));temp _odd (Vlong word);gvars gv)
   SEP(lookup_bytes gv sh)) row_arithmetic
  (normal_ret_assert
   (PROP() LOCAL(temp _wi (Vint (Int.repr wi));temp _r (Vint (Int.repr (Z.of_nat r)));
                 temp _odd (Vlong (clear word));gvars gv) SEP(lookup_bytes gv sh)))%assert.
Proof.
 move=>stored pad scan fits table readable live wi_ok occurs tail.
 have [_ found]:=@word_scan_physical_rows m words count odd stored pad raw scan.
 have [r [actual dark]]:=proj1 (found _) occurs.
 have small:=elimT ltP (ltn_ord r).
 exists r;split=> //;split=> //;split;first lia.
 have [path [_ execute]]:=@c_bit_transition Espec gv sh wi word p rest readable live wi_ok ltac:(lia) tail.
 split=> //;by rewrite -actual.
Qed.
