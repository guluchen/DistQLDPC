(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.floyd.reassoc_seq VST.zlist.list_solver.
Require Import level_ast VerifDetected ClightSelect RowTally RowGather.
Definition gather_loop (s:statement) :=
 match s with Ssequence (Ssequence _ (Sset ix _)) (Sloop _ _) => Pos.eqb ix _i__2
 | _=>false end.
Definition native_gather : statement:=ltac:(native_fragment gather_loop f_index_children).
Definition gather_mem s op rp bp children os cols blocks buffer :=
 (field_at Tsh level_type [StructField _rstart] op s *
  data_at Tsh (tarray tuint (Zlength os)) (map (fun z=>Vint (Int.repr z)) os) op *
  field_at Tsh level_type [StructField _rq] rp s *
  data_at Tsh (tarray tuint (Zlength cols)) (map Vint cols) rp *
  field_at Tsh level_type [StructField _blk] bp s *
  data_at Tsh (tarray tuint (Zlength blocks)) (map Vint blocks) bp *
  data_at Tsh (tarray tuint (Zlength buffer)) (map Vint buffer) children)%logic.
Definition gather_loc s children r count :=
 [temp _s s;temp _children children;temp _branch (Vint (Int.repr r));temp _count__1 (Vint (Int.repr count))].

Theorem semax_gather_row {Espec:OracleKind} s op rp bp children os cols blocks old r lo hi :
  0<=r<Int.max_signed -> r+1<Zlength os -> Znth r os=lo -> Znth (r+1) os=hi ->
  0<=lo<=hi -> hi<=Int.max_unsigned -> hi<=Zlength cols -> hi-lo<=Zlength old ->
  Zlength old<=Int.max_signed ->
  (forall j,lo<=j<hi -> Int.unsigned (Znth j cols)<Zlength blocks) ->
  semax (func_tycontext f_index_children Vprog [] [])
    (PROPx nil (LOCALx (gather_loc s children r 0) (SEPx [gather_mem s op rp bp children os cols blocks old])))
    native_gather
    (normal_ret_assert (PROPx nil
      (LOCALx (gather_loc s children r (Zlength (gathered blocks cols lo hi)))
       (SEPx [gather_mem s op rp bp children os cols blocks (filled (gathered blocks cols lo hi) old)])))).
Proof.
 intros row oslen begin endoff ordered ulimit within room signedcap live.
 unfold native_gather,gather_loc. abbreviate_semax. reassoc_seq.
 unfold gather_mem;Intros. do 2 forward.
 forward_loop
   (EX i:Z, PROP(lo<=i<=hi)
    LOCAL(temp _s s;temp _children children;temp _branch (Vint (Int.repr r));
       temp _i__2 (Vint (Int.repr i));temp _count__1 (Vint (Int.repr (Zlength (gathered blocks cols lo i)))))
    SEP(gather_mem s op rp bp children os cols blocks (filled (gathered blocks cols lo i) old)))%assert
  break: (PROP() LOCAL(temp _s s;temp _children children;temp _branch (Vint (Int.repr r));
           temp _count__1 (Vint (Int.repr (Zlength (gathered blocks cols lo hi)))))
     SEP(gather_mem s op rp bp children os cols blocks (filled (gathered blocks cols lo hi) old)))%assert.
 - Exists lo;unfold gather_mem.
   assert (nothing:gathered blocks cols lo lo=[]) by (unfold gathered,free_row;rewrite sublist_nil by lia;reflexivity).
   rewrite nothing;unfold filled;rewrite Zlength_nil,sublist_same by (pose proof (Zlength_nonneg old);lia).
   rewrite ?begin;entailer!;try apply derives_refl.
 - Intros i. pose proof (@gather_size blocks cols lo i ltac:(lia) ltac:(lia)) as fits.
   pose proof (@filled_len (gathered blocks cols lo i) old ltac:(lia)) as buflen.
   unfold gather_mem;Intros. do 2 forward. rewrite endoff. forward_if.
   + assert (idx:lo<=i<hi) by rep_lia.
     pose proof (live i idx) as upper;pose proof (Int.unsigned_range (Znth i cols)) as lower.
     do 4 forward. reassoc_seq;apply semax_if_seq;forward_if.
     * assert (free:is_free blocks (Znth i cols)=true).
       { unfold is_free;pose proof (Int.eq_spec (Znth (Int.unsigned (Znth i cols)) blocks) Int.zero);
         destruct (Int.eq _ _);congruence. }
       do 5 forward. forward. Exists (i+1).
       unfold gather_mem;rewrite gather_step by lia;rewrite free, Zlength_app.
       rewrite !filled_len by (rewrite ?Zlength_app;cbn;lia).
       rewrite <-fill_one by lia;rewrite upd_Znth_map;entailer!.
     * assert (busy:is_free blocks (Znth i cols)=false).
       { unfold is_free;pose proof (Int.eq_spec (Znth (Int.unsigned (Znth i cols)) blocks) Int.zero);
         destruct (Int.eq _ _);congruence. }
       forward. Exists (i+1);unfold gather_mem;rewrite gather_step by lia;rewrite busy;entailer!.
   + assert (i=hi) by rep_lia;subst i;forward;unfold gather_mem;entailer!.
Qed.
