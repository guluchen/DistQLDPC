(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.zlist.list_solver.
Require Import level_ast VerifDetected EpochFreshness.

Definition clear_tag_spec : ident * funspec :=
 DECLARE _cc_clear_tags
 WITH p:val, tags:list int64
 PRE [tptr tulong,tulong]
    PROP (is_pointer_or_null p;Zlength tags<=Int64.max_unsigned)
    PARAMS(p;Vlong (Int64.repr (Zlength tags))) SEP(parity_storage Tsh tags p)
 POST [tvoid] PROP() RETURN() SEP(parity_storage Tsh (wiped tags) p).
Definition next_tag_spec : ident * funspec :=
 DECLARE _cc_next_tag
 WITH last:Z,p:val,tags:list int64
 PRE [tulong,tptr tulong,tulong]
   PROP (0<=last<=Int64.max_unsigned;is_pointer_or_null p; Zlength tags<=Int64.max_unsigned)
   PARAMS(Vlong (Int64.repr last);p;Vlong (Int64.repr (Zlength tags))) SEP(parity_storage Tsh tags p)
 POST [tulong] PROP() RETURN(Vlong (Int64.repr (advance_tag false last)))
   SEP(parity_storage Tsh (after_tags false last tags) p).
Definition pair_tag_spec : ident*funspec :=
 DECLARE _cc_next_tag_pair
 WITH last:Z, q:val,r:val,t:val,qs:list int64,rs:list int64,ts:list int64
 PRE [tulong,tptr tulong,tulong,tptr tulong,tulong,tptr tulong,tulong]
   PROP(0<=last<=Int64.max_unsigned;is_pointer_or_null q;is_pointer_or_null r;is_pointer_or_null t;
     Zlength qs<=Int64.max_unsigned;Zlength rs<=Int64.max_unsigned;Zlength ts<=Int64.max_unsigned)
   PARAMS(Vlong (Int64.repr last);q;Vlong (Int64.repr (Zlength qs));r;Vlong (Int64.repr (Zlength rs));
          t;Vlong (Int64.repr (Zlength ts)))
   SEP(parity_storage Tsh qs q;parity_storage Tsh rs r;parity_storage Tsh ts t)
 POST [tulong] PROP() RETURN(Vlong (Int64.repr (advance_tag true last)))
   SEP(parity_storage Tsh (after_tags true last qs) q;parity_storage Tsh (after_tags true last rs) r;
       parity_storage Tsh (after_tags true last ts) t).
Definition EpochGprog : funspecs := ltac:(with_library prog [clear_tag_spec;next_tag_spec;pair_tag_spec]).

Lemma prefix_zero xs : cleared_prefix xs 0=xs.
Proof. unfold cleared_prefix;rewrite sublist_same by lia;reflexivity. Qed.
Lemma prefix_all xs : cleared_prefix xs (Zlength xs)=wiped xs.
Proof. unfold cleared_prefix,wiped;rewrite sublist_nil,app_nil_r by lia;reflexivity. Qed.
Lemma tag_ptr_ix (i:Z): 0<=i<=Int64.max_unsigned ->
 Ptrofs.unsigned (Ptrofs.of_int64 (Int64.repr i))=i.
Proof.
 intro within;unfold Ptrofs.of_int64;rewrite Int64.unsigned_repr,Ptrofs.unsigned_repr by rep_lia;reflexivity.
Qed.

Theorem body_clear_tags : semax_body Vprog EpochGprog f_cc_clear_tags clear_tag_spec.
Proof.
 start_function. pose proof (Zlength_nonneg tags) as N.
 forward_loop
   (EX i:Z, PROP(0<=i<=Zlength tags)
    LOCAL(temp _tags p;temp _n (Vlong (Int64.repr (Zlength tags)));temp _i (Vlong (Int64.repr i)))
    SEP(parity_storage Tsh (cleared_prefix tags i) p))%assert
   break: (PROP() LOCAL() SEP(parity_storage Tsh (wiped tags) p))%assert.
 - forward;Exists 0;rewrite prefix_zero;entailer!.
 - Intros i. forward_if.
   + assert (live:0<=i<Zlength tags) by rep_lia.
     pose proof (@prefix_size tags i ltac:(lia)) as len.
     rewrite parity_storage_nonempty by lia.
     forward. forward. Exists (i+1);rewrite parity_storage_nonempty by (rewrite prefix_size;lia).
     rewrite <-prefix_step by lia. rewrite upd_Znth_Zlength by lia.
     rewrite ?tag_ptr_ix,?upd_Znth_map by lia;entailer!;rewrite ?tag_ptr_ix,?upd_Znth_map by lia;apply derives_refl.
   + assert (i=Zlength tags) by rep_lia. subst i;forward;rewrite prefix_all;entailer!.
 - entailer!.
Qed.

Theorem body_next_tag : semax_body Vprog EpochGprog f_cc_next_tag next_tag_spec.
Proof.
 start_function. forward_if.
 - assert (edge:last=Int64.max_unsigned).
   { pose proof (Int64.eq_spec (Int64.repr last) (Int64.repr (-1))) as yes.
     rewrite H2 in yes;apply (f_equal Int64.unsigned) in yes.
     rewrite Int64.unsigned_repr in yes by lia;exact yes. }
   forward_call (p,tags);forward.
 - assert (below:last<>Int64.max_unsigned).
   { intro e;subst last;apply H2;change (Int64.repr (Int64.unsigned (Int64.repr (-1)))=Int64.repr (-1));apply Int64.repr_unsigned. }
   forward;unfold advance_tag,after_tags,recycled;destruct Z_le_dec;try lia;entailer!.
Qed.

Theorem body_next_pair : semax_body Vprog EpochGprog f_cc_next_tag_pair pair_tag_spec.
Proof.
 start_function. forward_if.
 - rewrite Int64.unsigned_repr in H6 by lia.
   change (last>=Int64.max_unsigned-2) in H6.
   forward_call (q,qs);forward_call (r,rs);forward_call (t,ts);forward;
     unfold advance_tag,after_tags,recycled;destruct Z_le_dec;try lia;entailer!.
 - rewrite Int64.unsigned_repr in H6 by lia.
   change (last<Int64.max_unsigned-2) in H6.
   forward;unfold advance_tag,after_tags,recycled;destruct Z_le_dec;try lia;entailer!.
Qed.
