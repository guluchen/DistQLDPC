(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.zlist.list_solver PreparedGatherCandidates.
Require Import row_builder_ast.
#[local] Instance RowSpecs:compspecs. make_compspecs prog. Defined.
Definition row_vars:varspecs. mk_varspecs prog. Defined.
Local Open Scope Z_scope.

Definition row_words xs p:=if Z.eq_dec (Zlength xs) 0 then emp else
  data_at Tsh (tarray tuint (Zlength xs)) xs p.
Lemma open_row xs p:0<Zlength xs ->
 row_words xs p=data_at Tsh (tarray tuint (Zlength xs)) xs p.
Proof. unfold row_words;destruct Z.eq_dec;intros;lia || reflexivity. Qed.

(* The prefix belongs to rows already appended. The rest can contain
   Vundef. No address in either the prefix or the remaining suffix is
   rewritten. Null array pointers are permitted for a zero-sized table. *)
Definition append_spec:ident*funspec:=
 DECLARE _cc_append_candidate_row
 WITH dest:val,src:val,ep:val,prefix:list val,row:list int,old:list val
 PRE [tptr tuint,tuint,tptr tuint,tuint,tptr tuint]
 PROP(Zlength prefix+Zlength row<=Zlength old;Zlength old<=Int.max_unsigned;
      is_pointer_or_null dest;is_pointer_or_null src)
 PARAMS(dest;Vint (Int.repr (Zlength prefix));src;Vint (Int.repr (Zlength row));ep)
 SEP(row_words (written_values prefix old) dest;row_words (map Vint row) src;data_at_ Tsh tuint ep)
 POST [tvoid] PROP() RETURN()
 SEP(row_words (written_values (prefix++map Vint row) old) dest;row_words (map Vint row) src;
     data_at Tsh tuint (Vint (Int.repr (Zlength prefix+Zlength row))) ep).
Definition append_calls:funspecs:=ltac:(with_library prog [append_spec]).
Definition copied prefix row i:=prefix++map Vint (sublist 0 i row).
Lemma copied_size prefix row i:0<=i<=Zlength row -> Zlength (copied prefix row i)=Zlength prefix+i.
Proof. intros;unfold copied;rewrite Zlength_app,Zlength_map,Zlength_sublist by lia;lia. Qed.
Lemma copied_next prefix row i:0<=i<Zlength row ->
 copied prefix row (i+1)=copied prefix row i++[Vint (Znth i row)].
Proof.
 intros;unfold copied;rewrite (sublist_split 0 i (i+1)),(sublist_one i),map_app by lia.
 rewrite app_assoc;reflexivity.
Qed.

Theorem producer_appends_one_row:
 semax_body row_vars append_calls f_cc_append_candidate_row append_spec.
Proof.
 start_function.
 pose proof (Zlength_nonneg prefix);pose proof (Zlength_nonneg row).
 forward_loop
 (EX i:Z, PROP(0<=i<=Zlength row)
  LOCAL(temp _flat dest;temp _start (Vint (Int.repr (Zlength prefix)));temp _row src;
        temp _length (Vint (Int.repr (Zlength row)));temp _end ep;temp _j (Vint (Int.repr i)))
  SEP(row_words (written_values (copied prefix row i) old) dest;row_words (map Vint row) src;
      data_at_ Tsh tuint ep))%assert
 break: (PROP() LOCAL(temp _start (Vint (Int.repr (Zlength prefix)));temp _length (Vint (Int.repr (Zlength row)));
                     temp _end ep)
  SEP(row_words (written_values (prefix++map Vint row) old) dest;row_words (map Vint row) src;
      data_at_ Tsh tuint ep))%assert.
 - forward;Exists 0;unfold copied;rewrite sublist_nil by lia;cbn [map];rewrite app_nil_r;entailer!.
 - Intros i;forward_if.
   + assert (idx:0<=i<Zlength row) by rep_lia.
     pose proof (copied_size prefix row i ltac:(lia)) as sofar.
     assert (extent:Zlength (written_values (copied prefix row i) old)=Zlength old)
        by (rewrite written_length by lia;reflexivity).
     assert (dest_live:0<Zlength (written_values (copied prefix row i) old)) by lia.
     assert (src_live:0<Zlength (map Vint row)) by (rewrite Zlength_map;lia).
     rewrite (@open_row _ dest dest_live),(@open_row _ src src_live).
     rewrite ?Zlength_map,?extent;do 2 forward.
     { assert (index_fits:0<=Zlength prefix+i<Zlength (written_values (copied prefix row i) old))
         by (rewrite extent;lia).
       apply prop_right;exact index_fits. }
     forward.
     Exists (i+1).
     assert (next_bound:Zlength (copied prefix row (i+1))<=Zlength old) by (rewrite copied_size by lia;lia).
     assert (next_live:0<Zlength (written_values (copied prefix row (i+1)) old))
       by (rewrite written_length by exact next_bound;lia).
     rewrite (@open_row _ dest next_live),?(@open_row _ src src_live).
     rewrite copied_next by lia;rewrite <-append_written_value by lia.
     rewrite ?written_length,?copied_size,?Zlength_map by lia;entailer!.
     rewrite upd_Znth_Zlength by (rewrite written_length by (rewrite copied_size by lia;lia);lia).
     rewrite written_length by (rewrite copied_size by lia;lia);apply derives_refl.
   + assert (i=Zlength row) by rep_lia;subst;unfold copied;rewrite sublist_same by lia;forward;entailer!.
 - forward;entailer!;unfold Int.add;rewrite !Int.unsigned_repr by rep_lia;reflexivity.
Qed.

(* Repeated writes of the returned end to offsets[i+1] give the
   exclusive prefix sums used at the native gather call. *)
Fixpoint row_boundaries (start:Z) (rows:list (list int)):list Z:=
 match rows with
 | []=>[start]
 | row::rest=>start::row_boundaries (start+Zlength row) rest
 end.

Lemma row_bounds_from_iterations (before:list (list int)) row rest start:
 let offsets:=row_boundaries start (before++row::rest) in
 nth (length before) offsets (-1)=start+Zlength (List.concat before) /\
 nth (S (length before)) offsets (-1)=start+Zlength (List.concat before)+Zlength row.
Proof.
 revert start;induction before as [|a before IH];intro start.
 - cbn [length app List.concat row_boundaries nth];rewrite Zlength_nil;destruct rest;simpl;lia.
 - cbn [length app List.concat row_boundaries nth].
   destruct (IH (start+Zlength a)) as [lo hi].
   rewrite Zlength_app;split;lia.
Qed.

Require Import PreparedConstructedRow.
Theorem offsets_select_appended_pcm_row (before:list (list int)) row rest:
 let rows:=before++row::rest in let offsets:=row_boundaries 0 rows in
 sublist (nth (length before) offsets (-1)) (nth (S (length before)) offsets (-1))
         (List.concat rows)=row.
Proof.
 intros rows offsets;destruct (row_bounds_from_iterations before row rest 0) as [lo hi].
 change (nth (length before) offsets (-1)=0+Zlength (List.concat before)) in lo.
 change (nth (S (length before)) offsets (-1)=0+Zlength (List.concat before)+Zlength row) in hi.
 rewrite lo,hi;unfold rows;rewrite List.concat_app;cbn [List.concat Z.add].
 apply row_between_offsets.
Qed.
