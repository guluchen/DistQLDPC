(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.zlist.list_solver raw_pcm_ast.
#[local] Instance RawPCMComposites : compspecs. make_compspecs prog. Defined.
Definition raw_vars:varspecs. mk_varspecs prog. Defined.
Local Open Scope Z_scope.

Definition packed_words n:=if Z.eq_dec n 0 then 0 else 1+(n-1)/64.
Definition words_spec:ident*funspec:=
 DECLARE _words_for WITH n:Z
 PRE [tint] PROP(0<=n<=Int.max_signed) PARAMS(Vint (Int.repr n)) SEP()
 POST [tint] PROP() RETURN(Vint (Int.repr (packed_words n))) SEP().
Definition row_storage p (n:Z) (xs:list int64):=data_at Tsh (tarray tulong n) (map Vlong xs) p.
Definition swap_spec:ident*funspec:=
 DECLARE _swap_words WITH a:val,b:val,xs:list int64,ys:list int64
 PRE [tptr tulong,tptr tulong,tint]
 PROP(Zlength xs=Zlength ys;Zlength xs<=Int.max_signed)
 PARAMS(a;b;Vint (Int.repr (Zlength xs))) SEP(row_storage a (Zlength xs) xs;row_storage b (Zlength xs) ys)
 POST [tvoid] PROP() RETURN() SEP(row_storage a (Zlength xs) ys;row_storage b (Zlength xs) xs).
Definition xor_rows (xs ys:list int64):=map (fun p=>Int64.xor (fst p) (snd p)) (combine xs ys).
Definition xor_spec:ident*funspec:=
 DECLARE _xor_words WITH a:val,b:val,sh:share,xs:list int64,ys:list int64
 PRE [tptr tulong,tptr tulong,tint]
 PROP(readable_share sh;Zlength xs=Zlength ys;Zlength xs<=Int.max_signed)
 PARAMS(a;b;Vint (Int.repr (Zlength xs)))
 SEP(row_storage a (Zlength xs) xs;data_at sh (tarray tulong (Zlength ys)) (map Vlong ys) b)
 POST [tvoid] PROP() RETURN()
 SEP(row_storage a (Zlength xs) (xor_rows xs ys);data_at sh (tarray tulong (Zlength ys)) (map Vlong ys) b).
Definition packed_bit xs q:=Int64.testbit (Znth (q/64) xs) (q mod 64).
Definition bit_spec:ident*funspec:=
 DECLARE _bit WITH row:val,sh:share,xs:list int64,q:Z
 PRE [tptr tulong,tint] PROP(readable_share sh;0<=q<=Int.max_signed;q<64*Zlength xs)
 PARAMS(row;Vint (Int.repr q)) SEP(data_at sh (tarray tulong (Zlength xs)) (map Vlong xs) row)
 POST [tbool] PROP() RETURN(Vint (if packed_bit xs q then Int.one else Int.zero))
 SEP(data_at sh (tarray tulong (Zlength xs)) (map Vlong xs) row).
Definition raw_calls:funspecs:=ltac:(with_library prog [words_spec;swap_spec;xor_spec;bit_spec]).

Lemma packed_words_cover n:0<=n -> 0<=packed_words n /\ n<=64*packed_words n<n+64.
Proof.
 intros nn;unfold packed_words;destruct Z.eq_dec;subst;try lia.
 pose proof (Z.div_mod (n-1) 64 ltac:(lia)).
 pose proof (Z.mod_pos_bound (n-1) 64 ltac:(lia));lia.
Qed.

Theorem words_for_body:semax_body raw_vars raw_calls f_words_for words_spec.
Proof.
 start_function;forward_if.
 - assert (n=0) by rep_lia. subst n;forward;entailer!.
 - assert (0<n) by rep_lia.
   assert (bounds:0<= (n-1)/64 <= n-1).
   { split;[apply Z.div_pos|apply Z.div_le_upper_bound];lia. }
   assert (value:packed_words n=1+(n-1)/64) by (unfold packed_words;destruct (Z.eq_dec n 0);lia).
   assert (quotient:Z.quot (n-1) 64=(n-1)/64) by (apply Z.quot_div_nonneg;lia).
   assert (divided:Int.divs (Int.repr (n-1)) (Int.repr 64)=Int.repr ((n-1)/64)).
   { unfold Int.divs. rewrite !Int.signed_repr by rep_lia. now rewrite quotient. }
   forward;entailer!;try rewrite divided;try rewrite Int.signed_repr by rep_lia;try rewrite value;try rewrite quotient;try rep_lia;try reflexivity.
   all: try solve [split;[lia|intros [_ bad];discriminate bad]].
   unfold Int.add;rewrite !Int.unsigned_repr by rep_lia;reflexivity.
Qed.

(* At position j only the first j machine words have crossed to the other row. *)
Definition swapped_part (original incoming:list int64) j:=
 sublist 0 j incoming ++ sublist j (Zlength original) original.
Lemma swap_view_at x y j:Zlength x=Zlength y -> 0<=j<Zlength x ->
 Znth j (swapped_part x y j)=Znth j x.
Proof. intros;unfold swapped_part;list_solve. Qed.
Lemma swap_view_advance x y j:Zlength x=Zlength y -> 0<=j<Zlength x ->
 upd_Znth j (swapped_part x y j) (Znth j y)=swapped_part x y (j+1).
Proof. intros;unfold swapped_part;list_solve. Qed.
Lemma swap_view_length x y j:Zlength x=Zlength y -> 0<=j<=Zlength x ->
 Zlength (swapped_part x y j)=Zlength x.
Proof. intros;unfold swapped_part;autorewrite with sublist;lia. Qed.

Theorem swap_words_body:semax_body raw_vars raw_calls f_swap_words swap_spec.
Proof.
 start_function.
 forward_for_simple_bound (Zlength xs)
   (EX j:Z,PROP() LOCAL(temp _a a;temp _b b;temp _words (Vint (Int.repr (Zlength xs))))
    SEP(row_storage a (Zlength xs) (swapped_part xs ys j);
        row_storage b (Zlength xs) (swapped_part ys xs j))).
 - entailer!;unfold swapped_part;autorewrite with sublist;cancel.
 - assert (sa:Zlength (swapped_part xs ys i)=Zlength xs) by (apply swap_view_length;lia).
   assert (sb:Zlength (swapped_part ys xs i)=Zlength xs) by (rewrite swap_view_length;lia).
   unfold row_storage;forward;forward;forward;forward;entailer!.
   try rewrite !Znth_map by lia.
   try rewrite !swap_view_at by lia.
   try rewrite !upd_Znth_map,!swap_view_advance by lia;try cancel.
   all: match goal with |- ?G => fail 1 "swap step" G end.
 - forward;entailer!;unfold swapped_part;rewrite <- H;autorewrite with sublist;cancel.
Qed.

Lemma xor_rows_width xs ys: Zlength xs=Zlength ys -> Zlength (xor_rows xs ys)=Zlength xs.
Proof. intros;unfold xor_rows;rewrite Zlength_map,Zlength_combine;lia. Qed.
Lemma xor_row_word xs ys j: Zlength xs=Zlength ys -> 0<=j<Zlength xs ->
 Znth j (xor_rows xs ys)=Int64.xor (Znth j xs) (Znth j ys).
Proof.
 intros;unfold xor_rows;rewrite Znth_map by (rewrite Zlength_combine;lia).
 rewrite Znth_combine by lia;reflexivity.
Qed.

Lemma swap_view_done x y:Zlength x=Zlength y -> swapped_part x y (Zlength x)=y.
Proof. intros;unfold swapped_part;list_solve. Qed.

Theorem xor_words_body:semax_body raw_vars raw_calls f_xor_words xor_spec.
Proof.
 start_function. pose (sum:=xor_rows xs ys).
 assert (width:Zlength xs=Zlength sum) by (unfold sum;rewrite xor_rows_width by assumption;reflexivity).
 forward_for_simple_bound (Zlength xs)
   (EX j:Z,PROP() LOCAL(temp _destination a;temp _pivot b;temp _words (Vint (Int.repr (Zlength xs))))
    SEP(row_storage a (Zlength xs) (swapped_part xs sum j);
        data_at sh (tarray tulong (Zlength ys)) (map Vlong ys) b)).
 - entailer!;unfold swapped_part;autorewrite with sublist;cancel.
 - assert (sz:Zlength (swapped_part xs sum i)=Zlength xs) by (apply swap_view_length;lia).
   unfold row_storage;forward;forward;forward;entailer!.
   try rewrite !Znth_map by lia. try rewrite !swap_view_at by lia.
   assert (word:Int64.xor (Znth i xs) (Znth i ys)=Znth i sum).
   { unfold sum;rewrite xor_row_word by lia;reflexivity. }
   rewrite word,upd_Znth_map,swap_view_advance by lia;cancel.
 - forward;entailer!;try rewrite swap_view_done by lia;try cancel;try apply derives_refl.
   all: match goal with |- ?G=> fail 1 "xor return" G end.
Qed.

Lemma xor_bit_is_field_addition xs ys q:
 Zlength xs=Zlength ys -> 0<=q<64*Zlength xs ->
 packed_bit (xor_rows xs ys) q=xorb (packed_bit xs q) (packed_bit ys q).
Proof.
 intros same range;assert (at_word:0<=q/64<Zlength xs) by (split;[apply Z.div_pos|apply Z.div_lt_upper_bound];lia).
 unfold packed_bit;rewrite xor_row_word by assumption.
 apply Int64.bits_xor;change (0<=q mod 64<64);apply Z.mod_pos_bound;lia.
Qed.

Lemma masked_shift_zero word j:0<=j<64 ->
 Int64.and (Int64.shru' word (Int.repr j)) Int64.one=Int64.zero <-> Int64.testbit word j=false.
Proof.
 intros range.
 assert (low:forall w, Int64.and w Int64.one=Int64.zero <-> Int64.testbit w 0=false).
 { intros w;split.
   - intro h;apply (f_equal (fun a=>Int64.testbit a 0)) in h.
     rewrite Int64.bits_and,Int64.bits_one,Int64.bits_zero in h by rep_lia.
     change ((Int64.testbit w 0 && true)%bool=false) in h;now rewrite andb_true_r in h.
   - intro h;apply Int64.same_bits_eq;intros i inside.
     rewrite Int64.bits_and,Int64.bits_one,Int64.bits_zero by assumption.
     destruct (zeq i 0);subst;[rewrite h|rewrite andb_false_r];reflexivity. }
 rewrite low,Int64.bits_shru' by rep_lia. rewrite Int.unsigned_repr by rep_lia.
 rewrite Z.add_0_l. destruct (zlt j Int64.zwordsize);[reflexivity|change Int64.zwordsize with 64 in *;lia].
Qed.

Theorem bit_body:semax_body raw_vars raw_calls f_bit bit_spec.
Proof.
 start_function.
 assert (index:0<=q/64<Zlength xs) by (split;[apply Z.div_pos|apply Z.div_lt_upper_bound];lia).
 assert (quotient:Int.divs (Int.repr q) (Int.repr 64)=Int.repr (q/64)).
 { unfold Int.divs;rewrite !Int.signed_repr by rep_lia. rewrite Z.quot_div_nonneg by lia;reflexivity. }
 assert (remainder:Int.mods (Int.repr q) (Int.repr 64)=Int.repr (q mod 64)).
 { unfold Int.mods;rewrite !Int.signed_repr by rep_lia. rewrite Z.rem_mod_nonneg by lia;reflexivity. }
 assert (width:q/64<=q) by (apply Z.div_le_upper_bound;lia).
 assert (at_index:Int.signed (Int.divs (Int.repr q) (Int.repr 64))=q/64) by (rewrite quotient,Int.signed_repr by rep_lia;reflexivity).
 assert (inside:0<=Int.signed (Int.divs (Int.repr q) (Int.repr 64))<Zlength xs) by lia.
 forward.
 { entailer!;match goal with h:_ /\ Int.repr 64=Int.mone |- _ => destruct h as [_ bad];discriminate bad end. }
 assert (bitrange:0<=q mod 64<64) by (apply Z.mod_pos_bound;lia).
 forward.
 - apply prop_right;split;[rewrite remainder,Int.unsigned_repr by rep_lia;change (q mod 64<64);lia|intros [_ bad];discriminate bad].
 - rewrite at_index,remainder;apply prop_right;unfold packed_bit.
   pose (word:=Znth (q/64) xs);pose (j:=q mod 64);fold word j.
   assert (shift:Int64.shru word (Int64.repr (Int.unsigned (Int.repr j)))=Int64.shru' word (Int.repr j)).
   { unfold Int64.shru,Int64.shru';rewrite Int64.unsigned_repr by (pose proof (Int.unsigned_range_2 (Int.repr j));rep_lia);reflexivity. }
   rewrite shift.
   change (Vint (if Int64.eq (Int64.and (Int64.shru' word (Int.repr j)) Int64.one) Int64.zero
           then Int.zero else Int.one)=Vint (if Int64.testbit word j then Int.one else Int.zero)).
   pose proof (masked_shift_zero word j bitrange) as relation.
   pose proof (Int64.eq_spec (Int64.and (Int64.shru' word (Int.repr j)) Int64.one) Int64.zero) as compare.
   destruct (Int64.eq (Int64.and (Int64.shru' word (Int.repr j)) Int64.one) Int64.zero);
    destruct (Int64.testbit word j);intuition congruence.
Qed.
