(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.floyd.field_compat raw_pcm_ast RawPCMPrimitives.
#[local] Existing Instance RawPCMComposites.
Local Open Scope Z_scope.

Definition packed_storage base words:=row_storage base (Zlength words) words.
Definition word_address base offset:=offset_val (8*offset) base.

(* Recover the concrete pointer used by row_at from a single backing
   array. The same split also joins the array after changing the row. *)
Lemma split_packed_storage base (first last:list int64):
 field_compatible0 (tarray tulong (Zlength (first++last))) [ArraySubsc (Zlength first)] base ->
 packed_storage base (first++last)=
 (packed_storage base first * packed_storage (word_address base (Zlength first)) last)%logic.
Proof.
 intro address;unfold packed_storage,row_storage,word_address.
 rewrite map_app.
 etransitivity.
 { apply (@split2_data_at_Tarray_app RawPCMComposites (Zlength first) (Zlength (first++last))
   Tsh tulong (map Vlong first) (map Vlong last) base);
   rewrite ?Zlength_map,?Zlength_app;pose proof (Zlength_nonneg first);pose proof (Zlength_nonneg last);lia. }
 rewrite field_address0_offset by assumption.
 change (nested_field_offset (tarray tulong (Zlength (first++last))) [ArraySubsc (Zlength first)]) with (8*Zlength first).
 rewrite Zlength_app;replace (Zlength first+Zlength last-Zlength first) with (Zlength last) by lia;reflexivity.
Qed.

Theorem borrow_packed_row base (prefix current suffix:list int64):
 field_compatible0 (tarray tulong (Zlength (prefix++(current++suffix)))) [ArraySubsc (Zlength prefix)] base ->
 field_compatible0 (tarray tulong (Zlength (current++suffix))) [ArraySubsc (Zlength current)]
    (word_address base (Zlength prefix)) ->
 packed_storage base (prefix++(current++suffix))=
 (packed_storage base prefix *
  (packed_storage (word_address base (Zlength prefix)) current *
   packed_storage (word_address base (Zlength prefix+Zlength current)) suffix))%logic.
Proof.
 intros first next;rewrite (split_packed_storage base prefix (current++suffix) first).
 rewrite (split_packed_storage _ current suffix next).
 unfold word_address;rewrite offset_offset_val.
 replace (8*Zlength current+8*Zlength prefix) with (8*(Zlength prefix+Zlength current)) by ring.
 replace (8*Zlength prefix+8*Zlength current) with (8*(Zlength prefix+Zlength current)) by ring;reflexivity.
Qed.
