(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.floyd.reassoc_seq VerifDetected VerifChildVisit EnabledCall
 ClightSelect PreparedSeedDispatch PreparedOverlapDepth PreparedSiblingScan PreparedVerdictExit PreparedSampling.
Require flag_level_ast.
Import flag_level_ast.
#[local] Existing Instance VerifDetected.CompSpecs.
Local Open Scope Z_scope.

Definition after_choice (s:statement):=match s with
 | Ssequence flag (Ssequence (Sset i _) (Ssequence (Sset r _) tail)) =>
   andb (is_overlap_decision flag) (andb (Pos.eqb i _excluded) (andb (Pos.eqb r _result) (from_children tail)))
 | _=>false end.
Definition selected_subtree:statement:=ltac:(native_fragment after_choice f_dfs).
Definition ready_scan:=match selected_subtree with
 | Ssequence flag (Ssequence exc (Ssequence res _))=>Ssequence flag (Ssequence exc res)
 | _=>Sskip end.
Lemma cached_dispatch_source:
  selected_subtree=Ssequence choose_overlap (Ssequence (Sset _excluded (Econst_int (Int.repr 0) tint))
    (Ssequence (Sset _result (Econst_int (Int.repr 0) tint)) search_finish)).
Proof. reflexivity. Qed.

Definition chosen_loc c s children depth count bits sample:=
 [temp _s s;temp _children children;temp _policy (nested_policy (nested c));temp _options (Vint bits);
  temp _size (Vint (Int.repr depth));temp _count (Vint (Int.repr count));lvar _sample sample_type sample].

(* The count and child pointer are the outputs of the policy callback.
   The next instructions only cache the overlap decision and initialize
   the result and exclusion counter. The array, path and sample object
   remain available to the sibling loop. *)
Theorem initialize_sibling_scan {Espec:OracleKind} c s children w depth count bits sample (frame:mpred):
 0<=depth<=w -> w<=Int.max_signed ->
 let budget:=field_at Tsh level_type [StructField _w] (Vint (Int.repr w)) s in
 semax (func_tycontext f_dfs prepared_vars [] [])
  (PROPx [] (LOCALx (chosen_loc c s children depth count bits sample) (SEPx [budget;frame])))
  ready_scan (normal_ret_assert (PROPx [] (LOCALx
     (scan_loc_mode (enabled_at bits w depth) c s children depth count 0 0 bits++[lvar _sample sample_type sample])
     (SEPx [budget;frame])))).
Proof.
 intros bounds fits budget;unfold ready_scan;rewrite cached_dispatch_source;cbn beta iota.
 unfold choose_overlap,chosen_loc,scan_loc_mode,enabled_at,budget;cbn [app];abbreviate_semax;reassoc_seq.
 apply semax_if_seq;forward_if.
 - destruct (Int.eq (Int.and bits (Int.repr 16)) Int.zero) eqn:mask;[apply Int.same_if_eq in mask;congruence|].
   cbn [andb negb];forward;forward;try solve [entailer!;rep_lia].
   do 3 forward;entailer!;destruct (zlt 3 (w-depth)),(Z.ltb_spec 3 (w-depth));try lia;reflexivity.
 - assert (off:Int.eq (Int.and bits (Int.repr 16)) Int.zero=true) by
     (match goal with h:Int.and _ _=Int.zero |- _=>rewrite h,Int.eq_true;reflexivity end).
   do 4 forward;entailer!;rewrite ?off;reflexivity.
Qed.
