(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto.
Require Import level_ast VerifDetected VerifClosesBody HashLookup VerifLookup
  VerifClosedPrefix VerifOneLeft LeafAPI.

(* The search chooses the final qubit and writes it to the caller's actual
   path buffer. Its witness index and lookup trace do not appear in PRE. *)
Definition physical_step (accept:Z->Prop) : ident * funspec :=
 DECLARE _dfs
 WITH s:val,bp:val,cp:val,p:lookup_ptrs,b:lookup_data,v:close_view,odd:Z,qs:list Z,
   depth:Z,budgets:list int64,path:list int,nodes:int64,leaves:int64,saved:int
 PRE [tptr level_type,tptr (Tstruct _cc_level_policy noattr),tint]
   PROP (1<=depth<Int.max_signed;0<odd<=Int.max_signed;
     1<Zlength budgets; depth<Zlength path;
     book_safe b v odd; leaf_image accept b v odd qs)
   PARAMS (s;nullval;Vint (Int.repr depth))
   SEP (one_left_fields s bp cp (depth+1) budgets path nodes leaves saved;
        close_mem Tsh s odd v;book_mem s b p)
 POST [tint] EX a:Z,
   PROP (leaf_answer accept (extent b) a)
   RETURN (Vint (Int.repr (final_pick a)))
   SEP (one_left_fields s bp cp (depth+1) (bump budgets 1) (last_path depth a path)
     (Int64.add nodes Int64.one) (Int64.add leaves Int64.one) (last_size (depth+1) a saved);
     close_mem Tsh s odd v;book_mem s b p).

Lemma physical_step_refines accept :
  funspec_sub (snd dfs_one_spec) (snd (physical_step accept)).
Proof.
  do_funspec_sub.
  destruct w as [[[[[[[[[[[[[s bp]cp]p]b]v]odd]qs]depth]budgets]path]nodes]leaves]saved];
    cbn [fst snd]; normalize.
  destruct (@checked_answer accept b v odd qs ltac:(assumption) ltac:(assumption)) as [a [run ok]].
  Exists (s,bp,cp,p,b,v,odd,a,depth,budgets,path,nodes,leaves,saved) emp;apply andp_right.
  - entailer!;cancel.
  - apply prop_right;intros rho';normalize;Exists a;entailer!;cancel.
Qed.
Theorem body_physical_step accept :
  semax_body Vprog OneGprog f_dfs (physical_step accept).
Proof.
  eapply semax_body_funspec_sub;[apply body_dfs_one_left|apply physical_step_refines|].
  vm_compute;repeat(apply list_norepet_cons;[simpl;intuition congruence|]);apply list_norepet_nil.
Qed.
