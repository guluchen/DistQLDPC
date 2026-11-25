(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VerifDetected VerifChildVisit VerifClosesBody VerifToggleBody
 VerifFlipBody VerifOneLeft VerifLastPair VerifLastPairClosed HashLookup VerifLookup LeafAPI
 NativeFlipPayload PackedDetector PreparedPairDispatch PreparedPairStorage PreparedClosedPairMemory
 PreparedTerminalTrace PreparedAnswerFrame PreparedOpenPair PreparedFlip flag_level_ast.
#[local] Existing Instance VerifDetected.CompSpecs.
Local Open Scope Z_scope.

Definition open_pair_storage s cp w path payload policy b p leaves saved:=
 (child_fields s cp (pb p) w (HashLookup.blocked b) path * packed_mem s (pk p) policy (keys b) payload *
  lookup_index s b p * pair_statistics s leaves saved)%logic.

Lemma share_plain_lookup s cp w path payload policy b p leaves saved:
 query b=checksum payload ->
 let v:=words_at payload in
 open_pair_storage s cp w path payload policy b p leaves saved =
 (pair_fields s cp w path leaves saved * close_mem Tsh s (odd_count payload) v * book_mem s b p *
  policy_storage policy)%logic.
Proof.
 intros key v;unfold open_pair_storage,child_fields,packed_mem,lookup_index,pair_statistics,
   pair_fields,close_mem,book_mem,toggle_mem;rewrite key;unfold v,width;apply pred_ext;cancel.
Qed.

Theorem open_lookup_without_policy {Espec:OracleKind} s cp path payload policy b p leaves saved depth accept qs:
 query b=checksum payload -> 1<=depth<=Int.max_signed-2 -> depth+1<Zlength path ->
 0<odd_count payload<=Int.max_signed -> book_safe b (words_at payload) (odd_count payload) ->
 leaf_image accept b (words_at payload) (odd_count payload) qs ->
 let store:=open_pair_storage s cp (depth+2) in
 semax pair_delta (PROPx [] (LOCALx (pair_loc s depth 0) (SEPx [store path payload policy b p leaves saved])))
   prepared_pair (normal_ret_assert (EX a:Z,PROPx [leaf_answer accept (extent b) a]
     (LOCALx (pair_loc s depth (final_pick a)) (SEPx [store (last_path (depth+1) a path)
        payload policy b p (Int64.add leaves Int64.one) (last_size (depth+2) a saved)])))).
Proof.
 intros key cap size odd safe image store.
 pose proof (@prepared_pair_open Espec accept s cp p b (words_at payload) (odd_count payload)
    qs path leaves saved depth cap size odd safe image) as run.
 pose proof (frame_answer _ _ _ _ _ _ _ _ (policy_storage policy) run) as keep.
 eapply semax_post'.
 2:{ eapply semax_pre;[|exact keep];unfold store,pair_loc;rewrite share_plain_lookup by exact key;entailer!;cancel. }
 Intros a;Exists a;unfold store,pair_loc;rewrite share_plain_lookup by exact key;entailer!;cancel.
Qed.

Definition closed_plain_storage s cp bp w blocks path payload policy addr ks count saved:=
 (child_fields s cp bp w blocks path * packed_mem s addr policy ks payload * closed_stats s count saved)%logic.
Definition closed_plain_rest s cp bp blocks path payload policy addr ks:=
 (terminal_trace s cp path * field_at Tsh level_type [StructField _blk] bp s *
  data_at Tsh (tarray tuint (Zlength blocks)) (map Vint blocks) bp *
  physical_without_detector s addr (words_at payload) ks (checksum payload) * policy_storage policy)%logic.
Lemma share_plain_closed s cp bp w blocks path payload policy addr ks count saved:
 odd_count payload=0 ->
 closed_plain_storage s cp bp w blocks path payload policy addr ks count saved=
 (pair_closed_fields s w (ppar (words_at payload)) (parities (words_at payload)) count saved *
  closed_plain_rest s cp bp blocks path payload policy addr ks)%logic.
Proof.
 intros zero;unfold closed_plain_storage,child_fields,packed_mem,toggle_mem,width,closed_stats,
  pair_closed_fields,closed_plain_rest,physical_without_detector,terminal_trace;rewrite zero,(split_detector (ppar (words_at payload)) (parities (words_at payload))).
 apply pred_ext;cancel.
Qed.

Theorem closed_lookup_without_policy {Espec:OracleKind} s cp bp blocks path payload policy addr ks count saved depth:
 1<=depth<=Int.max_signed-2 -> odd_count payload=0 -> Zlength (parities (words_at payload))<=Int.max_signed ->
 let detects:=packed_detects (parities (words_at payload)) in
 let store:=closed_plain_storage s cp bp (depth+2) blocks path payload policy addr ks in
 semax pair_delta (PROPx [] (LOCALx (pair_loc s depth 0) (SEPx [store count saved]))) prepared_pair
 (normal_ret_assert (PROPx [] (LOCALx (pair_loc s depth (if detects then 3 else 0))
   (SEPx [store (Int64.add count Int64.one) (if detects then Int.repr (depth+1) else saved)])))).
Proof.
 intros cap shut width_ok detects store.
 pose proof (@prepared_pair_closed Espec s (ppar (words_at payload)) (parities (words_at payload))
     count saved depth cap width_ok) as run.
 pose proof (@semax_frame' Espec VerifDetected.CompSpecs _ _ _ _ _ _ _ _
    (closed_plain_rest s cp bp blocks path payload policy addr ks) run) as keep.
 eapply semax_post'.
 2:{ eapply semax_pre;[|exact keep];unfold store,pair_loc;rewrite share_plain_closed by exact shut;entailer!;cancel. }
 unfold store,pair_loc,detects;rewrite share_plain_closed by exact shut;entailer!;cancel.
Qed.
