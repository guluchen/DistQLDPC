(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.floyd.reassoc_seq raw_pcm_ast RawPCMPrimitives.
#[local] Existing Instance RawPCMPrimitives.RawPCMComposites.
Local Open Scope Z_scope.

(* Arbitrarily many checks are possible at width zero. The pointer to
   the entries is never dereferenced, even when it is null. *)
Definition empty_view sh ptr entries rows:=
 data_at sh pcm_view_type (Vint (Int.repr rows),(Vint Int.zero,(entries,Vlong Int64.zero))) ptr.
Definition valid_empty_spec:ident*funspec:=
 DECLARE _valid_matrix WITH a:val,entries:val,r:Z,sh:share
 PRE [tptr pcm_view_type] PROP(0<=r<=Int.max_signed;readable_share sh;is_pointer_or_null entries)
 PARAMS(a) SEP(empty_view sh a entries r)
 POST [tbool] PROP() RETURN(Vint Int.one) SEP(empty_view sh a entries r).
Definition no_columns_spec:ident*funspec:=
 DECLARE _cc_pcm_distance WITH x:val,z:val,xe:val,ze:val,xr:Z,zr:Z,xsh:share,zsh:share,
    witness:val,bytes:int64,out:val,old:int,poll:val,ctx:val
 PRE [tptr pcm_view_type,tptr pcm_view_type,tptr tuchar,tulong,tptr tint,
      tptr (Tfunction (Tcons (tptr tvoid) Tnil) tbool cc_default),tptr tvoid]
 PROP(0<=xr<=Int.max_signed;0<=zr<=Int.max_signed;readable_share xsh;readable_share zsh;
      is_pointer_or_null xe;is_pointer_or_null ze;is_pointer_or_null witness;
      is_pointer_or_null poll;is_pointer_or_null ctx)
 PARAMS(x;z;witness;Vlong bytes;out;poll;ctx)
 SEP(empty_view xsh x xe xr;empty_view zsh z ze zr;data_at Tsh tint (Vint old) out)
 POST [tint] PROP() RETURN(Vint (Int.repr 2))
 SEP(empty_view xsh x xe xr;empty_view zsh z ze zr;data_at Tsh tint (Vint old) out).
Definition empty_calls:funspecs:=ltac:(with_library prog [valid_empty_spec;no_columns_spec]).

Lemma unsigned_below_zero (v:int64):Int64.ltu v Int64.zero=false.
Proof. unfold Int64.ltu;rewrite Int64.unsigned_zero;pose proof (Int64.unsigned_range v);destruct zlt;lia || reflexivity. Qed.

Theorem validate_an_empty_pcm:semax_body raw_vars empty_calls f_valid_matrix valid_empty_spec.
Proof.
 start_function;unfold empty_view,pcm_view_type;Intros.
 assert_PROP (isptr a) as ptr by entailer!.
 assert (nonneg:Int.lt (Int.repr r) Int.zero=false).
 { unfold Int.lt;rewrite Int.signed_repr by rep_lia;rewrite Int.signed_zero;destruct zlt;try reflexivity;lia. }
 reassoc_seq.
 apply semax_if_seq;forward_if;[exfalso;destruct a;cbn in *;intuition congruence|].
 do 2 forward.
 rewrite ?nonneg.
 apply semax_if_seq;forward_if.
 { exfalso;destruct (zlt r 0);[lia|discriminate]. }
 do 2 forward;apply semax_if_seq;forward_if;[try solve [contradiction|congruence|discriminate]|forward].
 repeat forward.
 forward_if (PROP() LOCAL(temp _a a;temp _nr (Vlong (Int64.repr r));temp _nc (Vlong Int64.zero);
      temp _t'3 (Vint Int.zero)) SEP(empty_view sh a entries r)).
 - assert (positive:0<r) by (destruct (Z.eq_dec r 0);[subst r;intuition congruence|lia]).
   forward;try solve [entailer!;rewrite Int.signed_repr by rep_lia;unfold Int64.eq;rewrite Int64.unsigned_repr by rep_lia;destruct zeq;lia || congruence].
   unfold empty_view,pcm_view_type;entailer!;try rewrite unsigned_below_zero;try reflexivity.
   change (Vint Int.zero=bool2val (Int64.ltu (Int64.divu (Int64.repr (-1)) (Int64.repr r)) Int64.zero)).
   rewrite unsigned_below_zero;reflexivity.
 - forward;unfold empty_view,pcm_view_type;entailer!.
 - unfold empty_view,pcm_view_type;Intros.
   apply semax_if_seq;forward_if;[solve [congruence|discriminate|contradiction|rep_lia]|].
   do 2 forward;rewrite ?Int64.mul_zero.
   apply semax_if_seq;forward_if;[try solve [congruence|discriminate]|];forward.
   apply semax_if_seq;forward_if;[try solve [congruence|discriminate]|];forward.
   apply semax_if_seq;forward_if;[try solve [congruence|discriminate]|];repeat forward.
   forward_loop (PROP() LOCAL(temp _a a;temp _i (Vlong Int64.zero)) SEP(empty_view sh a entries r))
     continue:(PROP(False) LOCAL() SEP())%assert
     break:(PROP() LOCAL() SEP(empty_view sh a entries r))%assert.
   + unfold empty_view,pcm_view_type;entailer!;try apply derives_refl.
   + unfold empty_view,pcm_view_type;Intros;forward;forward_if;
       try solve [contradiction|congruence|discriminate].
     forward;unfold empty_view,pcm_view_type;entailer!;try apply derives_refl.
   + forward;unfold empty_view,pcm_view_type;entailer!.
Qed.

Theorem distance_at_zero_columns:semax_body raw_vars empty_calls f_cc_pcm_distance no_columns_spec.
Proof.
 start_function;assert_PROP (isptr out) as out_live by entailer!.
 destruct out;try contradiction.
 assert (enough:Int64.cmpu Cgt Int64.zero bytes=false) by apply unsigned_below_zero.
 reassoc_seq;forward_call (x,xe,xr,xsh).
 apply semax_if_seq;forward_if;[solve [contradiction|congruence|discriminate]|].
 forward_call (z,ze,zr,zsh);forward.
 unfold empty_view,pcm_view_type;Intros.
 apply semax_if_seq;forward_if;[solve [contradiction|congruence|discriminate]|].
 do 3 forward.
 apply semax_if_seq;forward_if;[solve [contradiction|congruence|discriminate]|];forward.
 apply semax_if_seq;forward_if.
 { exfalso;solve [congruence|contradiction|discriminate]. }
 do 2 forward;try rewrite enough.
 apply semax_if_seq;forward_if.
 { exfalso;pose proof (Int64.unsigned_range bytes).
   match goal with bad:(Int64.unsigned bytes<_ ) |- _ =>change (Int64.unsigned bytes<0) in bad;lia end. }
 forward;apply semax_if_seq;forward_if;[solve [contradiction|congruence|discriminate]|];forward.
 apply semax_if_seq;forward_if;[solve [contradiction|congruence|discriminate]|];repeat forward.
 apply semax_if_seq;forward_if;[forward|solve [contradiction|congruence|discriminate]].
 entailer!.
Qed.
