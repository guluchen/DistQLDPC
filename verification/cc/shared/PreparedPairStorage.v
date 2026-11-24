(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VerifDetected VerifClosesBody VerifToggleBody VerifFlipBody NativeFlipPayload
 VerifChildVisit VerifEnabledVisit EnabledCall OverlapView OverlapColumnState OverlapChildState OverlapSharedBlocks
 HashLookup VerifLookup VerifLastPair PreparedFlip VerifEnabledSiblings.
Require flag_level_ast.
Import flag_level_ast.
#[local] Existing Instance VerifDetected.CompSpecs.
Local Open Scope Z_scope.

Definition lookup_index s b p:mpred:=
 (field_at Tsh level_type [StructField _htab] (pt p) s * field_at Tsh level_type [StructField _hnext] (pn p) s *
  field_at Tsh level_type [StructField _hmask] (Vlong (mask b)) s *
  data_at Tsh (tarray tint (Zlength (slots b))) (map (fun i=>Vint (Int.repr i)) (slots b)) (pt p) *
  data_at Tsh (tarray tint (Zlength (links b))) (map (fun i=>Vint (Int.repr i)) (links b)) (pn p))%logic.
Definition pair_statistics s leaves previous:mpred:=
 (field_at Tsh level_type [StructField _leaf2] (Vlong leaves) s *
  field_at Tsh level_type [StructField _witness_size] (Vint previous) s)%logic.
Definition lookup_remainder c st policy:=
 (view_without_blocks (callback_owner c) (conn c) (geometry c) st * pointers c * policy_storage policy)%logic.

(* The lookup shares the block vector with sibling exclusion and the hash
   and column keys with flip. Their storage is transferred exactly once. *)
Lemma pair_open_storage c s cp w st path payload policy b p leaves previous:
 0<Zlength (OverlapColumnState.blocked st) ->
 pb p=blockp (conn c) -> HashLookup.blocked b=OverlapColumnState.blocked st ->
 query b=checksum payload ->
 let v:=words_at payload in
 (enabled_memory c s cp w path st * packed_mem s (pk p) policy (keys b) payload *
  lookup_index s b p * pair_statistics s leaves previous)%logic =
 (pair_fields s cp w path leaves previous * close_mem Tsh s (odd_count payload) v * book_mem s b p *
  lookup_remainder c st policy)%logic.
Proof.
 intros pos link blocks key v;rewrite child_owner_view by exact pos.
 unfold child_fields,packed_mem,lookup_index,pair_statistics,pair_fields,close_mem,book_mem,lookup_remainder,toggle_mem.
 rewrite link,blocks,key;unfold v,width;apply pred_ext;cancel.
Qed.
