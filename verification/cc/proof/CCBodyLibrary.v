(* Public VST soundness for a library whose search and distance bodies are
   replaced by other proofs of their original specifications. *)
Require Import VST.floyd.proofauto VST.floyd.SeparationLogicAsLogicSoundness.
Require Import CCV.ccv_core CCV.CCCompactLibrary CCV.CCBodyLifts CCV.CCBodyProgram CCV.CCExpandedBody CCV.CCLibraryFunctions
 CCV.CCLibraryEntry CCV.CCLinkedProgram CCV.CCSearchSpecs CCV.CCSearchContext
 CCV.CCDriverContext CCV.CCDriverProgram CCV.CCVerificationDriver CCV.VerifDistance.
Import ListNotations.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
Section Checked.
Variables search distance:statement.
Local Notation driver := (proof_driver search distance).
Local Notation lib := (proof_library search distance).
Hypothesis search_ok : semax_body CCSearchContext.Vprog CCSearchContext.Gprog
 (with_body f_search search) search_spec.
Hypothesis dist_ok : @semax_body VerifDistance.Vprog VerifDistance.Gprog VerifDistance.CompSpecs
 (with_body f_ccv_distance distance) distance_spec.
Local Definition located (g:Genv.t Clight.fundef type) (fs:list(ident*Clight.fundef)):Prop:=
 forall i f,In (i,f) fs ->exists b,Genv.find_symbol g i=Some b /\ Genv.find_funct_ptr g b=Some f.
Local Lemma pop_loc g id f tail:located g ((id,f)::tail) ->
 (exists b,Genv.find_symbol g id=Some b /\ Genv.find_funct_ptr g b=Some f) /\ located g tail.
Proof.
 intro All;split;[apply All;left;reflexivity|intros i fn H;apply All;right;assumption].
Qed.
Local Ltac use_location f :=
 match goal with All:located _ _ |- _=>
 let Sym:=fresh "address" in let Code:=fresh "binding" in let Tail:=fresh "locations" in
 destruct(pop_loc _ _ _ _ All) as [[?b [Sym Code]] Tail];clear All;
 f Sym Code;clear Sym Code b end.
Local Ltac external_decl :=
 use_location ltac:(fun Sym Code=>eapply semax_func_cons_ext_vacuous;
  [lazy;reflexivity|reflexivity|exact Sym|exact Code|]).
Local Ltac quick_cons L :=
 use_location ltac:(fun Sym Code=>eapply semax_func_cons;
 [ lazy;reflexivity
 | repeat apply Forall_cons;try apply Forall_nil;try computable;reflexivity
 | unfold var_sizes_ok;repeat constructor;try(simpl;rep_lia)
 | reflexivity | exact Sym | exact Code | exact L | ]);
 repeat external_decl;try apply semax_func_nil.
Local Ltac next_internal :=
 lazymatch goal with|-semax_func _ _ _ ?fs _=>
 let xs:=eval hnf in fs in lazymatch xs with(?id,Internal _)::_=>
 idtac "verified declaration" id;first[
 unify id ccv_core._shape;quick_cons lift_body_shape_legal
 | unify id ccv_core._validate;quick_cons lift_body_validate_legal
 | unify id ccv_core._clear;quick_cons lift_body_clear
 | unify id ccv_core._toggle;quick_cons lift_body_core_toggle
 | unify id ccv_core._nontrivial;quick_cons lift_body_nontrivial
 | unify id ccv_core._restore;quick_cons lift_body_restore
 | unify id ccv_core._forbid;quick_cons lift_body_forbid
 | unify id ccv_core._overlap;quick_cons lift_body_overlap
 | unify id ccv_core._bounds;quick_cons lift_body_bounds
 | unify id ccv_core._leaf;quick_cons lift_body_leaf
 | unify id ccv_core._search;quick_cons (lift_search _ search_ok)
 | unify id ccv_core._stats_init;quick_cons body_stats_linked
 | unify id ccv_core._ccv_decide;quick_cons lift_body_decide_modular
 | unify id ccv_core._ccv_distance;quick_cons (lift_distance _ dist_ok)
 | unify id ccv_primitives._ccv_bit_xor;quick_cons lift_body_bit_xor
 | unify id ccv_primitives._ccv_ceil_div;quick_cons lift_body_ceil_div
 | unify id ccv_primitives._ccv_dot;quick_cons lift_body_dot
 | unify id ccv_primitives._ccv_weight;quick_cons lift_body_weight
 | unify id ccv_primitives._ccv_toggle;quick_cons lift_body_toggle
 ]
 | _=>fail "No next internal function"
 end end.
