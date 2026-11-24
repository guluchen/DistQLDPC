(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.floyd.reassoc_seq VerifDetected PreparedSeedDispatch ClightSelect.
Require flag_level_ast.
Import flag_level_ast.
#[local] Existing Instance VerifDetected.CompSpecs.
Local Open Scope Z_scope.

Definition is_overlap_decision (st:statement) := match st with
 | Ssequence (Sifthenelse _ _ _) (Sset dest _) => Pos.eqb dest _update_overlap
 | _=>false end.
Definition choose_overlap:statement:=ltac:(native_fragment is_overlap_decision f_dfs).
Definition depth_locs s wdepth bits:=[temp _s s;temp _size (Vint (Int.repr wdepth));temp _options (Vint bits)].
Definition enabled_at bits w depth:=andb (negb (Int.eq (Int.and bits (Int.repr 16)) Int.zero)) (Z.ltb 3 (w-depth)).

Theorem overlap_decision_exact {Espec:OracleKind} s bits w depth (frame:mpred):
 0<=depth<=w -> w<=Int.max_signed ->
 semax (func_tycontext f_dfs prepared_vars [] [])
 (PROPx [] (LOCALx (depth_locs s depth bits)
  (SEPx [field_at Tsh level_type [StructField _w] (Vint (Int.repr w)) s;frame])))
 choose_overlap (normal_ret_assert (PROPx [] (LOCALx
 (temp _update_overlap (Vint (if enabled_at bits w depth then Int.one else Int.zero))::depth_locs s depth bits)
 (SEPx [field_at Tsh level_type [StructField _w] (Vint (Int.repr w)) s;frame])))).
Proof.
 intros interval fits;unfold choose_overlap,depth_locs,enabled_at;abbreviate_semax;reassoc_seq.
 apply semax_if_seq;forward_if.
 - destruct (Int.eq (Int.and bits (Int.repr 16)) Int.zero) eqn:mask;
    [apply Int.same_if_eq in mask;congruence|];cbn [negb andb].
   forward;forward;try solve [entailer!;rep_lia];forward;entailer!;
    destruct (zlt 3 (w-depth)), (Z.ltb_spec 3 (w-depth));try lia;reflexivity.
 - assert (off:Int.eq (Int.and bits (Int.repr 16)) Int.zero=true) by
    (match goal with H:Int.and _ _=Int.zero |- _=>rewrite H,Int.eq_true;reflexivity end).
   forward;forward;entailer!;rewrite ?off;reflexivity.
Qed.
