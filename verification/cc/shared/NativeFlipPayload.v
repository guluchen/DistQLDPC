(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.zlist.list_solver VerifClosesBody VerifToggleBody
 VerifFlipBody PreparedFlip.
Require FlipRoundtrip ClosureMatrix ToggleModel.
Local Open Scope Z_scope.

Record packed_support:= { words_at:close_view; odd_count:Z; checksum:int64 }.
Definition set_words v syn par:=Build_close_view (offsets v) (rows v) syn par (masks v)
 (poff v) (prows v) (psyn v) (ppar v) (pmasks v).
Definition column_list v q:=sublist (Znth q (offsets v)) (Znth (q+1) (offsets v)) (rows v).
Definition step_support p keys q init:=
 let v:=words_at init in let first:=after_primary v q (odd_count init) in
 Build_packed_support (set_words v (after_extra p q (fst first)) (differences v q))
   (snd first) (Int64.xor (checksum init) (Znth q keys)).
Definition packed_mem s addr p keys init:=let v:=words_at init in
 (toggle_mem s addr v (odd_count init) (checksum init) keys (syndrome v) (parities v) * PreparedFlip.policy_storage p)%logic.

Lemma detector_word_count v q:
 0<=q -> 0<=width v -> (q+1)*width v<=Zlength (masks v) -> Zlength (differences v q)=width v.
Proof.
 intros q_ok width_ok room;unfold differences;rewrite Zlength_map,Zlength_combine,Zlength_sublist by nia.
 unfold width in *;nia.
Qed.
Lemma updated_packed_allocation s addr p keys q x :
 0<=q -> 0<=width (words_at x) -> (q+1)*width (words_at x)<=Zlength (masks (words_at x)) ->
 let v:=words_at x in let f:=after_primary v q (odd_count x) in
 packed_mem s addr p keys (step_support p keys q x)=
 (toggle_mem s addr v (snd f) (Int64.xor (checksum x) (Znth q keys)) keys (after_extra p q (fst f)) (differences v q) *
   PreparedFlip.policy_storage p)%logic.
Proof.
 destruct x as [v odd hash];cbn [words_at];intros q_ok width_ok room;cbv zeta.
 unfold step_support,packed_mem,toggle_mem;cbn [words_at odd_count checksum width set_words offsets rows
  poff prows psyn ppar pmasks masks parities syndrome].
 unfold width;cbn [set_words parities];rewrite !detector_word_count by assumption;reflexivity.
Qed.

Lemma detector_words_restore v q syn par:
 par=differences v q -> 0<=q -> 0<=width v -> (q+1)*width v<=Zlength (masks v) ->
 differences (set_words v syn par) q=parities v.
Proof.
 intros -> valid pos size;assert (len:=detector_word_count v q valid pos size).
 rewrite (ClosureMatrix.diffs_are_xors (set_words v syn (differences v q)) q).
 change (ClosureEncoding.xors (differences v q)
    (sublist (q*Zlength (differences v q)) ((q+1)*Zlength (differences v q)) (masks v))=parities v).
 rewrite len,(ClosureMatrix.diffs_are_xors v q);unfold ClosureMatrix.col_slice.
 apply ToggleModel.packed_rollback.
 apply Nat2Z.inj;change (Z.of_nat (length (parities v))=Z.of_nat (length (sublist (q*width v) ((q+1)*width v) (masks v)))).
 rewrite <- !Zlength_correct,Zlength_sublist by nia;unfold width in *;nia.
Qed.

(* The packed detector, the hash and the two CSR loops are all restored.
   The remaining syndrome premise is exactly FlipRoundtrip.native_flip_rolls_back. *)
Theorem packed_state_roundtrip p keys q init:
 let v:=words_at init in
 0<=q -> 0<=width v -> (q+1)*width v<=Zlength (masks v) ->
 let step:=FlipRoundtrip.one_flip p q (column_list v q) in
 step (step (syndrome v,odd_count init))=(syndrome v,odd_count init) ->
 step_support p keys q (step_support p keys q init)=init.
Proof.
 destruct init as [v odd h];cbn [words_at odd_count];intros q_ok positive room;cbv zeta;intro restored.
 set (first:=after_primary v q odd) in *.
 set (syn:=after_extra p q (fst first)) in *.
 change (FlipRoundtrip.one_flip p q (column_list v q) (syn,snd first)=(syndrome v,odd)) in restored.
 set (next:=set_words v syn (differences v q)).
 change ((after_extra p q (fst (after_primary next q (snd first))),snd (after_primary next q (snd first)))=(syndrome v,odd)) in restored.
 assert (back:=f_equal (@fst (list int64) Z) restored);assert (count:=f_equal (@snd (list int64) Z) restored).
 cbn [fst snd] in back,count.
 assert (det: differences next q=parities v) by (apply detector_words_restore;assumption || reflexivity).
 unfold step_support;cbn [words_at odd_count checksum];fold first syn next.
 rewrite back,count,det,Int64.xor_assoc,Int64.xor_idem,Int64.xor_zero.
 unfold next,set_words;destruct v;reflexivity.
Qed.
