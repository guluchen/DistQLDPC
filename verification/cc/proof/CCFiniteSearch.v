(* Finite-or-blocked behavior of the entire proof-only search, including
   its outer seed loop. The depth is symbolic throughout. *)
Require Import VST.floyd.proofauto compcert.lib.Maps.
Require Import CCV.ccv_core CCV.ccv_primitives CCV.CCStructuredRuns CCV.CCScanFrames
 CCV.CCScanGuard CCV.CCCountedScan CCV.CCCursorScan CCV.CCActualScans CCV.CCIterationScans
 CCV.CCScanCallees CCV.CCRestoreSettles CCV.CCExpandedBody CCV.CCBoundedMain
 CCV.CCSearchFragments CCV.VerifRootFrameContinuation CCV.VerifSeedLoop.
Import ListNotations.
Definition helper_bindings : list (ident*Clight.function) :=
 [(_clear,f_clear);(_toggle,f_toggle);(_nontrivial,f_nontrivial);(_restore,f_restore);
  (_forbid,f_forbid);(_overlap,f_overlap);(_bounds,f_bounds);(_leaf,f_leaf);
  (_ccv_ceil_div,ccv_primitives.f_ccv_ceil_div)].
Definition helpers_bound (p:Clight.program) :=
 forall i f, In (i,f) helper_bindings -> PTree.get i (AST.prog_defmap p)=Some (Gfun (Internal f)).
Section Finite.
Variable p:Clight.program.
Hypothesis bindings:helpers_bound p.
Local Notation ge := (Clight.globalenv p).
Local Ltac named_helper i :=
 lazymatch i with
 | _clear => constr:(f_clear) | _toggle => constr:(f_toggle)
 | _nontrivial => constr:(f_nontrivial) | _restore => constr:(f_restore)
 | _forbid => constr:(f_forbid) | _overlap => constr:(f_overlap)
 | _bounds => constr:(f_bounds) | _leaf => constr:(f_leaf)
 | ccv_core._ccv_ceil_div => constr:(ccv_primitives.f_ccv_ceil_div) end.
Local Ltac binding := apply bindings;unfold helper_bindings;repeat(first [left;reflexivity|right]).
Create HintDb search_callees.
Local Ltac structure :=
 lazymatch goal with
 | H:framed _ _ _ ?s |- framed _ _ _ ?s => exact H
 | |- framed _ _ _ (Ssequence _ _) => apply framed_seq;structure
 | |- framed _ _ _ (Sifthenelse _ _ _) => apply framed_if;structure
 | |- framed _ _ _ (Sloop (Ssequence _ _) (Sset ?id _)) =>
   apply (bounded_scan _ _ _ id);[closed_guard|structure|vm_compute;intuition congruence]
 | |- framed _ _ _ (Sloop (Ssequence _ (Sset ?id _)) Sskip) =>
   apply (while_increment _ _ _ id);
   [apply short_guard;apply produce_prefix;[closed_frame|apply short_comparison;
     [reflexivity|vm_compute;intuition congruence|closed_frame]]|vm_compute;intuition congruence]
 | |- framed _ _ _ (Scall _ (Evar ?id _) _) =>
   let f:=named_helper id in eapply (framed_direct_call p id _ f _ _ _);
   [binding|first [apply PTree.gempty|match goal with H:search_locals _ |- _=> apply H;discriminate end]|
    solve[eauto with search_callees]]
 | _ => closed_frame
 end.
Local Ltac helper f := apply structured_function_returns;intros args m e l m' Enter;
 pose proof(empty_call_env _ f _ _ _ _ _ eq_refl Enter) as Empty;subst e;
 cbn [fn_body f];structure.
Lemma finite_clear:call_settles ge f_clear. Proof. helper f_clear. Qed.
Lemma finite_toggle:call_settles ge f_toggle. Proof. helper f_toggle. Qed.
Lemma finite_nontrivial:call_settles ge f_nontrivial. Proof. helper f_nontrivial. Qed.
Lemma finite_forbid:call_settles ge f_forbid. Proof. helper f_forbid. Qed.
Lemma finite_ceil:call_settles ge ccv_primitives.f_ccv_ceil_div. Proof. helper ccv_primitives.f_ccv_ceil_div. Qed.
#[local] Hint Resolve finite_ceil finite_toggle finite_forbid finite_clear finite_nontrivial restore_settles : search_callees.
Lemma finite_overlap:call_settles ge f_overlap. Proof. helper f_overlap. Qed.
Lemma finite_bounds:call_settles ge f_bounds. Proof. helper f_bounds. Qed.
Lemma finite_leaf:call_settles ge f_leaf. Proof. helper f_leaf. Qed.
#[local] Hint Resolve finite_bounds finite_leaf finite_overlap : search_callees.
Lemma finite_iteration f e : search_locals e -> framed ge f e search_main_iteration.
Proof.
 intro Locals.
 let s:=eval cbv -[Int.repr tptr tuint tint tuchar tbool _clear _nontrivial _forbid _restore _overlap _bounds _toggle _leaf _top _row] in search_main_iteration in
 change(framed ge f e s);structure.
Qed.
Lemma expanded_heads f e n : search_locals e -> framed ge f e (bounded_main n).
Proof.
 intro Locals;induction n as [|n IH];cbn[bounded_main];[apply framed_set|].
 apply framed_if;[apply framed_seq;[apply finite_iteration;assumption|exact IH]|apply framed_skip].
Qed.
Lemma protected_seed n : ~In _seed (assigned (bounded_main n)).
Proof.
 induction n as [|n IH];[vm_compute;intuition congruence|].
 cbn [bounded_main assigned];rewrite !in_app_iff;intro C;destruct C as [[C|C]|C];
 [revert C;vm_compute;intuition congruence|contradiction|contradiction].
Qed.
Lemma seed_context f e middle : search_locals e -> framed ge f e middle ->
 ~In _seed (assigned middle) -> framed ge f e (body_with middle).
Proof.
 intros Locals Inside Outside.
 let s:=eval cbv -[Int.repr tptr tuint tint tuchar tbool _clear _toggle _restore _nontrivial _forbid _overlap _bounds _leaf _top _row _seed] in (body_with middle) in
 change (framed ge f e s).
 repeat lazymatch goal with
 | |- framed _ _ _ (Ssequence _ _) => apply framed_seq
 | |- framed _ _ _ (Sloop _ _) => fail
 | _ => structure end.
 apply (bounded_scan _ _ _ _seed).
 - closed_guard.
 - structure.
 - cbv beta iota delta [assigned List.app fst snd].
   repeat rewrite in_app_iff. simpl. intuition (subst;first [contradiction|discriminate]).
Qed.
Theorem expanded_search_settles n : call_settles ge (with_body f_search (body_with (bounded_main n))).
Proof.
 apply structured_function_returns;intros args m e l m' Entry.
 apply seed_context;[|apply expanded_heads|apply protected_seed];
 intros id T R;inversion Entry;subst;
 match goal with A:Clight.alloc_variables _ _ _ _ _ _ |- _ =>
 rewrite (alloc_keeps_globals _ _ _ _ _ _ A);[apply PTree.gempty|simpl;intuition] end.
Qed.
End Finite.
