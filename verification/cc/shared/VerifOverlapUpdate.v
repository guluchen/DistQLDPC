(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.floyd.reassoc_seq VST.zlist.list_solver.
Require Import OverlapView OverlapColumnState OverlapRowState OverlapRowSpecs overlap_ast.
#[local] Existing Instance OverlapSpecs.
Local Open Scope Z_scope.
Definition UGprog:funspecs:=ltac:(with_library prog [block_spec;unblock_spec;update_spec]).
Definition head_loc p q enter i:=
 [temp _view p;temp _q (Vint (Int.repr q));temp _add (flag_value enter);temp _i (Vint (Int.repr i))].
Lemma offset_range xs i:0<=offset xs i<=Int.max_unsigned.
Proof. unfold offset;apply Int.unsigned_range_2. Qed.

(* The loop body is translated from the header used by HalfSearch. Its
   row calls use the full contracts for both native row functions. *)
Theorem body_update_overlap:semax_body Ovars UGprog f_cc_update_overlap update_spec.
Proof.
 start_function;unfold admissible,endpoints in H;destruct H as [q_bounds [q_room [span [last_ok safe]]]].
 set (lo:=offset (column_offsets g) q) in *;set (hi:=offset (column_offsets g) (q+1)) in *.
 pose proof (offset_range (column_offsets g) (q+1)) as end_fits;fold hi in end_fits.
 set (at_index:=column_prefix g (Int.repr q) enter st lo).
 assert (bool_ok:tc_val tbool (flag_value enter)) by (destruct enter;compute;auto).
 unfold view_mem;Intros;rewrite (stored_array (column_offsets g)) by lia;reassoc_seq;do 2 forward.
 forward_loop
  (EX i:Z, PROPx [lo<=i<=hi] (LOCALx (head_loc p q enter i) (SEPx [view_mem p a g (at_index i)])))%assert
 continue: (EX i:Z, PROPx [lo<=i<hi] (LOCALx (head_loc p q enter i) (SEPx [view_mem p a g (at_index (i+1))])))%assert
 break: (PROP() LOCAL() SEP(view_mem p a g (at_index hi)))%assert.
 - Exists lo;unfold head_loc,view_mem,at_index,column_prefix;rewrite sublist_nil by lia;
     rewrite (stored_array (column_offsets g)) by lia;unfold lo,offset;rewrite Int.repr_unsigned;entailer!;try apply derives_refl.
   fold (offset (column_offsets g) q);fold lo;lia.
 - Intros i;unfold head_loc,view_mem;Intros;rewrite (stored_array (column_offsets g)) by lia.
   do 2 (forward;try solve [entailer!;rep_lia]).
   forward_if.
   2:{ change (i>=hi) in H2;assert (i=hi) by lia;subst i;forward;unfold view_mem;
      rewrite (stored_array (column_offsets g)) by lia;entailer!;try apply derives_refl. }
   change (i<hi) in H2;assert (live:lo<=i<hi) by lia.
   specialize (safe i live);fold (at_index i) in safe.
   destruct safe as [row_ok [qs_ok [row_cap no_overflow]]];destruct row_ok as [row_range [row_room [starts [ends ex_ok]]]].
   rewrite (stored_array (column_rows g)) by lia;do 2 forward.
   (* Split the optional array and the two callback directions at the source conditionals. *)
   set (word:=Znth i (column_rows g)) in *;set (r:=Int.unsigned word).
   change (0<=r<Zlength (slack (at_index i))) in row_range.
   assert (row_index:offset (column_rows g) i=r) by reflexivity.
   rewrite row_index in row_room,starts,ends,ex_ok,row_cap,no_overflow;clear row_index.
   assert (row_next:Int.unsigned (Int.add word (Int.repr 1))=r+1).
   { change (Int.unsigned (Int.repr (r+1))=r+1);apply Int.unsigned_repr;lia. }
   set (ex:=exempt_for g r).
   assert_PROP (is_pointer_or_null (exemptp a g)) as ex_ptr.
   { unfold exemptp,exempt_store;destruct (exempt_qubits g) as [es|] eqn:E.
     - change (r < Zlength es) in ex_ok;rewrite (signed_live es) by lia;entailer!.
     - entailer!. }
   forward;try solve [entailer!].
   forward_if (temp _t'1 (Vint ex)).
   { unfold exemptp,exempt_store;destruct (exempt_qubits g) as [es|] eqn:E.
     - change (r<Zlength es) in ex_ok;rewrite (signed_live es) by lia;entailer!;
         try (unfold denote_tc_test_eq;destruct (exemp a);simpl in *;try contradiction;auto with valid_pointer).
     - entailer!. }
   + unfold exemptp,exempt_store,ex,exempt_for in *;destruct (exempt_qubits g) as [exs|];[|contradiction].
     rewrite (signed_live exs) by lia;do 3 (forward;try solve [entailer!;rep_lia]);entailer!;
        try rewrite (signed_live exs) by lia;try cancel;try reflexivity.
   + unfold exemptp,exempt_store,ex,exempt_for in *;destruct (exempt_qubits g) as [exs|].
     * rewrite (signed_live exs) by lia;assert_PROP (isptr (exemp a)) as ep by entailer!;
       rewrite H3 in ep;contradiction.
     * forward;entailer!.
   + forward;reassoc_seq;apply semax_if_seq;forward_if.
     * assert (same:Int.eq ex (Int.repr q)=true) by (rewrite H3;apply Int.eq_true).
       forward;Exists i;unfold head_loc,at_index;rewrite next_column_row by lia;
         unfold update_row;fold word r ex;rewrite same;unfold view_mem;
         entailer!;rewrite (stored_array (column_offsets g)),(stored_array (column_rows g)) by lia;apply derives_refl.
     * assert (other:Int.eq ex (Int.repr q)=false) by (apply Int.eq_false;assumption).
       fold r ex in no_overflow;rewrite other in no_overflow.
       rewrite (signed_live (slack (at_index i))) by lia.
       forward_if.
       -- destruct enter;[|discriminate].
          do 3 forward.
          { entailer!;fold r;pose proof (Int.signed_range (Znth r (slack (at_index i))));lia. }
          do 2 forward.
          set (old:=Znth r (slack (at_index i))).
          set (down:=Int.sub old Int.one).
          forward_if.
          ++ do 5 forward.
             forward_if (PROP() LOCAL(temp _view p;temp _q (Vint (Int.repr q));temp _add (flag_value true);
               temp _i (Vint (Int.repr i));temp _row (Vint word);temp _exempt (Vint ex))
               SEP(view_mem p a g (Build_snapshot (upd_Znth r (slack (at_index i)) down)
                  (blocked (at_index i)) (Int64.add (tight (at_index i)) Int64.one)
                  (if Int.ltu word (first_extra g) then tight_extra (at_index i)
                   else Int64.add (tight_extra (at_index i)) Int64.one) (forbidden (at_index i)))))%assert.
             ** do 4 forward. unfold view_mem;cbn [slack blocked tight tight_extra forbidden];rewrite H6.
                rewrite (stored_array (column_offsets g)),(stored_array (column_rows g)) by lia.
                rewrite (signed_live (upd_Znth r (slack (at_index i)) down)) by (rewrite upd_Znth_Zlength;lia).
                rewrite upd_Znth_Zlength,upd_Znth_map by lia;fold r;entailer!;try cancel.
             ** try forward. unfold view_mem;cbn [slack blocked tight tight_extra forbidden];rewrite H6.
                rewrite (stored_array (column_offsets g)),(stored_array (column_rows g)) by lia.
                rewrite (signed_live (upd_Znth r (slack (at_index i)) down)) by (rewrite upd_Znth_Zlength;lia).
                rewrite upd_Znth_Zlength,upd_Znth_map by lia;fold r;entailer!;try cancel.
             ** unfold view_mem;Intros;rewrite (stored_array (row_offsets g)) by lia.
                cbn [slack blocked tight tight_extra forbidden] in *.
                do 6 (forward;try solve [entailer!;rep_lia]).
                set (begin_row:=offset (row_offsets g) r);set (end_row:=offset (row_offsets g) (r+1)).
                assert (slice:valid_input (row_qubits g) (blocked (at_index i)) begin_row end_row).
                { unfold valid_input,begin_row,end_row;pose proof (offset_range (row_offsets g) r);
                  pose proof (offset_range (row_offsets g) (r+1));repeat split;try lia;exact qs_ok. }
                forward_call (qubitp a,blockp a,ex,row_qubits g,blocked (at_index i),begin_row,end_row);
                  try solve [entailer!;rewrite row_next;unfold begin_row,end_row,offset;rewrite !Int.repr_unsigned;reflexivity].
                do 4 forward;Exists i;unfold head_loc,at_index;rewrite next_column_row by lia.
                unfold update_row;fold word r ex old down;rewrite other.
                assert (zero:Int.eq down Int.zero=true) by (change (down=Int.zero) in H5;rewrite H5;apply Int.eq_true).
                fold (at_index i);fold old down;rewrite zero. unfold view_mem;fold begin_row end_row.
                destruct (row_state ex (row_qubits g) (blocked (at_index i)) begin_row end_row).
                cbn [fst snd slack blocked tight tight_extra forbidden];rewrite (stored_array (row_offsets g)) by lia;
                  entailer!;try cancel.
          ++ forward;Exists i;unfold head_loc,at_index;rewrite next_column_row by lia.
             unfold update_row;fold word r ex;rewrite other;fold (at_index i);fold old down.
             assert (nz:Int.eq down Int.zero=false) by (apply Int.eq_false;exact H5).
             rewrite nz;unfold view_mem;cbn [counters slack blocked tight tight_extra forbidden].
             rewrite (stored_array (column_offsets g)),(stored_array (column_rows g)) by lia.
             rewrite (signed_live (upd_Znth r (slack (at_index i)) down)) by (rewrite upd_Znth_Zlength;lia).
             rewrite upd_Znth_Zlength,upd_Znth_map by lia;fold r;entailer!;try cancel.
       -- destruct enter;[discriminate|].
          do 4 (forward;try solve [entailer!;fold r;pose proof (Int.signed_range (Znth r (slack (at_index i))));lia]).
          set (old:=Znth r (slack (at_index i))).
          forward_if.
          ++ rewrite (stored_array (row_offsets g)) by lia;do 6 (forward;try solve [entailer!;rep_lia]).
             set (begin_row:=offset (row_offsets g) r);set (end_row:=offset (row_offsets g) (r+1)).
             assert (slice:valid_input (row_qubits g) (blocked (at_index i)) begin_row end_row).
             { unfold valid_input,begin_row,end_row;pose proof (offset_range (row_offsets g) r);
               pose proof (offset_range (row_offsets g) (r+1));repeat split;try lia;exact qs_ok. }
             forward_call (qubitp a,blockp a,ex,row_qubits g,blocked (at_index i),begin_row,end_row);
               try solve [entailer!;rewrite row_next;unfold begin_row,end_row,offset;rewrite !Int.repr_unsigned;reflexivity].
             Exists i;unfold head_loc,at_index;rewrite next_column_row by lia.
             unfold update_row;fold word r ex old;rewrite other.
             assert (zero:Int.eq old Int.zero=true) by (change (old=Int.zero) in H5;rewrite H5;apply Int.eq_true).
             fold (at_index i);fold old;rewrite zero;fold begin_row end_row;unfold view_mem;cbn [counters slack blocked tight tight_extra forbidden].
             rewrite (stored_array (column_offsets g)),(stored_array (column_rows g)) by lia.
             rewrite (stored_array (row_offsets g)) by lia.
             rewrite (signed_live (upd_Znth r (slack (at_index i)) (Int.add old Int.one)))
               by (rewrite upd_Znth_Zlength;lia).
             rewrite upd_Znth_Zlength,upd_Znth_map by lia;fold r;entailer!;try cancel.
          ++ forward;Exists i;unfold head_loc,at_index;rewrite next_column_row by lia.
             unfold update_row;fold word r ex;rewrite other;fold (at_index i);fold old.
             assert (nz:Int.eq old Int.zero=false) by (apply Int.eq_false;exact H5).
             rewrite nz;unfold view_mem;cbn [counters slack blocked tight tight_extra forbidden].
             rewrite (stored_array (column_offsets g)),(stored_array (column_rows g)) by lia.
             rewrite (signed_live (upd_Znth r (slack (at_index i)) (Int.add old Int.one)))
               by (rewrite upd_Znth_Zlength;lia).
             rewrite upd_Znth_Zlength,upd_Znth_map by lia;fold r;entailer!;try cancel.
 - Intros i;unfold head_loc;forward;Exists (i+1);unfold head_loc;entailer!;try apply derives_refl.
 - unfold POSTCONDITION,abbreviate;cbn [RA_normal frame_ret_assert function_body_ret_assert normal_ret_assert].
   unfold stackframe_of;simpl fn_vars;cbn [fold_right map]. rewrite sepcon_emp.
   unfold after_column,endpoints,at_index,hi,lo;entailer!;try apply derives_refl.
Qed.
