(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.floyd.reassoc_seq VerifDetected VerifChildVisit
 PreparedDepthSpec PreparedBudgetContract PreparedRootStages PreparedChildCall PreparedSeedDispatch
 PreparedRecursiveCall PreparedPlainDescent PreparedWitnessRegister OverlapColumnState flag_level_ast.
#[local] Existing Instance VerifDetected.CompSpecs.
Local Open Scope Z_scope.

(* The nested C call can use the same static bit-position table as its parent. *)
Definition index_dfs_using_globals (gv:globals) (entry:entry_domain) (heap:budget_heap) (report:budget_report)
  (valid_witness:Z->list int->Prop) bits:ident*funspec:=
 DECLARE _dfs WITH g:layout,s:val,cp:val,bp:val,w:Z,d:Z,st:snapshot,path:list int,saved:int
 PRE [tptr level_type,tptr (Tstruct _cc_level_policy noattr),tint,tuint]
 PROP(1<=d<=w;w<=Int.max_signed;w<=Zlength path;entry g s cp bp w st (active_prefix d path))
 PARAMS(s;nullval;Vint (Int.repr d);Vint bits) GLOBALS(gv)
 SEP(child_fields s cp bp w (blocked st) path;heap w s (active_prefix d path);witness_register s saved)
 POST [tint] EX tail:list int,EX code:Z,EX written:int,
 PROP(0<=code<=3;Zlength tail=Zlength path;active_prefix d tail=active_prefix d path;
    report w g st (active_prefix d path) code tail;witness_at_limit w saved code written tail;
    witness_status code -> valid_witness (Int.signed written) tail)
 RETURN(Vint (Int.repr code))
 SEP(child_fields s cp bp w (blocked st) tail;heap w s (active_prefix d path);witness_register s written).

Theorem compiled_child_with_chooser_globals {Espec:OracleKind} (gv:globals) (entry:entry_domain) (flip:funspec)
 (heap:budget_heap) (report:budget_report) (valid_witness:Z->list int->Prop) bits
 (g:layout) s cp bp w d q st path saved children count i frame:
 1<=d<w-2 -> w<=Int.max_signed -> w<=Zlength path -> entry g s cp bp w st (append_qubit path d q) ->
 let node:=append_qubit path d q in let regs:=plain_descent_loc s d q children count i bits++[gvars gv] in
 let child:=index_dfs_using_globals gv entry heap report valid_witness bits in
 semax (func_tycontext f_dfs prepared_vars (prepared_calls flip (snd child)) nil)
   (PROPx nil (LOCALx regs (SEPx [child_fields s cp bp w (blocked st) path;
      heap w s node;witness_register s saved;frame]))) child_bracket
   (normal_ret_assert (EX tail:list int,EX code:Z,EX written:int,
    PROPx [0<=code<=3;Zlength tail=Zlength path;active_prefix (d+1) tail=node;
      report w g st node code tail;witness_at_limit w saved code written tail;
      witness_status code -> valid_witness (Int.signed written) tail]
      (LOCALx (temp _result (Vint (Int.repr code))::regs)
       (SEPx [child_fields s cp bp w (blocked st) tail;heap w s node;witness_register s written;frame])))).
Proof.
 intros deep cap room reached node regs child;unfold child,regs,plain_descent_loc,child_bracket,child_fields;
   cbn [app];abbreviate_semax;Intros.
 apply semax_if_seq;forward_if;try solve [contradiction|congruence|discriminate].
 do 2 forward;rewrite upd_Znth_map.
 set (chosen:=upd_Znth d path (Int.repr q)).
 assert (len:Zlength chosen=Zlength path) by (unfold chosen;rewrite upd_Znth_Zlength by lia;reflexivity).
 assert (save:active_prefix (d+1) chosen=node) by (apply stored_prefix;lia).
 assert (admissible:entry g s cp bp w st (active_prefix (d+1) chosen)) by (rewrite save;exact reached).
 forward;apply semax_if_seq;forward_if.
 { exfalso;match goal with K:Int.repr d=Int.sub _ _ |- _=>unfold Int.sub in K;rewrite !Int.unsigned_repr in K by rep_lia;
   apply (f_equal Int.signed) in K;rewrite !Int.signed_repr in K by rep_lia;lia end. }
 forward_call (g,s,cp,bp,w,d+1,st,chosen,saved);
   try solve [entailer!;rep_lia|entailer!;f_equal;unfold Int.add;rewrite Int.unsigned_repr by rep_lia;reflexivity].
 { unfold child_fields;rewrite save;unfold chosen;rewrite ?upd_Znth_Zlength by lia;unfold Frame;cancel;
   instantiate (Frame:=[frame]);cbn [fold_right_sepcon];cancel;try apply derives_refl. }
 Intros returned;destruct returned as [[tail code] written];cbn [fst snd] in *.
 forward_if;try solve [contradiction|congruence|discriminate];forward.
 Exists tail code written;rewrite save in *;unfold child_fields;entailer!;try apply derives_refl.
Qed.

Require Import EnabledCall PreparedIndexWitnessScan PreparedIndexWitnessUndo.
Theorem deep_visit_in_global_environment {Espec:OracleKind} (gv:globals) (entry:entry_domain) c (heap:node_storage)
 (subheap:budget_heap) (report:budget_report) (valid_witness:Z->list int->Prop) bits
 s cp bp w d q st cur saved children count i loan (path:list int):
 1<=d<w-2 -> w<=Int.max_signed -> w<=Zlength cur -> Zlength cur=Zlength path ->
 let node:=append_qubit cur d q in let locs:=plain_descent_loc s d q children count i bits++[gvars gv] in
 let callee:=index_dfs_using_globals gv entry subheap report valid_witness bits in
 let D:=func_tycontext f_dfs prepared_vars (visit_calls (snd (depth_flip c heap bits)) (snd callee)) nil in
 entry (geometry c) s cp bp w st node -> subheap w s node=(heap s node * loan)%logic ->
 forall frame:mpred,
 let owned tail written:=(child_fields s cp bp w (blocked st) tail * heap s node *
        witness_register s written * frame * loan)%logic in
 semax D (PROPx nil (LOCALx (temp _result (Vint Int.zero)::locs) (SEPx [owned cur saved]))) child_bracket
  (normal_ret_assert (EX tail:list int,EX code:Z,EX written:int,PROPx
    [0<=code<=3;Zlength tail=Zlength path;active_prefix (d+1) tail=node;
     report w (geometry c) st node code tail;witness_at_limit w saved code written tail /\
      (witness_status code -> valid_witness (Int.signed written) tail)]
    (LOCALx (temp _result (Vint (Int.repr code))::locs) (SEPx [owned tail written])))).
Proof.
 intros deep cap room len node locs callee D reached partition frame owned.
 pose proof (@compiled_child_with_chooser_globals Espec gv entry (snd (depth_flip c heap bits)) subheap report
    valid_witness bits (geometry c) s cp bp w d q st cur saved children count i frame deep cap room reached) as raw.
 cbn zeta in raw;fold node locs in raw;rewrite partition in raw.
 eapply semax_Delta_subsumption;[exact (proj1 (visit_contexts _ _))|].
 eapply semax_post'.
 2:{ eapply semax_pre;[|exact raw];unfold locs,plain_descent_loc,owned;cbn [app];go_lowerx;normalize;try cancel;try apply derives_refl.
     all: try (apply andp_right;[apply prop_right;repeat split;try assumption|cancel]).
     all: try solve [match goal with h:_ |- _=>first [exact (proj1 h)|exact (proj2 h)] end]. }
 Intros tail code written;Exists tail code written;unfold owned,locs,plain_descent_loc;cbn [app];go_lowerx;normalize;try cancel;try apply derives_refl.
 all: try (apply andp_right;[apply prop_right;repeat split;try assumption;intuition|cancel]).
 all: try solve [match goal with h:_ |- _=>first [exact (proj1 h)|exact (proj2 h)] end].
 all: unfold witness_at_limit, witness_status in *; intuition (try congruence; try lia).
Qed.


Require Import PreparedCallerLocals.

Lemma preserve_globals_for_child {Espec:OracleKind} D gv stmt (before:list localdef)
 (own:list mpred) (facts:list int->Z->int->list Prop) (after:Z->list localdef)
 (returned:list int->int->list mpred):
 closed_wrt_modvars stmt (LOCALx [gvars gv] (SEPx nil)) ->
 semax D (PROPx nil (LOCALx before (SEPx own))) stmt
 (normal_ret_assert (EX tail:list int,EX code:Z,EX written:int,
   PROPx (facts tail code written) (LOCALx (after code) (SEPx (returned tail written))))) ->
 semax D (PROPx nil (LOCALx (before++[gvars gv]) (SEPx own))) stmt
 (normal_ret_assert (EX tail:list int,EX code:Z,EX written:int,
   PROPx (facts tail code written) (LOCALx (after code++[gvars gv]) (SEPx (returned tail written))))).
Proof.
 intros stable body;set (answers:=(list int * (Z * int))%type).
 pose (P:=fun a:answers=>facts (fst a) (fst (snd a)) (snd (snd a))).
 pose (L:=fun a:answers=>after (fst (snd a))).
 pose (S:=fun a:answers=>returned (fst a) (snd (snd a))).
 assert (packed:semax D (PROPx nil (LOCALx before (SEPx own))) stmt
    (normal_ret_assert (EX a:answers,PROPx (P a) (LOCALx (L a) (SEPx (S a)))))).
 { eapply semax_post';[|exact body];Intros tail code written;Exists (tail,(code,written));apply andp_left2;apply derives_refl. }
 pose proof (@keep_caller_locals_for_answer answers Espec VerifDetected.CompSpecs D stmt nil before own
        [gvars gv] nil P L S stable packed) as keep.
 rewrite app_nil_r in keep;eapply semax_post';[|exact keep].
 Intros a;destruct a as [tail [code written]];Exists tail code written.
 unfold P,L,S;cbn [fst snd];rewrite app_nil_r;apply andp_left2;apply derives_refl.
Qed.
