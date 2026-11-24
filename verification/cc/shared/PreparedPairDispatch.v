(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.floyd.reassoc_seq.
Require Import ClightSelect VerifDetected PackedDetector VerifPackedDetector VerifClosesBody
 HashLookup VerifLookup VerifOneLeft LeafAPI VerifLastPair VerifLastPairClosed PreparedSeedDispatch.
Require flag_level_ast.
Import flag_level_ast.
#[local] Existing Instance VerifDetected.CompSpecs.

Definition prepared_pair : statement := ltac:(native_fragment dispatch_read f_dfs).
Lemma prepared_pair_source : find_dispatch (fn_body f_dfs)=Some prepared_pair.
Proof. reflexivity. Qed.
Definition PairG : funspecs := ltac:(with_library prog [lookup_spec;detected_spec]).
Definition pair_delta := func_tycontext f_dfs prepared_vars PairG [].

Theorem prepared_pair_open {Espec:OracleKind} accept s cp p b v odd qs path leaves saved depth :
  1<=depth<=Int.max_signed-2 -> depth+1<Zlength path -> 0<odd<=Int.max_signed ->
  book_safe b v odd -> leaf_image accept b v odd qs ->
  semax pair_delta
   (PROP() LOCAL(temp _s s;temp _size (Vint (Int.repr depth));temp _result (Vint Int.zero))
    SEP(pair_fields s cp (depth+2) path leaves saved;close_mem Tsh s odd v;book_mem s b p))
   prepared_pair
   (normal_ret_assert (EX a:Z, PROP(leaf_answer accept (extent b) a)
     LOCAL(temp _s s;temp _size (Vint (Int.repr depth));temp _result (Vint (Int.repr (final_pick a))))
     SEP(pair_fields s cp (depth+2) (last_path (depth+1) a path) (Int64.add leaves Int64.one)
              (last_size (depth+2) a saved);close_mem Tsh s odd v;book_mem s b p))) .
Proof.
  intros fits pathlong oddok safe physical.
  destruct (@checked_answer accept b v odd qs safe physical) as [a [run ok]].
  pose proof (@qubits_fit b v odd safe) as cap.
  pose proof (@lookup_answer_range b v odd (origin b) a safe run
    (within_mask _ _ (table_mask_bound _ _ _ safe))) as arange.
  assert (nonzero:Int.repr odd<>Int.zero).
  { intro bad;apply (f_equal Int.unsigned) in bad;rewrite Int.unsigned_repr in bad by rep_lia;
    change (odd=0) in bad;lia. }
  pose proof (subtract_two depth fits) as same.
  unfold pair_delta;abbreviate_semax. unfold prepared_pair,pair_fields,close_mem;Intros.
  forward. forward_if;try solve [entailer!;rep_lia|rep_lia|congruence].
  forward. forward_if;try solve [entailer!;rep_lia|rep_lia|congruence].
  forward;forward;forward_call (s,p,b,v,odd,a).
  { unfold close_mem;entailer!. }
  forward_if.
  - do 4 forward. Exists a;unfold pair_fields,last_path,last_size,final_pick.
    destruct (Z_lt_dec a 0);[rep_lia|]. rewrite upd_Znth_Zlength by lia.
    entailer!;rewrite upd_Znth_map;apply derives_refl.
  - forward;Exists a;unfold pair_fields,last_path,last_size,final_pick.
    destruct (Z_lt_dec a 0);[|rep_lia];entailer!.
Qed.

(* A closure after the first of two moves produces a shorter witness.
   The native enum value is INCONSISTENT, which forces the driver to
   revisit its lower bound. A stabilizer leaves the result EMPTY. *)
Theorem prepared_pair_closed {Espec:OracleKind} s par words closed saved depth :
  1<=depth<=Int.max_signed-2 -> Zlength words<=Int.max_signed ->
  semax pair_delta
   (PROP() LOCAL(temp _s s;temp _size (Vint (Int.repr depth));temp _result (Vint Int.zero))
    SEP(pair_closed_fields s (depth+2) par words closed saved))
   prepared_pair
   (normal_ret_assert (PROP() LOCAL(temp _s s;temp _size (Vint (Int.repr depth));
       temp _result (Vint (Int.repr (if packed_detects words then 3 else 0))))
    SEP(pair_closed_fields s (depth+2) par words (Int64.add closed Int64.one)
      (if packed_detects words then Int.repr (depth+1) else saved)))).
Proof.
  intros fits len;pose proof (subtract_two depth fits) as same.
  unfold pair_delta,prepared_pair,pair_closed_fields;abbreviate_semax. Intros.
  forward. forward_if;try solve [entailer!;rep_lia|rep_lia|congruence].
  forward. forward_if;try solve [exfalso;apply H0;reflexivity|entailer!;rep_lia|rep_lia|congruence].
  forward. forward. forward_call (s,par,words,Tsh).
  rewrite detected_return_bits. destruct (packed_detects words) eqn:Hres.
  - forward_if;try solve [contradiction|discriminate].
    forward;forward;try unfold pair_closed_fields;rewrite ?Hres;entailer!.
  - forward_if;try solve [contradiction|discriminate].
    forward;try unfold pair_closed_fields;rewrite ?Hres;entailer!.
Qed.
