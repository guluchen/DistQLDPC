(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto raw_pcm_ast RawPCMPrimitives.
#[local] Existing Instance RawPCMComposites.
Local Open Scope Z_scope.

Definition row_count_at sh p nr:=field_at sh pcm_view_type [StructField _rows] (Vint (Int.repr nr)) p.
Definition empty_product_spec:ident*funspec:=
 DECLARE _commute WITH ap:val,bp:val,sa:share,sb:share,ra:Z,rb:Z
 PRE [tptr pcm_view_type,tptr pcm_view_type]
 PROP(readable_share sa;readable_share sb;0<=ra<=Int.max_signed;0<=rb<=Int.max_signed;ra=0 \/ rb=0)
 PARAMS(ap;bp) SEP(row_count_at sa ap ra;row_count_at sb bp rb)
 POST [tbool] PROP() RETURN(Vint Int.one) SEP(row_count_at sa ap ra;row_count_at sb bp rb).
Definition empty_calls:funspecs:=ltac:(with_library prog [empty_product_spec]).

(* Empty views may use a null pointer to their binary entries. Neither
   set of entries is read when there are no row pairs to compare. *)
Theorem no_check_pairs_commute:semax_body raw_vars empty_calls f_commute empty_product_spec.
Proof.
 start_function.
 pose (owned:=(row_count_at sa ap ra * row_count_at sb bp rb)%logic).
 forward.
 forward_loop (EX i:Z,PROP(0<=i<=ra)
   LOCAL(temp _a ap;temp _b bp;temp _i (Vint (Int.repr i))) SEP(owned))
   continue:(EX i:Z,PROP(0<=i<ra) LOCAL(temp _a ap;temp _b bp;temp _i (Vint (Int.repr i))) SEP(owned))%assert
   break:(PROP() LOCAL() SEP(owned))%assert.
 - Exists 0;unfold owned;entailer!.
 - Intros i;unfold owned,row_count_at,pcm_view_type;Intros;forward;forward_if.
   2:{ forward;unfold owned,row_count_at,pcm_view_type;entailer!. }
   assert (inside:0<=i<ra) by rep_lia.
   assert (rb=0) by lia;subst rb.
   forward.
   forward_loop (PROP() LOCAL(temp _a ap;temp _b bp;temp _i (Vint (Int.repr i));temp _j (Vint Int.zero)) SEP(owned))
    continue:(PROP(False) LOCAL() SEP())%assert
    break:(PROP() LOCAL(temp _a ap;temp _b bp;temp _i (Vint (Int.repr i))) SEP(owned))%assert.
   + unfold owned,row_count_at,pcm_view_type;entailer!.
   + unfold owned,row_count_at,pcm_view_type;Intros;forward;forward_if;[rep_lia|].
     forward;unfold owned,row_count_at,pcm_view_type;entailer!.
   + Exists i;entailer!.
 - Intros i;forward;Exists (i+1);entailer!.
 - forward;unfold owned;entailer!.
Qed.
