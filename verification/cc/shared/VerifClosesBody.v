(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto.
Require Import Coq.Logic.ClassicalDescription.
Require Import level_ast VerifDetected.

Record close_view := {
  offsets : list Z; rows : list int; syndrome : list int64;
  parities : list int64; masks : list int64;
  poff : val; prows : val; psyn : val; ppar : val; pmasks : val
}.
Definition word_index (r : int) := Int.unsigned (Int.shru r (Int.repr 6)).
Definition bit_index (r : int) := Int.unsigned (Int.and r (Int.repr 63)).
Definition scan_bit (v : close_view) (i : Z) :=
  let r := Znth i (rows v) in
  Int64.and (Int64.shru' (Znth (word_index r) (syndrome v)) (Int.and r (Int.repr 63))) Int64.one.
Definition scan_ok v (lo hi : Z) :=
  forall i, lo <= i < hi -> scan_bit v i <> Int64.zero.
Definition width v := Zlength (parities v).
Definition differences v q :=
  map (fun p => Int64.xor (fst p) (snd p))
      (combine (parities v) (sublist (q*width v) ((q+1)*width v) (masks v))).
Definition close_result v q odd :=
 let lo := Znth q (offsets v) in let hi := Znth (q+1) (offsets v) in
 if Z.eq_dec (hi-lo) odd then
   if excluded_middle_informative (scan_ok v lo hi)
   then detected_value (differences v q) else Vint Int.zero
 else Vint Int.zero.

Definition close_mem sh s odd v : mpred :=
 (field_at sh level_type [StructField _cstart] (poff v) s *
  field_at sh level_type [StructField _nodd] (Vint (Int.repr odd)) s *
  field_at sh level_type [StructField _cr] (prows v) s *
  field_at sh level_type [StructField _syn] (psyn v) s *
  field_at sh level_type [StructField _kw] (Vint (Int.repr (width v))) s *
  field_at sh level_type [StructField _gmask] (pmasks v) s *
  field_at sh level_type [StructField _gpar] (ppar v) s *
  data_at sh (tarray tuint (Zlength (offsets v)))
    (map (fun z => Vint (Int.repr z)) (offsets v)) (poff v) *
  data_at sh (tarray tuint (Zlength (rows v))) (map Vint (rows v)) (prows v) *
  data_at sh (tarray tulong (Zlength (syndrome v))) (map Vlong (syndrome v)) (psyn v) *
  data_at sh (tarray tulong (Zlength (parities v))) (map Vlong (parities v)) (ppar v) *
  data_at sh (tarray tulong (Zlength (masks v))) (map Vlong (masks v)) (pmasks v))%logic.

Definition closes_spec : ident * funspec :=
 DECLARE _closes
 WITH s:val, sh:share, v:close_view, q:Z, odd:Z
 PRE [tptr level_type,tint]
 PROP (readable_share sh; 0<=q<Int.max_signed; q+1<Zlength (offsets v);
       0<=Znth q (offsets v)<=Znth (q+1) (offsets v);
       Znth (q+1) (offsets v)<=Zlength (rows v); Zlength (rows v)<=Int.max_unsigned;
       0<=odd<=Int.max_signed; 0<width v<=Int.max_signed;
       (q+1)*width v<=Zlength (masks v);
       forall i, Znth q (offsets v)<=i<Znth (q+1) (offsets v) ->
         word_index (Znth i (rows v))<Zlength (syndrome v))
 PARAMS(s;Vint(Int.repr q)) SEP(close_mem sh s odd v)
 POST [tint] PROP() RETURN(close_result v q odd) SEP(close_mem sh s odd v).

Definition ClosesGprog : funspecs := ltac:(with_library prog [closes_spec]).
Theorem body_closes : semax_body Vprog ClosesGprog f_closes closes_spec.
Proof.
  start_function. unfold close_mem. Intros.
  do 5 forward. forward_if.
  - forward. unfold close_mem. entailer!. unfold close_result.
    destruct (Z.eq_dec _ _) as [Eq | Ne]; [ | reflexivity].
    congruence.
  - forward_loop
      (EX i:Z, PROP (Znth q (offsets v)<=i<=Znth (q+1) (offsets v);
                      scan_ok v (Znth q (offsets v)) i)
        LOCAL (temp _s s; temp _q (Vint (Int.repr q)); temp _i (Vint (Int.repr i));
               temp _end (Vint (Int.repr (Znth (q+1) (offsets v)))))
        SEP (close_mem sh s odd v))%assert
    break: (PROP(scan_ok v (Znth q (offsets v)) (Znth (q+1) (offsets v)))
        LOCAL (temp _s s; temp _q (Vint (Int.repr q)))
        SEP (close_mem sh s odd v))%assert.
    + forward. Exists (Znth q (offsets v)). unfold close_mem. entailer!.
      unfold scan_ok; intros; lia.
    + Intros i. unfold close_mem. Intros. forward_if.
      * do 3 forward.
        pose proof (H7 i ltac:(lia)) as inword.
        unfold word_index in inword.
        assert (0 <= Int.unsigned (Int.shru (Znth i (rows v)) (Int.repr 6)) < Zlength (syndrome v)) by (split; [apply Int.unsigned_range | assumption]).
        forward.
        assert (0 <= Int.unsigned (Int.and (Znth i (rows v)) (Int.repr 63)) < 64) as shift.
        { split; [apply Int.unsigned_range | ].
          rewrite Int.and_commut. pose proof (Int.and_le (Int.repr 63) (Znth i (rows v))) as lim.
          change (Int.unsigned (Int.repr 63)) with 63 in lim; lia. }
        forward_if.
        -- entailer!.
           exact (proj2 shift).
        -- forward. unfold close_mem. entailer!. unfold close_result.
           destruct (Z.eq_dec _ _); [ | reflexivity].
           destruct (excluded_middle_informative _) as [allset|]; [ | reflexivity].
           exfalso; apply (allset i ltac:(lia)). unfold scan_bit, word_index.
           unfold Int64.shru', Int64.shru in *. rewrite Int64.unsigned_repr in H13 by rep_lia. exact H13.
        -- forward. Exists (i+1). unfold close_mem. entailer!.
           unfold scan_ok in *; intros j bounds.
           destruct (Z.eq_dec j i) as [-> | different].
           ++ unfold scan_bit, word_index, Int64.shru', Int64.shru in *.
              rewrite Int64.unsigned_repr in H13 by rep_lia. exact H13.
           ++ apply H10; lia.
      * assert (i = Znth (q+1) (offsets v)) by lia. subst i.
        forward. unfold close_mem. entailer!.
    + unfold close_mem. Intros. forward. forward. forward.
      assert_PROP (isptr (pmasks v)) as mask_ptr by entailer!.
      forward. simpl eval_cast. simpl eval_binop. simpl sem_binary_operation'. rewrite !Int.signed_repr by rep_lia.
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

      forward.
      forward_loop
       (EX j:Z, PROP (0<=j<=width v)
        LOCAL(temp _s s; temp _j (Vint (Int.repr j)); temp _g (offset_val (sizeof tulong * (q*width v)) (pmasks v));
              temp _acc (Vlong (parity_union (sublist 0 j (differences v q)))))
        SEP (close_mem sh s odd v))%assert
      break: (PROP() LOCAL(temp _acc (Vlong (parity_union (differences v q)))) SEP(close_mem sh s odd v))%assert.
      * Exists 0. unfold close_mem. entailer!.
      * Intros j. unfold close_mem. Intros.
        forward. forward_if.
        -- forward. unfold width in *. forward.
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
           forward.
           forward. forward. Exists (j+1). unfold close_mem, width in *. entailer!.
           rewrite (sublist_split 0 j (j+1)) by lia.
           rewrite (sublist_one j) by lia. rewrite parity_union_snoc.
           rewrite atdiff by lia. reflexivity.
        -- assert (j=width v) by lia. subst j. forward.
           unfold close_mem. rewrite <-diff_len. autorewrite with sublist. entailer!.
      * forward. unfold close_mem. entailer!. unfold close_result.
        destruct (Z.eq_dec _ _) as [eq|ne].
        -- destruct (excluded_middle_informative _) as [_|bad]; [ | contradiction].
           unfold detected_value. fold Int64.zero.
           destruct (Int64.eq (parity_union (differences v q)) Int64.zero); reflexivity.
        -- exfalso. apply ne. apply (f_equal Int.unsigned) in H8.
           rewrite !Int.unsigned_repr in H8 by rep_lia. exact H8.
Qed.
