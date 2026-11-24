(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VerifDetected VerifChildVisit VerifEnabledSiblings EnabledCall OverlapView
 OverlapColumnState OverlapSharedBlocks VerifClosesBody VerifToggleBody VerifFlipBody VerifLastPairClosed
 NativeFlipPayload PreparedFlip PreparedTerminalTrace.
Require flag_level_ast.
Import flag_level_ast.
#[local] Existing Instance VerifDetected.CompSpecs.
Local Open Scope Z_scope.

Definition unused_empty_detector p (words:list int64):=
 match words with nil=>data_at Tsh (tarray tulong 0) (@nil val) p | _::_=>emp end.
Lemma split_detector p words:
 data_at Tsh (tarray tulong (Zlength words)) (map Vlong words) p=
 (parity_storage Tsh words p * unused_empty_detector p words)%logic.
Proof. destruct words;cbn [parity_storage unused_empty_detector];[rewrite emp_sepcon|rewrite sepcon_emp];reflexivity. Qed.

Definition physical_without_detector s addr v ks hash:=
 (field_at Tsh level_type [StructField _cstart] (poff v) s *
  field_at Tsh level_type [StructField _cr] (prows v) s *
  field_at Tsh level_type [StructField _syn] (psyn v) s *
  field_at Tsh level_type [StructField _gmask] (pmasks v) s *
  field_at Tsh level_type [StructField _synkey] (Vlong hash) s *
  field_at Tsh level_type [StructField _colkey] addr s *
  data_at Tsh (tarray tuint (Zlength (offsets v))) (map (fun i=>Vint (Int.repr i)) (offsets v)) (poff v) *
  data_at Tsh (tarray tuint (Zlength (rows v))) (map Vint (rows v)) (prows v) *
  data_at Tsh (tarray tulong (Zlength (syndrome v))) (map Vlong (syndrome v)) (psyn v) *
  data_at Tsh (tarray tulong (Zlength (masks v))) (map Vlong (masks v)) (pmasks v) *
  data_at Tsh (tarray tulong (Zlength ks)) (map Vlong ks) addr *
  unused_empty_detector (ppar v) (parities v))%logic.

Definition closed_stats s count saved:=
 (field_at Tsh level_type [StructField _closed] (Vlong count) s *
  field_at Tsh level_type [StructField _witness_size] (Vint saved) s)%logic.
Definition closed_parent_fields c s cp st path addr ks policy payload:=
 (terminal_trace s cp path * field_at Tsh level_type [StructField _blk] (blockp (conn c)) s *
  cols c st * pointers c * physical_without_detector s addr (words_at payload) ks (checksum payload) *
  policy_storage policy)%logic.

Theorem share_closed_pair_fields c s cp w st path payload policy addr ks count saved:
 odd_count payload=0 ->
 let v:=words_at payload in
 (enabled_memory c s cp w path st * packed_mem s addr policy ks payload * closed_stats s count saved)%logic =
 (pair_closed_fields s w (ppar v) (parities v) count saved * closed_parent_fields c s cp st path addr ks policy payload)%logic.
Proof.
 intros closed v;unfold enabled_memory,level_links,packed_mem,toggle_mem,width,closed_stats,pair_closed_fields,
  closed_parent_fields,physical_without_detector,terminal_trace,v.
 rewrite closed;rewrite (split_detector (ppar (words_at payload)) (parities (words_at payload))).
 apply pred_ext;cancel.
Qed.
