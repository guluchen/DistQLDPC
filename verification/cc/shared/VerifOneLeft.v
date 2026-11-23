(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.floyd.reassoc_seq.
Require Import level_ast VerifDetected VerifClosesBody HashLookup VerifLookup VerifClosedPrefix.

Definition one_left_fields s bp cp w (budgets:list int64) (path:list int)
  (nodes leaves:int64) (saved:int) : mpred :=
 (field_at Tsh level_type [StructField _nodes] (Vlong nodes) s *
  field_at Tsh level_type [StructField _by_budget] bp s *
  data_at Tsh (tarray tulong (Zlength budgets)) (map Vlong budgets) bp *
  field_at Tsh level_type [StructField _w] (Vint (Int.repr w)) s *
  field_at Tsh level_type [StructField _poll] nullval s *
  field_at Tsh level_type [StructField _leaf1] (Vlong leaves) s *
  field_at Tsh level_type [StructField _witness_size] (Vint saved) s *
  field_at Tsh level_type [StructField _cur] cp s *
  data_at Tsh (tarray tint (Zlength path)) (map Vint path) cp)%logic.

Lemma chain_answer_range b v odd q a : book_safe b v odd ->
  chain_run b v odd q a -> q<Zlength (keys b) -> -1<=a<Zlength (keys b).
Proof.
  intros safe trace; induction trace;intro bound.
  - pose proof (Zlength_nonneg (keys b));lia.
  - lia.
  - apply IHtrace. apply (proj2 (next_index _ _ _ safe q ltac:(rewrite (next_length _ _ _ safe);lia))).
Qed.

Lemma lookup_answer_range b v odd i a : book_safe b v odd ->
  probe_run b v odd i a -> 0<=Int64.unsigned i<Zlength (slots b) -> -1<=a<Zlength (keys b).
Proof.
  intros safe trace;induction trace; intro within.
  - pose proof (Zlength_nonneg (keys b));lia.
  - eapply chain_answer_range;[exact safe|eassumption|]. unfold slot.
    exact (proj2 (head_index _ _ _ safe _ within)).
  - apply IHtrace. unfold advance. apply within_mask;exact (table_mask_bound _ _ _ safe).
Qed.

Definition final_pick (a:Z) := if Z_lt_dec a 0 then 0 else 1.
Definition last_path (depth a:Z) (path:list int) :=
  if Z_lt_dec a 0 then path else upd_Znth depth path (Int.repr a).
Definition last_size (w a:Z) (saved:int) :=
  if Z_lt_dec a 0 then saved else Int.repr w.

Definition dfs_one_spec : ident * funspec :=
 DECLARE _dfs
 WITH s:val,bp:val,cp:val,p:lookup_ptrs,b:lookup_data,v:close_view,odd:Z,a:Z,
   depth:Z,budgets:list int64,path:list int,nodes:int64,leaves:int64,saved:int
 PRE [tptr level_type,tptr (Tstruct _cc_level_policy noattr),tint]
   PROP (1<=depth<Int.max_signed;0<odd<=Int.max_signed;
     1<Zlength budgets;depth<Zlength path;
     book_safe b v odd; probe_run b v odd (origin b) a)
   PARAMS (s;nullval;Vint (Int.repr depth))
   SEP (one_left_fields s bp cp (depth+1) budgets path nodes leaves saved;
     close_mem Tsh s odd v;book_mem s b p)
 POST [tint] PROP () RETURN (Vint (Int.repr (final_pick a)))
   SEP (one_left_fields s bp cp (depth+1) (bump budgets 1) (last_path depth a path)
     (Int64.add nodes Int64.one) (Int64.add leaves Int64.one) (last_size (depth+1) a saved);
     close_mem Tsh s odd v;book_mem s b p).
Definition OneGprog : funspecs := ltac:(with_library prog [lookup_spec;dfs_one_spec]).

Theorem body_dfs_one_left : semax_body Vprog OneGprog f_dfs dfs_one_spec.
Proof.
  start_function.
  assert (at_origin: 0<=Int64.unsigned (origin b)<Zlength (slots b)).
  { unfold origin; apply within_mask; eapply table_mask_bound; eassumption. }
  pose proof (@lookup_answer_range b v odd (origin b) a ltac:(assumption) ltac:(assumption) at_origin) as R.
  pose proof (@qubits_fit b v odd ltac:(assumption)) as N.
  unfold one_left_fields,close_mem. Intros.
  do 9 (forward;try solve [entailer!]).
  replace (depth+1-depth) with 1 in * by lia.
  apply semax_if_seq. forward_if;[contradiction|forward].
  apply semax_if_seq. forward_if;[contradiction|forward].
  apply semax_if_seq. forward_if;[contradiction|].
  forward. apply semax_if_seq. forward_if;[rep_lia|].
  assert (nonzero:Int.repr odd<>Int.zero).
  { intro bad;apply (f_equal Int.unsigned) in bad. rewrite Int.unsigned_repr in bad by rep_lia;
    change (odd=0) in bad;lia. }
  forward. apply semax_if_seq. forward_if;[congruence|]. reassoc_seq.
  apply semax_if_seq. forward_if;[contradiction|forward].
  apply semax_if_seq. forward_if;[contradiction|forward].
  apply semax_if_seq. forward_if;[contradiction|].
  assert (last : Int.sub (Int.repr (depth+1)) (Int.repr 1)=Int.repr depth).
  { unfold Int.sub;rewrite !Int.unsigned_repr by rep_lia;f_equal;lia. }
  forward. apply semax_if_seq. forward_if;[|solve [congruence|rep_lia]].
  forward. forward. forward_call (s,p,b,v,odd,a).
  { unfold close_mem;entailer!. }
  reassoc_seq. apply semax_if_seq. forward_if.
  - forward. unfold final_pick,one_left_fields,last_path,last_size,bump.
    destruct (Z_lt_dec a 0);[|rep_lia].
    rewrite upd_Znth_Zlength by lia. entailer!. rewrite upd_Znth_map; apply derives_refl.
  - forward. forward. forward. forward.
    unfold final_pick,one_left_fields,last_path,last_size,bump.
    destruct (Z_lt_dec a 0);[rep_lia|].
    rewrite !upd_Znth_Zlength by lia. entailer!.
    rewrite !upd_Znth_map;apply derives_refl.
Qed.
