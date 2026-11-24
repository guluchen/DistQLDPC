(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.floyd.reassoc_seq VST.zlist.list_solver.
Require Import seed_ast VerifSeedMove SeedPolicyView SeedBlockView VerifRememberColumn EmptySeedColumns.
#[local] Existing Instance SeedC.
Local Open Scope Z_scope.
Definition block_columns_empty b (starts:list int) block :=
 0<=block<Int.max_signed /\ block+1<Zlength (block_offsets b) /\
 0<=block_at b block<=block_at b (block+1) /\ block_at b (block+1)<=Zlength (block_members b) /\
 forall j,block_at b block<=j<block_at b (block+1) ->
 let q:=Int.unsigned (Znth j (block_members b)) in
 q<=Int.max_signed /\ q+1<Zlength starts /\ Znth (q+1) starts=Znth q starts.
Definition empty_orbit:ident*funspec:=
 DECLARE _cc_seed_block_done WITH p:val,b:orbit_blocks,cp:val,starts:list int,block:Z
 PRE [tptr tvoid,tint] PROP(block_columns_empty b starts block)
 PARAMS(p;Vint (Int.repr block)) SEP(blocks_at p b;offsets_at p cp starts)
 POST [tvoid] PROP() RETURN() SEP(blocks_at p b;offsets_at p cp starts).
Definition EmptyBlockG:funspecs:=ltac:(with_library prog [move_spec;empty_orbit]).
Lemma skip_column_without_rows {Espec:OracleKind} p cp starts block j word :
 let q:=Int.unsigned word in q<=Int.max_signed -> q+1<Zlength starts -> Znth (q+1) starts=Znth q starts ->
 forall frame:mpred,
 semax (func_tycontext f_cc_seed_block_done SVars EmptyBlockG [])
 (PROPx [] (LOCALx (inner_loc p block j word) (SEPx [frame;offsets_at p cp starts]))) inner_scan
 (normal_ret_assert (PROPx [] (LOCALx (inner_loc p block j word) (SEPx [frame;offsets_at p cp starts])))).
Proof.
 intros q fits room no_rows frame;pose proof (Int.unsigned_range_2 word) as valid.
 assert (next:Int.unsigned (Int.add word (Int.repr 1))=q+1) by
  (change (Int.unsigned (Int.repr (q+1))=q+1);apply Int.unsigned_repr;rep_lia).
 unfold inner_loc,block_loc,inner_scan,offsets_at;abbreviate_semax;Intros;do 2 forward.
 forward_loop (PROPx [] (LOCALx (temp _i (Vint (Znth q starts))::inner_loc p block j word)
   (SEPx [frame;offsets_at p cp starts])))%assert
 continue:(PROP(False) LOCAL() SEP())%assert
 break:(PROPx [] (LOCALx (inner_loc p block j word) (SEPx [frame;offsets_at p cp starts])))%assert.
 - unfold inner_loc,block_loc,offsets_at;entailer!;try apply derives_refl.
 - unfold inner_loc,block_loc,offsets_at;Intros;forward;forward;try solve [entailer!;rewrite next;lia].
   rewrite ?next,no_rows;forward_if.
   { exfalso;match goal with H:Int.ltu ?x ?x=true |- _=>apply Int.ltu_inv in H;lia end. }
   forward;unfold inner_loc,block_loc,offsets_at;entailer!;try apply derives_refl.
 - unfold POSTCONDITION,abbreviate;cbn [RA_normal normal_ret_assert].
   unfold inner_loc,block_loc,offsets_at;try apply ENTAIL_refl;try apply derives_refl;try entailer!.
Qed.
Theorem body_empty_orbit:semax_body SVars EmptyBlockG f_cc_seed_block_done empty_orbit.
Proof.
 start_function;destruct H as [id_ok [room [range [cap all_empty]]]].
 set (lo:=block_at b block) in *;set (hi:=block_at b (block+1)) in *.
 assert (end_ok:hi<=Int.max_unsigned) by (unfold hi,block_at;apply Int.unsigned_range_2).
 unfold blocks_at;Intros;rewrite (pos_unsigned (block_offsets b)) by lia;reassoc_seq;do 3 forward.
 forward_loop (EX j:Z,PROPx [lo<=j<=hi] (LOCALx (block_loc p block j)
   (SEPx [blocks_at p b;offsets_at p cp starts])))%assert
 continue: (EX j:Z,PROPx [lo<=j<hi] (LOCALx (block_loc p block j)
   (SEPx [blocks_at p b;offsets_at p cp starts])))%assert
 break: (PROP() LOCAL() SEP(blocks_at p b;offsets_at p cp starts))%assert.
 - Exists lo;unfold block_loc,blocks_at;rewrite (pos_unsigned (block_offsets b)) by lia.
   unfold lo,block_at;rewrite Int.repr_unsigned;entailer!;try apply derives_refl.
   fold (block_at b block);fold lo;lia.
 - Intros j;unfold block_loc,blocks_at;Intros;rewrite (pos_unsigned (block_offsets b)) by lia.
   do 2 (forward;try solve [entailer!;rep_lia]);forward_if.
   2:{ change (j>=hi) in H0;forward;unfold blocks_at;rewrite (pos_unsigned (block_offsets b)) by lia;entailer!;try apply derives_refl. }
   change (j<hi) in H0;assert (live:lo<=j<hi) by lia.
   destruct (all_empty j live) as [fits [next unused]].
   rewrite (pos_unsigned (block_members b)) by lia;do 2 forward.
   eapply semax_post'.
   2:{ eapply semax_pre;[|apply (@skip_column_without_rows Espec p cp starts block j (Znth j (block_members b))
     fits next unused (blocks_at p b))];unfold inner_loc,block_loc,blocks_at.
     rewrite (pos_unsigned (block_offsets b)),(pos_unsigned (block_members b)) by lia;entailer!;try apply derives_refl. }
   Exists j;unfold inner_loc,block_loc;entailer!;try apply derives_refl.
 - Intros j;unfold block_loc;forward;Exists (j+1);unfold block_loc;entailer!;try apply derives_refl.
 - unfold POSTCONDITION,abbreviate;cbn [RA_normal frame_ret_assert function_body_ret_assert normal_ret_assert].
   unfold stackframe_of;simpl fn_vars;cbn [fold_right map];rewrite sepcon_emp;entailer!;try apply derives_refl.
Qed.
