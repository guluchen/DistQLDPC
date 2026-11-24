(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.floyd.reassoc_seq VST.zlist.list_solver.
Require Import level_ast VerifDetected ClightSelect ClightNested RowTally.

Definition tally_loop : statement:=ltac:(native_while_fragment (counts_on _i) f_index_children).
Definition tally_memory s cp bp mp cols blocks marks :=
 (field_at Tsh level_type [StructField _rq] cp s *
  data_at Tsh (tarray tuint (Zlength cols)) (map Vint cols) cp *
  field_at Tsh level_type [StructField _blk] bp s *
  data_at Tsh (tarray tuint (Zlength blocks)) (map Vint blocks) bp *
  field_at Tsh level_type [StructField _mark] mp s *
  data_at Tsh (tarray tulong (Zlength marks)) (map Vlong marks) mp)%logic.
Definition counted b m t cols lo i :=
 fold_left (row_step b m t) (sublist lo i cols) (Int.zero,Int.zero).
Lemma counted_next b m t cols lo i : 0<=lo<=i -> i<Zlength cols ->
 counted b m t cols lo (i+1)=row_step b m t (counted b m t cols lo i) (Znth i cols).
Proof. intros;unfold counted;rewrite (sublist_split lo i (i+1)),(sublist_one i),fold_left_app by lia;reflexivity. Qed.
Definition tally_loc s lo hi t (acc:int*int) :=
 [temp _s s;temp _begin (Vint (Int.repr lo));temp _end (Vint (Int.repr hi));
  temp _stamp (Vlong t);temp _count (Vint (fst acc));temp _clash (Vint (snd acc))].
Theorem semax_row_tally {Espec:OracleKind} s cp bp mp cols blocks marks lo hi t :
 0<=lo<=hi -> hi<=Int.max_unsigned -> hi<=Zlength cols ->
 (forall j,lo<=j<hi->Int.unsigned (Znth j cols)<Zlength blocks) ->
 Zlength marks=Zlength blocks ->
 semax (func_tycontext f_index_children Vprog [] [])
  (PROPx nil (LOCALx (tally_loc s lo hi t (Int.zero,Int.zero))
    (SEPx [tally_memory s cp bp mp cols blocks marks])))
  tally_loop
  (normal_ret_assert (PROPx nil (LOCALx (tally_loc s lo hi t (counted blocks marks t cols lo hi))
    (SEPx [tally_memory s cp bp mp cols blocks marks])))).
Proof.
 intros ordered limit within row_ix equal_len. unfold tally_loop,tally_loc;cbn iota;abbreviate_semax.
 forward.
 forward_loop
   (EX i:Z, PROPx [lo<=i<=hi]
     (LOCALx (temp _i (Vint (Int.repr i))::tally_loc s lo hi t (counted blocks marks t cols lo i))
      (SEPx [tally_memory s cp bp mp cols blocks marks])))%assert
 break: (PROPx nil (LOCALx (tally_loc s lo hi t (counted blocks marks t cols lo hi))
         (SEPx [tally_memory s cp bp mp cols blocks marks])))%assert.
 - Exists lo;unfold tally_loc,counted;rewrite sublist_nil by lia;entailer!.
 - Intros i;unfold tally_loc,tally_memory;Intros;forward_if.
   + assert (inside:lo<=i<hi) by rep_lia. pose proof (row_ix i inside) as live.
     pose proof (Int.unsigned_range (Znth i cols)) as nonnegative.
     do 10 forward. Exists (i+1);unfold tally_memory,tally_loc;rewrite counted_next by lia.
     unfold row_step,is_free,has_stamp,flag;cbn [fst snd].
     destruct (Int.eq (Znth (Int.unsigned (Znth i cols)) blocks) Int.zero) eqn:F;
     destruct (Int64.eq (Znth (Int.unsigned (Znth i cols)) marks) t) eqn:M;entailer!;
       cbn [Int64.cmpu];fold Int.zero;rewrite F,M;cbn [Z.b2z Z.land];
       fold Int.zero;rewrite ?Int.add_zero,?Int.or_zero;split;reflexivity.
   + assert (i=hi) by rep_lia;subst;forward;unfold tally_loc,tally_memory;entailer!;try apply derives_refl.
 - unfold tally_loc;entailer!;try apply derives_refl.
Qed.
