(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.floyd.reassoc_seq VST.zlist.list_solver.
Require Import seed_ast VerifSeedMove SeedPolicyView SeedBlockModel SeedBlockView VerifRememberColumn.
#[local] Existing Instance SeedC.
Local Open Scope Z_scope.
Theorem body_seed_block_done:semax_body SVars BlockG f_cc_seed_block_done exhausted_spec.
Proof.
 start_function;destruct H as [id_ok [room [span [cap safe]]]].
 set (lo:=block_at b block) in *;set (hi:=block_at b (block+1)) in *.
 set (at_index:=crossed_block g b limits initial lo).
 assert (hi_fits:hi<=Int.max_unsigned) by (unfold hi,block_at;apply Int.unsigned_range_2).
 unfold exhausted_at,blocks_at;Intros;rewrite (pos_unsigned (block_offsets b)) by lia.
 reassoc_seq;do 3 forward.
 forward_loop (EX j:Z,PROPx [lo<=j<=hi] (LOCALx (block_loc p block j)
   (SEPx [exhausted_at p a pa g b limits (at_index j)])))%assert
 continue: (EX j:Z,PROPx [lo<=j<hi] (LOCALx (block_loc p block j)
   (SEPx [exhausted_at p a pa g b limits (at_index (j+1))])))%assert
 break: (PROP() LOCAL() SEP(exhausted_at p a pa g b limits (at_index hi)))%assert.
 - Exists lo;unfold block_loc,exhausted_at,blocks_at,at_index,crossed_block.
   rewrite sublist_nil by lia;cbn [fold_left];rewrite (pos_unsigned (block_offsets b)) by lia.
   unfold lo,block_at;rewrite Int.repr_unsigned;entailer!;try apply derives_refl.
   fold (block_at b block);fold lo;lia.
 - Intros j;unfold block_loc,exhausted_at,blocks_at;Intros.
   rewrite (pos_unsigned (block_offsets b)) by lia;do 2 (forward;try solve [entailer!;rep_lia]);forward_if.
   2:{ change (j>=hi) in H0;assert (j=hi) by lia;subst j;forward;unfold exhausted_at,blocks_at;
       rewrite (pos_unsigned (block_offsets b)) by lia;entailer!;try apply derives_refl. }
   change (j<hi) in H0;assert (live:lo<=j<hi) by lia.
   specialize (safe j live);fold (at_index j) in safe.
   rewrite (pos_unsigned (block_members b)) by lia;do 2 forward.
   eapply semax_post'.
   2:{ eapply semax_pre;[|apply (@remember_one_column Espec p a pa g b limits block j
          (Znth j (block_members b)) (at_index j) safe)].
       unfold inner_loc,block_loc,exhausted_at,blocks_at;rewrite (pos_unsigned (block_offsets b)),(pos_unsigned (block_members b)) by lia.
       entailer!;try apply derives_refl. }
   Exists j;unfold inner_loc,block_loc,at_index;rewrite crossed_next by lia;entailer!;try apply derives_refl.
 - Intros j;unfold block_loc;forward;Exists (j+1);unfold block_loc;entailer!;try apply derives_refl.
 - unfold POSTCONDITION,abbreviate;cbn [RA_normal frame_ret_assert function_body_ret_assert normal_ret_assert].
   unfold stackframe_of;simpl fn_vars;cbn [fold_right map];rewrite sepcon_emp;entailer!;try apply derives_refl.
Qed.
