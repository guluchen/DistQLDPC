(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.zlist.list_solver VerifDetected VerifChildVisit EnabledCall
 OverlapColumnState OverlapChildState UniversalRootSearch PreparedRecursiveCall PreparedSeedDispatch PreparedRootStages.
Require flag_level_ast.
Import flag_level_ast.
#[local] Existing Instance VerifDetected.CompSpecs.
Local Open Scope Z_scope.

Definition node_storage:=val->list int->mpred.
Definition node_report:=layout->snapshot->list int->Z->list int->Prop.
Definition active_prefix depth (path:list int):=sublist 0 depth path.
Definition depth_dfs c (heap:node_storage) (report:node_report) (bits:int):ident*funspec:=
 DECLARE _dfs WITH geom:layout,s:val,cp:val,w:Z,depth:Z,q:Z,st:snapshot,path:list int
 PRE [tptr level_type,tptr (Tstruct _cc_level_policy noattr),tint,tuint]
 PROP(1<=depth<=w;w<=Int.max_signed;w<=Zlength path;0<=q<Zlength (blocked st);Znth (depth-1) path=Int.repr q)
 PARAMS(s;nested_policy (nested c);Vint (Int.repr depth);Vint bits)
 SEP(enabled_memory (with_rows c geom) s cp w path st;heap s (active_prefix depth path))
 POST [tint] EX final:snapshot,EX tail:list int,EX r:Z,
 PROP(same_search final st;0<=r<=3;Zlength tail=Zlength path;active_prefix depth tail=active_prefix depth path;
  report geom st (active_prefix depth path) r tail;
  witness_status r -> returned_trace (nested c) (blocked st) q tail)
 RETURN(Vint (Int.repr r))
 SEP(enabled_memory (with_rows c geom) s cp w tail final;heap s (active_prefix depth path)).
Definition root_projection (report:node_report):root_report:=
 fun g st q=>report g st [Int.repr q].
Lemma first_prefix (path:list int) q:0<Zlength path -> Znth 0 path=Int.repr q ->
 active_prefix 1 path=[Int.repr q].
Proof. intros pos mark;unfold active_prefix;change 1 with (0+1);rewrite sublist_one by lia;rewrite mark;reflexivity. Qed.

Theorem depth_spec_serves_seed c (heap:node_storage) report bits:
 (forall s q,active_support (nested c) s (Some q)=heap s [Int.repr q]) ->
 funspec_sub (snd (depth_dfs c heap report bits)) (snd (root_dfs_spec c (root_projection report) bits)).
Proof.
 intros root;do_funspec_sub;destruct w as [[[[[[geom s] cp] weight] q] st] path].
 cbn [fst snd];normalize.
 assert (pre:active_prefix 1 path=[Int.repr q]) by (apply first_prefix;[lia|assumption]).
 Exists (geom,s,cp,weight,1,q,st,path) emp;apply andp_right.
 - rewrite pre,root;entailer!;cancel.
 - apply prop_right;intro rho;normalize;Exists x x0 x1;rewrite pre,root in *.
   assert (hd:Znth 0 x0=Int.repr q).
   { match goal with H:active_prefix 1 x0=[Int.repr q] |- _=>
      unfold active_prefix in H;change 1 with (0+1) in H;rewrite sublist_one in H by lia;congruence end. }
   unfold root_projection;entailer!;cancel.
Qed.

(* Every recursive frame borrows the packed syndrome of its own prefix. *)
Definition depth_flip c (heap:node_storage) (bits:int):ident*funspec:=
 DECLARE _flip WITH s:val,prefix:list int,q:Z,enter:bool
 PRE [tptr level_type,tptr (Tstruct _cc_level_policy noattr),tint,tuint]
 PROP(0<=q<Int.max_signed;q+1<Zlength (column_offsets (geometry c)))
 PARAMS(s;nested_policy (nested c);Vint (Int.repr q);Vint bits)
 SEP(heap s (if enter then prefix else prefix++[Int.repr q]))
 POST [tvoid] PROP() RETURN() SEP(heap s (if enter then prefix++[Int.repr q] else prefix)).
Definition depth_context c heap report bits:=prepared_calls (snd (depth_flip c heap bits)) (snd (depth_dfs c heap report bits)).

Lemma depth_flip_serves_seed c heap mask:
 (forall s,active_support (nested c) s None=heap s []) ->
 (forall s q,active_support (nested c) s (Some q)=heap s [Int.repr q]) ->
 funspec_sub (snd (depth_flip c heap mask)) (snd (root_flip c mask)).
Proof.
 intros zero one;do_funspec_sub;destruct w as [[s q] enter];cbn [fst snd];normalize.
 Exists (s,(@nil int),q,enter) emp;apply andp_right.
 - destruct enter;cbn [app];rewrite ?zero,?one;entailer!;cancel.
 - apply prop_right;intro rho;normalize;destruct enter;cbn [app];rewrite ?zero,?one;entailer!;cancel.
Qed.
Theorem same_search_functions c heap report bits:
 (forall s,active_support (nested c) s None=heap s []) ->
 (forall s q,active_support (nested c) s (Some q)=heap s [Int.repr q]) ->
 tycontext_sub (func_tycontext f_cc_run_prepared_level prepared_vars (RecG c (root_projection report) bits) [])
    (func_tycontext f_cc_run_prepared_level prepared_vars (depth_context c heap report bits) []).
Proof.
 intros zero one;apply tycontext_sub_i99;split.
 - apply sub_option_get;repeat (apply Forall_cons;[reflexivity|]);apply Forall_nil.
 - apply subsume_spec_get.
   let A:=fresh in let B:=fresh in
   set (A:=make_tycontext_s (RecG c (root_projection report) bits));
   set (B:=make_tycontext_s (depth_context c heap report bits));
   let a:=make_ground_PTree A in change A with a;clear A;
   let b:=make_ground_PTree B in change B with b;clear B.
   repeat (apply Forall_cons;[first [apply subsumespec_refl|
    eexists;split;[reflexivity|apply funspec_sub_sub_si;first [apply depth_spec_serves_seed;assumption|
    apply depth_flip_serves_seed;assumption]]]|]);apply Forall_nil.
Qed.
