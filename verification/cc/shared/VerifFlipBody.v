(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto.
Require Import level_ast VerifDetected VerifClosesBody ClosureWord VerifToggleBody.

Definition policy_type := Tstruct _cc_level_policy noattr.
Lemma owner_valid p : field_at_ Tsh policy_type [StructField _owner] p |-- valid_pointer p.
Proof. apply field_at_valid_ptr0; [auto | simpl; lia | reflexivity]. Qed.
#[local] Hint Resolve owner_valid : valid_pointer.
Inductive row_policy :=
| Bare
| NoRedundant (policy : val)
| WithRedundant (policy starts row_data : val) (ofs : list Z) (rs : list int).

Definition policy_ptr spec :=
  match spec with Bare => nullval | NoRedundant p | WithRedundant p _ _ _ _ => p end.
Definition policy_storage spec : mpred :=
  match spec with
  | Bare => emp
  | NoRedundant p => (field_at_ Tsh policy_type [StructField _owner] p *
                      field_at Tsh policy_type [StructField _redundant_start] nullval p)%logic
  | WithRedundant p starts rp os rs =>
    (field_at_ Tsh policy_type [StructField _owner] p *
     field_at Tsh policy_type [StructField _redundant_start] starts p *
     field_at Tsh policy_type [StructField _redundant_rows] rp p *
     data_at Tsh (tarray tuint (Zlength os)) (map (fun z => Vint (Int.repr z)) os) starts *
     data_at Tsh (tarray tuint (Zlength rs)) (map Vint rs) rp)%logic
  end.
Definition extra_bounds spec q words :=
  match spec with WithRedundant _ _ _ os rs =>
    q+1 < Zlength os /\
    0 <= Znth q os <= Znth (q+1) os /\
    Znth (q+1) os <= Zlength rs /\ Zlength rs <= Int.max_unsigned /\
    forall i, Znth q os <= i < Znth (q+1) os -> word_index (Znth i rs) < words
  | _ => True end.
Definition extra_step (syn : list int64) (r : int) :=
  fst (sparse_flip (syn,0) r).
Definition extra_sweep syn os rs q i :=
  fold_left extra_step (sublist (Znth q os) i rs) syn.
Definition after_extra spec q syn :=
  match spec with WithRedundant _ _ _ os rs => extra_sweep syn os rs q (Znth (q+1) os)
  | _ => syn end.
Definition after_primary v q odd := flipped v q odd (Znth (q+1) (offsets v)).

Lemma extra_next syn os rs q i :
  0 <= Znth q os <= i -> i < Zlength rs ->
  extra_sweep syn os rs q (i+1) = extra_step (extra_sweep syn os rs q i) (Znth i rs).
Proof.
  intros. unfold extra_sweep. rewrite (sublist_split _ i (i+1)) by lia.
  rewrite (sublist_one i), fold_left_app by lia. reflexivity.
Qed.

Lemma extra_length syn os rs q i :
  Zlength (extra_sweep syn os rs q i) = Zlength syn.
Proof.
  unfold extra_sweep. generalize (sublist (Znth q os) i rs).
  intros extra; revert syn. induction extra as [|r tail IH]; intros; [reflexivity|simpl].
  rewrite IH. unfold extra_step, sparse_flip; cbn [fst].
  destruct (Z_lt_dec (word_index r) (Zlength syn)).
  - apply upd_Znth_Zlength; split; [apply Int.unsigned_range | assumption].
  - rewrite upd_Znth_out_of_range by lia; reflexivity.
Qed.

Definition flip_spec : ident * funspec :=
 DECLARE _flip
 WITH s:val, keys:val, v:close_view, colkeys:list int64, q:Z, odd:Z, hash:int64, policy:row_policy
 PRE [tptr level_type,tptr policy_type,tint]
 PROP (0<=q<Int.max_signed; q+1<Zlength (offsets v); q<Zlength colkeys;
       0<=Znth q (offsets v)<=Znth (q+1) (offsets v);
       Znth (q+1) (offsets v)<=Zlength (rows v); Zlength (rows v)<=Int.max_unsigned;
       Int.min_signed<=odd<=Int.max_signed; 0<width v<=Int.max_signed;
       (q+1)*width v<=Zlength (masks v);
       forall i, Znth q (offsets v)<=i<Znth (q+1) (offsets v) ->
         word_index (Znth i (rows v))<Zlength (syndrome v);
       forall i, Znth q (offsets v)<=i<Znth (q+1) (offsets v) ->
         Int.min_signed < snd (flipped v q odd i) < Int.max_signed;
       extra_bounds policy q (Zlength (syndrome v)))
 PARAMS(s;policy_ptr policy;Vint(Int.repr q))
 SEP(toggle_mem s keys v odd hash colkeys (syndrome v) (parities v);policy_storage policy)
 POST [tvoid] PROP() RETURN()
 SEP(toggle_mem s keys v (snd (after_primary v q odd))
    (Int64.xor hash (Znth q colkeys)) colkeys
    (after_extra policy q (fst (after_primary v q odd))) (differences v q);
    policy_storage policy).

Definition FlipGprog : funspecs := ltac:(with_library prog [toggle_spec;flip_spec]).

Theorem body_flip : semax_body Vprog FlipGprog f_flip flip_spec.
Proof.
  start_function. forward_call (s,keys,v,colkeys,q,odd,hash).
  fold (after_primary v q odd).
  destruct policy as [|p|p starts rp os rs]; cbn [policy_ptr policy_storage after_extra] in *.
  - apply semax_if_seq. forward_if; [contradiction|forward].
    forward_if; [contradiction|forward]. entailer!.
  - Intros. assert_PROP (isptr p) as owner_ptr by entailer!.
    apply semax_if_seq. forward_if.
    + forward. forward. forward_if; [contradiction|forward]. entailer!.
    + subst p; contradiction.
  - Intros. destruct H10 as [indices [ordered [bound [limit addressed]]]].
    assert_PROP (isptr p) as owner_ptr by entailer!.
    assert_PROP (isptr starts) as array_ptr by entailer!.
    apply semax_if_seq. forward_if; [|subst p; contradiction]. forward. forward.
    assert (cast_true : sem_cast_l2bool starts = Some Vtrue).
    { destruct starts; try contradiction; reflexivity. }
    forward_if; [|rewrite cast_true in H11; discriminate]. do 2 forward.
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
