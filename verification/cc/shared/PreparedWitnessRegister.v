(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VerifDetected VerifOneLeft PreparedDepthSpec PreparedChildCall.
Require flag_level_ast.
Import flag_level_ast.
#[local] Existing Instance VerifDetected.CompSpecs.
Local Open Scope Z_scope.

(* The caller reads _witness_size after the complete level. Preserve
   ownership of this exact word together with the prefix it describes. *)
Definition witness_register s (stored:int):=
 field_at Tsh level_type [StructField _witness_size] (Vint stored) s.

Definition witness_at_limit w (previous:int) r (written:int) (tail:list int):Prop:=
 (r=0 \/ r=2 -> written=previous) /\
 (r=1 -> written=Int.repr w /\ 0<w<=Zlength tail) /\
 (r=3 -> exists depth, 0<depth<w /\ depth<=Zlength tail /\ written=Int.repr depth).

Theorem open_pair_register w depth a (old:int) (path:list int):
 0<w<=Int.max_signed -> depth=w-1 -> 0<=depth<Zlength path ->
 witness_at_limit w old (final_pick a) (last_size w a old) (last_path depth a path).
Proof.
 intros fits index enough;unfold witness_at_limit,final_pick,last_size,last_path.
 destruct (Z_lt_dec a 0);rewrite ?upd_Znth_Zlength by lia;intuition lia.
Qed.

Theorem closed_pair_register w depth (logical:bool) (old:int) (path:list int):
 0<depth<w -> depth<=Zlength path ->
 witness_at_limit w old (if logical then 3 else 0) (if logical then Int.repr depth else old) path.
Proof.
 intros limit room;destruct logical;unfold witness_at_limit.
 - split;[intuition lia|split;[intuition lia|intros _;exists depth;auto]].
 - split;[auto|split;intuition lia].
Qed.

Lemma empty_child_keeps_prior_size w old intermediate returned r tail earlier:
 witness_at_limit w old 0 intermediate earlier -> witness_at_limit w intermediate r returned tail ->
 witness_at_limit w old r returned tail.
Proof. intros [same _] next;rewrite <-(same ltac:(auto));exact next. Qed.
