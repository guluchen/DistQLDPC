(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.floyd.reassoc_seq VST.zlist.list_solver.
Require Import level_ast VerifDetected.

(* q is blocked exactly when it is one of the permanently excluded seeds.
   The arrays start clear in the no-policy HalfSearch entry. *)
Definition seen (n i : Z) := Zrepeat Int.one i ++ Zrepeat Int.zero (n-i).
Lemma seen_length n i : 0<=i<=n -> Zlength (seen n i)=n.
Proof. intros;unfold seen; rewrite Zlength_app, !Zlength_Zrepeat by lia;lia. Qed.
Lemma seen_cell n i j : 0<=i<=n -> 0<=j<n ->
  Znth j (seen n i) = if Z_lt_dec j i then Int.one else Int.zero.
Proof.
  intros;unfold seen;destruct (Z_lt_dec j i).
  - rewrite app_Znth1, Znth_Zrepeat;rewrite ?Zlength_Zrepeat by lia;auto;lia.
  - rewrite app_Znth2, Zlength_Zrepeat, Znth_Zrepeat;rewrite ?Zlength_Zrepeat by lia;auto;lia.
Qed.

Lemma put_seed n i : 0<=i<n -> upd_Znth i (seen n i) Int.one=seen n (i+1).
Proof.
  intros;apply Znth_eq_ext.
  - rewrite upd_Znth_Zlength, !seen_length by (rewrite ?seen_length;lia);reflexivity.
  - intros j J;rewrite upd_Znth_Zlength, seen_length in J by (rewrite ?seen_length;lia).
    destruct (Z.eq_dec j i) as [->|ne].
    + rewrite upd_Znth_same, seen_cell by (rewrite ?seen_length;lia).
      destruct (Z_lt_dec i (i+1));[reflexivity|lia].
    + rewrite upd_Znth_diff, !seen_cell by (rewrite ?seen_length;lia).
      repeat destruct Z_lt_dec;try reflexivity;lia.
Qed.
Lemma remove_seed n i : 0<=i<n -> upd_Znth i (seen n (i+1)) Int.zero=seen n i.
Proof.
  intros;rewrite <-put_seed, upd_Znth_twice by (rewrite ?seen_length;lia).
  replace Int.zero with (Znth i (seen n i)) at 1.
  - apply upd_Znth_triv;[rewrite seen_length;lia|reflexivity].
  - rewrite seen_cell by lia; destruct (Z_lt_dec i i);[lia|reflexivity].
Qed.

Definition seed_blocks s b n i : mpred :=
 (field_at Tsh level_type [StructField _blk] b s *
  data_at Tsh (tarray tuint n) (map Vint (seen n i)) b)%logic.
Definition seed_head s cur h : mpred :=
 (field_at Tsh level_type [StructField _cur] cur s *
  data_at Tsh (tarray tint 1) [Vint h] cur)%logic.

(* Modular interface for the two callees. The implementation of DFS must
   meet this contract before the traversal can be linked. Its footprint
   includes the current head and blocked array. Its private state includes
   the remaining witness and statistics, whose values may change. *)
Record seed_calls := {
  seed_extent : Z;
  core_at : val -> option Z -> mpred;
  answer : Z -> Z
}.
Definition seed_flip (c : seed_calls) : ident * funspec :=
 DECLARE _flip
 WITH s:val, q:Z, on:bool
 PRE [tptr level_type, tptr (Tstruct _cc_level_policy noattr), tint]
  PROP (0<=q<seed_extent c; seed_extent c<=Int.max_signed) PARAMS(s;nullval;Vint (Int.repr q))
  SEP(core_at c s (if on then None else Some q))
 POST [tvoid] PROP() RETURN()
  SEP(core_at c s (if on then Some q else None)).
Definition seed_dfs (c : seed_calls) : ident * funspec :=
 DECLARE _dfs
 WITH s:val,b:val,cur:val,n:Z,q:Z
 PRE [tptr level_type, tptr (Tstruct _cc_level_policy noattr), tint]
  PROP(0<=q<n; n<=Int.max_signed; n=seed_extent c) PARAMS(s;nullval;Vint Int.one)
  SEP(core_at c s (Some q);seed_blocks s b n (q+1);seed_head s cur (Int.repr q))
 POST [tint]
  PROP(0<=answer c q<=3) RETURN(Vint (Int.repr (answer c q)))
  SEP(core_at c s (Some q);seed_blocks s b n (q+1);seed_head s cur (Int.repr q)).

Definition base_fields s n calls : mpred :=
  (field_at Tsh level_type [StructField _n] (Vint (Int.repr n)) s *
   field_at Tsh level_type [StructField _seeds] (Vlong (Int64.repr calls)) s)%logic.
Definition clear_before c i := forall j, 0<=j<i -> answer c j=0.
Definition stopped c n i result :=
  (i=n /\ result=0) \/ (0<=i<n /\ result=answer c i /\ result<>0).
Definition index_seeds (c : seed_calls) : ident * funspec :=
 DECLARE _cc_run_level
 WITH s:val,b:val,cur:val,n:Z,first:int
 PRE [tptr level_type, tptr (Tstruct _cc_level_policy noattr)]
   PROP(0<=n<=Int.max_signed; n=seed_extent c) PARAMS(s;nullval)
   SEP(base_fields s n 0;core_at c s None;seed_blocks s b n 0;seed_head s cur first)
 POST [tint] EX i:Z, EX result:Z, EX head:int,
   PROP(0<=i<=n; stopped c n i result; clear_before c i;
        result<>0 -> head=Int.repr i)
   RETURN(Vint (Int.repr result))
   SEP(base_fields s n (if Z.eq_dec result 0 then i else i+1);
       core_at c s None;seed_blocks s b n i;seed_head s cur head).

Definition SeedGprog c : funspecs :=
  ltac:(let calls := constr:([seed_flip c;seed_dfs c;index_seeds c]) in with_library prog calls).

Lemma next_seed_count i : 0<=i<Int.max_signed ->
  Int64.add (Int64.repr i) Int64.one=Int64.repr (i+1).
Proof.
  intros. unfold Int64.add;rewrite Int64.unsigned_repr;[reflexivity|rep_lia].
Qed.

Theorem body_index_seeds c : semax_body Vprog (SeedGprog c) f_cc_run_level (index_seeds c).
Proof.
  start_function. unfold base_fields. Intros. reassoc_seq.
  apply semax_if_seq. forward_if; [contradiction|forward;forward].
  forward.
  forward_for_simple_bound n
    (EX i:Z, EX head:int,
     PROP(clear_before c i)
     LOCAL(temp _count (Vint (Int.repr n));temp _s s;temp _policy nullval)
     SEP(base_fields s n i;core_at c s None;seed_blocks s b n i;seed_head s cur head)).
  - Exists first. unfold base_fields. entailer!. unfold clear_before;intros;lia.
  - reassoc_seq. apply semax_extract_exists; intro current_head.
    unfold base_fields,seed_blocks,seed_head. Intros.
    assert (len : Zlength (seen n i)=n) by (apply seen_length;lia).
    assert (free : Znth i (seen n i)=Int.zero).
    { rewrite seen_cell by lia; destruct (Z_lt_dec i i);[lia|reflexivity]. }
    apply semax_if_seq. forward_if;[contradiction|forward]. forward.
    apply semax_if_seq. forward_if;[contradiction|forward].
    apply semax_if_seq. forward_if;[contradiction|].
    forward. forward. forward. rewrite free.
    apply semax_if_seq. forward_if;[|solve [contradiction|congruence]].
    forward. forward. forward. forward. forward. rewrite free. forward.
    rewrite upd_Znth_map, put_seed by lia.
    rewrite next_seed_count by rep_lia.
    forward_call (s,i,true). reassoc_seq.
    apply semax_if_seq. forward_if;[contradiction|forward].
    apply semax_if_seq. forward_if;[contradiction|].
    forward. forward.
    forward_call (s,b,cur,n,i);try solve [unfold seed_blocks,seed_head;entailer!].
    reassoc_seq. try forward.
    apply semax_if_seq. forward_if;[contradiction|forward].
    apply semax_if_seq. forward_if;[contradiction|].
    forward_call (s,i,false).
    unfold seed_blocks,seed_head. Intros.
    assert (len1:Zlength (seen n (i+1))=n) by (apply seen_length;lia).
    assert (busy:Znth i (seen n (i+1))=Int.one).
    { rewrite seen_cell by lia;destruct (Z_lt_dec i (i+1));[reflexivity|lia]. }
    forward. forward. forward. rewrite busy. forward.
    change (Int.sub Int.one (Int.repr 1)) with Int.zero.
    rewrite upd_Znth_map, remove_seed by lia.
    apply semax_if_seq. forward_if;[contradiction|forward].
    apply semax_if_seq. forward_if;[contradiction|].
    apply semax_if_seq. forward_if.
    + forward. Exists i (answer c i) (Int.repr i). unfold base_fields, seed_head,seed_blocks.
      unfold stopped. destruct (Z.eq_dec (answer c i) 0);entailer!;try rep_lia;intuition.
    + forward_if;[contradiction|].
      forward. forward. forward. rewrite free. forward.
      rewrite upd_Znth_map,put_seed by lia.
      Exists (Int.repr i). unfold base_fields,seed_head,seed_blocks. entailer!.
      unfold clear_before in *;intros j J.
      destruct (Z.eq_dec j i);[subst;rep_lia|auto with zarith].
  - Intros head. forward. Exists (seed_extent c) 0 head. unfold stopped. entailer!.
    destruct (Z.eq_dec 0 0);[apply derives_refl|congruence].
Qed.
