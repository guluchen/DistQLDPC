(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.floyd.reassoc_seq raw_pcm_ast RawPCMPrimitives.
#[local] Existing Instance RawPCMPrimitives.RawPCMComposites.
Local Open Scope Z_scope.

Definition zero_rows_view sh ptr entries n:=
 data_at sh pcm_view_type (Vint Int.zero,(Vint (Int.repr n),(entries,Vlong Int64.zero))) ptr.
Definition no_rows_spec:ident*funspec:=
 DECLARE _valid_matrix WITH a:val,buf:val,n:Z,sh:share
 PRE [tptr pcm_view_type] PROP(0<=n<=Int.max_signed;readable_share sh;is_pointer_or_null buf)
 PARAMS(a) SEP(zero_rows_view sh a buf n)
 POST [tbool] PROP() RETURN(Vint Int.one) SEP(zero_rows_view sh a buf n).
Definition no_rows_calls:funspecs:=ltac:(with_library prog [no_rows_spec]).

Theorem validate_zero_checks:semax_body raw_vars no_rows_calls f_valid_matrix no_rows_spec.
Proof.
 start_function;unfold zero_rows_view,pcm_view_type;Intros.
 assert_PROP (isptr a) as address by entailer!.
 reassoc_seq;apply semax_if_seq;forward_if;[exfalso;destruct a;cbn in *;intuition congruence|].
 do 2 forward;apply semax_if_seq;forward_if;[solve [discriminate|contradiction|congruence]|].
 do 2 forward;apply semax_if_seq;forward_if;[exfalso;destruct (zlt n 0);[lia|discriminate]|].
 do 4 forward;apply semax_if_seq;forward_if;[solve [discriminate|contradiction|congruence]|];forward.
 apply semax_if_seq;forward_if;[solve [discriminate|contradiction|congruence]|];do 2 forward.
 assert (zero_product:forall z,Int64.mul Int64.zero z=Int64.zero) by reflexivity.
 rewrite ?zero_product.
 apply semax_if_seq;forward_if;[solve [discriminate|contradiction|congruence]|];forward.
 apply semax_if_seq;forward_if;[solve [discriminate|contradiction|congruence]|];forward.
 apply semax_if_seq;forward_if;[solve [discriminate|contradiction|congruence]|];forward.
 forward_loop (PROP() LOCAL(temp _a a;temp _i (Vlong Int64.zero)) SEP(zero_rows_view sh a buf n))
   continue:(PROP(False) LOCAL() SEP())%assert
   break:(PROP() LOCAL() SEP(zero_rows_view sh a buf n))%assert.
 - unfold zero_rows_view,pcm_view_type;entailer!;try apply derives_refl.
 - unfold zero_rows_view,pcm_view_type;Intros;forward;forward_if;try solve [contradiction|congruence|discriminate].
   forward;unfold zero_rows_view,pcm_view_type;entailer!;try apply derives_refl.
 - forward;unfold zero_rows_view,pcm_view_type;entailer!.
Qed.
