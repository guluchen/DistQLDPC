(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VerifDetected VerifChildVisit VerifClosesBody VerifFlipBody VerifToggleBody
 VerifLowestBit VerifRowTally NativeFlipPayload PreparedFlip PreparedChooserStorage PreparedIndexWhile
 PreparedIndexIteration PreparedIndexWordStep PreparedIndexAdvance PreparedIndexSweep PreparedIndexEpoch
 PreparedIndexFinish PreparedIndexChooser PreparedIndexCall PreparedIndexChildrenView PreparedChoiceCall
 PreparedCallerLocals EpochFreshness flag_level_ast.
#[local] Existing Instance VerifDetected.CompSpecs.
Local Open Scope Z_scope.

(* Both C routines read level->syn. Transfer the pointer and its
   array once, leaving the column, logical and hash fields in place. *)
Definition unborrowed_fields s keys (v:close_view) odd hash (colkeys:list int64):=
 (field_at Tsh level_type [StructField _cstart] (poff v) s *
  field_at Tsh level_type [StructField _cr] (prows v) s *
  field_at Tsh level_type [StructField _nodd] (Vint (Int.repr odd)) s *
  field_at Tsh level_type [StructField _kw] (Vint (Int.repr (width v))) s *
  field_at Tsh level_type [StructField _gpar] (ppar v) s *
  field_at Tsh level_type [StructField _gmask] (pmasks v) s *
  field_at Tsh level_type [StructField _synkey] (Vlong hash) s *
  field_at Tsh level_type [StructField _colkey] keys s *
  data_at Tsh (tarray tuint (Zlength (offsets v))) (map (fun z=>Vint (Int.repr z)) (offsets v)) (poff v) *
  data_at Tsh (tarray tuint (Zlength (rows v))) (map Vint (rows v)) (prows v) *
  data_at Tsh (tarray tulong (width v)) (map Vlong (parities v)) (ppar v) *
  data_at Tsh (tarray tulong (Zlength (masks v))) (map Vlong (masks v)) (pmasks v) *
  data_at Tsh (tarray tulong (Zlength colkeys)) (map Vlong colkeys) keys)%logic.

Definition index_workspace gv sh s op qp mp off cols (nw n:Z) last marks nc pk:=
 (field_at Tsh level_type [StructField _mw] (Vint (Int.repr nw)) s *
  counters_header s n last * lookup_bytes gv sh * offsets_heap s op off *
  row_and_mark_storage s qp mp cols marks * statistics s nc pk)%logic.

Lemma hand_syndrome_to_chooser gv sh s op qp mp off cols n last marks nc pk keys keyp t:
 let v:=words_at t in let words:=syndrome v in
 (packed_mem s keyp Bare keys t * index_workspace gv sh s op qp mp off cols (Zlength words) n last marks nc pk)%logic =
 (chooser_private gv sh s (psyn v) op qp mp off cols words nc pk n last marks *
       unborrowed_fields s keyp v (odd_count t) (checksum t) keys)%logic.
Proof.
 intros v words;unfold packed_mem,toggle_mem,index_workspace,chooser_private,syndrome_memory,unborrowed_fields,v,words.
 cbn [policy_storage];apply pred_ext;cancel.
Qed.

Theorem compiled_choice_borrows_syndrome {Espec:OracleKind} gv sh s op qp bp mp children pathp offsets cols
 blocks d w keyp keys t nc pk old last marks path bits meaning:
 let v:=words_at t in let words:=syndrome v in let sp:=psyn v in
 let input:=call_before gv sh s sp op qp bp mp children offsets cols blocks w words nc pk old last marks in
 let after:=call_after gv sh s sp op qp bp mp children offsets cols blocks w words nc pk old last marks in
 let size:=call_count offsets cols blocks in let spec:=call_spec gv s children d input after size meaning in
 let regs:=caller_locals gv s children d bits in let packed:=packed_mem s keyp Bare keys t in
 let work:=index_workspace gv sh s op qp mp offsets cols (Zlength words) (Zlength marks) in
 let header:=Int64.repr (advance_tag false (Int64.unsigned last)) in
 Int.and bits (Int.repr 1)=Int.zero -> is_pointer_or_null s -> is_pointer_or_null children ->
 semax (func_tycontext f_dfs Vprog (caller_functions spec) nil)
 (PROPx nil (LOCALx regs (SEPx [child_fields s pathp bp w blocks path;child_storage children old;
    (packed * work last marks nc pk)%logic]))) choose_count
 (normal_ret_assert (EX result:scan_exit,let picks:=output_columns offsets cols blocks result in
    PROPx [meaning result] (LOCALx (temp _count (Vint (Int.repr (size result)))::regs)
      (SEPx [child_fields s pathp bp w blocks path;child_array children (map Int.unsigned picks);
             unused_candidates children picks old;
             (packed * work header (returned_tags result) (returned_nocand nc result) (returned_pack pk result))%logic])))).
Proof.
 intros v words sp input after size spec regs packed work header direct valid out.
 pose proof (@dfs_borrows_and_releases Espec gv sh s sp op qp bp mp children pathp offsets cols blocks d w
    words nc pk old last marks path bits meaning direct valid out) as raw.
 set (retained:=unborrowed_fields s keyp v (odd_count t) (checksum t) keys).
 pose proof (@keep_caller_locals_for_answer scan_exit Espec VerifDetected.CompSpecs _ choose_count nil regs
   [child_fields s pathp bp w blocks path;child_storage children old;
    chooser_private gv sh s sp op qp mp offsets cols words nc pk (Zlength marks) last marks] nil [retained]
   (fun z=>[meaning z]) (fun z=>temp _count (Vint (Int.repr (size z)))::regs)
   (fun z=>let picks:=output_columns offsets cols blocks z in
    [child_fields s pathp bp w blocks path;child_array children (map Int.unsigned picks);unused_candidates children picks old;
     chooser_private gv sh s sp op qp mp offsets cols words (returned_nocand nc z) (returned_pack pk z)
        (Zlength marks) header (returned_tags z)]) ltac:(unfold choose_count;auto 100 with closed) raw) as saved.
 eapply semax_post'.
 2:{ eapply semax_pre;[|exact saved];unfold packed,work,words,v;rewrite hand_syndrome_to_chooser.
     unfold regs,caller_locals,retained,sp,words,v;go_lowerx;normalize;cancel. }
 Intros z;Exists z;cbn beta iota zeta;unfold packed,work,words,v;rewrite hand_syndrome_to_chooser.
 unfold regs,caller_locals,retained,sp,words,v;go_lowerx;normalize;cancel.
Qed.

From mathcomp Require Import all_ssreflect all_algebra.
Require Import PreparedUniformIndex PreparedIndexLink PreparedSeedDispatch.
Set Implicit Arguments.
Unset Strict Implicit.
Local Open Scope ring_scope.
Section Uniform.
Variable Espec:OracleKind.
#[local] Existing Instance Espec.
Variables m n:nat.
Variables (H:'M['F_2]_(m,n)) (rows:'I_m->seq 'I_n) (a:@choice_site n).

