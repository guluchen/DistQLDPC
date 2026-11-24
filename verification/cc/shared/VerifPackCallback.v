(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.floyd.reassoc_seq VST.zlist.list_solver RowTally.
Require VerifMarkRow.
Require Import pack_ast.

#[local] Instance PackSpecs : compspecs. make_compspecs prog. Defined.
Definition pack_vars : varspecs. mk_varspecs prog. Defined.
Definition pack32 xs p := if Z.eq_dec (Zlength xs) 0 then emp else
 data_at Tsh (tarray tuint (Zlength xs)) (map Vint xs) p.
Definition pack64 xs p := if Z.eq_dec (Zlength xs) 0 then emp else
 data_at Tsh (tarray tulong (Zlength xs)) (map Vlong xs) p.
Lemma pack32_nonempty xs p : 0<Zlength xs -> pack32 xs p =
 data_at Tsh (tarray tuint (Zlength xs)) (map Vint xs) p.
Proof. unfold pack32;destruct Z.eq_dec;intros;congruence || lia || reflexivity. Qed.
Lemma pack64_nonempty xs p : 0<Zlength xs -> pack64 xs p =
 data_at Tsh (tarray tulong (Zlength xs)) (map Vlong xs) p.
Proof. unfold pack64;destruct Z.eq_dec;intros;congruence || lia || reflexivity. Qed.

Definition tot bs ms st cols i :=
 fold_left (row_step bs ms st) (sublist 0 i cols) (Int.zero,Int.zero).
Lemma tot_next b m t cols i:0<=i<Zlength cols ->
 tot b m t cols (i+1)=row_step b m t (tot b m t cols i) (Znth i cols).
Proof. intro;unfold tot;rewrite (sublist_split 0 i (i+1)),(sublist_one i),fold_left_app by lia;reflexivity. Qed.
Definition valid_keys (cols blocks:list int) := forall i,0<=i<Zlength cols -> Int.unsigned (Znth i cols)<Zlength blocks.
Definition total_count bs cols := Int.repr (Zlength (free_row bs cols)).
Definition total_clash bs ms st cols := flag (row_clash bs ms st cols).
Lemma tot_end b m t cols : Zlength cols<=Int.max_unsigned ->
 tot b m t cols (Zlength cols)=(total_count b cols,total_clash b m t cols).
Proof.
 intro ok;unfold tot,total_count,total_clash;rewrite sublist_same by (pose proof (Zlength_nonneg cols);lia).
 change (Int.zero,Int.zero) with (Int.repr 0,flag false).
 rewrite row_tally by lia;reflexivity.
Qed.
Definition tally_spec : ident*funspec :=
 DECLARE _cc_tally_pack_row
 WITH rp:val,bp:val,mp:val,cp:val,kp:val,cols:list int,bs:list int,ms:list int64,t:int64
 PRE [tptr tuint,tuint,tptr tuint,tptr tulong,tulong,tptr tuint,tptr tuint]
   PROP(Zlength cols<=Int.max_unsigned;Zlength bs=Zlength ms;valid_keys cols bs;
        is_pointer_or_null rp;is_pointer_or_null bp;is_pointer_or_null mp)
   PARAMS(rp;Vint (Int.repr (Zlength cols));bp;mp;Vlong t;cp;kp)
   SEP(pack32 cols rp;pack32 bs bp;pack64 ms mp;data_at_ Tsh tuint cp;data_at_ Tsh tuint kp)
 POST [tvoid] PROP() RETURN()
   SEP(pack32 cols rp;pack32 bs bp;pack64 ms mp;data_at Tsh tuint (Vint (total_count bs cols)) cp;
       data_at Tsh tuint (Vint (total_clash bs ms t cols)) kp).
Definition mark_spec : ident*funspec :=
 DECLARE _cc_mark_pack_row
 WITH rp:val,mp:val,cols:list int,ms:list int64,t:int64
 PRE [tptr tuint,tuint,tptr tulong,tulong]
   PROP(Zlength cols<=Int.max_unsigned;
        forall i,0<=i<Zlength cols -> Int.unsigned (Znth i cols)<Zlength ms;
        is_pointer_or_null rp;is_pointer_or_null mp)
   PARAMS(rp;Vint (Int.repr (Zlength cols));mp;Vlong t)
   SEP(pack32 cols rp;pack64 ms mp)
 POST [tvoid] PROP() RETURN()
   SEP(pack32 cols rp;pack64 (fold_left (VerifMarkRow.mark_word t) cols ms) mp).
Definition PackGprog : funspecs := ltac:(with_library prog [tally_spec;mark_spec]).

Theorem callback_tally_body:semax_body pack_vars PackGprog f_cc_tally_pack_row tally_spec.
Proof.
 start_function. pose proof (Zlength_nonneg cols) as n.
 forward;forward.
 forward_loop
  (EX i:Z, PROP(0<=i<=Zlength cols)
   LOCAL(temp _row rp;temp _length (Vint (Int.repr (Zlength cols)));temp _blocked bp;temp _marks mp;
         temp _stamp (Vlong t);temp _count cp;temp _clash kp;temp _j (Vint (Int.repr i));
         temp _available (Vint (fst (tot bs ms t cols i)));temp _intersects (Vint (snd (tot bs ms t cols i))))
   SEP(pack32 cols rp;pack32 bs bp;pack64 ms mp;data_at_ Tsh tuint cp;data_at_ Tsh tuint kp))%assert
 break: (PROP() LOCAL(temp _count cp;temp _clash kp;temp _available (Vint (total_count bs cols));
          temp _intersects (Vint (total_clash bs ms t cols)))
   SEP(pack32 cols rp;pack32 bs bp;pack64 ms mp;data_at_ Tsh tuint cp;data_at_ Tsh tuint kp))%assert.
 - forward;Exists 0;unfold tot;rewrite sublist_nil by lia;entailer!.
 - Intros i;forward_if.
   + assert (live:0<=i<Zlength cols) by rep_lia.
     pose proof (H1 i live) as cell;pose proof (Int.unsigned_range (Znth i cols)) as nn.
     rewrite !pack32_nonempty,pack64_nonempty by lia.
     do 7 forward. Exists (i+1);rewrite ?pack32_nonempty,?pack64_nonempty by lia.
     rewrite tot_next by lia;unfold row_step,is_free,has_stamp,flag;cbn [fst snd].
     destruct (Int.eq (Znth (Int.unsigned (Znth i cols)) bs) Int.zero) eqn:F;
     destruct (Int64.eq (Znth (Int.unsigned (Znth i cols)) ms) t) eqn:M;entailer!;
       cbn [Int64.cmpu];fold Int.zero;rewrite ?F,?M;cbn [Z.b2z Z.land];fold Int.zero;
       rewrite ?Int.add_zero,?Int.or_zero;split;reflexivity.
   + assert (i=Zlength cols) by rep_lia;subst i;rewrite tot_end by assumption;forward;entailer!.
 - forward;forward;entailer!.
Qed.

Theorem callback_mark_body:semax_body pack_vars PackGprog f_cc_mark_pack_row mark_spec.
Proof.
 start_function;pose proof (Zlength_nonneg cols) as n.
 forward_loop
  (EX i:Z, PROP(0<=i<=Zlength cols)
   LOCAL(temp _row rp;temp _length (Vint (Int.repr (Zlength cols)));temp _marks mp;
         temp _stamp (Vlong t);temp _j (Vint (Int.repr i)))
   SEP(pack32 cols rp;pack64 (VerifMarkRow.marked t ms cols 0 i) mp))%assert
 break: (PROP() LOCAL() SEP(pack32 cols rp;pack64 (fold_left (VerifMarkRow.mark_word t) cols ms) mp))%assert.
 - forward;Exists 0;unfold VerifMarkRow.marked;rewrite sublist_nil by lia;entailer!;try apply derives_refl.
 - Intros i;forward_if.
   + assert (live:0<=i<Zlength cols) by rep_lia.
     pose proof (H0 i live) as cell;pose proof (Int.unsigned_range (Znth i cols)) as nn.
     assert (same:Zlength (VerifMarkRow.marked t ms cols 0 i)=Zlength ms) by
       (apply VerifMarkRow.mark_range;try lia;intros;apply H0;lia).
     rewrite pack32_nonempty,pack64_nonempty by lia. do 3 forward.
     Exists (i+1);rewrite ?pack32_nonempty by lia.
     rewrite VerifMarkRow.mark_step by lia. unfold VerifMarkRow.mark_word.
     rewrite pack64_nonempty,upd_Znth_Zlength,upd_Znth_map by (rewrite ?upd_Znth_Zlength;lia);entailer!.
   + assert (i=Zlength cols) by rep_lia;subst i;unfold VerifMarkRow.marked;
     rewrite sublist_same by lia;forward;entailer!.
 - entailer!.
Qed.
