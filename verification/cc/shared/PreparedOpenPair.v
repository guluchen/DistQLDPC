(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VerifDetected VerifChildVisit VerifEnabledVisit
 EnabledCall OverlapColumnState OverlapView VerifClosesBody VerifFlipBody VerifOneLeft VerifLastPair
 HashLookup VerifLookup LeafAPI NativeFlipPayload PreparedPairStorage PreparedPairDispatch PreparedAnswerFrame.
Require flag_level_ast.
Import flag_level_ast.
#[local] Existing Instance VerifDetected.CompSpecs.
Local Open Scope Z_scope.

Definition active_pair c s cp w st path payload policy b p leaves saved:=
 (enabled_memory c s cp w path st * packed_mem s (pk p) policy (keys b) payload *
  lookup_index s b p * pair_statistics s leaves saved)%logic.
Definition pair_loc s depth r:=
 [temp _s s;temp _size (Vint (Int.repr depth));temp _result (Vint (Int.repr r))].

Theorem lookup_with_live_parent {Espec:OracleKind} c s cp st path payload policy b p leaves saved depth accept qs:
 0<Zlength (OverlapColumnState.blocked st) -> pb p=blockp (conn c) ->
 HashLookup.blocked b=OverlapColumnState.blocked st -> query b=checksum payload ->
 1<=depth<=Int.max_signed-2 -> depth+1<Zlength path -> 0<odd_count payload<=Int.max_signed ->
 book_safe b (words_at payload) (odd_count payload) -> leaf_image accept b (words_at payload) (odd_count payload) qs ->
 semax pair_delta (PROPx [] (LOCALx (pair_loc s depth 0)
  (SEPx [active_pair c s cp (depth+2) st path payload policy b p leaves saved])))
 prepared_pair
 (normal_ret_assert (EX a:Z,PROPx [leaf_answer accept (extent b) a]
  (LOCALx (pair_loc s depth (final_pick a))
   (SEPx [active_pair c s cp (depth+2) st (last_path (depth+1) a path) payload policy b p
    (Int64.add leaves Int64.one) (last_size (depth+2) a saved)])))).
Proof.
 intros live link block key bound len odd safe image.
 pose proof (@prepared_pair_open Espec accept s cp p b (words_at payload) (odd_count payload)
     qs path leaves saved depth bound len odd safe image) as run.
 pose proof (frame_answer _ _ _ _ _ _ _ _ (lookup_remainder c st policy) run) as keep.
 eapply semax_post'.
 2:{ eapply semax_pre;[|exact keep];unfold active_pair,pair_loc;
     rewrite pair_open_storage by assumption;entailer!;cancel. }
 Intros a;Exists a;unfold active_pair,pair_loc;rewrite pair_open_storage by assumption;entailer!;cancel.
Qed.
