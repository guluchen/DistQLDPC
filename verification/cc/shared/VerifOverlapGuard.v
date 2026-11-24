(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.floyd.reassoc_seq.
Require Import ClightSelect level_ast VerifDetected EnabledCall.
Local Open Scope Z_scope.
#[local] Existing Instance VerifDetected.CompSpecs.

Definition sets_overlap (st:statement):bool :=
 match st with Ssequence _ (Sset id _) => Pos.eqb id _update_overlap | _=>false end.
Definition native_guard:statement:=ltac:(native_fragment sets_overlap f_dfs).
Definition flag_loc s policy depth:=
 [temp _s s;temp _policy policy;temp _size (Vint (Int.repr depth))].
Definition overlap_slot p fp:=(field_at Tsh (Tstruct _cc_level_policy noattr) [StructField _overlap] fp p * weak_valid_pointer p)%logic.
Definition guard_word depth w := if Z_lt_dec 3 (w-depth) then Int.one else Int.zero.

(* The two short-circuit tests precede the signed subtraction.  Match the
   exact function field dereferenced by the C code in the non-null case. *)
Theorem guard_without_policy {Espec:OracleKind} c s depth:
 is_pointer_or_null s -> Int.min_signed<=depth<=Int.max_signed ->
 semax (func_tycontext f_dfs Vprog (EGprog c) [])
   (PROPx nil (LOCALx (flag_loc s nullval depth) (SEPx nil))) native_guard
   (normal_ret_assert (PROPx nil (LOCALx (temp _update_overlap (Vint Int.zero)::flag_loc s nullval depth) (SEPx nil)))).
Proof.
 intros;unfold native_guard,flag_loc;abbreviate_semax;reassoc_seq.
 apply semax_if_seq;forward_if;[contradiction|forward].
 apply semax_if_seq;forward_if;[contradiction|forward].
 forward;entailer!.
Qed.
Theorem guard_without_callback {Espec:OracleKind} c s p depth:
 is_pointer_or_null s -> Int.min_signed<=depth<=Int.max_signed ->
 semax (func_tycontext f_dfs Vprog (EGprog c) [])
   (PROPx nil (LOCALx (flag_loc s p depth) (SEPx [overlap_slot p nullval]))) native_guard
   (normal_ret_assert (PROPx nil (LOCALx (temp _update_overlap (Vint Int.zero)::flag_loc s p depth)
       (SEPx [overlap_slot p nullval])))).
Proof.
 intros;unfold native_guard,flag_loc,overlap_slot;abbreviate_semax;reassoc_seq.
 Intros;assert_PROP (isptr p) as live by entailer!.
 apply semax_if_seq;forward_if;try solve [subst p;contradiction].
 { destruct p;try contradiction;cbn [denote_tc_test_eq];apply andp_right;[entailer!|auto 40 with valid_pointer]. }
 do 2 forward.
 apply semax_if_seq;forward_if;[contradiction|forward].
 forward;entailer!.
Qed.
Theorem guard_with_callback {Espec:OracleKind} c s p fp depth w:
 isptr fp -> 0<=depth<=w -> w<=Int.max_signed ->
 semax (func_tycontext f_dfs Vprog (EGprog c) [])
   (PROPx nil (LOCALx (flag_loc s p depth)
      (SEPx [overlap_slot p fp;weak_valid_pointer fp;field_at Tsh level_type [StructField _w] (Vint (Int.repr w)) s]))) native_guard
   (normal_ret_assert (PROPx nil (LOCALx (temp _update_overlap (Vint (guard_word depth w))::flag_loc s p depth)
      (SEPx [overlap_slot p fp;weak_valid_pointer fp;field_at Tsh level_type [StructField _w] (Vint (Int.repr w)) s])))).
Proof.
 intros fp_live span bound;unfold native_guard,flag_loc,overlap_slot;abbreviate_semax;reassoc_seq.
 Intros;assert_PROP (isptr p) as live by entailer!.
 destruct fp;try contradiction.
 apply semax_if_seq;forward_if;try solve [subst p;contradiction].
 { destruct p;try contradiction;cbn [denote_tc_test_eq];apply andp_right;[entailer!|auto 40 with valid_pointer]. }
 do 2 forward;try solve [entailer!;cbn [denote_tc_test_eq];apply andp_right;[entailer!|auto 40 with valid_pointer]].
 apply semax_if_seq;forward_if;try solve [congruence|discriminate].
 do 2 forward;try solve [entailer!;rep_lia].
 forward;entailer!;unfold guard_word;destruct (Z_lt_dec 3 (w-depth)),(zlt 3 (w-depth));try lia;reflexivity.
Qed.
