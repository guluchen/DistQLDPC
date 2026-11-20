(* Complete actual canonical-root seed loop. Only completed inner searches
   advance the all-minimum-target coverage invariant. *)
Require Import VST.floyd.proofauto.
Require Import CCV.ccv_core CCV.CCSearchSpecs CCV.CCSearchContext CCV.CCSearchFragments
 CCV.CCSearchHeap CCV.CCRawTopHeap CCV.CCSeedLoopState CCV.CCSearchExit CCV.CCAPIBridge
 CCV.VerifRootPreparation CCV.VerifRootSeedBody CCV.VerifMainLoop.
Import ListNotations. Open Scope Z_scope.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
Definition seed_limit_read:=Sset _t'50(Efield(Ederef(Etempvar _p(tptr(Tstruct _ccv_problem noattr)))
 (Tstruct _ccv_problem noattr))_n tuint).
Definition seed_limit_test:=Sifthenelse(Ebinop Olt(Etempvar _seed tuint)(Etempvar _t'50 tuint)tint)Sskip Sbreak.
Definition seed_increment:=Sset _seed(Ebinop Oadd(Etempvar _seed tuint)(Econst_int(Int.repr 1)tint)tuint).
Lemma seed_loop_actual_layout:search_seed_loop=
 Sloop(Ssequence(Ssequence seed_limit_read seed_limit_test)root_seed_body)seed_increment.
Proof. reflexivity. Qed.
Section Proof.
Context{Espec:OracleKind}.
Theorem block_seed_loop:forall sh a p tp rp cap budget rules s0,
 readable_share sh ->legal_model a ->1<=cap<=model_n a ->0<=rules<=63 ->
 semax CCSearchContext.Delta(seed_loop_invariant sh a p tp rp cap budget rules s0)
 search_seed_loop
 (overridePost(seed_loop_finished sh a p tp rp cap budget rules s0)
 (function_body_ret_assert tint(search_return sh a p tp rp cap budget s0))).
Proof.
 intros sh a p tp rp cap budget rules s0 SH Legal Cap Rules.
 pose proof(legal_model_ranges a Legal)as[NR More].
 unfold CCSearchContext.Delta;abbreviate_semax.
 rewrite seed_loop_actual_layout.
 forward_loop(seed_loop_invariant sh a p tp rp cap budget rules s0)
 continue:(seed_loop_continue sh a p tp rp cap budget rules s0)
 break:(seed_loop_finished sh a p tp rp cap budget rules s0).
 - apply andp_left2;apply derives_refl.
 - unfold seed_loop_invariant;Intros seed top xs fs ys zs pk buf frames out s.
   unfold search_heap_raw_top,problem_repr. Intros.
   unfold seed_limit_read,seed_limit_test. forward.
   apply semax_if_seq. forward_if.
   + repeat apply -> semax_skip_seq.
     assert(Inside:0<=seed<model_n a)by(try rewrite !Int.unsigned_repr in * by rep_lia;lia).
     eapply semax_post with(R':=overridePost(main_loop_finished sh a p tp rp cap seed budget rules s0)
     (function_body_ret_assert tint(search_return sh a p tp rp cap budget s0))).
     * unfold POSTCONDITION,abbreviate.
       cbn[RA_normal loop1_ret_assert overridePost function_body_ret_assert].
       apply andp_left2;apply seed_finished_to_continue;assumption.
     * cbn[RA_break overridePost function_body_ret_assert];normalize.
     * cbn[RA_continue overridePost function_body_ret_assert];normalize.
     * intros vl;cbn[RA_return overridePost function_body_ret_assert];apply andp_left2;apply derives_refl.
     * eapply semax_pre.
       2:{ apply(block_root_seed_body sh a p tp rp cap seed budget rules top xs fs ys zs pk buf frames out s0 s);
       assumption. }
       unfold root_state_raw,search_heap_raw_top,problem_repr.
       go_lowerx;normalize;cancel;try(apply andp_right;[apply prop_right;tauto|cancel]).
   + assert(AtEnd:seed=model_n a)by(try rewrite !Int.unsigned_repr in * by rep_lia;lia).
     subst seed. forward.
     unfold seed_loop_finished,search_heap_raw_top,problem_repr.
     Exists top xs fs ys zs pk buf frames out s.
     entailer!;cancel.
 - unfold seed_loop_continue;Intros seed top xs fs ys zs pk buf frames out s.
   assert(Add:Int.add(Int.repr seed)(Int.repr 1)=Int.repr(seed+1)).
   { unfold Int.add;rewrite !Int.unsigned_repr by rep_lia;reflexivity. }
   assert(NextNat:Z.to_nat(seed+1)=S(Z.to_nat seed))by(rewrite Z2Nat.inj_add by lia;cbn;lia).
   unfold seed_increment. forward. rewrite Add.
   unfold seed_loop_invariant. Exists(seed+1)top xs fs ys zs pk buf frames out s.
   rewrite NextNat. entailer!;cancel.
 - cbn[RA_normal overridePost function_body_ret_assert];apply andp_left2;apply derives_refl.
Qed.
End Proof.
Print Assumptions block_seed_loop.
