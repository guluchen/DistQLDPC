(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.floyd.reassoc_seq VST.zlist.list_solver.
Require Import seed_ast VerifSeedMove SeedExemptionState SeedColumnModel SeedPolicyView.
#[local] Existing Instance SeedC.
Local Open Scope Z_scope.
Definition scan_loc p q enter i:=
 [temp _state p;temp _seed (Vint (Int.repr q));temp _enter (flag enter);temp _i (Vint (Int.repr i))].
Theorem body_seed_exemption:semax_body SVars ColumnG f_cc_seed_exemption seed_visit_spec.
Proof.
 start_function;destruct H as [qbound [qroom [span [rowcap safe]]]].
 set (lo:=index_at g seed) in *;set (hi:=index_at g (seed+1)) in *.
 assert (end_fits:hi<=Int.max_unsigned) by (unfold hi,index_at;apply Int.unsigned_range_2).
 set (at_index:=prefix g limits enter seed initial).
 assert (bool_ok:tc_val tbool (flag enter)) by (destruct enter;compute;auto).
 unfold scans_at;Intros;rewrite (pos_unsigned (col_starts g)) by lia;reassoc_seq;do 3 forward.
 forward_loop (EX i:Z, PROPx [lo<=i<=hi] (LOCALx (scan_loc p seed enter i)
     (SEPx [scans_at p pa g;moving_at p a limits (at_index i)])))%assert
 continue: (EX i:Z, PROPx [lo<=i<hi] (LOCALx (scan_loc p seed enter i)
     (SEPx [scans_at p pa g;moving_at p a limits (at_index (i+1))])))%assert
 break: (PROP() LOCAL() SEP(scans_at p pa g;moving_at p a limits (at_index hi)))%assert.
 - Exists lo;unfold scan_loc,scans_at,at_index,prefix,visited_seed_rows;rewrite sublist_nil by lia.
   rewrite (pos_unsigned (col_starts g)) by lia;unfold lo,index_at;rewrite Int.repr_unsigned;entailer!;try apply derives_refl.
   fold (index_at g seed);fold lo;lia.
 - Intros i;unfold scans_at,scan_loc;Intros;rewrite (pos_unsigned (col_starts g)) by lia.
   do 2 (forward;try solve [entailer!;rep_lia]);forward_if.
   2:{ change (i>=hi) in H0;assert (i=hi) by lia;subst i;forward;unfold scans_at;
       rewrite (pos_unsigned (col_starts g)) by lia;entailer!;try apply derives_refl. }
   change (i<hi) in H0;assert (live:lo<=i<hi) by lia.
   specialize (safe i live);fold (at_index i) in safe.
   set (word:=Znth i (col_rows g)) in *;set (r:=Int.unsigned word) in *.
   destruct safe as [base_ok [fallback_ok change_ok]].
   rewrite (pos_unsigned (col_rows g)),(pos_signed (base_order g)) by lia.
   do 4 forward;apply semax_if_seq;forward_if.
   + forward;Exists i;unfold scan_loc,at_index,prefix;rewrite seed_prefix_next by lia.
     fold word r in H1;unfold visit_seed_row;fold word r;destruct (Z_lt_dec (Int.signed (Znth r (base_order g))) 0);[|lia].
     unfold scans_at;rewrite (pos_unsigned (col_starts g)),(pos_unsigned (col_rows g)),(pos_signed (base_order g)) by lia.
     entailer!;try apply derives_refl.
   + fold word r in H1;assert (active:0<=Int.signed (Znth r (base_order g))) by lia.
     specialize (change_ok active);set (next:=seed_choice (base_order g) (first_block g) r seed enter) in *.
     destruct change_ok as [active_row [limlen [signed_next [inside_next inside_old]]]].
     rewrite (pos_signed (first_block g)) by lia;forward.
     assert (fb_index:0<=Int.unsigned (Znth i (col_rows g))<Zlength (first_block g)) by (fold word r;lia).
     forward_if (PROPx nil (LOCALx (temp _row (Vint word)::temp _next (Vint (Int.repr next))::scan_loc p seed enter i)
       (SEPx [scans_at p pa g;moving_at p a limits (at_index i)])))%assert.
     * destruct enter;[discriminate|];do 2 forward;forward_if.
       -- do 2 forward;fold word r in H3;unfold scan_loc,scans_at,next,seed_choice,clear_seed;
          destruct (Z_lt_dec (Int.signed (Znth r (first_block g))) 0);[|lia];rewrite Int.repr_signed.
          rewrite (pos_unsigned (col_starts g)),(pos_unsigned (col_rows g)),(pos_signed (base_order g)),(pos_signed (first_block g)) by lia.
          entailer!;try apply derives_refl.
       -- try forward;fold word r in H3;unfold scan_loc,scans_at,next,seed_choice,clear_seed;
          destruct (Z_lt_dec (Int.signed (Znth r (first_block g))) 0);[lia|];rewrite Int.repr_signed.
          rewrite (pos_unsigned (col_starts g)),(pos_unsigned (col_rows g)),(pos_signed (base_order g)),(pos_signed (first_block g)) by lia.
          entailer!;try apply derives_refl.
     * destruct enter;[|congruence];try forward;unfold scan_loc,scans_at,next,seed_choice.
       rewrite (pos_unsigned (col_starts g)),(pos_unsigned (col_rows g)),(pos_signed (base_order g)),(pos_signed (first_block g)) by lia.
       entailer!;try apply derives_refl.
     * unfold scan_loc,moving_at;Intros;pose proof (Int.unsigned_range_2 word) as row_fits.
       forward_call (p,a,exempts (at_index i),limits,reference_counts (at_index i),forbidden_events (at_index i),r,next);
         try solve [entailer!;unfold r;rewrite Int.repr_unsigned;reflexivity].
       Exists i;unfold scan_loc,at_index,prefix;rewrite seed_prefix_next by lia.
       unfold visit_seed_row;fold word r;destruct Z_lt_dec;[lia|];fold next;rewrite move_matches;entailer!;try apply derives_refl.
 - Intros i;unfold scan_loc;forward;Exists (i+1);unfold scan_loc;entailer!;try apply derives_refl.
 - unfold POSTCONDITION,abbreviate;cbn [RA_normal frame_ret_assert function_body_ret_assert normal_ret_assert].
   unfold stackframe_of;simpl fn_vars;cbn [fold_right map];rewrite sepcon_emp;entailer!;try apply derives_refl.
Qed.
