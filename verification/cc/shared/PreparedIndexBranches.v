(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VerifDetected PreparedDepthSpec PreparedBudgetContract
 PreparedPlainDescent PreparedIndexGlobals PreparedSeedDispatch flag_level_ast.
#[local] Existing Instance VerifDetected.CompSpecs.
Local Open Scope Z_scope.

Inductive dfs_branch := at_weight | already_closed | one_remaining | deep_open.
Definition same_branch a b :=
 match a,b with
 | at_weight,at_weight | already_closed,already_closed | one_remaining,one_remaining | deep_open,deep_open => true
 | _,_=>false end.
Lemma self_branch a:same_branch a a=true. Proof. destruct a;reflexivity. Qed.

(* Exactly the order of the nonpolling C guards at function entry. *)
Definition classify_call (odd:list int->Z) (w:Z) words:=
 let d:=Zlength words in
 if Z.eqb d w then at_weight else if Z.eqb (odd words) 0 then already_closed
 else if Z.eqb d (w-1) then one_remaining else deep_open.

Definition at_native_case (odd:list int->Z) (e:entry_domain) (part:dfs_branch):entry_domain:=
 fun g s cp bp w st words=>if same_branch (classify_call odd w words) part
                           then e g s cp bp w st words else False.

Lemma classify_match odd w words:1<=Zlength words<=w ->
 match classify_call odd w words with
 | at_weight=>Zlength words=w
 | already_closed=>Zlength words<w /\ odd words=0
 | one_remaining=>Zlength words=w-1 /\ odd words<>0
 | deep_open=>Zlength words<=w-2 /\ odd words<>0
 end.
Proof.
 intros depth;unfold classify_call.
 destruct (Z.eqb_spec (Zlength words) w);[assumption|].
 destruct (Z.eqb_spec (odd words) 0);[lia|].
 destruct (Z.eqb_spec (Zlength words) (w-1));lia.
Qed.

(* Pick a branch using the actual weight and prefix at the C call.
   Its postcondition and callee environment are identical in every case. *)
Theorem combine_c_bodies calls gv odd entry heap report valid bits:
 (forall part,semax_body prepared_vars calls f_dfs
     (index_dfs_using_globals gv (at_native_case odd entry part) heap report valid bits)) ->
 semax_body prepared_vars calls f_dfs (index_dfs_using_globals gv entry heap report valid bits).
Proof.
 intro all_parts;destruct (all_parts at_weight) as [parameters [return_type _]].
 split;[exact parameters|split;[exact return_type|]].
 intros Espec ts args.
 destruct args as [[[[[[[[g s] cp] bp] w] d] st] path] saved].
 set (part:=classify_call odd w (active_prefix d path)).
 destruct (all_parts part) as [_ [_ body]].
 specialize (body Espec ts (g,s,cp,bp,w,d,st,path,saved)).
 cbn beta iota zeta in body |- *.
 unfold at_native_case in body;fold part in body;rewrite self_branch in body;exact body.
Qed.

(* A physical proof can be reused at a narrower entry without changing
   any storage, globals, recursive return or witness condition. *)
Lemma narrow_index_domain static_globals (wide small:entry_domain) heap report valid bits:
 (forall g s cp bp w st words,1<=Zlength words<=w -> small g s cp bp w st words ->
    wide g s cp bp w st words) ->
 funspec_sub (snd (index_dfs_using_globals static_globals wide heap report valid bits))
   (snd (index_dfs_using_globals static_globals small heap report valid bits)).
Proof.
 intro restrict;do_funspec_sub.
 destruct w as [[[[[[[[geom0 s] cp] bp] wt] depth] snap] path] saved];cbn [fst snd];normalize.
 assert (length:Zlength (active_prefix depth path)=depth) by (unfold active_prefix;rewrite Zlength_sublist;lia).
 assert (domain:wide geom0 s cp bp wt snap (active_prefix depth path)) by (apply restrict;[lia|assumption]).
 Exists (geom0,s,cp,bp,wt,depth,snap,path,saved) emp;apply andp_right.
 - entailer!;try cancel;try apply derives_refl.
 - apply prop_right;intro rho;normalize;Exists x x0 x1;entailer!;cancel;try apply derives_refl.
Qed.
