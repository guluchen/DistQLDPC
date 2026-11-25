(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto.
Require Import VerifDetected VerifChildVisit VerifClosesBody VerifFlipBody PackedDetector NativeFlipPayload
 EnabledCall OverlapView OverlapColumnState OverlapSharedBlocks PreparedDepthSpec PreparedChildCall PreparedTerminalTrace
 PreparedPairDispatch PreparedOpenPair PreparedClosedPairMemory PreparedClosedPair PreparedPairBracket.
Require Import PreparedPlainDescent PreparedPlainPair.
Require flag_level_ast.
Import flag_level_ast.
#[local] Existing Instance VerifDetected.CompSpecs.
Local Open Scope Z_scope.

Theorem closed_plain_bracket {Espec:OracleKind} c s cp bp blocks payload addr ks count saved
 depth q children n i bits path:
 nested_policy (nested c)=nullval ->
 1<=depth<=Int.max_signed-2 -> depth+1<Zlength path ->
 odd_count payload=0 -> Zlength (parities (words_at payload))<=Int.max_signed ->
 let w:=depth+2 in let chosen:=upd_Znth depth path (Int.repr q) in
 let logical:=packed_detects (parities (words_at payload)) in
 let r:Z:=if logical then 3 else 0 in let sv:=if logical then Int.repr (depth+1) else saved in
 let locs:=plain_descent_loc s depth q children n i bits in
 let state:=fun cells stat prior=>closed_plain_storage s cp bp w blocks cells payload Bare addr ks stat prior in
 semax pair_delta (PROPx [] (LOCALx (temp _result (Vint Int.zero)::locs) (SEPx [state path count saved])))
 child_bracket (normal_ret_assert (PROPx [active_prefix (depth+1) chosen=append_qubit path depth q]
 (LOCALx (temp _result (Vint (Int.repr r))::locs) (SEPx [state chosen (Int64.add count Int64.one) sv])))).
Proof.
 intros plain fit room shut width w chosen logical r sv locs state.
 set (saved_child:=state chosen (Int64.add count Int64.one) sv).
 assert (dispatch:semax pair_delta (PROPx [] (LOCALx (pair_loc s depth 0) (SEPx [state chosen count saved])))
 prepared_pair (normal_ret_assert (EX a:unit,PROPx [True] (LOCALx (pair_loc s depth r) (SEPx [saved_child]))))).
 { pose proof (@closed_lookup_without_policy Espec s cp bp blocks chosen payload Bare addr ks count saved depth fit shut width) as original.
   eapply semax_post';[|exact original];Exists tt;unfold pair_loc,saved_child,state,w,r,sv,logical;entailer!;try apply derives_refl. }
 assert (regs:locs=descent_loc c s depth q children n i bits false) by
   (unfold locs,plain_descent_loc,descent_loc;rewrite plain;reflexivity).
 rewrite regs;eapply semax_post'.
 2:{ apply (@run_two_move_bracket unit Espec c s cp depth q children n i bits path
     (@field_at VerifDetected.CompSpecs Tsh level_type [StructField _w] (Vint (Int.repr w)) s *
      @field_at VerifDetected.CompSpecs Tsh level_type [StructField _blk] bp s *
      @data_at VerifDetected.CompSpecs Tsh (tarray tuint (Zlength blocks)) (map Vint blocks) bp *
      packed_mem s addr Bare ks payload * closed_stats s count saved)%logic
     (fun cells=>state cells count saved) (fun _=>True) (fun _=>r) (fun _=>saved_child));
     [exact fit|exact room| |exact dispatch].
     intro cells;unfold state,closed_plain_storage,child_fields,terminal_trace;apply pred_ext;cancel. }
 Intros a;assert (stored:active_prefix (depth+1) chosen=append_qubit path depth q) by (apply stored_prefix;lia).
 unfold saved_child,locs,descent_loc;entailer!;cancel.
Qed.
