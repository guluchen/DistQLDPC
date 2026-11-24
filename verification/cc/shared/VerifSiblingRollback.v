(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.zlist.list_solver.
Require Import ClightSelect level_ast VerifDetected SiblingCounters.

(* Select the for-loop from the compiler output, in the enclosing function's
   own type context. Failing to find its induction variable is a proof error. *)
Fixpoint find_counted (id:ident) (st:statement) : option statement :=
  match st with
  | Ssequence first following =>
    match first, following with
    | Sset idx _, Sloop _ _ => if Pos.eqb id idx then Some st else None
    | _, _ => match find_counted id first with
              | Some found => Some found | None => find_counted id following end
    end
  | _ => None
  end.
Definition native_undo : statement := ltac:(native_fragment (counts_on _i__1) f_dfs).
Lemma native_undo_source : find_counted _i__1 (fn_body f_dfs)=Some native_undo.
Proof. reflexivity. Qed.

Definition prefix_undo xs base i := sweep (-1) (sublist 0 i xs) (sweep 1 xs base).
Lemma undo_prefix_size xs base i : in_array (Zlength base) xs -> 0<=i<=Zlength xs ->
  Zlength (prefix_undo xs base i)=Zlength base.
Proof.
  intros range pos. unfold prefix_undo. rewrite sweep_size.
  - apply sweep_size;assumption.
  - rewrite sweep_size by assumption. apply Forall_sublist;exact range.
Qed.
Lemma undo_prefix_next xs base i : 0<=i<Zlength xs ->
  prefix_undo xs base (i+1)=adjust (-1) (prefix_undo xs base i) (Znth i xs).
Proof.
  intro valid;unfold prefix_undo,sweep.
  rewrite (sublist_split 0 i (i+1) xs) by lia.
  rewrite (sublist_one i) by lia. rewrite fold_left_app;reflexivity.
Qed.

Definition undo_mem s children bp xs base :=
  (field_at Tsh level_type [StructField _blk] bp s *
   data_at Tsh (tarray tuint (Zlength xs)) (map (fun q=>Vint (Int.repr q)) xs) children *
   data_at Tsh (tarray tuint (Zlength base)) (map Vint base) bp)%logic.
Definition undo_local s children len :=
   [temp _s s;temp _children children;temp _excluded (Vint (Int.repr len))].
Definition native_dfs_context := func_tycontext f_dfs Vprog [] [].

(* xs is exactly the excluded prefix of the children. The later array
   elements belong to the caller's frame. Counts include ancestor exclusions. *)
Theorem semax_native_undo {Espec:OracleKind} s children bp xs base :
  Zlength xs<=Int.max_signed -> Zlength base<=Int.max_unsigned ->
  in_array (Zlength base) xs ->
  semax native_dfs_context
    (PROPx nil (LOCALx (undo_local s children (Zlength xs))
       (SEPx [undo_mem s children bp xs (sweep 1 xs base)])))
    native_undo
    (normal_ret_assert (PROPx nil (LOCALx (undo_local s children (Zlength xs))
       (SEPx [undo_mem s children bp xs base])))).
Proof.
  intros bounded capacity range.
  pose proof (Zlength_nonneg xs) as nonnegative.
  unfold native_dfs_context,native_undo,undo_local. abbreviate_semax.
  forward_for_simple_bound (Zlength xs)
    (EX i:Z, PROP(0<=i<=Zlength xs) LOCAL(temp _s s;temp _children children;temp _excluded (Vint (Int.repr (Zlength xs))))
      SEP(undo_mem s children bp xs (prefix_undo xs base i))).
  - try forward;try (Exists 0);unfold prefix_undo;rewrite ?sublist_nil by lia;entailer!;apply derives_refl.
  - unfold undo_mem. Intros. pose proof (@undo_prefix_size xs base i range ltac:(lia)) as oldlen.
    assert (valid:0<=Znth i xs<Zlength base).
    { apply Forall_forall with (x:=Znth i xs) in range;[exact range|apply Znth_In;lia]. }
    assert (u:Int.unsigned (Int.repr (Znth i xs))=Znth i xs) by (apply Int.unsigned_repr;lia).
    do 5 forward. forward. unfold undo_mem.
    rewrite undo_prefix_next by lia. unfold adjust.
    rewrite upd_Znth_Zlength,upd_Znth_map by lia.
    rewrite decrement_word,?u;entailer!.
  - unfold prefix_undo. rewrite sublist_same by lia. rewrite rollback_siblings by assumption.
    entailer!.
Qed.
