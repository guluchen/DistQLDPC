(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.floyd.reassoc_seq VST.zlist.list_solver.
Require Import seed_ast VerifSeedMove SeedExemptionState SeedColumnModel SeedPolicyView SeedBlockModel SeedBlockView.
#[local] Existing Instance SeedC.
Local Open Scope Z_scope.
Definition block_loc p block j:=
 [temp _state p;temp _block (Vint (Int.repr block));temp _j (Vint (Int.repr j))].
Definition inner_loc p block j word:=temp _q (Vint word)::block_loc p block j.
Definition ignores base fb:=orb (Z.ltb (Int.signed base) 0) (Z.leb 0 (Int.signed fb)).
Definition guard_val (yes:bool):=Vint (if yes then Int.one else Int.zero).

Theorem remember_one_column {Espec:OracleKind} p a pa g b limits block j word initial :
 inner_safe g limits (Int.unsigned word) initial ->
 semax (func_tycontext f_cc_seed_block_done SVars BlockG [])
  (PROPx nil (LOCALx (inner_loc p block j word) (SEPx [exhausted_at p a pa g b limits initial])))
  inner_scan
  (normal_ret_assert (PROPx nil (LOCALx (inner_loc p block j word)
   (SEPx [exhausted_at p a pa g b limits (process_qubit g limits initial word)])))).
Proof.
 intro safe;set (q:=Int.unsigned word) in *;destruct safe as [bound [room [span [cap safe]]]].
 set (lo:=index_at g q) in *;set (hi:=index_at g (q+1)) in *.
 assert (end_fits:hi<=Int.max_unsigned) by (unfold hi,index_at;apply Int.unsigned_range_2).
 assert (next_index:Int.unsigned (Int.add word (Int.repr 1))=q+1)
   by (change (Int.unsigned (Int.repr (q+1))=q+1);apply Int.unsigned_repr;rep_lia).
 set (at_index:=before_row g limits q initial).
 unfold inner_scan,inner_loc,block_loc,exhausted_at,scans_at;cbn [dynamic_rows col_starts col_rows base_order first_block];
 abbreviate_semax;Intros;rewrite (pos_unsigned (col_starts g)) by lia;do 2 forward.
 forward_loop (EX i:Z, PROPx [lo<=i<=hi] (LOCALx (temp _i (Vint (Int.repr i))::inner_loc p block j word)
  (SEPx [exhausted_at p a pa g b limits (at_index i)])))%assert
 continue: (EX i:Z, PROPx [lo<=i<hi] (LOCALx (temp _i (Vint (Int.repr i))::inner_loc p block j word)
  (SEPx [exhausted_at p a pa g b limits (at_index (i+1))])))%assert
 break: (PROPx nil (LOCALx (inner_loc p block j word) (SEPx [exhausted_at p a pa g b limits (at_index hi)])))%assert.
 - Exists lo;unfold inner_loc,block_loc,exhausted_at,scans_at,at_index,before_row,remember_column.
   rewrite sublist_nil by lia;cbn [fold_left dynamic_rows col_starts col_rows base_order first_block].
   rewrite (pos_unsigned (col_starts g)) by lia;unfold lo,index_at;rewrite Int.repr_unsigned;entailer!;try apply derives_refl.
   fold q;fold (index_at g q);fold lo;lia.
 - Intros i;unfold inner_loc,block_loc,exhausted_at,scans_at;cbn [dynamic_rows col_starts col_rows base_order first_block].
   Intros;rewrite (pos_unsigned (col_starts g)) by lia.
   forward;forward;try solve [entailer!;rewrite next_index;lia];rewrite ?next_index;forward_if.
   2:{ change (i>=hi) in H0;assert (i=hi) by lia;subst i;forward;unfold inner_loc,block_loc,exhausted_at,scans_at;
       cbn [dynamic_rows col_starts col_rows base_order first_block];rewrite (pos_unsigned (col_starts g)) by lia;
       entailer!;try apply derives_refl. }
   change (i<hi) in H0;assert (live:lo<=i<hi) by lia;specialize (safe i live);fold (at_index i) in safe.
   set (rw:=Znth i (col_rows g)) in *;set (r:=Int.unsigned rw) in *;destruct safe as [base_ok [fb_ok can_move]].
   assert (fb_index:0<=Int.unsigned (Znth i (col_rows g))<Zlength (exhausted_fallback (at_index i))) by (fold rw r;lia).
   rewrite (pos_unsigned (col_rows g)),(pos_signed (base_order g)),(pos_signed (exhausted_fallback (at_index i))) by lia.
   do 4 forward;reassoc_seq.
   set (base:=Znth r (base_order g));set (fb:=Znth r (exhausted_fallback (at_index i))).
   forward_if (temp _t'1 (guard_val (ignores base fb))).
   + forward;unfold ignores,guard_val.
     assert (off:(Int.signed base <? 0)=true) by (apply Z.ltb_lt;unfold base,r,rw;lia).
     rewrite off;entailer!.
   + do 3 forward;unfold ignores,guard_val.
     assert (on:(Int.signed base <? 0)=false) by (apply Z.ltb_ge;unfold base,r,rw;lia).
     rewrite on;cbn [orb];entailer!;fold rw r fb;unfold Int.lt;change (Int.signed (Int.repr 0)) with 0.
     destruct (Z.leb_spec 0 (Int.signed fb)),(zlt (Int.signed fb) 0);try lia;reflexivity.
   + apply semax_if_seq;forward_if.
     * assert (used:ignores base fb=true) by (destruct (ignores base fb);congruence).
       unfold ignores in used;apply Bool.orb_true_iff in used.
       assert (skip_row:remember_row limits (base_order g) q (at_index i) rw=at_index i).
       { unfold remember_row;fold r base fb;destruct (Z_lt_dec (Int.signed base) 0);auto.
         destruct (Z_lt_dec (Int.signed fb) 0);auto;destruct used as [low|taken];
           [apply Z.ltb_lt in low|apply Z.leb_le in taken];lia. }
       assert (step:at_index (i+1)=remember_row limits (base_order g) q (at_index i) rw)
         by (unfold at_index,before_row,rw;apply remember_next;lia).
       forward;Exists i;unfold inner_loc,block_loc;rewrite step,skip_row.
       unfold exhausted_at,scans_at;cbn [dynamic_rows col_starts col_rows base_order first_block].
       rewrite (pos_unsigned (col_starts g)),(pos_unsigned (col_rows g)),(pos_signed (base_order g)),
          (pos_signed (exhausted_fallback (at_index i))) by lia;entailer!;try apply derives_refl.
     * assert (unused:ignores base fb=false) by (destruct (ignores base fb);[discriminate|reflexivity]).
       unfold ignores in unused;apply Bool.orb_false_iff in unused;destruct unused as [on new].
       apply Z.ltb_ge in on;apply Z.leb_gt in new.
       specialize (can_move on new) as [inrow [len [inblock old]]].
       do 2 forward;rewrite upd_Znth_map.
       unfold moving_at;Intros;pose proof (Int.unsigned_range_2 rw) as fits.
       forward_call (p,a,exempts (live_rows (at_index i)),limits,reference_counts (live_rows (at_index i)),
         forbidden_events (live_rows (at_index i)),r,q);
         try solve [entailer!;unfold r,q;rewrite !Int.repr_unsigned;reflexivity].
       assert (step:at_index (i+1)=Build_exhausted_state
          (upd_Znth r (exhausted_fallback (at_index i)) (Int.repr q))
          (replace_exemption limits (live_rows (at_index i)) r q)).
       { assert (raw:at_index (i+1)=remember_row limits (base_order g) q (at_index i) rw)
           by (unfold at_index,before_row,rw;apply remember_next;lia).
         rewrite raw;unfold remember_row;fold r base fb.
         destruct (Z_lt_dec (Int.signed base) 0);[lia|];
           destruct (Z_lt_dec (Int.signed fb) 0);[reflexivity|lia]. }
       Exists i;unfold inner_loc,block_loc;rewrite step;unfold exhausted_at,scans_at;
         cbn [dynamic_rows col_starts col_rows base_order first_block live_rows exhausted_fallback].
       rewrite move_matches,(pos_unsigned (col_starts g)),(pos_unsigned (col_rows g)),(pos_signed (base_order g)) by lia.
       rewrite pos_signed,upd_Znth_Zlength by (rewrite ?upd_Znth_Zlength;lia).
       unfold q;rewrite Int.repr_unsigned;entailer!;try apply derives_refl.
 - Intros i;unfold inner_loc,block_loc;forward;Exists (i+1);unfold inner_loc,block_loc;entailer!;try apply derives_refl.
 - unfold POSTCONDITION,abbreviate;cbn [RA_normal normal_ret_assert];unfold inner_loc,block_loc,process_qubit;
   fold q;fold hi;entailer!;try apply derives_refl.
   unfold exhausted_at,scans_at,at_index;cbn [dynamic_rows col_starts col_rows base_order first_block];cancel.
Qed.