Lemma generic_library {Espec:OracleKind} g:located g (prog_funct lib) ->
 semax_func CCSearchContext.Vprog linked_Gprog g (prog_funct lib) linked_Gprog.
Proof.
 rewrite compact_library_correct. rewrite <-compact_specs_correct at 2.
 unfold compact_functions,compact_specs. intro locations.
 repeat external_decl.
 repeat next_internal.
Qed.
Local Lemma located_prefix (p:Clight.program) xs ys:list_norepet(prog_defs_names p) ->
 prog_funct p=(xs++ys)%list ->located (Genv.globalenv p) xs.
Proof.
 intros ND Eq i fn InList.
 assert (M:In(i,fn)(prog_funct p)) by (rewrite Eq;apply in_or_app;left;exact InList).
 exact (semax_prog.prog_contains_prog_funct p ND i fn M).
Qed.
Lemma replacement_library {Espec:OracleKind} : semax_func CCSearchContext.Vprog linked_Gprog
 (Genv.globalenv driver) (prog_funct lib) linked_Gprog.
Proof.
 apply generic_library. apply (located_prefix driver _ [(driver_id,Internal driver_fn)]).
 - apply compute_list_norepet_e;vm_compute;reflexivity.
 - apply proof_driver_functions.
Qed.
Context {Espec:OracleKind} (ora:OK_ty).
Definition body_main_spec:ident*funspec := (driver_id,main_spec_ext driver ora).
Definition body_specs:funspecs := linked_Gprog ++ [body_main_spec].
Lemma replacement_extends : tycontext_subVG CCSearchContext.Vprog linked_Gprog CCSearchContext.Vprog body_specs.
Proof.
 split;intro i;[apply make_tycontext_g_app1;[apply old_no_duplicate_specs|apply compute_list_norepet_e;vm_compute;reflexivity]|apply subsumespec_app1].
Qed.
Local Transparent tint eval_expr tc_expr force_val.
Lemma body_stub:semax_body CCSearchContext.Vprog body_specs driver_fn body_main_spec.
Proof.
 split;[reflexivity|];split;[reflexivity|];intros E ts x.
 eapply semax_pre;[|apply semax_return]. intro rho.
 match goal with |- ?P |-- _ => change (P |-- TT && ((!! True && TT) * emp)) end.
 rewrite sepcon_emp;repeat apply andp_right;try apply TT_right;apply prop_right;exact I.
Qed.
Lemma replacement_functions:semax_func CCSearchContext.Vprog body_specs
 (Genv.globalenv driver)(prog_funct driver)body_specs.
Proof.
 rewrite proof_driver_functions. unfold body_specs at 2;apply semax_func_app.
 - eapply semax_func_subsumption with (V:=CCSearchContext.Vprog)(F:=linked_Gprog).
   + exact(tycontext_sub_i99 (Clight.mkfunction Tvoid cc_default [] [] [] Sskip) _ _ _ _ [] replacement_extends).
   + apply(proj1 replacement_extends).
   + apply replacement_library.
 - prove_semax_prog_setup_globalenv.
   eapply semax_func_cons;[vm_compute;reflexivity|constructor|constructor|reflexivity|LookupID|LookupB|apply body_stub|apply semax_func_nil].
 - reflexivity.
Qed.
Theorem checked_replacement_program:semax_prog driver ora CCSearchContext.Vprog body_specs.
Proof.
 split3;[ | |split3;[ | |split]].
 - vm_compute;reflexivity.
 - vm_compute;reflexivity.
 - change (Maps.PTree.elements (@cenv_cs CCSearchSpecs.CompSpecs)=Maps.PTree.elements (prog_comp_env linked_prog)).
   rewrite linked_composite_env;reflexivity.
 - apply replacement_functions.
 - reflexivity.
 - change(exists post,main_spec_ext driver ora=main_spec_ext' driver ora post);eexists;reflexivity.
Qed.
Theorem replacement_context : library_context Espec CCSearchSpecs.CompSpecs CCSearchContext.Vprog body_specs driver.
Proof.
 destruct (@MainTheorem.CSHL_Sound.semax_prog_sound _ _ _ _ _ _ checked_replacement_program)
 as [NoDup [Align [Env [Funcs [Vars Main]]]]];constructor;assumption.
Qed.
End Checked.
