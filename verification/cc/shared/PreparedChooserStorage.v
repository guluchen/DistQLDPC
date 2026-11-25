(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VerifDetected VerifChildVisit VerifLowestBit VerifRowTally
 PreparedIndexSweep PreparedIndexWordStep PreparedIndexAdvance PreparedIndexEpoch PreparedIndexWhile
 PreparedIndexIteration PreparedIndexFinish PreparedIndexChildrenView PreparedIndexCall PreparedIndexChooser EpochFreshness
 flag_level_ast.
#[local] Existing Instance VerifDetected.CompSpecs.
Local Open Scope Z_scope.

Definition path_storage s pathp (path:list int):=
 (field_at Tsh level_type [StructField _cur] pathp s *
  data_at Tsh (tarray tint (Zlength path)) (map Vint path) pathp)%logic.

Definition row_and_mark_storage s qp mp cols marks:=
 (field_at Tsh level_type [StructField _rq] qp s * data_at Tsh (tarray tuint (Zlength cols)) (map Vint cols) qp *
  field_at Tsh level_type [StructField _mark] mp s * data_at Tsh (tarray tulong (Zlength marks)) (map Vlong marks) mp)%logic.

Definition chooser_private gv sh s sp op qp mp offsets cols words nc pk n last marks:=
 (counters_header s n last * syndrome_memory s sp words * lookup_bytes gv sh * offsets_heap s op offsets *
  row_and_mark_storage s qp mp cols marks * statistics s nc pk)%logic.

(* The chooser and DFS both access _blk and _w. Convey ownership of
   those fields across the call; framing a second copy is impossible. *)
Lemma borrow_for_choice gv sh s sp op qp bp mp children pathp offsets cols blocks w words nc pk old last marks path:
 (child_fields s pathp bp w blocks path * child_storage children old *
  chooser_private gv sh s sp op qp mp offsets cols words nc pk (Zlength marks) last marks)%logic =
 (call_before gv sh s sp op qp bp mp children offsets cols blocks w words nc pk old last marks *
  path_storage s pathp path)%logic.
Proof.
 unfold child_fields,chooser_private,row_and_mark_storage,call_before,chooser_storage,tally_memory,stored_weight,path_storage.
 apply pred_ext;cancel.
Qed.

Lemma release_after_choice gv sh s sp op qp bp mp children pathp offsets cols blocks w words nc pk old last marks path result:
 let picks:=output_columns offsets cols blocks result in
 let header:=Int64.repr (advance_tag false (Int64.unsigned last)) in
 (call_after gv sh s sp op qp bp mp children offsets cols blocks w words nc pk old last marks result *
  path_storage s pathp path)%logic =
 (child_fields s pathp bp w blocks path * child_array children (map Int.unsigned picks) *
   unused_candidates children picks old *
   chooser_private gv sh s sp op qp mp offsets cols words (returned_nocand nc result) (returned_pack pk result)
     (Zlength marks) header (returned_tags result))%logic.
Proof.
 intros picks header;rewrite returned_row_for_siblings.
 unfold retained_by_parent,child_fields,chooser_private,row_and_mark_storage,tally_memory,stored_weight,path_storage,picks,header.
 apply pred_ext;cancel.
Qed.

Require Import PreparedChoiceCall PreparedCallerLocals.

Theorem dfs_borrows_and_releases {Espec:OracleKind} gv sh s sp op qp bp mp children pathp
 offsets cols blocks d w words nc pk old last marks path bits meaning:
 let input:=call_before gv sh s sp op qp bp mp children offsets cols blocks w words nc pk old last marks in
 let after:=call_after gv sh s sp op qp bp mp children offsets cols blocks w words nc pk old last marks in
 let size:=call_count offsets cols blocks in
 let spec:=call_spec gv s children d input after size meaning in
 let regs:=caller_locals gv s children d bits in
 let private:=chooser_private gv sh s sp op qp mp offsets cols words nc pk (Zlength marks) last marks in
 let header:=Int64.repr (advance_tag false (Int64.unsigned last)) in
 Int.and bits (Int.repr 1)=Int.zero -> is_pointer_or_null s -> is_pointer_or_null children ->
 semax (func_tycontext f_dfs Vprog (caller_functions spec) nil)
 (PROPx nil (LOCALx regs (SEPx [child_fields s pathp bp w blocks path;child_storage children old;private])))
 choose_count (normal_ret_assert (EX result:scan_exit,
   let picks:=output_columns offsets cols blocks result in
   PROPx [meaning result] (LOCALx (temp _count (Vint (Int.repr (size result)))::regs)
    (SEPx [child_fields s pathp bp w blocks path;child_array children (map Int.unsigned picks);
     unused_candidates children picks old;
     chooser_private gv sh s sp op qp mp offsets cols words (returned_nocand nc result) (returned_pack pk result)
       (Zlength marks) header (returned_tags result)])))).
Proof.
 intros input after size spec regs private header direct valid out.
 pose proof (@dfs_calls_index Espec gv s children d bits input after size meaning direct valid out) as raw.
 pose proof (@keep_caller_locals_for_answer scan_exit Espec VerifDetected.CompSpecs _ choose_count
   nil regs [input] nil [path_storage s pathp path]
   (fun z=>[meaning z]) (fun z=>temp _count (Vint (Int.repr (size z)))::regs) (fun z=>[after z])
   ltac:(unfold choose_count;auto 100 with closed) raw) as framed.
 eapply semax_post'.
 2:{ eapply semax_pre;[|exact framed].
     unfold regs,caller_locals;go_lowerx;normalize.
     unfold input,private,call_before,chooser_storage,chooser_private,child_fields,row_and_mark_storage,stored_weight,
       path_storage,tally_memory;cancel. }
 Intros z;Exists z;cbn beta iota zeta;unfold regs,caller_locals;go_lowerx;normalize.
 unfold after,header;rewrite returned_row_for_siblings.
 unfold path_storage,child_fields,retained_by_parent,chooser_private,row_and_mark_storage,stored_weight,tally_memory;cancel.
Qed.

Require Import EnabledCall PreparedSeedDispatch PreparedInitializeScan PreparedSiblingScan
 PreparedOverlapDepth PreparedPlainSiblings PreparedVerdictExit PreparedSampling.

Definition plain_chosen_loc s children d count bits ptr:=
 [temp _s s;temp _children children;temp _policy nullval;temp _options (Vint bits);
  temp _size (Vint (Int.repr d));temp _count (Vint (Int.repr count));lvar _sample sample_type ptr].

Theorem initialize_plain_subtree {Espec:OracleKind} D c s children pathp bp w blocks path d count bits ptr
 (rest:mpred) post:
 tycontext_sub (func_tycontext f_dfs prepared_vars [] []) D ->
 nested_policy (nested c)=nullval -> Int.and bits (Int.repr 16)=Int.zero ->
 0<=d<=w -> w<=Int.max_signed ->
 let owned:=[child_fields s pathp bp w blocks path;rest] in
 semax D (PROPx [] (LOCALx (plain_scan_regs s children d count 0 0 bits++[lvar _sample sample_type ptr])
  (SEPx owned))) search_finish post ->
 semax D (PROPx [] (LOCALx (plain_chosen_loc s children d count bits ptr) (SEPx owned))) selected_subtree post.
Proof.
 intros sub null off depth fits owned body.
 apply (semax_unfold_seq (Ssequence ready_scan search_finish) selected_subtree eq_refl).
 eapply semax_seq';[|exact body].
 eapply semax_Delta_subsumption;[exact sub|].
 set (held:=(field_at Tsh level_type [StructField _blk] bp s *
  data_at Tsh (tarray tuint (Zlength blocks)) (map Vint blocks) bp * path_storage s pathp path * rest)%logic).
 pose proof (@initialize_sibling_scan Espec c s children w d count bits ptr held depth fits) as init.
 unfold chosen_loc,scan_loc_mode,enabled_at in init;rewrite null,off,Int.eq_true in init;cbn [andb negb] in init.
 eapply semax_post'.
 2:{ eapply semax_pre;[|exact init]. unfold owned,plain_chosen_loc,held,child_fields,path_storage;go_lowerx;normalize;cancel. }
 unfold owned,plain_scan_regs,held,child_fields,path_storage;cbn [app];go_lowerx;normalize;cancel.
Qed.
