(* Outer canonical-seed loop states. These definitions and bridges do not
   by themselves prove the actual outer loop. *)
Require Import VST.floyd.proofauto.
Require Import CCV.ccv_core CCV.CCSearchSpecs CCV.CCSearchHeap CCV.CCRawTopHeap CCV.CCJournalArray
 CCV.CCRootArray CCV.CCSeedCoverage CCV.CCSearchExit CCV.CCSearchResults CCV.CCAPIBridge
 CCV.CCLoopInvariant CCV.CCPhaseZeroPrunerFacts CCV.VerifMainLoop.
Import ListNotations. Open Scope Z_scope.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
Definition seed_loop_invariant sh a p tp rp cap budget rules s0:assert:=
 (EX seed:Z,EX top:val,EX xs:list Z,EX fs:list Z,EX ys:list Z,EX zs:list Z,
 EX pk:list Z,EX buf:list val,EX frames:list frame_value,EX out:list Z,EX s:stats_model,
 PROP(0<=seed<=model_n a;seeds_before_clear(Z.to_nat(model_n a))(model_h_rows a)(model_l_rows a)(Z.to_nat cap)(Z.to_nat seed);
 legal_stats budget s;stats_monotone s0 s;Zlength xs=model_n a;Zlength fs=model_n a;
 Zlength ys=model_m a;Zlength zs=model_l a;Zlength pk=model_n a;Zlength out=model_n a)
 LOCAL(temp _p(ptr_problem p);temp _w(ptr_workspace p);temp _out(ptr_out p);temp _stats(ptr_stats p);
 temp _cap(Vint(Int.repr cap));temp _seed(Vint(Int.repr seed));temp _budget(Vint(Int.repr budget));
 temp _rules(Vint(Int.repr rules));lvar _top tuint tp;lvar _row tuint rp)
 SEP(search_heap_raw_top sh a p tp rp top xs fs ys zs pk buf frames out s))%assert.
Definition seed_loop_continue sh a p tp rp cap budget rules s0:assert:=
 (EX seed:Z,EX top:val,EX xs:list Z,EX fs:list Z,EX ys:list Z,EX zs:list Z,
 EX pk:list Z,EX buf:list val,EX frames:list frame_value,EX out:list Z,EX s:stats_model,
 PROP(0<=seed<model_n a;seeds_before_clear(Z.to_nat(model_n a))(model_h_rows a)(model_l_rows a)(Z.to_nat cap)(S(Z.to_nat seed));
 legal_stats budget s;stats_monotone s0 s;Zlength xs=model_n a;Zlength fs=model_n a;
 Zlength ys=model_m a;Zlength zs=model_l a;Zlength pk=model_n a;Zlength out=model_n a)
 LOCAL(temp _p(ptr_problem p);temp _w(ptr_workspace p);temp _out(ptr_out p);temp _stats(ptr_stats p);
 temp _cap(Vint(Int.repr cap));temp _seed(Vint(Int.repr seed));temp _budget(Vint(Int.repr budget));
 temp _rules(Vint(Int.repr rules));lvar _top tuint tp;lvar _row tuint rp)
 SEP(search_heap_raw_top sh a p tp rp top xs fs ys zs pk buf frames out s))%assert.
Definition seed_loop_finished sh a p tp rp cap budget rules s0:assert:=
 (EX top:val,EX xs:list Z,EX fs:list Z,EX ys:list Z,EX zs:list Z,
 EX pk:list Z,EX buf:list val,EX frames:list frame_value,EX out:list Z,EX s:stats_model,
 PROP(True;seeds_before_clear(Z.to_nat(model_n a))(model_h_rows a)(model_l_rows a)(Z.to_nat cap)(Z.to_nat(model_n a));
 legal_stats budget s;stats_monotone s0 s;Zlength xs=model_n a;Zlength fs=model_n a;
 Zlength ys=model_m a;Zlength zs=model_l a;Zlength pk=model_n a;Zlength out=model_n a)
 LOCAL(temp _p(ptr_problem p);temp _w(ptr_workspace p);temp _out(ptr_out p);temp _stats(ptr_stats p);
 temp _cap(Vint(Int.repr cap));temp _seed(Vint(Int.repr (model_n a)));temp _budget(Vint(Int.repr budget));
 temp _rules(Vint(Int.repr rules));lvar _top tuint tp;lvar _row tuint rp)
 SEP(search_heap_raw_top sh a p tp rp top xs fs ys zs pk buf frames out s))%assert.
Lemma seed_finished_to_continue sh a p tp rp cap seed budget rules s0:
 legal_model a ->0<=seed<model_n a ->
 main_loop_finished sh a p tp rp cap seed budget rules s0 |--
 seed_loop_continue sh a p tp rp cap budget rules s0.
Proof.
 intros Legal Seed.
 pose proof(legal_model_ranges a Legal)as[NR More].
 unfold main_loop_finished,seed_loop_continue.
 Intros log buf xs ys zs pk frames s.
 go_lowerx;normalize.
 assert(Whole:loop_shape a cap seed[][]log buf xs ys zs pk frames)by assumption.
 destruct(loop_bitmap_facts a cap seed[][]log buf xs ys zs pk frames Legal ltac:(lia)Whole)
 as[BL[BB[FL FB]]].
 assert(OL:Zlength(Zrepeat 0(model_n a))=model_n a)by(rewrite Zlength_Zrepeat;lia).
 Exists seed(Vint(Int.repr(Zlength log)))xs(journal_bitmap(root_mask(model_n a)seed)log)
 ys zs pk buf frames(Zrepeat 0(model_n a))s.
 rewrite search_heap_raw_top_initialized.
 normalize;cancel;try(apply andp_right;[apply prop_right;unfold loop_shape in Whole;tauto|cancel]).
Qed.
Lemma all_seeds_empty_query a cap:
 0<=cap ->seeds_before_clear(Z.to_nat(model_n a))(model_h_rows a)(model_l_rows a)
 (Z.to_nat cap)(Z.to_nat(model_n a)) ->query_result a cap 0(Zrepeat 0(model_n a)).
Proof.
 intros Cap Before;right;left;split;[reflexivity|split;[reflexivity|]].
 intros e Good.
 pose proof(all_seeds_empty_no_good(Z.to_nat(model_n a))(model_h_rows a)(model_l_rows a)
 (Z.to_nat cap)Before e Good)as Bound.
 apply Nat2Z.inj_lt in Bound;rewrite Z2Nat.id in Bound by assumption;exact Bound.
Qed.
Print Assumptions seed_finished_to_continue.
Print Assumptions all_seeds_empty_query.
