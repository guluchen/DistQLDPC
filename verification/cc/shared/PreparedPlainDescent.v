(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.floyd.reassoc_seq VerifDetected VerifChildVisit
 PreparedDepthSpec PreparedBudgetContract PreparedRootStages PreparedChildCall PreparedSeedDispatch
 PreparedRecursiveCall OverlapColumnState flag_level_ast.
#[local] Existing Instance VerifDetected.CompSpecs.
Local Open Scope Z_scope.

(* The native index-mode caller passes NULL. The recursive call borrows
   the physical block and path arrays. No policy record or function
   pointer is owned, even as an unused frame. *)
Definition plain_dfs_contract (heap:budget_heap) (report:budget_report) bits:ident*funspec:=
 DECLARE _dfs WITH g:layout,s:val,cp:val,bp:val,w:Z,d:Z,st:snapshot,path:list int
 PRE [tptr level_type,tptr (Tstruct _cc_level_policy noattr),tint,tuint]
 PROP(1<=d<=w;w<=Int.max_signed;w<=Zlength path)
 PARAMS(s;nullval;Vint (Int.repr d);Vint bits)
 SEP(child_fields s cp bp w (blocked st) path;heap w s (active_prefix d path))
 POST [tint] EX tail:list int,EX code:Z,
 PROP(0<=code<=3;Zlength tail=Zlength path;active_prefix d tail=active_prefix d path;
   report w g st (active_prefix d path) code tail)
 RETURN(Vint (Int.repr code))
 SEP(child_fields s cp bp w (blocked st) tail;heap w s (active_prefix d path)).

Definition plain_descent_loc s depth q children count i bits:=
 [temp _s s;temp _policy nullval;temp _size (Vint (Int.repr depth));temp _options (Vint bits);
  temp _a (Vint (Int.repr q));temp _update_overlap (Vint Int.zero);temp _children children;
  temp _count (Vint (Int.repr count));temp _i (Vint (Int.repr i));temp _excluded (Vint (Int.repr i))].

Theorem null_policy_recurses {Espec:OracleKind} (flip:funspec) (heap:budget_heap) report bits
 (g:layout) s cp bp w d q st path children count i frame :
 1<=d<w-2 -> w<=Int.max_signed -> w<=Zlength path ->
 let child:=append_qubit path d q in
 let regs:=plain_descent_loc s d q children count i bits in
 semax (func_tycontext f_dfs prepared_vars (prepared_calls flip (snd (plain_dfs_contract heap report bits))) nil)
   (PROPx nil (LOCALx regs (SEPx [child_fields s cp bp w (blocked st) path;heap w s child;frame])))
   child_bracket
   (normal_ret_assert (EX tail:list int,EX code:Z,
    PROPx [0<=code<=3;Zlength tail=Zlength path;active_prefix (d+1) tail=child;report w g st child code tail]
      (LOCALx (temp _result (Vint (Int.repr code))::regs)
       (SEPx [child_fields s cp bp w (blocked st) tail;heap w s child;frame])))).
Proof.
 intros deep cap room child regs;unfold regs,plain_descent_loc,child_bracket,child_fields;abbreviate_semax;Intros.
 apply semax_if_seq;forward_if;try solve [contradiction|congruence|discriminate].
 do 2 forward;rewrite upd_Znth_map.
 set (chosen:=upd_Znth d path (Int.repr q)).
 assert (len:Zlength chosen=Zlength path) by (unfold chosen;rewrite upd_Znth_Zlength by lia;reflexivity).
 assert (save:active_prefix (d+1) chosen=child) by (apply stored_prefix;lia).
 forward;apply semax_if_seq;forward_if.
 { exfalso;match goal with K:Int.repr d=Int.sub _ _ |- _=>unfold Int.sub in K;rewrite !Int.unsigned_repr in K by rep_lia;
   apply (f_equal Int.signed) in K;rewrite !Int.signed_repr in K by rep_lia;lia end. }
 forward_call (g,s,cp,bp,w,d+1,st,chosen);
   try solve [entailer!;rep_lia|entailer!;f_equal;unfold Int.add;rewrite Int.unsigned_repr by rep_lia;reflexivity].
 { unfold child_fields;rewrite save;unfold chosen;rewrite ?upd_Znth_Zlength by lia;unfold Frame;cancel;
   instantiate (Frame:=[frame]);cbn [fold_right_sepcon];cancel;try apply derives_refl. }
 Intros returned;destruct returned as [tail code];cbn [fst snd] in *.
 forward_if;try solve [contradiction|congruence|discriminate];forward.
 Exists tail code;rewrite save in *;unfold child_fields;entailer!;try apply derives_refl.
Qed.
