(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VerifDetected VerifChildVisit EnabledCall OverlapColumnState OverlapChildState
 UniversalRootSearch PreparedRecursiveCall PreparedSeedDispatch PreparedRootStages PreparedDepthSpec.
Require flag_level_ast.
Import flag_level_ast.
#[local] Existing Instance VerifDetected.CompSpecs.
Local Open Scope Z_scope.

(* The same DFS machine code is called at several successive weight limits.
   Bind the report to the actual _w cell, including when a larger trace
   buffer is reused by the caller across levels. *)
Definition budget_heap:=Z->node_storage.
Definition budget_report:=Z->node_report.
Definition budget_dfs c (heap:budget_heap) (obs:budget_report) (bits:int):ident*funspec:=
 DECLARE _dfs WITH geom:layout,s:val,cp:val,w:Z,depth:Z,q:Z,st:snapshot,path:list int
 PRE [tptr level_type,tptr (Tstruct _cc_level_policy noattr),tint,tuint]
 PROP(1<=depth<=w;w<=Int.max_signed;w<=Zlength path;0<=q<Zlength (blocked st);Znth (depth-1) path=Int.repr q)
 PARAMS(s;nested_policy (nested c);Vint (Int.repr depth);Vint bits)
 SEP(enabled_memory (with_rows c geom) s cp w path st;heap w s (active_prefix depth path))
 POST [tint] EX final:snapshot,EX tail:list int,EX r:Z,
 PROP(same_search final st;0<=r<=3;Zlength tail=Zlength path;active_prefix depth tail=active_prefix depth path;
  obs w geom st (active_prefix depth path) r tail;witness_status r -> returned_trace (nested c) (blocked st) q tail)
 RETURN(Vint (Int.repr r))
 SEP(enabled_memory (with_rows c geom) s cp w tail final;heap w s (active_prefix depth path)).

Lemma weight_independent_dfs c heap obs bits:
 budget_dfs c (fun _=>heap) (fun _=>obs) bits=depth_dfs c heap obs bits.
Proof. reflexivity. Qed.

Definition budget_root c (obs:Z->root_report) (bits:int):ident*funspec:=
 DECLARE _dfs WITH geom:layout,s:val,cp:val,w:Z,q:Z,st:snapshot,path:list int
 PRE [tptr level_type,tptr (Tstruct _cc_level_policy noattr),tint,tuint]
 PROP(1<=w<=Int.max_signed;w<=Zlength path;0<=q<Zlength (blocked st);Znth 0 path=Int.repr q)
 PARAMS(s;nested_policy (nested c);Vint Int.one;Vint bits)
 SEP(enabled_memory (with_rows c geom) s cp w path st;active_support (nested c) s (Some q))
 POST [tint] EX final:snapshot,EX tail:list int,EX r:Z,
 PROP(same_search final st;0<=r<=3;Zlength tail=Zlength path;Znth 0 tail=Int.repr q;
  obs w geom st q r tail;witness_status r -> returned_trace (nested c) (blocked st) q tail)
 RETURN(Vint (Int.repr r)) SEP(enabled_memory (with_rows c geom) s cp w tail final;active_support (nested c) s (Some q)).

Lemma same_root_for_constant_report c obs bits:
 budget_root c (fun _=>obs) bits=root_dfs_spec c obs bits.
Proof. reflexivity. Qed.

Theorem budget_contract_for_root c (heap:node_storage) (obs:budget_report) bits:
 (forall s q,active_support (nested c) s (Some q)=heap s [Int.repr q]) ->
 funspec_sub (snd (budget_dfs c (fun _=>heap) obs bits)) (snd (budget_root c (fun w=>root_projection (obs w)) bits)).
Proof.
 intros root;do_funspec_sub;destruct w as [[[[[[geom s] cp] weight] q] st] path].
 cbn [fst snd];normalize.
 assert (pre:active_prefix 1 path=[Int.repr q]) by (apply first_prefix;[lia|assumption]).
 Exists (geom,s,cp,weight,1,q,st,path) emp;apply andp_right.
 - rewrite pre,root;entailer!;cancel.
 - apply prop_right;intro rho;normalize;Exists x x0 x1;rewrite pre,root in *.
   assert (hd:Znth 0 x0=Int.repr q).
   { match goal with H:active_prefix 1 x0=[Int.repr q] |- _=>unfold active_prefix in H;
     change 1 with (0+1) in H;rewrite sublist_one in H by lia;congruence end. }
   unfold root_projection;entailer!;cancel.
Qed.
