(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VerifDetected VerifChildVisit VerifRowTally
 EpochFreshness RowGather PreparedIndexFinish PreparedIndexEpoch PreparedIndexCall
 PreparedIndexWhile PreparedIndexSweep PreparedIndexWordStep PreparedIndexBitBody PreparedIndexAdvance PreparedIndexIteration.
#[local] Existing Instance VerifDetected.CompSpecs.
Local Open Scope Z_scope.

Definition unused_candidates children picks old:=
 let tail:=sublist (Zlength picks) (Zlength old) old in
 let total:=Zlength (filled picks old) in
 data_at Tsh (tarray tuint (total-Zlength picks)) (map Vint tail)
    (field_address0 (tarray tuint total) [ArraySubsc (Zlength picks)] children).

(* The exact suffix stays available to reassemble the original buffer after
   DFS returns. This equality also covers the zero-length prefix of a cut. *)
Lemma split_returned_candidates children picks old :
 child_storage children (filled picks old)=
 (child_array children (map Int.unsigned picks) * unused_candidates children picks old)%logic.
Proof.
 assert (repr:forall ls:list int,map (fun i=>Vint (Int.repr i)) (map Int.unsigned ls)=map Vint ls).
 { induction ls as [|q tail ih];cbn;[reflexivity|rewrite Int.repr_unsigned,ih;reflexivity]. }
 unfold child_array,child_storage,unused_candidates;rewrite repr,Zlength_map.
 set (tail:=sublist (Zlength picks) (Zlength old) old).
 change (filled picks old) with (picks++tail).
 rewrite map_app.
 apply split2_data_at_Tarray_app;rewrite ?Zlength_map,?Zlength_app;try reflexivity;lia.
Qed.

Definition returned_tags result:=match result with AllBits _ _ tags|EmptyRow tags|TooManyRows tags=>tags end.
Definition returned_nocand nc result:=match result with EmptyRow _=>Int64.add nc Int64.one|_=>nc end.
Definition returned_pack pk result:=match result with TooManyRows _=>Int64.add pk Int64.one|_=>pk end.

Definition retained_by_parent gv sh s sp op cp bp mp children offsets cols blocks w words nc pk old last (marks:list int64) result:=
 (counters_header s (Zlength marks) (Int64.repr (advance_tag false (Int64.unsigned last))) *
  syndrome_memory s sp words * lookup_bytes gv sh * offsets_heap s op offsets *
  tally_memory s cp bp mp cols blocks (returned_tags result) * stored_weight s w *
  statistics s (returned_nocand nc result) (returned_pack pk result) *
  unused_candidates children (output_columns offsets cols blocks result) old)%logic.

Lemma returned_row_for_siblings gv sh s sp op cp bp mp children offsets cols blocks w words nc pk old last marks result :
 call_after gv sh s sp op cp bp mp children offsets cols blocks w words nc pk old last marks result=
 (child_array children (map Int.unsigned (output_columns offsets cols blocks result)) *
  retained_by_parent gv sh s sp op cp bp mp children offsets cols blocks w words nc pk old last marks result)%logic.
Proof.
 assert (empty_fill:filled [] old=old) by
   (unfold filled;cbn [app];rewrite Zlength_nil,sublist_same by (pose proof (Zlength_nonneg old);lia);reflexivity).
 destruct result as [r p tags|tags|tags];
   unfold call_after,chooser_storage,retained_by_parent;
   cbn [output_columns returned_tags returned_nocand returned_pack].
 - rewrite split_returned_candidates;apply pred_ext;cancel.
 - pose proof (split_returned_candidates children [] old) as split;rewrite empty_fill in split;rewrite split;apply pred_ext;cancel.
 - pose proof (split_returned_candidates children [] old) as split;rewrite empty_fill in split;rewrite split;apply pred_ext;cancel.
Qed.

Require Import PreparedChoiceCall flag_level_ast.

Theorem direct_call_supplies_child_array {Espec:OracleKind} gv sh s sp op cp bp mp children offsets cols blocks dep w words nc pk old last marks bits meaning:
 let input:=call_before gv sh s sp op cp bp mp children offsets cols blocks w words nc pk old last marks in
 let returned:=call_after gv sh s sp op cp bp mp children offsets cols blocks w words nc pk old last marks in
 let size:=call_count offsets cols blocks in
 let spec:=call_spec gv s children dep input returned size meaning in
 Int.and bits (Int.repr 1)=Int.zero -> is_pointer_or_null s -> is_pointer_or_null children ->
 semax (func_tycontext f_dfs Vprog (caller_functions spec) [])
  (PROPx [] (LOCALx (caller_locals gv s children dep bits) (SEPx [input])))
  choose_count (normal_ret_assert (EX result:scan_exit,
    PROPx [meaning result]
     (LOCALx (temp _count (Vint (Int.repr (size result)))::caller_locals gv s children dep bits)
       (SEPx [child_array children (map Int.unsigned (output_columns offsets cols blocks result));
           retained_by_parent gv sh s sp op cp bp mp children offsets cols blocks w words nc pk old last marks result]))))%assert.
Proof.
 intros input returned size spec direct valid out.
 eapply semax_post';[|exact (@dfs_calls_index Espec gv s children dep bits input returned size meaning direct valid out)].
 Intros result;Exists result;unfold returned;rewrite returned_row_for_siblings;unfold caller_locals;entailer!;cancel.
Qed.
