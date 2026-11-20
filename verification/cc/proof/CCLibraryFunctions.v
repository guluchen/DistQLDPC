(* Candidate closed-library function proof for the actual CompCert-linked
   frozen units. A normal coqc receipt is required before claiming PASS.
   Library partial correctness only: no main/CLI, termination or C++ theorem. *)
Require Import VST.floyd.proofauto.
Require Import CCV.CCSearchSpecs CCV.CCSearchContext CCV.CCLinkedProgram
 CCV.VerifSearch CCV.VerifDecide CCV.VerifDistance.
Import ListNotations.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
(* Prove this five-store body directly in the final library context to avoid
   expensive conversion of its separately generated compspec proof fields. *)
Lemma body_stats_linked:semax_body CCSearchContext.Vprog linked_Gprog
 ccv_core.f_stats_init VerifStats.stats_init_spec.
Proof. start_function. forward. forward. forward. forward. forward. entailer!. Qed.
(* Adapted from VST2.14 floyd/forward.v semax_func_cons. The internal
   identifier-membership boolean uses kernel-checked vm_compute; the theorem
   and every callee/body obligation are unchanged. Nonvacuous externals fail. *)
Ltac linked_func_cons L :=
 repeat(eapply semax_func_cons_ext_vacuous;[vm_compute;reflexivity|vm_compute;reflexivity|LookupID|LookupB|]);
 try_prove_tycontext_subVG L;
 eapply semax_func_cons;
 [ vm_compute;reflexivity
 | repeat apply Forall_cons;try apply Forall_nil;try computable;reflexivity
 | unfold var_sizes_ok;repeat constructor;try(simpl;rep_lia)
 | reflexivity|LookupID|LookupB
 | try solve[apply L];apply_semax_body L
 | ];
 repeat(eapply semax_func_cons_ext_vacuous;[vm_compute;reflexivity|vm_compute;reflexivity|LookupID|LookupB|]);
 try apply semax_func_nil.
Ltac close_linked_function :=
 lazymatch goal with|-semax_func _ _ _ ?fs _=>
 let xs:=eval hnf in fs in lazymatch xs with(?id,Internal _)::_=>
 first[
 unify id ccv_core._shape;linked_func_cons VerifShape.body_shape_legal
 | unify id ccv_core._validate;linked_func_cons VerifValidate.body_validate_legal
 | unify id ccv_core._clear;linked_func_cons VerifClear.body_clear
 | unify id ccv_core._toggle;linked_func_cons VerifCoreToggle.body_core_toggle
 | unify id ccv_core._nontrivial;linked_func_cons VerifNontrivial.body_nontrivial
 | unify id ccv_core._restore;linked_func_cons VerifRestore.body_restore
 | unify id ccv_core._forbid;linked_func_cons VerifForbid.body_forbid
 | unify id ccv_core._overlap;linked_func_cons VerifOverlap.body_overlap
 | unify id ccv_core._bounds;linked_func_cons VerifBounds.body_bounds
 | unify id ccv_core._leaf;linked_func_cons VerifLeaf.body_leaf
 | unify id ccv_core._search;linked_func_cons VerifSearch.body_search
 | unify id ccv_core._stats_init;linked_func_cons body_stats_linked
 | unify id ccv_core._ccv_decide;linked_func_cons VerifDecide.body_decide_modular
 | unify id ccv_core._ccv_distance;linked_func_cons VerifDistance.body_distance_modular
 | unify id ccv_primitives._ccv_bit_xor;linked_func_cons VerifPrimitives.body_bit_xor
 | unify id ccv_primitives._ccv_ceil_div;linked_func_cons VerifPrimitives.body_ceil_div
 | unify id ccv_primitives._ccv_dot;linked_func_cons VerifDot.body_dot
 | unify id ccv_primitives._ccv_weight;linked_func_cons VerifWeight.body_weight
 | unify id ccv_primitives._ccv_toggle;linked_func_cons VerifToggle.body_toggle
 ]
 | _=>fail "No next internal function"
 end end.
Section LibraryProof.
Context{Espec:OracleKind}.
Theorem linked_library_functions:semax_func CCSearchContext.Vprog linked_Gprog
 (Genv.globalenv linked_prog)(prog_funct linked_prog)linked_Gprog.
Proof.
 prove_semax_prog_setup_globalenv.
 assert(SameContext:tycontext_subVG CCSearchContext.Vprog linked_Gprog CCSearchContext.Vprog linked_Gprog).
 { split;intro i;[apply sub_option_refl|apply subsumespec_refl]. }
 repeat(eapply semax_func_cons_ext_vacuous;[vm_compute;reflexivity|vm_compute;reflexivity|LookupID|LookupB|]).
 repeat close_linked_function.
Qed.
End LibraryProof.
Print Assumptions linked_library_functions.

