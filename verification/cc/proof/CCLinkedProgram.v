(* Computed CompCert link of the two unchanged, frozen Clight units.
   No C/AST rewrite. Link equality is distinct from a semax_func theorem. *)
Require Import VST.floyd.proofauto.
Require Import compcert.common.Linking.
Require Import CCV.ccv_core CCV.ccv_primitives CCV.CCSearchSpecs CCV.CCSearchContext
 CCV.VerifSearch CCV.VerifDecide CCV.VerifDistance.
Import ListNotations.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
Local Transparent Linking.Linker_prog Linking.Linker_def Linking.Linker_vardef
 Ctypes.Linker_fundef Ctypes.Linker_types Ctypes.Linker_composite_defs Ctypes.Linker_program.
Local Transparent external_function_eq typ_eq rettype_eq calling_convention_eq signature_eq chunk_eq.
Definition linked_prog:Clight.program.
 let p:=eval cbv in(Linking.link_prog(program_of_program ccv_core.prog)(program_of_program ccv_primitives.prog))in
 lazymatch p with
 | Some ?q=>exact(Clightdefs.mkprogram ccv_core.composites
   (AST.prog_defs q)(AST.prog_public q)(AST.prog_main q)Logic.I)
 | None=>fail "link rejected"
 end.
Defined.
Lemma linked_ast_actual:link(program_of_program ccv_core.prog)(program_of_program ccv_primitives.prog)=
 Some(program_of_program linked_prog).
Proof. vm_compute;reflexivity. Qed.
Lemma linked_prog_actual:Ctypes.link_program ccv_core.prog ccv_primitives.prog=Some linked_prog.
Proof.
 unfold Ctypes.link_program. rewrite linked_ast_actual. cbn[prog_types].
 change(prog_types ccv_core.prog)with ccv_core.composites.
 change(prog_types ccv_primitives.prog)with(@nil composite_definition).
 cbn[link Ctypes.Linker_composite_defs lift_option].
 change(link_composite_defs ccv_core.composites [])with(Some ccv_core.composites).
 cbn[lift_option].
 lazymatch goal with|-context[link_build_composite_env ?a ?b ?c ?d ?e ?f ?g ?h]=>
 destruct(link_build_composite_env a b c d e f g h)as[env[P Q]]end.
 assert(Env:env=prog_comp_env linked_prog).
 { pose proof(prog_comp_env_eq linked_prog)as K.
   change(build_composite_env ccv_core.composites=Errors.OK(prog_comp_env linked_prog))in K.
   congruence. }
 subst env. f_equal. replace P with(prog_comp_env_eq linked_prog)by apply proof_irr. reflexivity.
Qed.
Definition linked_specs:funspecs:=VerifPrimitives.bit_xor_spec::CCSearchContext.Gprog.
Definition linked_Gprog:funspecs:=ltac:(let pr:=eval unfold linked_prog in linked_prog in
 let x:=old_with_library' pr linked_specs in exact x).
(* Adapted from VST2.14 floyd/forward.v, the build-composite portion of
   solve_cenvcs_goal, to discharge map equality without expanding proof fields. *)
Ltac finish_cenv_build :=
 match goal with|-build_composite_env ?com=Errors.OK ?env=>unfold build_composite_env,com end;
 repeat lazymatch goal with
 | |-add_composite_definitions ?env nil=_=>
   let e:=eval hnf in env in let e:=eval simpl in e in change env with e;reflexivity
 | |-add_composite_definitions ?env(Composite ?id ?su ?m ?a::?defs0)=_=>
   let e:=eval hnf in env in let e:=eval simpl in e in
   let c:=constr:(composite_of_def e id su m a)in let c:=eval hnf in c in
   change(add_composite_definitions env(Composite id su m a::defs0))with
    (Errors.bind c(fun co=>add_composite_definitions(Maps.PTree.set id co e)defs0));
   match c with Errors.OK
    {| co_su := _; co_members := ?m; co_attr := _; co_sizeof := ?s; co_alignof := ?a; co_rank := ?r;
      co_sizeof_pos := ?sp; co_alignof_two_p := ?atp; co_sizeof_alignof := ?sa |} =>
    let s':=eval compute in s in change s with s';
    let a':=eval compute in a in change a with a';
    let r':=eval compute in r in change r with r';
    replace sp with(Zgeb0_ge0 s' eq_refl)by apply proof_irr;
    replace atp with(prove_alignof_two_p a' eq_refl)by apply proof_irr;
    replace sa with(prove_Zdivide a' s' eq_refl)by apply proof_irr
   end;unfold Errors.bind at 1
 | |- _=>fail "Unexpected composite-build goal"
 end.
Lemma linked_composite_env:prog_comp_env linked_prog= @cenv_cs CCSearchSpecs.CompSpecs.
Proof. symmetry;eapply extract_compEnv. finish_cenv_build. Qed.
Print Assumptions linked_prog_actual.
Print Assumptions linked_composite_env.
