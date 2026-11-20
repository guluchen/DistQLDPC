(* Complete actual inner search while loop. Normal exit certifies completion
   of this root seed; early FOUND/UNKNOWN obey the function result contract.
   This does not yet compose the outer seed loop or prove total termination. *)
Require Import VST.floyd.proofauto.
Require Import CCV.ccv_core CCV.CCSearchSpecs CCV.CCSearchContext CCV.CCSearchFragments
 CCV.CCSearchHeap CCV.CCLoopInvariant CCV.CCStackInvariant CCV.CCSearchExit CCV.CCJournalArray
 CCV.CCRootArray CCV.CCSeedCoverage CCV.CCAPIBridge CCV.VerifMainIteration.
Import ListNotations. Open Scope Z_scope.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
Definition main_loop_finished sh a p tp rp cap seed budget rules s0:assert:=
 (EX log:list Z,EX buf:list val,EX xs:list Z,EX ys:list Z,EX zs:list Z,EX pk:list Z,
 EX frames:list frame_value,EX s:stats_model,
 PROP(loop_shape a cap seed[][]log buf xs ys zs pk frames;
 seeds_before_clear(Z.to_nat(model_n a))(model_h_rows a)(model_l_rows a)(Z.to_nat cap)(S(Z.to_nat seed));
 legal_stats budget s;stats_monotone s0 s)
 LOCAL(temp _p(ptr_problem p);temp _w(ptr_workspace p);temp _out(ptr_out p);temp _stats(ptr_stats p);
 temp _cap(Vint(Int.repr cap));temp _seed(Vint(Int.repr seed));temp _budget(Vint(Int.repr budget));
 temp _rules(Vint(Int.repr rules));temp _depth(Vint(Int.repr 0));lvar _top tuint tp;lvar _row tuint rp)
 SEP(search_heap sh a p tp rp(Zlength log)xs(journal_bitmap(root_mask(model_n a)seed)log)
 ys zs pk buf frames(Zrepeat 0(model_n a))s))%assert.
Lemma main_loop_actual_layout:search_main_loop=Swhile
 (Ebinop Ogt(Etempvar _depth tuint)(Econst_int(Int.repr 0)tuint)tint)search_main_iteration.
Proof. reflexivity. Qed.
Section Proof.
Context{Espec:OracleKind}.
Theorem block_main_loop:forall sh a p tp rp cap seed budget rules s0,
 readable_share sh ->legal_model a ->1<=cap<=model_n a ->0<=seed<=model_n a ->0<=rules<=63 ->
 semax CCSearchContext.Delta(search_while_invariant sh a p tp rp cap seed budget rules s0)
 search_main_loop
 (overridePost(main_loop_finished sh a p tp rp cap seed budget rules s0)
 (function_body_ret_assert tint(search_return sh a p tp rp cap budget s0))).
Proof.
 intros sh a p tp rp cap seed budget rules s0 SH Legal Cap Seed Rules.
 pose proof(legal_model_ranges a Legal)as[NR More].
 unfold CCSearchContext.Delta;abbreviate_semax.
 rewrite main_loop_actual_layout.
 forward_while(search_while_invariant sh a p tp rp cap seed budget rules s0).
 - apply andp_left2;apply derives_refl.
 - entailer!.
 -
   assert(Whole:loop_shape a cap seed path ghosts log buf xs ys zs pk frames)by assumption.
   assert(Geo:stack_geometry(Z.to_nat(model_n a))(Z.to_nat(model_m a))(Z.to_nat cap)
   (model_h_rows a)path ghosts log)by(unfold loop_shape in Whole;tauto).
   assert(Nonempty:path<>[]).
   { intro Empty;subst path;multimatch goal with Bad:_|-_=>change(0<0)%Z in Bad;lia end. }
   assert(GLen:length path=length ghosts)by(unfold stack_geometry in Geo;tauto).
   assert(GNonempty:ghosts<>[])by(intro Empty;rewrite Empty in GLen;destruct path;[contradiction|discriminate]).
   assert(Split:ghosts=removelast ghosts++[last ghosts empty_ghost])by(apply app_removelast_last;assumption).
   rewrite Split in Whole.
   eapply semax_post with(R':=overridePost(search_while_invariant sh a p tp rp cap seed budget rules s0)
   (function_body_ret_assert tint(search_return sh a p tp rp cap budget s0))).
   + unfold POSTCONDITION,abbreviate.
     cbn[RA_normal overridePost function_body_ret_assert loop1_ret_assert].
     unfold search_while_invariant. Intros p2 g2 l2 b2 x2 y2 z2 k2 f2 s2.
     Exists (((((((((p2,g2),l2),b2),x2),y2),z2),k2),f2),s2). entailer!;cancel.
   + cbn[RA_break overridePost function_body_ret_assert];normalize.
   + cbn[RA_continue overridePost function_body_ret_assert];normalize.
   + intros vl;cbn[RA_return overridePost function_body_ret_assert];apply andp_left2;apply derives_refl.
   + eapply semax_pre.
     2:{ apply(block_main_iteration sh a p tp rp cap seed budget rules s0 s path
     (removelast ghosts)(last ghosts empty_ghost)log buf xs ys zs pk frames);assumption. }
     unfold iteration_head;go_lowerx;normalize;cancel;try(apply andp_right;[apply prop_right;tauto|cancel]).
 -
   assert(Whole:loop_shape a cap seed path ghosts log buf xs ys zs pk frames)by assumption.
   assert(Geo:stack_geometry(Z.to_nat(model_n a))(Z.to_nat(model_m a))(Z.to_nat cap)
   (model_h_rows a)path ghosts log)by(unfold loop_shape in Whole;tauto).
   destruct Geo as[GLen[ND[Range MoreGeo]]].
   pose proof(CCSearchPhases.path_length_bound(Z.to_nat(model_n a))path ND Range)as Capacity.
   assert(DepthRange:0<=Z.of_nat(length path)<=Int.max_unsigned).
   { apply Nat2Z.inj_le in Capacity;rewrite Z2Nat.id in Capacity by lia;rep_lia. }
   assert(PathEmpty:path=[]).
   { assert(LenZero:Z.of_nat(length path)=0)by(rewrite Int.unsigned_repr in HRE by lia;lia).
     destruct path;[reflexivity|cbn in LenZero;lia]. }
   assert(GhostsEmpty:ghosts=[]).
   { rewrite PathEmpty in GLen;destruct ghosts;[reflexivity|cbn in GLen;lia]. }
   pose proof(empty_loop_shape_advances a cap seed path ghosts log buf xs ys zs pk frames Whole PathEmpty)as Advanced.
   subst path ghosts.
   forward.
   unfold main_loop_finished. Exists log buf xs ys zs pk frames s.
   entailer!;cancel.
Qed.
End Proof.
Print Assumptions block_main_loop.
