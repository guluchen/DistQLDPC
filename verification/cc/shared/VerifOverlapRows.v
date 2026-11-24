(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.zlist.list_solver VST.floyd.reassoc_seq.
Require Import OverlapRowState SiblingCounters overlap_ast OverlapRowSpecs.
#[local] Existing Instance OverlapSpecs.
Definition common_loc rp bp skip hi i :=
 [temp _qubits rp;temp _blocked bp;temp _exempt (Vint skip);temp _end (Vint (Int.repr hi));
  temp _i (Vint (Int.repr i))].
Lemma slices_live skip qs base lo i:
 Forall (fun q=>Int.unsigned q<Zlength base) qs ->
 Zlength (fst (row_state skip qs base lo i))=Zlength base /\
 Zlength (row_return skip qs base lo i)=Zlength base.
Proof. intros;apply effective_length;apply Forall_sublist;assumption. Qed.
Theorem body_block_row:semax_body Ovars OGprog f_cc_block_overlap_row block_spec.
Proof.
 start_function;destruct H as [interval [length_ok [cap valid]]]. forward.
 set (state:=row_state skip qs base lo).
 set (work:=fun (conditions:list Prop) i j=>PROPx conditions (LOCALx (temp _newly_blocked (Vlong (Int64.repr (snd (state j))))::common_loc rp bp skip hi i)
     (SEPx [array32 qs rp;array32 (fst (state j)) bp]))).
 forward_loop (EX i:Z, work [lo<=i<=hi] i i)%assert
 continue: (EX i:Z, work [lo<=i<hi] i (i+1))%assert
 break: (work [] hi hi).
 - forward;Exists lo;unfold work,common_loc,state,row_state;rewrite sublist_nil by lia;entailer!;try apply derives_refl.
 - unfold work,common_loc;Intros i;forward_if.
   2:{ assert (i=hi) by rep_lia;subst i;forward;unfold work,common_loc;entailer!;try apply derives_refl. }
   assert (live:lo<=i<hi) by rep_lia.
   pose proof (@slices_live skip qs base lo i valid) as [size0 _].
   assert (in_row:In (Znth i qs) qs) by (apply Znth_In;lia).
   pose proof (proj1 (Forall_forall _ _) valid _ in_row) as cell.
   pose proof (Int.unsigned_range (Znth i qs)) as word.
   assert (pos:0<=Int.unsigned (Znth i qs)<Zlength base) by (split;[exact (proj1 word)|exact cell]).
   change (Zlength (fst (state i))=Zlength base) in size0.
   rewrite !stored_array by lia;forward;reassoc_seq;apply semax_if_seq;forward_if.
   + assert (same:Int.eq (Znth i qs) skip=true) by (apply Int.eq_true || subst skip;apply Int.eq_true).
     forward;Exists i;unfold work,common_loc,state;rewrite state_step by lia;unfold block_step;rewrite same.
     unfold state in size0;rewrite ?stored_array by lia;entailer!;try apply derives_refl.
   + assert (different:Int.eq (Znth i qs) skip=false) by (apply Int.eq_false;assumption).
     do 4 forward;Exists i;unfold work,common_loc,state;rewrite state_step by lia;unfold block_step;rewrite different.
     cbn [fst snd];unfold adjust;rewrite ?stored_array,?upd_Znth_Zlength,?upd_Znth_map by (rewrite ?upd_Znth_Zlength;lia).
     pose proof (count_fits skip (sublist lo i qs) base 0) as bound;rewrite Zlength_sublist in bound by lia.
     change (0<=snd (state i)<=0+(i-lo)) in bound;fold (state i).
     destruct (Int.eq (Znth (Int.unsigned (Znth i qs)) (fst (state i))) Int.zero) eqn:F;
       entailer!;rewrite ?F;unfold Int64.add;rewrite ?Int64.unsigned_repr by rep_lia;try reflexivity.
     all: try solve [fold Int.zero;rewrite F;cbn [Z.b2z];change (Int.signed (Int.repr 1)) with 1;reflexivity |
                     fold Int.zero;rewrite F;cbn [Z.b2z];change (Int.signed (Int.repr 0)) with 0;rewrite Z.add_0_r;reflexivity].
     all: rewrite stored_array,upd_Znth_Zlength by (rewrite ?upd_Znth_Zlength;lia);apply derives_refl.
 - Intros i;unfold work,common_loc;forward;Exists (i+1);unfold work,common_loc;entailer!;try apply derives_refl.
 - unfold work,common_loc,state;forward;entailer!;try apply derives_refl.
Qed.

Theorem body_unblock_row:semax_body Ovars OGprog f_cc_unblock_overlap_row unblock_spec.
Proof.
 start_function;destruct H as [interval [length_ok [cap valid]]].
 forward_loop
  (EX i:Z, PROPx [lo<=i<=hi] (LOCALx (common_loc rp bp skip hi i)
   (SEPx [array32 qs rp;array32 (row_return skip qs base lo i) bp])))%assert
 break: (PROP()LOCAL()SEP(array32 qs rp;array32 (row_return skip qs base lo hi) bp))%assert.
 - forward;Exists lo;unfold row_return,common_loc;rewrite sublist_nil by lia;entailer!;try apply derives_refl.
 - Intros i;unfold common_loc;forward_if.
   2:{ assert (i=hi) by rep_lia;subst i;forward;entailer!;try apply derives_refl. }
   assert (live:lo<=i<hi) by rep_lia.
   pose proof (@slices_live skip qs base lo i valid) as [_ size0].
   assert (in_row:In (Znth i qs) qs) by (apply Znth_In;lia).
   pose proof (proj1 (Forall_forall _ _) valid _ in_row) as cell.
   pose proof (Int.unsigned_range (Znth i qs)) as word.
   assert (pos:0<=Int.unsigned (Znth i qs)<Zlength base) by (split;[exact (proj1 word)|exact cell]).
   rewrite !stored_array by lia;forward;reassoc_seq;apply semax_if_seq;forward_if.
   + assert (different:Int.eq (Znth i qs) skip=false) by (apply Int.eq_false;assumption).
     do 2 forward. forward;Exists (i+1);unfold common_loc;rewrite return_step by lia;unfold unblock_step;rewrite different.
     unfold adjust;rewrite ?stored_array,?upd_Znth_Zlength,?upd_Znth_map,?decrement_word by (rewrite ?upd_Znth_Zlength;lia);entailer!.
   + assert (same:Int.eq (Znth i qs) skip=true) by (subst skip;apply Int.eq_true).
     forward;Exists (i+1);unfold common_loc;rewrite return_step by lia;unfold unblock_step;rewrite same.
     rewrite ?stored_array by lia;entailer!;try apply derives_refl.
 - entailer!.
Qed.
