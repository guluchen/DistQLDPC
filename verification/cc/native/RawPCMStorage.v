(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.floyd.reassoc_seq raw_pcm_ast RawPCMPrimitives.
#[local] Existing Instance RawPCMComposites.
Local Open Scope Z_scope.

(* The caller instantiates the libc allocation predicate. A null result
   owns no block, so an exhausted allocator remains a permitted result. *)
Section Storage.
Variable block:Z->val->mpred.
Definition allocation bytes p:=if eq_dec p nullval then emp else block bytes p.
Definition requested count:=if Z.eq_dec count 0 then 1 else count.
Definition calloc_bytes:ident*funspec:=
 DECLARE _calloc WITH count:Z,unit:Z
 PRE [tulong,tulong] PROP(0<count<=Int64.max_unsigned;0<unit<=Int64.max_unsigned;count*unit<=Int64.max_unsigned)
 PARAMS(Vlong (Int64.repr count);Vlong (Int64.repr unit)) SEP()
 POST [tptr tvoid] EX p:val,PROP(is_pointer_or_null p) RETURN(p) SEP(allocation (count*unit) p).
Definition matrix_storage_spec:ident*funspec:=
 DECLARE _matrix_storage WITH nr:Z,nc:Z,unit:Z
 PRE [tulong,tulong,tulong]
 PROP(0<=nr<=Int64.max_unsigned;0<=nc<=Int64.max_unsigned;0<unit<=Int64.max_unsigned;
      nr*nc*unit<=Int64.max_unsigned)
 PARAMS(Vlong (Int64.repr nr);Vlong (Int64.repr nc);Vlong (Int64.repr unit)) SEP()
 POST [tptr tvoid] EX p:val,PROP(is_pointer_or_null p) RETURN(p) SEP(allocation (requested (nr*nc)*unit) p).
Definition storage_calls:funspecs:=ltac:(with_library prog [calloc_bytes;matrix_storage_spec]).

Lemma bounded_division a b:0<a<=Int64.max_unsigned -> 0<=b<=Int64.max_unsigned ->
 a*b<=Int64.max_unsigned ->
 Int64.ltu (Int64.divu (Int64.repr (-1)) (Int64.repr a)) (Int64.repr b)=false.
Proof.
 intros ar br within;unfold Int64.ltu,Int64.divu.
 rewrite (Int64.unsigned_repr a),(Int64.unsigned_repr b) by lia.
 change (Int64.unsigned (Int64.repr (-1))) with Int64.max_unsigned.
 assert (qb:0<=Int64.max_unsigned/a<=Int64.max_unsigned).
 { split;[apply Z.div_pos|apply Z.div_le_upper_bound];change Int64.max_unsigned with 18446744073709551615 in *;nia. }
 assert (lower:b<=Int64.max_unsigned/a) by (apply Z.div_le_lower_bound;nia).
 rewrite Int64.unsigned_repr by lia;destruct zlt;lia || reflexivity.
Qed.

Theorem checked_allocation_extent:semax_body raw_vars storage_calls f_matrix_storage matrix_storage_spec.
Proof.
 start_function;reassoc_seq.
 assert (fit:0<=nr*nc<=Int64.max_unsigned) by nia.
 assert (product:Int64.mul (Int64.repr nr) (Int64.repr nc)=Int64.repr (nr*nc))
   by (unfold Int64.mul;rewrite !Int64.unsigned_repr by lia;reflexivity).
 assert (zero_test:forall a,0<=a<=Int64.max_unsigned ->
   (Int64.eq (Int64.repr a) Int64.zero=true <-> a=0)).
 { intros a range;unfold Int64.eq;rewrite Int64.unsigned_zero,Int64.unsigned_repr by lia.
   destruct zeq;split;congruence. }
 forward_if (PROP() LOCAL(temp _rows (Vlong (Int64.repr nr));temp _cols (Vlong (Int64.repr nc));
       temp _unit (Vlong (Int64.repr unit));temp _t'1 (Vint Int.zero)) SEP()).
 - assert (nonzero:0<nr) by (destruct (Z.eq_dec nr 0);[subst;contradiction|lia]).
   assert (guard:=bounded_division nr nc ltac:(lia) ltac:(lia) ltac:(lia)).
   forward;try solve [entailer!;unfold Int64.eq;rewrite Int64.unsigned_zero,Int64.unsigned_repr by lia;destruct zeq;lia || congruence].
   entailer!;try rewrite guard;try reflexivity.
   change (Vint Int.zero=bool2val (Int64.ltu (Int64.divu (Int64.repr (-1)) (Int64.repr nr)) (Int64.repr nc))).
   rewrite guard;reflexivity.
 - forward;entailer!.
 - apply semax_if_seq;forward_if;[contradiction|].
   forward;rewrite product.
   assert (guard:=bounded_division unit (nr*nc) ltac:(lia) fit ltac:(nia)).
   apply semax_if_seq;forward_if.
   all: try solve [entailer!;unfold Int64.eq;rewrite Int64.unsigned_zero,Int64.unsigned_repr by lia;destruct zeq;lia || congruence].
   all: try solve [apply prop_right;intro bad;apply (f_equal Int64.unsigned) in bad;
     rewrite Int64.unsigned_zero,Int64.unsigned_repr in bad by lia;lia].
   { exfalso;try congruence;rep_lia. }
   forward_if (PROP() LOCAL(temp _unit (Vlong (Int64.repr unit));temp _t'2 (Vlong (Int64.repr (requested (nr*nc))))) SEP()).
   + assert (nz:nr*nc<>0) by (intro z;rewrite z in *;contradiction).
     forward;unfold requested;destruct Z.eq_dec;entailer!;congruence.
   + assert (z:nr*nc=0).
     { match goal with h: Int64.repr (nr*nc)=Int64.zero |- _ =>
         apply (f_equal Int64.unsigned) in h;rewrite Int64.unsigned_zero,Int64.unsigned_repr in h by lia;exact h
       end. }
     forward;unfold requested;rewrite z;entailer!.
   + assert (extent:0<requested (nr*nc)<=Int64.max_unsigned /\ requested (nr*nc)*unit<=Int64.max_unsigned).
     { unfold requested;destruct Z.eq_dec;nia. }
     forward_call (requested (nr*nc),unit);try solve [entailer!;lia].
     Intros p;forward;Exists p;entailer!.
Qed.
End Storage.
