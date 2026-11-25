(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VerifDetected VerifChildVisit VerifClosesBody VerifFlipBody
 NativeFlipPayload PreparedFlip PreparedChooserStorage PreparedIndexWhile PreparedIndexChildrenView
 PreparedIndexSyndromeLoan PreparedIndexFinish PreparedIndexCall PreparedChoiceCall PreparedIndexLink
 PreparedUniformIndex PreparedSeedDispatch PreparedPCMChooser RowGather flag_level_ast.
From mathcomp Require Import all_ssreflect all_algebra.
#[local] Existing Instance VerifDetected.CompSpecs.
Set Implicit Arguments.
Unset Strict Implicit.
Local Open Scope ring_scope.
Local Delimit Scope Z_scope with coqZ.

Definition ready_row ptr stride:mpred:=
 EX old:seq Integers.int, !!(Zlength old=stride) && child_storage ptr old.

Lemma give_row_back ptr old picks stride:
 Zlength old=stride -> (Zlength picks<=stride)%coqZ ->
 (child_array ptr (map Int.unsigned picks) * unused_candidates ptr picks old) |-- ready_row ptr stride.
Proof.
 move=>same fits;rewrite -split_returned_candidates;unfold ready_row.
 Exists (filled picks old);apply andp_right;last apply derives_refl.
 apply prop_right;rewrite filled_len;lia.
Qed.

(* These four mutable fields survive a recursive call with different
   contents. Both sides of the call retain the original physical width. *)
Definition reusable_index gv sh s op qp mp off cols nw n:mpred:=
 EX epoch:int64, EX tags:seq int64, EX nc:int64, EX pk:int64,
 !!(Zlength tags=n) && index_workspace gv sh s op qp mp off cols nw n epoch tags nc pk.

Section Reuse.
Variable Espec:OracleKind.
#[local] Existing Instance Espec.
Variables m n:nat.
Variables (H:'M['F_2]_(m,n)) (rows:'I_m->seq 'I_n) (a:@choice_site n).

Definition with_buffers last tags nc pk old:=
 @Site n (globals_at a) (const_share a) (level_p a) (syndrome_p a) (offsets_p a)
 (columns_p a) (blocks_p a) (marks_p a) (output_p a) (row_offsets a) (entries a)
 (blocked_cells a) (call_depth a) (requested_weight a) (odd_words a) nc pk old last tags
 (partial a) (allowed a) (moves a) (syndrome_count a).

Lemma replace_call_buffers last tags nc pk old:
 legal_choice H rows a -> Zlength tags=Z.of_nat n -> Zlength old=Zlength (spare_cells a) ->
 legal_choice H rows (with_buffers last tags nc pk old).
