(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto.
Require Import VerifDetected VerifChildVisit VerifClosesBody VerifFlipBody PackedDetector NativeFlipPayload
 EnabledCall OverlapView OverlapColumnState OverlapSharedBlocks PreparedDepthSpec PreparedChildCall PreparedTerminalTrace
 PreparedPairDispatch PreparedOpenPair PreparedClosedPairMemory PreparedClosedPair PreparedPairBracket.
Require flag_level_ast.
Import flag_level_ast.
#[local] Existing Instance VerifDetected.CompSpecs.
Local Open Scope Z_scope.

Theorem closed_bracket_saves_current_child {Espec:OracleKind} c s cp st payload policy addr ks count saved
 depth q children n i bits path:
 1<=depth<=Int.max_signed-2 -> depth+1<Zlength path ->
 odd_count payload=0 -> Zlength (parities (words_at payload))<=Int.max_signed ->
 let w:=depth+2 in let chosen:=upd_Znth depth path (Int.repr q) in
 let logical:=packed_detects (parities (words_at payload)) in
 let r:Z:=if logical then 3 else 0 in let sv:=if logical then Int.repr (depth+1) else saved in
 let locs:=descent_loc c s depth q children n i bits false in
 let state:=fun cells stat prior=>closed_pair_heap c s cp w st cells payload policy addr ks stat prior in
 semax pair_delta (PROPx [] (LOCALx (temp _result (Vint Int.zero)::locs) (SEPx [state path count saved])))
 child_bracket (normal_ret_assert (PROPx [active_prefix (depth+1) chosen=append_qubit path depth q]
 (LOCALx (temp _result (Vint (Int.repr r))::locs) (SEPx [state chosen (Int64.add count Int64.one) sv])))).
Proof.
 intros fit room shut width w chosen logical r sv locs state.
 set (saved_child:=state chosen (Int64.add count Int64.one) sv).
 assert (dispatch:semax pair_delta (PROPx [] (LOCALx (pair_loc s depth 0) (SEPx [state chosen count saved])))
 prepared_pair (normal_ret_assert (EX a:unit,PROPx [True] (LOCALx (pair_loc s depth r) (SEPx [saved_child]))))).
 { pose proof (@closed_with_live_parent Espec c s cp st chosen payload policy addr ks count saved depth fit shut width) as original.
   eapply semax_post';[|exact original];Exists tt;unfold pair_loc,saved_child,state,w,r,sv,logical;entailer!;try apply derives_refl. }
 eapply semax_post'.
 2:{ apply (@run_two_move_bracket unit Espec c s cp depth q children n i bits path
     (@field_at VerifDetected.CompSpecs Tsh level_type [StructField _w] (Vint (Int.repr w)) s *
      @field_at VerifDetected.CompSpecs Tsh level_type [StructField _blk] (blockp (conn c)) s * cols c st * pointers c *
      packed_mem s addr policy ks payload * closed_stats s count saved)%logic
     (fun cells=>state cells count saved) (fun _=>True) (fun _=>r) (fun _=>saved_child));
     [exact fit|exact room| |exact dispatch].
     intro cells;unfold state,closed_pair_heap,enabled_memory,level_links,terminal_trace;apply pred_ext;cancel. }
 Intros a;assert (stored:active_prefix (depth+1) chosen=append_qubit path depth q) by (apply stored_prefix;lia).
 unfold saved_child,locs,descent_loc;entailer!;cancel.
Qed.
