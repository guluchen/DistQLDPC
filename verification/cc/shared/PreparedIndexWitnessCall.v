(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.floyd.reassoc_seq VerifDetected VerifChildVisit
 PreparedDepthSpec PreparedBudgetContract PreparedRootStages PreparedChildCall PreparedSeedDispatch
 PreparedRecursiveCall PreparedPlainDescent PreparedWitnessRegister OverlapColumnState flag_level_ast.
#[local] Existing Instance VerifDetected.CompSpecs.
Local Open Scope Z_scope.

(* This is the physical length field the outer driver reads. Keep it
   separate from the allocation preserved by flip. *)
Definition index_dfs_with_witness (entry:entry_domain) (heap:budget_heap) (report:budget_report)
  (valid_witness:Z->list int->Prop) bits:ident*funspec:=
 DECLARE _dfs WITH g:layout,s:val,cp:val,bp:val,w:Z,d:Z,st:snapshot,path:list int,saved:int
 PRE [tptr level_type,tptr (Tstruct _cc_level_policy noattr),tint,tuint]
 PROP(1<=d<=w;w<=Int.max_signed;w<=Zlength path;entry g s cp bp w st (active_prefix d path))
 PARAMS(s;nullval;Vint (Int.repr d);Vint bits)
 SEP(child_fields s cp bp w (blocked st) path;heap w s (active_prefix d path);witness_register s saved)
 POST [tint] EX tail:list int,EX code:Z,EX written:int,
 PROP(0<=code<=3;Zlength tail=Zlength path;active_prefix d tail=active_prefix d path;
    report w g st (active_prefix d path) code tail;witness_at_limit w saved code written tail;
    witness_status code -> valid_witness (Int.signed written) tail)
 RETURN(Vint (Int.repr code))
 SEP(child_fields s cp bp w (blocked st) tail;heap w s (active_prefix d path);witness_register s written).

Definition may_hold_witness (heap:budget_heap):budget_heap:=fun w s node=>
 ((EX saved:int,witness_register s saved)*heap w s node)%logic.

Theorem stronger_child_serves_plain entry heap report valid_witness bits:
 funspec_sub (snd (index_dfs_with_witness entry heap report valid_witness bits))
             (snd (plain_dfs_contract entry (may_hold_witness heap) report bits)).
Proof.
 do_funspec_sub;destruct w as [[[[[[[geom s] cp] bp] weight] d] st] path].
 cbn [fst snd];unfold may_hold_witness;normalize.
 match goal with stored:int |- _ => Exists (geom,s,cp,bp,weight,d,st,path,stored) emp end;apply andp_right.
 - entailer!;cancel.
 - apply prop_right;intro rho;normalize;Exists x x0;entailer!;Exists x1;cancel.
Qed.

Theorem compiled_child_returns_register {Espec:OracleKind} (entry:entry_domain) (flip:funspec)
 (heap:budget_heap) (report:budget_report) (valid_witness:Z->list int->Prop) bits
 (g:layout) s cp bp w d q st path saved children count i frame:
 1<=d<w-2 -> w<=Int.max_signed -> w<=Zlength path -> entry g s cp bp w st (append_qubit path d q) ->
 let node:=append_qubit path d q in let regs:=plain_descent_loc s d q children count i bits in
 let child:=index_dfs_with_witness entry heap report valid_witness bits in
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
   abbreviate_semax;Intros.
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
