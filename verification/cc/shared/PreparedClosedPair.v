(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VerifDetected VerifChildVisit EnabledCall OverlapColumnState
 VerifClosesBody VerifFlipBody VerifLastPairClosed PackedDetector NativeFlipPayload PreparedClosedPairMemory
 PreparedPairDispatch PreparedOpenPair.
Require flag_level_ast.
Import flag_level_ast.
#[local] Existing Instance VerifDetected.CompSpecs.
Local Open Scope Z_scope.

Definition closed_pair_heap c s cp w st path payload policy addr ks count saved:=
 (enabled_memory c s cp w path st * packed_mem s addr policy ks payload * closed_stats s count saved)%logic.
Theorem closed_with_live_parent {Espec:OracleKind} c s cp st path payload policy addr ks count saved depth:
 1<=depth<=Int.max_signed-2 -> odd_count payload=0 -> Zlength (parities (words_at payload))<=Int.max_signed ->
 let logical:=packed_detects (parities (words_at payload)) in
 semax pair_delta (PROPx [] (LOCALx (pair_loc s depth 0)
   (SEPx [closed_pair_heap c s cp (depth+2) st path payload policy addr ks count saved])))
 prepared_pair (normal_ret_assert (PROPx [] (LOCALx (pair_loc s depth (if logical then 3 else 0))
   (SEPx [closed_pair_heap c s cp (depth+2) st path payload policy addr ks (Int64.add count Int64.one)
       (if logical then Int.repr (depth+1) else saved)])))).
Proof.
 intros fits shut len logical.
 pose proof (@prepared_pair_closed Espec s (ppar (words_at payload)) (parities (words_at payload))
   count saved depth fits len) as examined.
 pose proof (@semax_frame' Espec VerifDetected.CompSpecs _ _ _ _ _ _ _ _
     (closed_parent_fields c s cp st path addr ks policy payload) examined) as borrowed.
 eapply semax_post'.
 2:{ eapply semax_pre;[|exact borrowed];unfold closed_pair_heap,pair_loc;rewrite share_closed_pair_fields by exact shut;entailer!;cancel. }
 unfold closed_pair_heap,pair_loc,logical;rewrite share_closed_pair_fields by exact shut;entailer!;cancel.
Qed.
