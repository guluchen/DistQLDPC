(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.floyd.reassoc_seq.
Require Import ClightSelect level_ast VerifDetected VerifPackedDetector VerifClosesBody
  HashLookup VerifLookup VerifOneLeft LeafAPI.

(* Locate the dispatch that reads w and tests size == w-2. Select the
   generated guard and both arms, not a paraphrase of the optimized loop. *)
Definition dispatch_read (st:statement) : bool :=
  match st with
  | Ssequence (Sset t (Efield _ field _))
       (Sifthenelse (Ebinop Oeq (Etempvar size _) (Ebinop Osub (Etempvar via _) (Econst_int two _) _) _) _ _) =>
    Pos.eqb field _w && Pos.eqb size _size && Pos.eqb t via && Int.eq two (Int.repr 2)
  | _ => false end.
Fixpoint find_dispatch (s:statement) : option statement :=
 if dispatch_read s then Some s else
 match s with
 | Ssequence l r | Sloop l r | Sifthenelse _ l r =>
   match find_dispatch l with Some v=>Some v|None=>find_dispatch r end
 | _=>None end.
Definition native_dispatch : statement := ltac:(native_fragment dispatch_read f_dfs).
Lemma native_dispatch_source : find_dispatch (fn_body f_dfs)=Some native_dispatch.
Proof. reflexivity. Qed.

Definition pair_fields s cp w path leaves saved : mpred :=
 (field_at Tsh level_type [StructField _w] (Vint (Int.repr w)) s *
  field_at Tsh level_type [StructField _cur] cp s *
  data_at Tsh (tarray tint (Zlength path)) (map Vint path) cp *
  field_at Tsh level_type [StructField _leaf2] (Vlong leaves) s *
  field_at Tsh level_type [StructField _witness_size] (Vint saved) s)%logic.
Definition PairGprog : funspecs := ltac:(with_library prog [lookup_spec;detected_spec]).
Definition pair_context := func_tycontext f_dfs Vprog PairGprog [].
Lemma subtract_two d : 1<=d<=Int.max_signed-2 ->
 Int.sub (Int.repr (d+2)) (Int.repr 2)=Int.repr d.
Proof. intro ok;unfold Int.sub;rewrite !Int.unsigned_repr by rep_lia;f_equal;lia. Qed.

Theorem semax_last_pair_open {Espec:OracleKind} accept s cp p b v odd qs path leaves saved depth :
  1<=depth<=Int.max_signed-2 -> depth+1<Zlength path -> 0<odd<=Int.max_signed ->
  book_safe b v odd -> leaf_image accept b v odd qs ->
  semax pair_context
   (PROP() LOCAL(temp _s s;temp _size (Vint (Int.repr depth));temp _result (Vint Int.zero))
    SEP(pair_fields s cp (depth+2) path leaves saved;close_mem Tsh s odd v;book_mem s b p))
   native_dispatch
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
  unfold pair_context;abbreviate_semax. unfold native_dispatch,pair_fields,close_mem;Intros.
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
