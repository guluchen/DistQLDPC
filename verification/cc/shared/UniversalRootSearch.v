(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto level_ast VerifDetected VerifChildVisit EnabledCall
 OverlapColumnState OverlapChildState SeedLoopModel.
#[local] Existing Instance VerifDetected.CompSpecs.
Local Open Scope Z_scope.
Definition with_rows c g:=Build_policy_state (nested c) (callback_owner c) (callback_addr c) (conn c) g.

(* One DFS symbol must serve every seed, even when its tie-break layout changes. *)
Definition every_root_dfs c:ident*funspec:=
 DECLARE _dfs WITH geom:layout,s:val,cp:val,w:Z,q:Z,st:snapshot,path:list int
 PRE [tptr level_type,tptr (Tstruct _cc_level_policy noattr),tint]
 PROP(1<=w<=Int.max_signed;w<=Zlength path;0<=q<Zlength (blocked st);Znth 0 path=Int.repr q)
 PARAMS(s;nested_policy (nested c);Vint Int.one)
 SEP(enabled_memory (with_rows c geom) s cp w path st;active_support (nested c) s (Some q))
 POST [tint] EX final:snapshot,EX tail:list int,
 PROP(same_search final st;0<=child_outcome (nested c) (blocked st) q<=3;
  Zlength tail=Zlength path;Znth 0 tail=Int.repr q;
  child_outcome (nested c) (blocked st) q<>0 -> returned_trace (nested c) (blocked st) q tail)
 RETURN(Vint (Int.repr (child_outcome (nested c) (blocked st) q)))
 SEP(enabled_memory (with_rows c geom) s cp w tail final;active_support (nested c) s (Some q)).
Definition root_functions n (call:funspec):funspecs:=
 ltac:(let fs:=constr:([enter_child n;(_dfs,call)]) in with_library prog fs).
Definition all_roots c:=root_functions (nested c) (snd (every_root_dfs c)).
Lemma root_functions_source c:root_functions (nested c) (snd (root_dfs c))=RootG c.
Proof. reflexivity. Qed.
Lemma specialize_root_search c geom :
 funspec_sub (snd (every_root_dfs c)) (snd (root_dfs (with_rows c geom))).
Proof.
 do_funspec_sub;destruct w as [[[[[s cp] weight] q] st] path].
 cbn [fst snd with_rows nested];normalize.
 Exists (geom,s,cp,weight,q,st,path) emp;apply andp_right.
 - entailer!;cancel.
 - apply prop_right;intro rho;normalize;Exists x x0;entailer!;cancel.
Qed.
Lemma all_roots_subsumes_seed c geom:
 tycontext_sub (func_tycontext f_cc_run_level Vprog (RootG (with_rows c geom)) [])
   (func_tycontext f_cc_run_level Vprog (all_roots c) []).
Proof.
 apply tycontext_sub_i99;split.
 - apply sub_option_get;repeat (apply Forall_cons;[reflexivity|]);apply Forall_nil.
 - apply subsume_spec_get.
   let A:=fresh in let B:=fresh in
   set (A:=make_tycontext_s (RootG (with_rows c geom)));
   set (B:=make_tycontext_s (all_roots c));
   let a:=make_ground_PTree A in change A with a;clear A;
   let b:=make_ground_PTree B in change B with b;clear B.
   repeat (apply Forall_cons;[first [apply subsumespec_refl|
     eexists;split;[reflexivity|apply funspec_sub_sub_si;apply specialize_root_search]]|]);apply Forall_nil.
Qed.
