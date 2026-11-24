(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.floyd.field_compat VerifDetected VerifChildVisit PreparedCandidateSlice.
#[local] Existing Instance VerifDetected.CompSpecs.
Local Open Scope Z_scope.

Definition row_pointer base stride d:=offset_val (4*(d*stride)) base.
Definition remaining_arena base stride levels d:=
 data_at_ Tsh (tarray tuint ((levels-d)*stride)) (row_pointer base stride d).
Definition spare_words p stride (xs:list Z):=data_at_ Tsh (tarray tuint (stride-Zlength xs))
 (field_address0 (tarray tuint stride) [ArraySubsc (Zlength xs)] p).

Lemma next_candidate_row base stride d:
 offset_val (stride*4) (row_pointer base stride d)=row_pointer base stride (d+1).
Proof. unfold row_pointer;rewrite offset_offset_val;f_equal;ring. Qed.

(* Separate the parent's row before recursing. The child can write every
   slot in its own remaining arena and still cannot overwrite the parent. *)
Theorem borrow_depth_slice base stride levels d:
 0<=d<levels -> 0<=stride ->
 field_compatible0 (tarray tuint ((levels-d)*stride)) [ArraySubsc stride] (row_pointer base stride d) ->
 remaining_arena base stride levels d=
 (data_at_ Tsh (tarray tuint stride) (row_pointer base stride d) * remaining_arena base stride levels (d+1))%logic.
Proof.
 intros depth width fits;unfold remaining_arena.
 rewrite (split2_data_at__Tarray_app stride ((levels-d)*stride)) by nia.
 rewrite field_address0_offset by assumption.
 change (nested_field_offset (tarray tuint ((levels-d)*stride)) [ArraySubsc stride]) with (sizeof tuint*stride).
 change (sizeof tuint) with 4;replace (4*stride) with (stride*4) by ring;rewrite next_candidate_row.
 replace ((levels-d)*stride-stride) with ((levels-(d+1))*stride) by ring;reflexivity.
Qed.

Lemma release_written_row ptr stride xs:
 Zlength xs<=stride ->
 (child_array ptr xs * spare_words ptr stride xs) |-- data_at_ Tsh (tarray tuint stride) ptr.
Proof.
 intro room;unfold child_array,spare_words.
 rewrite (split2_data_at__Tarray_app (Zlength xs) stride) by (pose proof (Zlength_nonneg xs);lia).
 apply sepcon_derives;[apply data_at_data_at_|apply derives_refl].
Qed.

Theorem release_after_descendants base stride levels d xs:
 0<=d<levels -> 0<=stride -> Zlength xs<=stride ->
 field_compatible0 (tarray tuint ((levels-d)*stride)) [ArraySubsc stride] (row_pointer base stride d) ->
 ((child_array (row_pointer base stride d) xs * spare_words (row_pointer base stride d) stride xs) *
    remaining_arena base stride levels (d+1)) |-- remaining_arena base stride levels d.
Proof. intros;rewrite (borrow_depth_slice base stride levels d) by assumption;apply sepcon_derives;[apply release_written_row;assumption|apply derives_refl]. Qed.
