(* A finite proof-only unfolding of the frozen depth loop. The final
   instruction is deliberately stuck. Its verified precondition can hold
   only when there is enough depth for the original budget guard to return
   on exhaustion. No run of the solver is used to pick that depth. *)
Require Import VST.floyd.proofauto.
Require Import CCV.ccv_core CCV.CCSearchSpecs CCV.CCSearchContext CCV.CCSearchHeap
 CCV.CCLoopInvariant CCV.CCStackInvariant CCV.CCSearchExit CCV.CCSearchFragments
 CCV.CCAPIBridge CCV.CCStatsFields CCV.CCStatsInvariant CCV.VerifMainIteration CCV.VerifGuardedProgress CCV.VerifMainLoop.
Import ListNotations. Open Scope Z_scope.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
Definition unreachable_read := Sset _i (Ederef (Econst_int Int.zero tint) tuint).
Definition depth_guard := Ebinop Ogt (Etempvar _depth tuint) (Econst_int (Int.repr 0) tuint) tint.
Fixpoint bounded_main (n:nat) : statement :=
 match n with
 | O => unreachable_read
 | S tail => Sifthenelse depth_guard (Ssequence search_main_iteration (bounded_main tail)) Sskip
 end.
Section Proof.
Context {Espec:OracleKind}.
Theorem checked_bounded_main sh a p tp rp cap seed budget rules s0 :
 readable_share sh -> legal_model a -> 1<=cap<=model_n a -> 0<=seed<=model_n a ->
 0<=rules<=63 -> forall n base, stats_monotone s0 base ->
 budget-stat_steps base<Z.of_nat n ->
 semax CCSearchContext.Delta (search_while_invariant sh a p tp rp cap seed budget rules base)
 (bounded_main n)
 (overridePost (main_loop_finished sh a p tp rp cap seed budget rules s0)
   (function_body_ret_assert tint (search_return sh a p tp rp cap budget s0))).
Proof.
 intros SH Legal Cap Seed Rules.
 pose proof (legal_model_ranges a Legal) as [NR More].
 induction n as [|n IH];intros base Mono Room.
 - unfold search_while_invariant;Intros path ghosts log buf xs ys zs pk frames s.
   exfalso;unfold legal_stats,stats_monotone in *;cbn in Room;lia.
 - cbn [bounded_main];unfold depth_guard.
   unfold search_while_invariant at 1;Intros path ghosts log buf xs ys zs pk frames s.
   assert(Whole:loop_shape a cap seed path ghosts log buf xs ys zs pk frames)by assumption.
   assert(Geo:stack_geometry(Z.to_nat(model_n a))(Z.to_nat(model_m a))(Z.to_nat cap)
                (model_h_rows a)path ghosts log)by(unfold loop_shape in Whole;tauto).
   assert(Initial:stats_monotone s0 s)by(eapply stats_monotone_trans;eassumption).
   assert(GLen:length path=length ghosts)by(unfold stack_geometry in Geo;tauto).
   pose proof(CCSearchPhases.path_length_bound (Z.to_nat(model_n a)) path
     (proj1(proj2 Geo)) (proj1(proj2(proj2 Geo)))) as Capacity.
   assert(DRange:0<=Z.of_nat(length path)<=Int.max_unsigned).
   { apply Nat2Z.inj_le in Capacity;rewrite Z2Nat.id in Capacity by lia;rep_lia. }
   unfold CCSearchContext.Delta;abbreviate_semax;forward_if.
   + assert(Nonempty:path<>[])by(intro E;subst;multimatch goal with Bad:_|-_=>change(0<0)%Z in Bad;lia end).
     assert(GNonempty:ghosts<>[])by(intro E;rewrite E in GLen;destruct path;[contradiction|discriminate]).
     assert(Split:ghosts=removelast ghosts++[last ghosts empty_ghost])by(apply app_removelast_last;assumption).
     rewrite Split in Whole.
     eapply semax_seq with (Q:=search_while_invariant sh a p tp rp cap seed budget rules (step_stats s)).
     * eapply semax_pre.
       2:{ apply (block_guarded_iteration_progress sh a p tp rp cap seed budget rules s0 s path
             (removelast ghosts)(last ghosts empty_ghost)log buf xs ys zs pk frames);assumption. }
       unfold iteration_head;go_lowerx;normalize;cancel;try(apply andp_right;[apply prop_right;tauto|cancel]).
     * apply IH.
       -- unfold stats_monotone,step_stats in *;cbn;lia.
       -- rewrite Nat2Z.inj_succ in Room;unfold stats_monotone,step_stats in *;cbn;lia.
   + assert(PathEmpty:path=[]).
     { assert(LenZero:Z.of_nat(length path)=0)by(try rewrite !Int.unsigned_repr in * by lia;lia).
       destruct path;[reflexivity|cbn in LenZero;lia]. }
     assert(GhostsEmpty:ghosts=[])by(rewrite PathEmpty in GLen;destruct ghosts;[reflexivity|cbn in GLen;lia]).
     pose proof(empty_loop_shape_advances a cap seed path ghosts log buf xs ys zs pk frames Whole PathEmpty)as Advanced.
     subst path ghosts;forward;unfold main_loop_finished;Exists log buf xs ys zs pk frames s;entailer!;cancel.
Qed.
End Proof.

Lemma unreachable_read_stuck ge f k e le m :
 forall t next,~Clight.step2 ge (Clight.State f unreachable_read k e le m) t next.
Proof.
 intros t next Run;inversion Run;subst;try solve[intuition discriminate].
 match goal with E:Clight.eval_expr _ _ _ _ (Ederef _ _) _ |- _ =>inversion E;subst end.
 match goal with L:Clight.eval_lvalue _ _ _ _ (Ederef _ _) _ _ _ |- _=>inversion L;subst end.
 match goal with C:Clight.eval_expr _ _ _ _ (Econst_int _ _) (Vptr _ _) |- _ =>
 inversion C;subst;match goal with L:Clight.eval_lvalue _ _ _ _ (Econst_int _ _) _ _ _ |- _=>inversion L end end.
Qed.
Corollary finite_main_budget {Espec:OracleKind} sh a p tp rp cap seed budget rules s0 :
 readable_share sh -> legal_model a -> 1<=cap<=model_n a -> 0<=seed<=model_n a ->
 0<=rules<=63 -> legal_stats budget s0 ->
 semax CCSearchContext.Delta (search_while_invariant sh a p tp rp cap seed budget rules s0)
 (bounded_main (S (Z.to_nat (budget-stat_steps s0))))
 (overridePost (main_loop_finished sh a p tp rp cap seed budget rules s0)
   (function_body_ret_assert tint (search_return sh a p tp rp cap budget s0))).
Proof.
 intros;apply checked_bounded_main;auto.
 - unfold stats_monotone;lia.
 - rewrite Nat2Z.inj_succ,Z2Nat.id;unfold legal_stats in *;lia.
Qed.
