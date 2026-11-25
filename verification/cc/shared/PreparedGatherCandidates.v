(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.floyd.reassoc_seq VST.zlist.list_solver RowTally RowGather.
Require Import candidate_row_ast.
#[local] Instance CandidateSpecs:compspecs. make_compspecs prog. Defined.
Definition candidate_vars:varspecs. mk_varspecs prog. Defined.
Local Open Scope Z_scope.
Definition written_values (picks old:list val) := picks ++ sublist (Zlength picks) (Zlength old) old.
Lemma written_length picks old : Zlength picks<=Zlength old -> Zlength (written_values picks old)=Zlength old.
Proof.
 intro room;unfold written_values;rewrite Zlength_app,Zlength_sublist by (pose proof (Zlength_nonneg picks);lia);lia.
Qed.
Lemma written_at picks old i : Zlength picks<=Zlength old -> 0<=i<Zlength old ->
 Znth i (written_values picks old) = if Z_lt_dec i (Zlength picks) then Znth i picks else Znth i old.
Proof.
 intros room live;unfold written_values;destruct Z_lt_dec.
 - rewrite app_Znth1 by lia;reflexivity.
 - rewrite app_Znth2 by lia;rewrite Znth_sublist by (rewrite ?Zlength_sublist;try lia;apply Zlength_nonneg).
   f_equal;lia.
Qed.
Lemma append_written_value picks old q : Zlength picks<Zlength old ->
 upd_Znth (Zlength picks) (written_values picks old) q=written_values (picks++[q]) old.
Proof.
 intro room;assert (plus:Zlength (picks++[q])=Zlength picks+1) by (rewrite Zlength_app;reflexivity).
 pose proof (Zlength_nonneg picks) as nn. apply Znth_eq_ext.
 - rewrite upd_Znth_Zlength,!written_length by (rewrite ?plus,?written_length;lia);reflexivity.
 - intros i I;rewrite upd_Znth_Zlength,written_length in I by (rewrite ?written_length;lia).
   destruct (Z.eq_dec i (Zlength picks)) as [->|elsewhere].
   + rewrite upd_Znth_same,written_at by (rewrite ?plus,?written_length;lia).
     rewrite plus;destruct Z_lt_dec;[rewrite app_Znth2 by lia;rewrite Z.sub_diag;reflexivity|lia].
   + rewrite upd_Znth_diff,!written_at by (rewrite ?plus,?written_length;lia).
     rewrite plus;repeat destruct Z_lt_dec;try lia;try reflexivity.
     rewrite app_Znth1 by lia;reflexivity.
Qed.
Definition prefix_values bs row i := map Vint (gathered bs row 0 i).
Definition candidate_spec:ident*funspec:=
 DECLARE _cc_gather_candidates
 WITH rp:val,bp:val,cp:val,row:list int,bs:list int,old:list val
 PRE [tptr tuint,tuint,tptr tuint,tptr tuint]
 PROP(Zlength row<=Zlength old;Zlength row<=Int.max_signed;
      forall i,0<=i<Zlength row -> Int.unsigned (Znth i row)<Zlength bs)
 PARAMS(rp;Vint (Int.repr (Zlength row));bp;cp)
 SEP(data_at Tsh (tarray tuint (Zlength row)) (map Vint row) rp;
     data_at Tsh (tarray tuint (Zlength bs)) (map Vint bs) bp;
     data_at Tsh (tarray tuint (Zlength old)) old cp)
 POST [tint] PROP() RETURN(Vint (Int.repr (Zlength (free_row bs row))))
 SEP(data_at Tsh (tarray tuint (Zlength row)) (map Vint row) rp;
     data_at Tsh (tarray tuint (Zlength bs)) (map Vint bs) bp;
     data_at Tsh (tarray tuint (Zlength old)) (written_values (map Vint (free_row bs row)) old) cp).
Definition candidate_calls:funspecs:=ltac:(with_library prog [candidate_spec]).

(* [old] ranges over CompCert values, including Vundef in unused slots.
   The suffix of the parent's borrowed row is preserved word for word. *)
Theorem cpp_candidate_row_body:
 semax_body candidate_vars candidate_calls f_cc_gather_candidates candidate_spec.
Proof.
 start_function.
 forward.
 forward_for_simple_bound (Zlength row)
 (EX i:Z,PROP() LOCAL(temp _row rp;temp _length (Vint (Int.repr (Zlength row)));
   temp _blocked bp;temp _children cp;temp _count (Vint (Int.repr (Zlength (prefix_values bs row i)))))
 SEP(data_at Tsh (tarray tuint (Zlength row)) (map Vint row) rp;
     data_at Tsh (tarray tuint (Zlength bs)) (map Vint bs) bp;
     data_at Tsh (tarray tuint (Zlength old)) (written_values (prefix_values bs row i) old) cp))%assert.
 - assert (empty:prefix_values bs row 0=[]) by
     (unfold prefix_values,gathered,free_row;rewrite sublist_nil by lia;reflexivity).
   rewrite empty;unfold written_values;rewrite !Zlength_nil.
   rewrite sublist_same by (pose proof (Zlength_nonneg old);lia);entailer!.
 - assert (key:Int.unsigned (Znth i row)<Zlength bs) by (apply H1;lia).
   pose proof (Int.unsigned_range (Znth i row)).
   pose proof (@gather_size bs row 0 i ltac:(lia) ltac:(lia)) as count.
   assert (size_ok:0<=Zlength (prefix_values bs row i)<=i) by (unfold prefix_values;rewrite Zlength_map;lia).
   do 2 forward;forward_if.
   + assert (free:is_free bs (Znth i row)=true).
     { unfold is_free;rewrite H4;reflexivity. }
     do 2 forward;unfold prefix_values;rewrite gather_step by lia;rewrite free,map_app.
     change (map Vint [Znth i row]) with [Vint (Znth i row)].
     rewrite <-append_written_value by (rewrite Zlength_map;lia).
     rewrite Zlength_app, Zlength_cons, Zlength_nil;entailer!.
   + assert (busy:is_free bs (Znth i row)=false).
     { unfold is_free;apply Int.eq_false;exact H4. }
     forward;unfold prefix_values;rewrite gather_step by lia;rewrite busy;entailer!.
 - unfold prefix_values,gathered;rewrite sublist_same by (pose proof (Zlength_nonneg row);lia).
   forward;rewrite Zlength_map;entailer!.
Qed.