Proof.
 move=>ok width size.
 have fits:(Zlength old<=Int.max_signed)%coqZ by have limit:=output_fits ok;lia.
 have enough (r:'I_m):(Znth (Z.of_nat r+1)%coqZ (row_offsets a)-Znth (Z.of_nat r) (row_offsets a)<=Zlength old)%coqZ
   by have room:=@output_room m n H rows a ok r;lia.
 destruct ok;constructor;cbn [with_buffers];assumption.
Qed.

Lemma returned_row_fits z:legal_choice H rows a -> provenance_at H rows a z ->
 (Zlength (output_columns (row_offsets a) (entries a) (blocked_cells a) z)<=Zlength (spare_cells a))%coqZ.
Proof.
 move=>ok [origin _];case:z origin=>[r used tags|tags|tags] origin;
   try exact:(Zlength_nonneg (spare_cells a)).
 case:origin=>row [-> [odd image]].
 have [bounds [top [room slice]]]:=@row_image m n H rows a ok row.
 have width:=@gather_size (blocked_cells a) (entries a) _ _ bounds room.
 have fits:=@output_room m n H rows a ok row.
 cbn [output_columns];lia.
Qed.

Let area:=reusable_index (globals_at a) (const_share a) (level_p a) (offsets_p a)
 (columns_p a) (marks_p a) (row_offsets a) (entries a) (Zlength (odd_words a)) (Z.of_nat n).

Theorem choose_in_reusable_storage flip dfs keyp pathp keys t path options:
 legal_choice H rows a -> syndrome_p a=psyn (words_at t) -> odd_words a=syndrome (words_at t) ->
 Int.and options (Int.repr 1)=Int.zero -> is_pointer_or_null (level_p a) -> is_pointer_or_null (output_p a) ->
 let regs:=caller_locals (globals_at a) (level_p a) (output_p a) (call_depth a) options in
 let own:=child_fields (level_p a) pathp (blocks_p a) (requested_weight a) (blocked_cells a) path in
 let packed:=packed_mem (level_p a) keyp Bare keys t in let stride:=Zlength (spare_cells a) in
 semax (func_tycontext f_dfs prepared_vars (index_callees H rows flip dfs) nil)
 (PROPx nil (LOCALx regs (SEPx [::own;ready_row (output_p a) stride;packed;area]))) choose_count
 (normal_ret_assert (EX z:scan_exit,let picks:=output_columns (row_offsets a) (entries a) (blocked_cells a) z in
   EX spare:mpred, PROPx [::provenance_at H rows a z;
       (child_array (output_p a) (map Int.unsigned picks)*spare |-- ready_row (output_p a) stride)%logic]
     (LOCALx (temp _count (Vint (Int.repr (length_at a z)))::regs)
       (SEPx [::own;child_array (output_p a) (map Int.unsigned picks);spare;packed;area])))).
Proof.
 move=>ok sp words bit valid out regs own packed stride.
 unfold ready_row at 1;unfold area at 1;unfold reusable_index at 1;Intros old last tags nc pk.
 match goal with h:Zlength old=_ |- _=>pose proof h as row_size end.
 match goal with h:Zlength tags=_ |- _=>pose proof h as mark_size end.
 have legal:=@replace_call_buffers last tags nc pk old ok mark_size row_size.
 pose proof (@registered_choice_reads_current_state Espec m n H rows (with_buffers last tags nc pk old)
       flip dfs keyp pathp keys t path options legal sp words bit valid out) as raw.
 cbn zeta in raw.
 eapply semax_post';last first.
 - eapply semax_pre;[|exact raw].
   unfold own,regs,packed,caller_locals;cbn [with_buffers];rewrite mark_size.
   go_lowerx;normalize;cancel;try apply derives_refl.
 - Intros z;Exists z (unused_candidates (output_p a)
     (output_columns (row_offsets a) (entries a) (blocked_cells a) z) old).
   match goal with h:provenance_at _ _ _ _ |- _=>pose proof h as fact end.
   change (selection_origin rows H (partial a) (allowed a) (moves a) (row_offsets a)
     (entries a) (blocked_cells a) z /\ Zlength (scan_marks z)=Zlength tags) in fact.
   have original:provenance_at H rows a z.
   { split;first exact:(proj1 fact). rewrite (proj2 fact) mark_size;exact:esym (marks_width ok). }
   have release:=@give_row_back (output_p a) old (output_columns (row_offsets a) (entries a) (blocked_cells a) z)
       stride row_size (returned_row_fits ok original).
   have next_size:Zlength (returned_tags z)=Z.of_nat n.
   { change (Zlength (scan_marks z)=Z.of_nat n);by rewrite (proj2 fact) mark_size. }
   unfold area,reusable_index;Exists (Int64.repr (EpochFreshness.advance_tag false (Int64.unsigned last))) (returned_tags z)
       (returned_nocand nc z) (returned_pack pk z).
   cbn [with_buffers];rewrite mark_size;unfold own,regs,packed,length_at,caller_locals.
   go_lowerx;normalize;try cancel;try apply derives_refl.
   all: try (apply andp_right;[apply prop_right;cbn;tauto|cancel]).
Qed.
End Reuse.
