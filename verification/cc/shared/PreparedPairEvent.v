(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VerifOneLeft VerifClosesBody VerifFlipBody PackedDetector NativeFlipPayload
 PreparedDepthSpec PreparedChildCall PreparedWitnessRegister.
Local Open Scope Z_scope.

(* None records a syndrome that closed on the current child. Some z
   records the signed index from the last-qubit table, including -1. *)
Definition pair_code (seen:bool) (last:option Z) :=
 match last with Some z=>final_pick z | None=>if seen then 3 else 0 end.
Definition pair_path depth (next:list int) (last:option Z) :=
 match last with Some z=>last_path (depth+1) z next | None=>next end.
Definition pair_size depth saved (seen:bool) (last:option Z):=
 match last with Some z=>last_size (depth+2) z saved | None=>if seen then Int.repr (depth+1) else saved end.
Definition pair_counts closed leaves (last:option Z):=
 match last with Some _=>(closed,Int64.add leaves Int64.one) | None=>(Int64.add closed Int64.one,leaves) end.

Lemma stored_child_survives_pair depth q (path:list int) seen last saved:
 1<=depth<=Int.max_signed-2 -> depth+1<Zlength path ->
 let next:=upd_Znth depth path (Int.repr q) in let tail:=pair_path depth next last in
 Zlength tail=Zlength path /\ active_prefix (depth+1) tail=append_qubit path depth q /\
 0<=pair_code seen last<=3 /\ witness_at_limit (depth+2) saved (pair_code seen last) (pair_size depth saved seen last) tail.
Proof.
 intros fits len next tail.
 assert (length_ok:Zlength next=Zlength path) by (unfold next;rewrite upd_Znth_Zlength by lia;reflexivity).
 assert (prefix:active_prefix (depth+1) next=append_qubit path depth q) by (apply stored_prefix;lia).
 destruct last as [z|];cbn [pair_path pair_code pair_size] in tail |- *.
 - pose proof (@open_pair_register (depth+2) (depth+1) z saved next ltac:(lia) ltac:(lia) ltac:(lia)) as sized.
   split;[unfold tail,last_path;destruct (Z_lt_dec z 0);rewrite ?upd_Znth_Zlength by lia;assumption|].
   split.
   + unfold tail,last_path;destruct (Z_lt_dec z 0);[exact prefix|];unfold active_prefix;rewrite sublist_upd_Znth_l by lia;exact prefix.
   + split;[unfold final_pick;destruct (Z_lt_dec z 0);lia|exact sized].
 - split;[exact length_ok|split;[exact prefix|split;[destruct seen;lia|]]].
   apply (@closed_pair_register (depth+2) (depth+1) seen saved next);lia.
Qed.
