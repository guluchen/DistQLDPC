(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto.
Require Import VerifDetected VerifClosesBody ClosureWord VerifToggleBody VerifFlipBody PreparedSeedDispatch.
Require flag_level_ast.
Import flag_level_ast.

Definition policy_storage (spec:row_policy) : mpred :=
 match spec with
 | WithRedundant p starts rp os rs =>
  (field_at Tsh policy_type [StructField _redundant_start] starts p *
   field_at Tsh policy_type [StructField _redundant_rows] rp p *
   data_at Tsh (tarray tuint (Zlength os)) (map (fun z=>Vint (Int.repr z)) os) starts *
   data_at Tsh (tarray tuint (Zlength rs)) (map Vint rs) rp)%logic
 | _=>emp end.
Definition redundant_option (bits:int) (spec:row_policy):Prop :=
 match spec with WithRedundant _ _ _ _ _=>Int.and bits (Int.repr 4)<>Int.zero
 | _=>Int.and bits (Int.repr 4)=Int.zero end.

Definition flip_spec : ident * funspec :=
 DECLARE _flip
 WITH s:val, keys:val, v:close_view, colkeys:list int64, q:Z, odd:Z, hash:int64, policy:row_policy,bits:int
 PRE [tptr level_type,tptr policy_type,tint,tuint]
 PROP (0<=q<Int.max_signed; q+1<Zlength (offsets v); q<Zlength colkeys;
       0<=Znth q (offsets v)<=Znth (q+1) (offsets v);
       Znth (q+1) (offsets v)<=Zlength (rows v); Zlength (rows v)<=Int.max_unsigned;
       Int.min_signed<=odd<=Int.max_signed; 0<width v<=Int.max_signed;
       (q+1)*width v<=Zlength (masks v);
       forall i, Znth q (offsets v)<=i<Znth (q+1) (offsets v) ->
         word_index (Znth i (rows v))<Zlength (syndrome v);
       forall i, Znth q (offsets v)<=i<Znth (q+1) (offsets v) ->
         Int.min_signed < snd (flipped v q odd i) < Int.max_signed;
       extra_bounds policy q (Zlength (syndrome v));redundant_option bits policy)
 PARAMS(s;policy_ptr policy;Vint(Int.repr q);Vint bits)
 SEP(toggle_mem s keys v odd hash colkeys (syndrome v) (parities v);policy_storage policy)
 POST [tvoid] PROP() RETURN()
 SEP(toggle_mem s keys v (snd (after_primary v q odd))
    (Int64.xor hash (Znth q colkeys)) colkeys
    (after_extra policy q (fst (after_primary v q odd))) (differences v q);
    policy_storage policy).

Definition FlipGprog : funspecs := ltac:(with_library prog [toggle_spec;flip_spec]).

Theorem body_flip : semax_body prepared_vars FlipGprog f_flip flip_spec.
Proof.
  start_function. forward_call (s,keys,v,colkeys,q,odd,hash).
  fold (after_primary v q odd).
  destruct policy as [|p|p starts rp os rs];cbn [policy_ptr policy_storage redundant_option after_extra] in *.
  - forward_if;[congruence|forward];entailer!.
  - forward_if;[congruence|forward];entailer!.
  - Intros. match goal with H:extra_bounds _ _ _ |- _=>destruct H as [indices [ordered [bound [limit addressed]]]] end.
    forward_if;[|congruence]. do 2 forward.
    set (syn0 := fst (after_primary v q odd)).
    assert (words : Zlength syn0 = Zlength (syndrome v)) by apply flip_length.
    forward_loop
      (EX i:Z, PROP(Znth q os<=i<=Znth (q+1) os)
       LOCAL(temp _s s; temp _policy p;temp _q (Vint (Int.repr q));temp _i (Vint (Int.repr i)))
       SEP(toggle_mem s keys v (snd (after_primary v q odd)) (Int64.xor hash (Znth q colkeys))
             colkeys (extra_sweep syn0 os rs q i) (differences v q);
           policy_storage (WithRedundant p starts rp os rs)))%assert
    break: (PROP() LOCAL()
       SEP(toggle_mem s keys v (snd (after_primary v q odd)) (Int64.xor hash (Znth q colkeys))
             colkeys (extra_sweep syn0 os rs q (Znth (q+1) os)) (differences v q);
           policy_storage (WithRedundant p starts rp os rs)))%assert.
    + Exists (Znth q os). unfold extra_sweep; rewrite sublist_nil by lia.
      cbn [fold_left policy_storage]. entailer!.
    + Intros i. unfold policy_storage, toggle_mem. Intros. forward. forward. forward_if.
      * do 4 forward.
        assert (wi: 0 <= word_index (Znth i rs) < Zlength (extra_sweep syn0 os rs q i)).
        { rewrite extra_length,words. split; [apply Int.unsigned_range|apply addressed;lia]. }
        unfold word_index in wi. forward.
        assert (shift : 0 <= bit_index (Znth i rs) < 64).
        { rewrite csr_bit_index; apply Z.mod_pos_bound; lia. }
        unfold bit_index in shift. forward.
        { entailer!. exact (proj2 shift). }
        forward. Exists (i+1). unfold policy_storage,toggle_mem.
        rewrite extra_next by lia. unfold extra_step, sparse_flip; cbn [fst].
        rewrite upd_Znth_Zlength,upd_Znth_map by (unfold word_index;lia). entailer!.
      * assert (i=Znth (q+1) os) by lia. subst i. forward. unfold toggle_mem,policy_storage. entailer!.
    + unfold policy_storage. entailer!. apply derives_refl.
Qed.