Theorem registered_choice_reads_current_state flip dfs (keyp pathp:Values.val)
 (keys:seq int64) (t:packed_support) (path:seq Integers.int) options:
 legal_choice H rows a -> syndrome_p a=psyn (words_at t) -> odd_words a=syndrome (words_at t) ->
 Int.and options (Int.repr 1)=Int.zero -> is_pointer_or_null (level_p a) -> is_pointer_or_null (output_p a) ->
 let s:=level_p a in let children:=output_p a in let blocks:=blocked_cells a in
 let regs:=caller_locals (globals_at a) s children (call_depth a) options in
 let packed:=packed_mem s keyp Bare keys t in
 let work:=index_workspace (globals_at a) (const_share a) s (offsets_p a) (columns_p a) (marks_p a)
   (row_offsets a) (entries a) (Zlength (odd_words a)) (Zlength (marks a)) in
 let hd:=Int64.repr (advance_tag false (Int64.unsigned (epoch a))) in
 let own:=child_fields s pathp (blocks_p a) (requested_weight a) blocks path in
 semax (func_tycontext f_dfs prepared_vars (index_callees H rows flip dfs) nil)
 (PROPx nil (LOCALx regs (SEPx [::own;child_storage children (spare_cells a);
   (packed*work (epoch a) (marks a) (empty_count a) (pack_count a))%logic]))) choose_count
 (normal_ret_assert (EX z:scan_exit,let picks:=output_columns (row_offsets a) (entries a) blocks z in
   PROPx [::provenance_at H rows a z] (LOCALx (temp _count (Vint (Int.repr (length_at a z)))::regs)
    (SEPx [::own;child_array children (map Int.unsigned picks);unused_candidates children picks (spare_cells a);
      (packed * work hd (returned_tags z) (returned_nocand (empty_count a) z) (returned_pack (pack_count a) z))%logic])))).
Proof.
 move=>legal sp words bit valid out s children blocks regs packed work hd own.
 have embed:=@one_context_for_all_nodes m n H rows flip dfs a legal.
 cbn zeta in embed;unfold before_at,after_at,length_at in embed;rewrite sp words in embed.
 eapply semax_Delta_subsumption;first exact embed.
 unfold own,work,regs,s,children,blocks,packed,hd,length_at;rewrite words.
 exact:(@compiled_choice_borrows_syndrome Espec (globals_at a) (const_share a) (level_p a)
     (offsets_p a) (columns_p a) (blocks_p a) (marks_p a) (output_p a) pathp (row_offsets a)
     (entries a) (blocked_cells a) (call_depth a) (requested_weight a) keyp keys t (empty_count a)
     (pack_count a) (spare_cells a) (epoch a) (marks a) path options (provenance_at H rows a) bit valid out).
Qed.
End Uniform.
