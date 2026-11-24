(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.floyd.reassoc_seq.
Require flag_level_ast.
Require Import PreparedSeedDispatch VerifOneLeft VerifDetected VerifClosesBody HashLookup VerifLookup VerifClosedPrefix.
Import flag_level_ast.

Definition one_left_fields s bp cp w (budgets:list int64) (path:list int)
  (nodes leaves:int64) (saved:int) : mpred :=
 (field_at Tsh level_type [StructField _nodes] (Vlong nodes) s *
  field_at Tsh level_type [StructField _by_budget] bp s *
  data_at Tsh (tarray tulong (Zlength budgets)) (map Vlong budgets) bp *
  field_at Tsh level_type [StructField _w] (Vint (Int.repr w)) s *
  field_at Tsh level_type [StructField _leaf1] (Vlong leaves) s *
  field_at Tsh level_type [StructField _witness_size] (Vint saved) s *
  field_at Tsh level_type [StructField _cur] cp s *
  data_at Tsh (tarray tint (Zlength path)) (map Vint path) cp)%logic.

Definition dfs_one_spec : ident * funspec :=
 DECLARE _dfs
 WITH s:val,bp:val,cp:val,p:lookup_ptrs,b:lookup_data,v:close_view,odd:Z,a:Z,
   depth:Z,budgets:list int64,path:list int,nodes:int64,leaves:int64,saved:int,policy:val,bits:int
 PRE [tptr level_type,tptr (Tstruct _cc_level_policy noattr),tint,tuint]
   PROP (1<=depth<Int.max_signed;0<odd<=Int.max_signed;
     1<Zlength budgets;depth<Zlength path;
     book_safe b v odd; probe_run b v odd (origin b) a;is_pointer_or_null policy;
     Int.and bits (Int.repr 2)=Int.zero;Int.and bits (Int.repr 8)=Int.zero)
   PARAMS (s;policy;Vint (Int.repr depth);Vint bits)
   SEP (one_left_fields s bp cp (depth+1) budgets path nodes leaves saved;
     close_mem Tsh s odd v;book_mem s b p)
 POST [tint] PROP () RETURN (Vint (Int.repr (final_pick a)))
   SEP (one_left_fields s bp cp (depth+1) (bump budgets 1) (last_path depth a path)
     (Int64.add nodes Int64.one) (Int64.add leaves Int64.one) (last_size (depth+1) a saved);
     close_mem Tsh s odd v;book_mem s b p).
Definition OneGprog : funspecs := ltac:(with_library prog [lookup_spec;dfs_one_spec]).

Theorem body_dfs_one_left : semax_body prepared_vars OneGprog f_dfs dfs_one_spec.
Proof.
  start_function.
  assert (at_origin: 0<=Int64.unsigned (origin b)<Zlength (slots b)).
  { unfold origin; apply within_mask; eapply table_mask_bound; eassumption. }
  pose proof (@lookup_answer_range b v odd (origin b) a ltac:(assumption) ltac:(assumption) at_origin) as R.
  pose proof (@qubits_fit b v odd ltac:(assumption)) as N.
  unfold one_left_fields,close_mem. Intros.
  do 8 (forward;try solve [entailer!]). reassoc_seq.
  replace (depth+1-depth) with 1 in * by lia.
  apply semax_if_seq. forward_if;[solve [congruence|contradiction]|forward].
  apply semax_if_seq. forward_if;[solve [congruence|contradiction]|forward].
  apply semax_if_seq. forward_if;[contradiction|].
  forward. apply semax_if_seq. forward_if;[rep_lia|].
  assert (nonzero:Int.repr odd<>Int.zero).
  { intro bad;apply (f_equal Int.unsigned) in bad. rewrite Int.unsigned_repr in bad by rep_lia;
    change (odd=0) in bad;lia. }
  forward. apply semax_if_seq. forward_if;[congruence|]. reassoc_seq.
  apply semax_if_seq. forward_if;[solve [congruence|contradiction]|forward].
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
