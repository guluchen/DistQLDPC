(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto.
Require Import level_ast VerifDetected VerifClosesBody ClosureWord.

Definition sparse_flip (state : list int64 * Z) (r : int) :=
  let '(syn,odd) := state in
  let b := Int64.shl Int64.one (Int64.repr (bit_index r)) in
  let new := Int64.xor (Znth (word_index r) syn) b in
  (upd_Znth (word_index r) syn new,
   if Int64.eq (Int64.and new b) Int64.zero then odd-1 else odd+1).

Definition flipped v q odd i :=
  fold_left sparse_flip (sublist (Znth q (offsets v)) i (rows v)) (syndrome v,odd).

Definition logical_sweep v q j :=
  sublist 0 j (differences v q) ++ sublist j (width v) (parities v).

Definition toggle_mem (s keys : val) v odd hash (colkeys syn par : list int64) : mpred :=
 (field_at Tsh level_type [StructField _cstart] (poff v) s *
  field_at Tsh level_type [StructField _cr] (prows v) s *
  field_at Tsh level_type [StructField _syn] (psyn v) s *
  field_at Tsh level_type [StructField _nodd] (Vint (Int.repr odd)) s *
  field_at Tsh level_type [StructField _kw] (Vint (Int.repr (width v))) s *
  field_at Tsh level_type [StructField _gpar] (ppar v) s *
  field_at Tsh level_type [StructField _gmask] (pmasks v) s *
  field_at Tsh level_type [StructField _synkey] (Vlong hash) s *
  field_at Tsh level_type [StructField _colkey] keys s *
  data_at Tsh (tarray tuint (Zlength (offsets v)))
    (map (fun z => Vint (Int.repr z)) (offsets v)) (poff v) *
  data_at Tsh (tarray tuint (Zlength (rows v))) (map Vint (rows v)) (prows v) *
  data_at Tsh (tarray tulong (Zlength syn)) (map Vlong syn) (psyn v) *
  data_at Tsh (tarray tulong (width v)) (map Vlong par) (ppar v) *
  data_at Tsh (tarray tulong (Zlength (masks v))) (map Vlong (masks v)) (pmasks v) *
  data_at Tsh (tarray tulong (Zlength colkeys)) (map Vlong colkeys) keys)%logic.

Definition toggle_spec : ident * funspec :=
 DECLARE _toggle
 WITH s:val, keys:val, v:close_view, colkeys:list int64, q:Z, odd:Z, hash:int64
 PRE [tptr level_type,tint]
 PROP (0<=q<Int.max_signed; q+1<Zlength (offsets v); q<Zlength colkeys;
       0<=Znth q (offsets v)<=Znth (q+1) (offsets v);
       Znth (q+1) (offsets v)<=Zlength (rows v); Zlength (rows v)<=Int.max_unsigned;
       Int.min_signed<=odd<=Int.max_signed; 0<width v<=Int.max_signed;
       (q+1)*width v<=Zlength (masks v);
       forall i, Znth q (offsets v)<=i<Znth (q+1) (offsets v) ->
         word_index (Znth i (rows v))<Zlength (syndrome v);
       forall i, Znth q (offsets v)<=i<Znth (q+1) (offsets v) ->
         Int.min_signed < snd (flipped v q odd i) < Int.max_signed)
 PARAMS(s;Vint(Int.repr q)) SEP(toggle_mem s keys v odd hash colkeys (syndrome v) (parities v))
 POST [tvoid] PROP() RETURN()
 SEP(toggle_mem s keys v (snd (flipped v q odd (Znth (q+1) (offsets v))))
    (Int64.xor hash (Znth q colkeys)) colkeys (fst (flipped v q odd (Znth (q+1) (offsets v))))
    (differences v q)).

Definition ToggleGprog : funspecs := ltac:(with_library prog [toggle_spec]).

Lemma flipped_next v q odd i :
  0 <= Znth q (offsets v) <= i -> i < Zlength (rows v) ->
  flipped v q odd (i+1) = sparse_flip (flipped v q odd i) (Znth i (rows v)).
Proof.
  intros. unfold flipped. rewrite (sublist_split _ i (i+1)) by lia.
  rewrite (sublist_one i) by lia. rewrite fold_left_app. reflexivity.
Qed.

Lemma flip_length v q odd i : Zlength (fst (flipped v q odd i)) = Zlength (syndrome v).
Proof.
  unfold flipped. generalize (sublist (Znth q (offsets v)) i (rows v)).
  generalize (syndrome v) odd; intros syn n rs; revert syn n.
  induction rs as [|r rest IH]; intros; [reflexivity | simpl].
  rewrite IH. destruct (Z_lt_dec (word_index r) (Zlength syn)).
  - apply upd_Znth_Zlength. unfold word_index; split; [apply Int.unsigned_range | assumption].
  - rewrite upd_Znth_out_of_range by lia. reflexivity.
Qed.

Theorem body_toggle : semax_body Vprog ToggleGprog f_toggle toggle_spec.
Proof.
  start_function. unfold toggle_mem. Intros. forward. forward.
  forward_loop
    (EX i:Z, PROP(Znth q (offsets v)<=i<=Znth (q+1) (offsets v))
     LOCAL(temp _s s; temp _q (Vint (Int.repr q)); temp _i (Vint (Int.repr i)))
     SEP(toggle_mem s keys v (snd (flipped v q odd i)) hash colkeys
         (fst (flipped v q odd i)) (parities v)))%assert
  break: (PROP() LOCAL(temp _s s;temp _q (Vint (Int.repr q)))
      SEP(toggle_mem s keys v (snd (flipped v q odd (Znth (q+1) (offsets v)))) hash colkeys
          (fst (flipped v q odd (Znth (q+1) (offsets v)))) (parities v)))%assert.
  - Exists (Znth q (offsets v)). unfold flipped, toggle_mem.
    rewrite sublist_nil by lia. cbn [fold_left fst snd]. entailer!.
  - Intros i. unfold toggle_mem. Intros. forward. forward. forward_if.
    + forward. forward.
      assert (shift : 0 <= Int.unsigned (Int.and (Znth i (rows v)) (Int.repr 63)) < 64).
      { split; [apply Int.unsigned_range | ]. rewrite Int.and_commut.
        pose proof (Int.and_le (Int.repr 63) (Znth i (rows v))) as lim.
        change (Int.unsigned (Int.repr 63)) with 63 in lim; lia. }
      forward; try solve [entailer!; exact (proj2 shift)].
      forward.
      assert (idx : 0 <= word_index (Znth i (rows v)) < Zlength (fst (flipped v q odd i))).
      { rewrite flip_length. split; [apply Int.unsigned_range | apply H8; lia]. }
      unfold word_index in idx.
      forward. forward. forward. forward.

      pose proof (H9 i ltac:(lia)) as room.
      pose proof (flipped_next v q odd i ltac:(lia) ltac:(lia)) as next.
      destruct (flipped v q odd i) as [syn no] eqn:curr.
      cbn [fst snd sparse_flip] in *. fold Int64.one in *.
      fold (word_index (Znth i (rows v))) in *.
      fold (bit_index (Znth i (rows v))) in *.
      set (wi:=word_index (Znth i (rows v))) in *.
      set (bit:= Int64.shl Int64.one (Int64.repr (bit_index (Znth i (rows v))))) in *.
      set (updated:=Int64.xor (Znth wi syn) bit) in *.

      forward_if (PROP()
        LOCAL(temp _s s; temp _q (Vint (Int.repr q)); temp _i (Vint (Int.repr i));
              temp _t'1 (Vint (Int.repr (if Int64.eq (Int64.and updated bit) Int64.zero then -1 else 1))))
        SEP(toggle_mem s keys v no hash colkeys (upd_Znth wi syn updated) (parities v)))%assert.
      * forward. unfold toggle_mem. rewrite upd_Znth_Zlength by lia.
        rewrite upd_Znth_map by lia. entailer!.

        pose proof (Int64.eq_spec (Int64.and updated bit) Int64.zero).
        destruct (Int64.eq (Int64.and updated bit) Int64.zero); congruence.
      * forward. unfold toggle_mem. rewrite upd_Znth_Zlength by lia.
        rewrite upd_Znth_map by lia. entailer!.
        pose proof (Int64.eq_spec (Int64.and updated bit) Int64.zero).
        destruct (Int64.eq (Int64.and updated bit) Int64.zero); [reflexivity | contradiction].
      * unfold toggle_mem. Intros. forward. forward.
        { entailer!. destruct (Int64.eq (Int64.and updated bit) Int64.zero); rewrite Int.signed_repr by rep_lia; lia. }
        forward. Exists (i+1). unfold toggle_mem. rewrite next. cbn [fst snd]. entailer!.
        destruct (Int64.eq (Int64.and updated bit) Int64.zero); apply derives_refl.
    + assert (i=Znth (q+1) (offsets v)) by lia. subst i. forward.
      unfold toggle_mem. entailer!.
  - unfold toggle_mem. Intros. do 4 forward.
    do 3 forward.
    assert_PROP (isptr (pmasks v)) as mask_ptr by entailer!.
    simpl eval_cast. simpl eval_binop. simpl sem_binary_operation'. rewrite !Int.signed_repr by rep_lia.
    rewrite mul64_repr.
    assert (col_ptr: force_val (sem_add_ptr_long tulong (pmasks v) (Vlong (Int64.repr (q*width v)))) =
                       offset_val (sizeof tulong * (q*width v)) (pmasks v)).
    { destruct (pmasks v); try contradiction; simpl. f_equal.
      rewrite (ptrofs_of_int64_int64_repr eq_refl), ptrofs_mul_repr. reflexivity. }
    rewrite col_ptr.

      assert (slicelen: Zlength (sublist (q*width v) ((q+1)*width v) (masks v)) = width v).
      { rewrite Zlength_sublist by (try nia). ring. }
      assert (diff_len: Zlength (differences v q) = width v).
      { unfold differences. rewrite Zlength_map, Zlength_combine, slicelen. unfold width. lia. }
      assert (atdiff: forall j, 0 <= j < width v -> Znth j (differences v q) =
          Int64.xor (Znth j (parities v)) (Znth (q*width v+j) (masks v))).
      { intros j hj; unfold differences. rewrite Znth_map by (rewrite Zlength_combine, slicelen; unfold width in *; lia).
        rewrite Znth_combine by (rewrite slicelen; reflexivity). simpl.
        rewrite Znth_sublist by nia. f_equal; f_equal; lia. }


    Require Import VST.zlist.list_solver.
    assert (actualwidth: Zlength (parities v) = width v) by reflexivity.
    assert (sweep0: logical_sweep v q 0 = parities v).
    { unfold logical_sweep, width; autorewrite with sublist; reflexivity. }
    assert (sweep_end: logical_sweep v q (width v) = differences v q).
    { unfold logical_sweep; list_solve. }
    assert (read_old: forall j, 0<=j<width v ->
                  Znth j (logical_sweep v q j) = Znth j (parities v)).
    { intros j jvalid; unfold logical_sweep; list_solve. }
    assert (write_new: forall j, 0<=j<width v ->
       upd_Znth j (logical_sweep v q j) (Znth j (differences v q)) = logical_sweep v q (j+1)).
    { intros j jvalid; unfold logical_sweep; list_solve. }
    assert (sweep_len: forall j, 0<=j<=width v -> Zlength (logical_sweep v q j)=width v).
    { intros j jvalid; unfold logical_sweep; list_solve. }
    forward.
    forward_loop
      (EX j:Z, PROP(0<=j<=width v)
       LOCAL(temp _s s; temp _q (Vint (Int.repr q)); temp _i__1 (Vint (Int.repr j));
             temp _g (offset_val (sizeof tulong*(q*width v)) (pmasks v)))
       SEP(toggle_mem s keys v (snd (flipped v q odd (Znth (q+1) (offsets v))))
         (Int64.xor hash (Znth q colkeys)) colkeys
         (fst (flipped v q odd (Znth (q+1) (offsets v)))) (logical_sweep v q j)))%assert
    break: (PROP() LOCAL()
       SEP(toggle_mem s keys v (snd (flipped v q odd (Znth (q+1) (offsets v))))
         (Int64.xor hash (Znth q colkeys)) colkeys
         (fst (flipped v q odd (Znth (q+1) (offsets v)))) (differences v q)))%assert.
    + Exists 0. rewrite sweep0. unfold toggle_mem. entailer!.
    + Intros j. unfold toggle_mem. Intros. forward. forward_if.
      * forward. forward.
        assert (jvalid : 0<=j<Zlength (logical_sweep v q j)) by (rewrite sweep_len by lia; lia).
        forward. unfold width in *.
        assert (idx: 0 <= q*Zlength (parities v)+j < Zlength (masks v)) by nia.
           assert_PROP (field_compatible (tarray tulong (Zlength (masks v)))
               [ArraySubsc (q*Zlength (parities v)+j)] (pmasks v)) as fc.
           { entailer!. }
           assert (load_addr: force_val (sem_add_ptr_int tulong Signed
                (offset_val (8*(q*Zlength (parities v))) (pmasks v)) (Vint (Int.repr j))) =
             field_address (tarray tulong (Zlength (masks v)))
                [ArraySubsc (q*Zlength (parities v)+j)] (pmasks v)).
           { rewrite field_address_offset by exact fc.
             destruct (pmasks v); try contradiction. simpl.
             f_equal.
             unfold Ptrofs.of_ints. rewrite Int.signed_repr by rep_lia.
             rewrite Ptrofs.add_assoc, ptrofs_mul_repr, ptrofs_add_repr. f_equal. f_equal. ring. }
        forward. forward. forward. Exists (j+1). unfold toggle_mem. entailer!.
        rewrite read_old by lia. rewrite <- atdiff by lia. rewrite upd_Znth_map by lia. rewrite write_new by lia. apply derives_refl.
      * assert (j=width v) by lia. subst j. forward. rewrite sweep_end. entailer!.
        unfold toggle_mem. cancel.
    + entailer!.
Qed.
