(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto.
Require Import level_ast VerifDetected VerifClosesBody HashLookup.

Record lookup_ptrs := {
  pt : val; pn : val; pb : val; pk : val
}.
Definition book_mem s b ptr : mpred :=
 (field_at Tsh level_type [StructField _htab] (pt ptr) s *
  field_at Tsh level_type [StructField _hnext] (pn ptr) s *
  field_at Tsh level_type [StructField _blk] (pb ptr) s *
  field_at Tsh level_type [StructField _colkey] (pk ptr) s *
  field_at Tsh level_type [StructField _hmask] (Vlong (mask b)) s *
  field_at Tsh level_type [StructField _synkey] (Vlong (query b)) s *
  data_at Tsh (tarray tint (Zlength (slots b))) (map (fun x => Vint (Int.repr x)) (slots b)) (pt ptr) *
  data_at Tsh (tarray tint (Zlength (links b))) (map (fun x => Vint (Int.repr x)) (links b)) (pn ptr) *
  data_at Tsh (tarray tuint (Zlength (blocked b))) (map Vint (blocked b)) (pb ptr) *
  data_at Tsh (tarray tulong (Zlength (keys b))) (map Vlong (keys b)) (pk ptr))%logic.

Definition close_safe v q odd :=
  0<=q<Int.max_signed /\ q+1<Zlength (offsets v) /\
  0<=Znth q (offsets v)<=Znth (q+1) (offsets v) /\
  Znth (q+1) (offsets v)<=Zlength (rows v) /\ Zlength (rows v)<=Int.max_unsigned /\
  0<=odd<=Int.max_signed /\ 0<width v<=Int.max_signed /\
  (q+1)*width v<=Zlength (masks v) /\
  forall i, Znth q (offsets v)<=i<Znth (q+1) (offsets v) ->
     word_index (Znth i (rows v))<Zlength (syndrome v).

Record book_safe b v odd : Prop := {
 table_mask_bound : Int64.unsigned (mask b)<Zlength (slots b);
 qubits_fit : Zlength (keys b)<=Int.max_signed;
 next_length : Zlength (links b)=Zlength (keys b);
 block_length : Zlength (blocked b)=Zlength (keys b);
 head_index : forall j, 0<=j<Zlength (slots b) -> -1<=Znth j (slots b)<Zlength (keys b);
 next_index : forall q, 0<=q<Zlength (links b) -> -1<=Znth q (links b)<Zlength (keys b);
 column_safe : forall q, 0<=q<Zlength (keys b) -> close_safe v q odd
}.

Definition lookup_spec : ident * funspec :=
 DECLARE _closing_qubit
 WITH s:val, ptr:lookup_ptrs, b:lookup_data, v:close_view, odd:Z, answer:Z
 PRE [tptr level_type]
 PROP(book_safe b v odd; probe_run b v odd (origin b) answer)
 PARAMS(s) SEP(close_mem Tsh s odd v; book_mem s b ptr)
 POST [tint] PROP() RETURN(Vint (Int.repr answer)) SEP(close_mem Tsh s odd v; book_mem s b ptr).
Definition LookupGprog : funspecs := ltac:(with_library prog [closes_spec;lookup_spec]).

Lemma within_mask b i : Int64.unsigned (mask b)<Zlength (slots b) ->
   0<= Int64.unsigned (Int64.and i (mask b)) < Zlength (slots b).
Proof.
  intros. split; [apply Int64.unsigned_range |].
  rewrite Int64.and_commut. pose proof (Int64.and_le (mask b) i);lia.
Qed.

Theorem body_closing_qubit : semax_body Vprog LookupGprog f_closing_qubit lookup_spec.
Proof.
  start_function. destruct H as [cap limit len_next len_block head next closable].
  unfold book_mem. Intros. do 3 forward.
  forward_loop
    (EX i:int64, PROP(0<=Int64.unsigned i<Zlength (slots b); probe_run b v odd i answer)
       LOCAL(temp _s s;temp _i (Vlong i))
       SEP(close_mem Tsh s odd v;book_mem s b ptr))%assert.
  - Exists (origin b). unfold book_mem,origin. entailer!. apply within_mask;assumption.
  - Intros i. unfold book_mem. Intros. forward.
    rewrite <- (Int64.repr_unsigned i) at 1.
    forward.
    pose proof (head (Int64.unsigned i) ltac:(lia)) as Hhead.
    fold (slot b i) in *. change (-1<=slot b i<Zlength (keys b)) in Hhead.
    repeat rewrite <- seq_assoc. apply semax_if_seq. forward_if.
    + assert (answer = -1).
      { match goal with T : probe_run _ _ _ i answer |- _ => inversion T; subst; try lia; reflexivity end. }
      subst answer. forward. unfold book_mem. entailer!.
    + do 3 forward. apply semax_if_seq. forward_if.
      * assert (trace : chain_run b v odd (slot b i) answer).
        { pose proof (Int64.eq_spec (Znth (slot b i) (keys b)) (query b)) as same.
          rewrite H3 in same. eapply probe_at_match; eauto;lia. }
        forward. forward_loop
         (EX q:Z, PROP(-1<=q<Zlength (keys b); chain_run b v odd q answer)
          LOCAL(temp _s s;temp _q (Vint (Int.repr q)))
          SEP(close_mem Tsh s odd v;book_mem s b ptr))%assert
        break: (PROP(answer = -1) LOCAL()
          SEP(close_mem Tsh s odd v;book_mem s b ptr))%assert.
        -- Exists (slot b i). unfold book_mem. entailer!.
        -- Intros q. unfold book_mem. Intros. forward_if.
           ++ forward. forward. forward_if
                (PROP() LOCAL(temp _s s;temp _q (Vint (Int.repr q));
                  temp _t'1 (Vint (if ClassicalDescription.excluded_middle_informative (usable b v odd q)
                                    then Int.one else Int.zero)))
                  SEP(close_mem Tsh s odd v;book_mem s b ptr))%assert.
              ** pose proof (closable q ltac:(lia)) as params.
                 unfold close_safe in params; decompose [and] params; clear params.
                 forward_call (s,Tsh,v,q,odd). forward. unfold book_mem. entailer!.
                 destruct (closes_boolean v q odd) as [dark|lit];
                 destruct (ClassicalDescription.excluded_middle_informative (usable b v odd q)) as [ok|no];
                 unfold usable in *; rewrite ?dark, ?lit in *; simpl in *; intuition congruence.
              ** forward. unfold book_mem. entailer!.
                 destruct (ClassicalDescription.excluded_middle_informative (usable b v odd q)) as [[zero _]|].
                 { exfalso; apply H7; exact zero. } reflexivity.
              ** apply semax_if_seq. forward_if.
                 --- assert (answer=q).
                     { match goal with T: chain_run _ _ _ q answer |- _ => inversion T; subst; try lia end.
                       destruct (ClassicalDescription.excluded_middle_informative (usable b v odd q)); intuition congruence. }
                     subst answer. forward; entailer!.
                 --- assert (sub: chain_run b v odd (Znth q (links b)) answer).
                     { eapply chain_at_miss; [eassumption|lia|]. intro yes.
                       destruct (ClassicalDescription.excluded_middle_informative (usable b v odd q));
                         try contradiction; discriminate. }
                     unfold book_mem. Intros. forward. forward. Exists (Znth q (links b)).
                     unfold book_mem. entailer!;apply next;lia.
           ++ assert (answer= -1).
              { match goal with T: chain_run _ _ _ q answer |- _ => inversion T;subst;lia end. }
              forward. unfold book_mem. entailer!.
        -- forward; entailer!.
      * assert (route: probe_run b v odd (advance b i) answer).
        { eapply probe_at_miss; eauto; lia. }
        forward. forward. Exists (advance b i). unfold book_mem,advance. entailer!; apply within_mask;assumption.
Qed.
