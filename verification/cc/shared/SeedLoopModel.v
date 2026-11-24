(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto ClightSelect level_ast VerifDetected VerifChildVisit
 EnabledCall OverlapColumnState OverlapChildState.
Local Open Scope Z_scope.
Definition actual_seed_loop:statement:=ltac:(native_fragment (counts_on _i) f_cc_run_level).
Definition iteration:=at_branch [true;false;true] actual_seed_loop.
Definition seed_nodes :=
 match iteration with Ssequence lookup (Ssequence exempt_in (Ssequence zero_result
  (Ssequence visit (Ssequence exempt_out (Ssequence return_on_hit block))))) =>
  [lookup;exempt_in;zero_result;visit;exempt_out;return_on_hit;block]
 | _=>[] end.
Ltac seed_statement n :=
 let s:=eval cbv beta iota zeta delta [List.nth seed_nodes iteration at_branch actual_seed_loop] in
  (List.nth n seed_nodes Sskip) in exact s.
Definition lookup_seed:statement:=ltac:(seed_statement 0%nat).
Definition exempt_in:statement:=ltac:(seed_statement 1%nat).
Definition zero_result:statement:=ltac:(seed_statement 2%nat).
Definition root_visit:statement:=ltac:(seed_statement 3%nat).
Definition exempt_out:statement:=ltac:(seed_statement 4%nat).
Definition return_on_hit:statement:=ltac:(seed_statement 5%nat).
Definition finish_orbit:statement:=ltac:(seed_statement 6%nat).
Definition visit_and_restore:=Ssequence exempt_in (Ssequence zero_result (Ssequence root_visit exempt_out)).
Lemma native_policy_iteration :
 iteration=Ssequence lookup_seed (Ssequence exempt_in (Ssequence zero_result
   (Ssequence root_visit (Ssequence exempt_out (Ssequence return_on_hit finish_orbit))))).
Proof. reflexivity. Qed.
Lemma checked_zero_result:zero_result=Sset _result (Econst_int (Int.repr 0) tint).
Proof. reflexivity. Qed.
Record root_phases := {
 seed_order:list int;
 waiting:Z->mpred;
 returned:Z->Z->mpred;
 observation:Z->Z->Prop
}.
Definition root_count c:=Zlength (seed_order c).
Definition exhausted_before c i:=forall j,0<=j<i -> observation c j 0.
Definition stop_at c i r :=
 (i=root_count c /\ r=0) \/ (0<=i<root_count c /\ r<>0 /\ observation c i r).
Definition after_stop c i r:=if Z.eq_dec r 0 then waiting c i else returned c i r.
Definition seed_vector c array:=if Z.eq_dec (root_count c) 0 then emp else
 data_at Tsh (tarray tint (root_count c)) (map Vint (seed_order c)) array.
Lemma live_seed_vector c array:0<root_count c ->
 seed_vector c array=data_at Tsh (tarray tint (root_count c)) (map Vint (seed_order c)) array.
Proof. intro positive;unfold seed_vector;destruct Z.eq_dec;[lia|reflexivity]. Qed.
Definition policy_seeds_at c p array :=
 (field_at Tsh (Tstruct _cc_level_policy noattr) [StructField _seed_count] (Vint (Int.repr (root_count c))) p *
  field_at Tsh (Tstruct _cc_level_policy noattr) [StructField _seed] array p *
  seed_vector c array * weak_valid_pointer p)%logic.
Definition outer_loc c s p i :=
 [temp _s s;temp _policy p;temp _i (Vint (Int.repr i));temp _count (Vint (Int.repr (root_count c)))].
Definition selected_loc c s p i:=temp _q (Vint (Znth i (seed_order c)))::outer_loc c s p i.
Definition result_loc c s p i r:=temp _result (Vint (Int.repr r))::selected_loc c s p i.
Definition start_seed c s p a i :=
 PROPx [] (LOCALx (selected_loc c s p i) (SEPx [policy_seeds_at c p a;waiting c i])).
Definition post_visit c s p a i r:=
 PROPx [0<=r<=3;observation c i r] (LOCALx (result_loc c s p i r) (SEPx [policy_seeds_at c p a;returned c i r])).
Definition next_orbit c s p a i:=
 PROPx [] (LOCALx (outer_loc c s p i) (SEPx [policy_seeds_at c p a;waiting c (i+1)])).
Definition policy_root_spec c s p a :ident*funspec:=
 DECLARE _cc_run_level WITH u:unit
 PRE [tptr level_type,tptr (Tstruct _cc_level_policy noattr)]
 PROP(isptr p;0<=root_count c<=Int.max_signed) PARAMS(s;p)
 SEP(policy_seeds_at c p a;waiting c 0)
 POST [tint] EX i:Z,EX r:Z,
 PROP(exhausted_before c i;stop_at c i r;0<=r<=3)
 RETURN(Vint (Int.repr r)) SEP(policy_seeds_at c p a;after_stop c i r).
Lemma extend_exhaustion c i:exhausted_before c i -> observation c i 0 -> exhausted_before c (i+1).
Proof. unfold exhausted_before;intros prior done j bound;destruct (Z.eq_dec j i);[subst;assumption|apply prior;lia]. Qed.

(* The root calls DFS at depth one, including for weights one and two. *)
Definition root_dfs c:ident*funspec :=
 DECLARE _dfs WITH s:val,cp:val,w:Z,q:Z,st:snapshot,path:list int
 PRE [tptr level_type,tptr (Tstruct _cc_level_policy noattr),tint]
 PROP(1<=w<=Int.max_signed;w<=Zlength path;0<=q<Zlength (blocked st);Znth 0 path=Int.repr q)
 PARAMS(s;nested_policy (nested c);Vint Int.one)
 SEP(enabled_memory c s cp w path st;active_support (nested c) s (Some q))
 POST [tint] EX final:snapshot,EX tail:list int,
 PROP(same_search final st;0<=child_outcome (nested c) (blocked st) q<=3;
  Zlength tail=Zlength path;Znth 0 tail=Int.repr q;
  child_outcome (nested c) (blocked st) q<>0 -> returned_trace (nested c) (blocked st) q tail)
 RETURN(Vint (Int.repr (child_outcome (nested c) (blocked st) q)))
 SEP(enabled_memory c s cp w tail final;active_support (nested c) s (Some q)).
Definition RootG c:funspecs:=ltac:(let fs:=constr:([enter_child (nested c);root_dfs c]) in with_library prog fs).
