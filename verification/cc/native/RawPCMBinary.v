(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.floyd.reassoc_seq raw_pcm_ast RawPCMPrimitives.
#[local] Existing Instance RawPCMPrimitives.RawPCMComposites.
Local Open Scope Z_scope.

Definition binary_view_spec:ident*funspec:=
 DECLARE _valid_matrix WITH a:val,buf:val,r:Z,n:Z,cells:list bool,sh:share
 PRE [tptr pcm_view_type]
 PROP(0<r<=Int.max_signed;0<n<=Int.max_signed;Zlength cells=(r*n)%Z;readable_share sh)
 PARAMS(a) SEP(matrix_bytes sh a buf r n cells)
 POST [tbool] PROP() RETURN(Vint Int.one) SEP(matrix_bytes sh a buf r n cells).
Definition binary_calls:funspecs:=ltac:(with_library prog [binary_view_spec]).

Lemma pcm_size_bounds r n:
 0<r<=Int.max_signed -> 0<n<=Int.max_signed ->
 0<r*n<Int64.max_unsigned /\ n<=Int64.max_unsigned/r.
Proof.
 intros rows cols.
 assert (limit:0<r*n<Int64.max_unsigned).
 { change Int.max_signed with 2147483647 in *;change Int64.max_unsigned with 18446744073709551615;nia. }
 split;[exact limit|apply Z.div_le_lower_bound;nia].
Qed.
Lemma native_size_guard r n:
 0<r<=Int.max_signed -> 0<n<=Int.max_signed ->
 Int64.ltu (Int64.divu (Int64.repr (-1)) (Int64.repr r)) (Int64.repr n)=false.
Proof.
 intros rows cols;pose proof (pcm_size_bounds _ _ rows cols) as [size quotient].
 unfold Int64.ltu,Int64.divu.
 rewrite (Int64.unsigned_repr r),(Int64.unsigned_repr n) by rep_lia.
 change (Int64.unsigned (Int64.repr (-1))) with Int64.max_unsigned.
 assert (div_range:0<=Int64.max_unsigned/r<=Int64.max_unsigned)
   by (split;[apply Z.div_pos|apply Z.div_le_upper_bound];change Int64.max_unsigned with 18446744073709551615 in *;nia).
 rewrite Int64.unsigned_repr by lia;destruct zlt;lia || reflexivity.
Qed.

Theorem valid_binary_matrix:semax_body raw_vars binary_calls f_valid_matrix binary_view_spec.
Proof.
 start_function.
 assert_PROP (isptr a /\ isptr buf) as addresses
   by (unfold matrix_bytes,pcm_view_type;entailer!).
 destruct addresses as [matrix_address array_address].
 assert (bounds:0<r*n<Int64.max_unsigned) by (apply (proj1 (pcm_size_bounds _ _ H H0))).
 assert (guard:=native_size_guard r n H H0).
 assert (not_negative:forall z,0<z<=Int.max_signed -> Int.lt (Int.repr z) Int.zero=false).
 { intros z range;unfold Int.lt;rewrite Int.signed_repr by rep_lia;rewrite Int.signed_zero;destruct zlt;lia || reflexivity. }
 assert (product:Int64.mul (Int64.repr r) (Int64.repr n)=Int64.repr (r*n)).
 { unfold Int64.mul;rewrite !Int64.unsigned_repr by rep_lia;reflexivity. }
 unfold matrix_bytes,pcm_view_type;Intros;reassoc_seq.
 apply semax_if_seq;forward_if;[exfalso;destruct a;cbn in *;intuition congruence|].
 do 2 forward;rewrite ?not_negative by lia.
 apply semax_if_seq;forward_if;[exfalso;destruct (zlt r 0);[lia|discriminate]|].
 do 2 forward;rewrite ?not_negative by lia.
 apply semax_if_seq;forward_if;[exfalso;destruct (zlt n 0);[lia|discriminate]|];repeat forward.
 forward_if (PROP() LOCAL(temp _a a;temp _nr (Vlong (Int64.repr r));temp _nc (Vlong (Int64.repr n));
     temp _t'3 (Vint Int.zero)) SEP(matrix_bytes sh a buf r n cells)).
 { forward;try solve [entailer!;rewrite Int.signed_repr by rep_lia;unfold Int64.eq;rewrite Int64.unsigned_repr by rep_lia;destruct zeq;lia || congruence].
   unfold matrix_bytes,pcm_view_type;entailer!;try rewrite guard;try reflexivity.
   change (Vint Int.zero=bool2val (Int64.ltu (Int64.divu (Int64.repr (-1)) (Int64.repr r)) (Int64.repr n))).
   rewrite guard;reflexivity. }
 { forward;unfold matrix_bytes,pcm_view_type;entailer!. }
 unfold matrix_bytes,pcm_view_type;Intros.
 apply semax_if_seq;forward_if.
 { exfalso;solve [congruence|discriminate|contradiction]. }
 do 2 forward;try rewrite product;apply semax_if_seq;forward_if;[exfalso;try congruence;try rep_lia|].
 forward;forward_if (PROP() LOCAL(temp _a a;temp _t'5 (Vint Int.zero)) SEP(matrix_bytes sh a buf r n cells)).
 { destruct buf;try contradiction;do 3 forward;unfold matrix_bytes,pcm_view_type;entailer!. }
 { forward;unfold matrix_bytes,pcm_view_type;entailer!. }
 unfold matrix_bytes,pcm_view_type;Intros;apply semax_if_seq;forward_if;[solve [contradiction|discriminate|congruence]|].
 forward.
 forward_loop (EX i:Z,PROP(0<=i<=r*n) LOCAL(temp _a a;temp _i (Vlong (Int64.repr i)))
    SEP(matrix_bytes sh a buf r n cells))
   continue:(EX i:Z,PROP(0<=i<r*n) LOCAL(temp _a a;temp _i (Vlong (Int64.repr i)))
    SEP(matrix_bytes sh a buf r n cells))%assert
   break:(PROP() LOCAL() SEP(matrix_bytes sh a buf r n cells))%assert.
 - Exists 0;unfold matrix_bytes,pcm_view_type;entailer!.
 - Intros i;unfold matrix_bytes,pcm_view_type;Intros;forward;forward_if;[|forward;unfold matrix_bytes,pcm_view_type;entailer!].
   assert (inside:0<=i<r*n) by rep_lia.
   assert (index:Ptrofs.unsigned (Ptrofs.of_int64 (Int64.repr i))=i).
   { change (Ptrofs.unsigned (Ptrofs.repr (Int64.unsigned (Int64.repr i)))=i).
     rewrite Int64.unsigned_repr by lia;rewrite Ptrofs.unsigned_repr;[reflexivity|change Ptrofs.max_unsigned with Int64.max_unsigned;lia]. }
   assert (value:Znth i (map cbit cells)=cbit (Znth i cells)) by (rewrite Znth_map by lia;auto).
   assert (fits:is_int I8 Unsigned (Znth i (map cbit cells))).
   { rewrite value;unfold cbit;destruct (Znth i cells);vm_compute;intuition discriminate. }
   forward;forward;try solve [entailer!;try exact fits;change (is_int I8 Unsigned (Znth i (map cbit cells)));exact fits].
   forward_if.
   + exfalso;lazymatch goal with bad:typed_true _ _ |- _ =>
       change (typed_true tint (force_val (both_int (fun x y=>Some (bool2val (Int.lt y x)))
         (sem_cast_i2i I32 Signed) (sem_cast_i2i I32 Signed)
         (Znth i (map cbit cells)) (Vint (Int.repr 1))))) in bad;
       rewrite value in bad;unfold cbit in bad;destruct (Znth i cells);vm_compute in bad;
       first [contradiction|congruence|exact (bad eq_refl)|discriminate bad|
         let shape:=type of bad in fail 1 "binary cell compared to one" shape]
     end.
   + forward;Exists i;unfold matrix_bytes,pcm_view_type;entailer!.
 - Intros i;forward;Exists (i+1);entailer!;unfold Int64.add;rewrite Int64.unsigned_repr by lia;reflexivity.
 - forward;entailer!.
Qed.
