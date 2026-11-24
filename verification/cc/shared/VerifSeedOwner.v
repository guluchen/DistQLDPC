(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto.
Require Import VerifSeedMove OverlapColumnState OverlapView VerifOverlapDispatch.
Require seed_ast owner_ast.
#[local] Existing Instance SeedC.
Local Open Scope Z_scope.
Definition seed_adaptor p a g := (seed_ast._cc_seed_overlap,callback_contract p g (view_mem p a g)).
Definition inner_adaptor p a g := (seed_ast._cc_overlap_policy,callback_contract p g (view_mem p a g)).
Definition SeedOwnerG p a g:funspecs :=
 ltac:(with_library seed_ast.prog [inner_adaptor p a g;seed_adaptor p a g]).

(* The C wrapper passes its first member explicitly to the previously
   checked callback. The C++ owner supplies the enclosing live object. *)
Lemma embedded_overlap_code:
 seed_ast.f_cc_overlap_policy=owner_ast.f_cc_overlap_policy.
Proof. reflexivity. Qed.
Theorem seed_owner_forwards p a g :
 isptr p -> field_compatible seed_type [] p ->
 semax_body SVars (SeedOwnerG p a g) seed_ast.f_cc_seed_overlap (seed_adaptor p a g).
Proof.
 intros ptr compatible;start_function1;destruct x as [[st q] enter];start_function2;start_function3.
 forward;destruct enter.
 - forward_call (st,q,true);try solve [entailer!;destruct p;try contradiction;reflexivity].
 - forward_call (st,q,false);try solve [entailer!;destruct p;try contradiction;reflexivity].
Qed.
