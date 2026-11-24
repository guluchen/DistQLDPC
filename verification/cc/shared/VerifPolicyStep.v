(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.floyd.reassoc_seq.
Require Import level_ast VerifDetected VerifClosesBody HashLookup VerifLookup
  VerifClosedPrefix VerifOneLeft LeafAPI VerifFlipBody VerifPolicyParity.
#[local] Hint Resolve owner_valid : valid_pointer.

Definition policy_gate p (enabled:bool) : mpred :=
  (field_at_ Tsh policy_type [StructField _owner] p *
   field_at Tsh policy_type [StructField _parity] (Vint (if enabled then Int.one else Int.zero)) p)%logic.

Lemma low_bit_clear z : Z.testbit z 0=false -> Int.and (Int.repr z) Int.one=Int.zero.
Proof.
  intro low;apply Int.same_bits_eq;intros i bound.
  rewrite Int.bits_and by assumption;rewrite Int.bits_one,Int.bits_zero.
  destruct (zeq i 0);[subst i; rewrite Int.testbit_repr by assumption;rewrite low|apply Bool.andb_false_r].
  reflexivity.
Qed.
Definition policy_step (accept:Z->Prop) (policy:val) (enabled:bool) : ident * funspec :=
 DECLARE _dfs
 WITH s:val,bp:val,cp:val,p:lookup_ptrs,b:lookup_data,v:close_view,odd:Z,qs:list Z,
   depth:Z,budgets:list int64,path:list int,nodes:int64,leaves:int64,saved:int
 PRE [tptr level_type,tptr (Tstruct _cc_level_policy noattr),tint]
   PROP (1<=depth<Int.max_signed;0<odd<=Int.max_signed;
     1<Zlength budgets; depth<Zlength path;
     (enabled=true -> Z.testbit (1-odd) 0=false);
     book_safe b v odd; leaf_image accept b v odd qs)
   PARAMS (s;policy;Vint (Int.repr depth))
   SEP (one_left_fields s bp cp (depth+1) budgets path nodes leaves saved;
        close_mem Tsh s odd v;book_mem s b p;policy_gate policy enabled)
 POST [tint] EX a:Z,
   PROP (leaf_answer accept (extent b) a)
   RETURN (Vint (Int.repr (final_pick a)))
   SEP (one_left_fields s bp cp (depth+1) (bump budgets 1) (last_path depth a path)
     (Int64.add nodes Int64.one) (Int64.add leaves Int64.one) (last_size (depth+1) a saved);
     close_mem Tsh s odd v;book_mem s b p;policy_gate policy enabled).

Definition PolicyStepGprog accept policy enabled : funspecs :=
  ltac:(let fs:=constr:([lookup_spec;policy_step accept policy enabled]) in with_library prog fs).

Theorem body_policy_search_step accept policy enabled :
 semax_body Vprog (PolicyStepGprog accept policy enabled) f_dfs (policy_step accept policy enabled).
Proof.
  start_function.
  destruct (@checked_answer accept b v odd qs ltac:(assumption) ltac:(assumption)) as [a [trace ok]].
  assert (at_origin: 0<=Int64.unsigned (origin b)<Zlength (slots b)).
  { unfold origin; apply within_mask; eapply table_mask_bound; eassumption. }
  pose proof (@lookup_answer_range b v odd (origin b) a ltac:(assumption) ltac:(assumption) at_origin) as R.
  pose proof (@qubits_fit b v odd ltac:(assumption)) as N.
  unfold one_left_fields,close_mem,policy_gate. Intros.
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
  assert_PROP (isptr policy) as valid_policy by entailer!.
  apply semax_if_seq;forward_if;[|subst policy;contradiction].
  destruct enabled;forward;forward;
    [apply semax_if_seq; forward_if; [|solve [discriminate|congruence]];
     forward;forward;forward; try solve [entailer!];
     assert (bit:Int.and (Int.sub (Int.sub (Int.repr (depth+1)) (Int.repr depth)) (Int.repr odd)) Int.one=Int.zero)
       by (rewrite !sub_word;replace (depth+1-depth) with 1 by lia;apply low_bit_clear;auto);
     change Int.one with (Int.repr 1) in bit;
     apply semax_if_seq;forward_if; [exfalso;rewrite bit in H13;exact (H13 eq_refl)|]
    |apply semax_if_seq;forward_if;[contradiction|forward];
     apply semax_if_seq;forward_if;[contradiction|]].
  all: try clear bit.
  all: assert (last : Int.sub (Int.repr (depth+1)) (Int.repr 1)=Int.repr depth)
    by (unfold Int.sub;rewrite !Int.unsigned_repr by rep_lia;f_equal;lia).
  all: forward; apply semax_if_seq; forward_if; [|solve [congruence|rep_lia]].
  all: forward;forward;forward_call (s,p,b,v,odd,a);try solve [unfold close_mem;entailer!].
  all: reassoc_seq;apply semax_if_seq;forward_if.
  all: first [
    forward;Exists a;unfold policy_gate,final_pick,one_left_fields,last_path,last_size,bump;
      destruct (Z_lt_dec a 0);[|rep_lia];rewrite upd_Znth_Zlength by lia;
      entailer!;rewrite upd_Znth_map;apply derives_refl
   |forward;forward;forward;forward;Exists a;unfold policy_gate,final_pick,one_left_fields,last_path,last_size,bump;
      destruct (Z_lt_dec a 0);[rep_lia|];rewrite !upd_Znth_Zlength by lia;
      entailer!;rewrite !upd_Znth_map;apply derives_refl].
Qed.
