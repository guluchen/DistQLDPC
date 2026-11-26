(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.floyd.reassoc_seq raw_pcm_ast RawPCMPrimitives.
#[local] Existing Instance RawPCMComposites.

Section Release.
Variable token:val->mpred.
Definition may_free p:=if eq_dec p nullval then emp else token p.
Definition free_owned:ident*funspec:=
 DECLARE _free WITH p:val
 PRE [tptr tvoid] PROP(is_pointer_or_null p) PARAMS(p) SEP(may_free p)
 POST [tvoid] PROP() RETURN() SEP().
Definition half_type:=Tstruct _half noattr.
Definition owner_fields (p:ident->val) h:=(
    field_at Tsh half_type [StructField _rstart] (p _rstart) h *
    field_at Tsh half_type [StructField _rq] (p _rq) h *
    field_at Tsh half_type [StructField _cstart] (p _cstart) h *
    field_at Tsh half_type [StructField _cr] (p _cr) h *
    field_at Tsh half_type [StructField _blk] (p _blk) h *
    field_at Tsh half_type [StructField _cand] (p _cand) h *
    field_at Tsh half_type [StructField _gmask] (p _gmask) h *
    field_at Tsh half_type [StructField _keys] (p _keys) h *
    field_at Tsh half_type [StructField _syn] (p _syn) h *
    field_at Tsh half_type [StructField _par] (p _par) h *
    field_at Tsh half_type [StructField _mark] (p _mark) h *
    field_at Tsh half_type [StructField _budget] (p _budget) h *
    field_at Tsh half_type [StructField _slots] (p _slots) h *
    field_at Tsh half_type [StructField _links] (p _links) h *
    field_at Tsh half_type [StructField _path] (p _path) h)%logic.
Definition owner_tokens (p:ident->val):=(
    may_free (p _rstart) *
    may_free (p _rq) *
    may_free (p _cstart) *
    may_free (p _cr) *
    may_free (p _blk) *
    may_free (p _cand) *
    may_free (p _gmask) *
    may_free (p _keys) *
    may_free (p _syn) *
    may_free (p _par) *
    may_free (p _mark) *
    may_free (p _budget) *
    may_free (p _slots) *
    may_free (p _links) *
    may_free (p _path))%logic.

(* Every non-null pointer must own its free token; null fields model
   a constructor that returned before allocating the entire half. *)
Definition release_owned_half:ident*funspec:=
 DECLARE _release_half WITH p:ident->val,h:val
 PRE [tptr half_type] PROP(forall id,is_pointer_or_null (p id))
 PARAMS(h) SEP(owner_fields p h;owner_tokens p)
 POST [tvoid] PROP() RETURN() SEP(owner_fields p h).
Definition release_calls:funspecs:=ltac:(with_library prog [free_owned;release_owned_half]).
Theorem release_owns_each_block_once:
 semax_body raw_vars release_calls f_release_half release_owned_half.
Proof.
 start_function;unfold owner_fields,owner_tokens,half_type;reassoc_seq;Intros.
 forward;forward_call (p _rstart);try solve [entailer!].
 forward;forward_call (p _rq);try solve [entailer!].
 forward;forward_call (p _cstart);try solve [entailer!].
 forward;forward_call (p _cr);try solve [entailer!].
 forward;forward_call (p _blk);try solve [entailer!].
 forward;forward_call (p _cand);try solve [entailer!].
 forward;forward_call (p _gmask);try solve [entailer!].
 forward;forward_call (p _keys);try solve [entailer!].
 forward;forward_call (p _syn);try solve [entailer!].
 forward;forward_call (p _par);try solve [entailer!].
 forward;forward_call (p _mark);try solve [entailer!].
 forward;forward_call (p _budget);try solve [entailer!].
 forward;forward_call (p _slots);try solve [entailer!].
 forward;forward_call (p _links);try solve [entailer!].
 forward;forward_call (p _path);try solve [entailer!].
 forward;unfold owner_fields,half_type;entailer!;try cancel;try apply derives_refl.
Qed.
End Release.
