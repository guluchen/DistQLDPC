(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto.
Require Import OverlapColumnState OverlapRowSpecs OverlapView VerifOverlapDispatch.
Require owner_ast overlap_ast.
#[local] Existing Instance OverlapSpecs.
Local Open Scope Z_scope.

(* The production C++ owner hands the address of its C view to this callback. *)
Definition actual_callback p a g : ident * funspec :=
 (owner_ast._cc_overlap_policy, callback_contract p g (view_mem p a g)).
Definition OwnerVars:varspecs. mk_varspecs owner_ast.prog. Defined.
Definition OwnerGprog p a g:funspecs := ltac:(with_library owner_ast.prog [update_spec;actual_callback p a g]).

Lemma same_update_code:owner_ast.f_cc_update_overlap=overlap_ast.f_cc_update_overlap.
Proof. reflexivity. Qed.
Lemma same_block_code:owner_ast.f_cc_block_overlap_row=overlap_ast.f_cc_block_overlap_row.
Proof. reflexivity. Qed.
Lemma same_unblock_code:owner_ast.f_cc_unblock_overlap_row=overlap_ast.f_cc_unblock_overlap_row.
Proof. reflexivity. Qed.
Lemma same_layout:owner_ast.composites=overlap_ast.composites.
Proof. reflexivity. Qed.

Theorem body_overlap_callback p a g :
 is_pointer_or_null (qubitp a) -> is_pointer_or_null (blockp a) ->
 semax_body OwnerVars (OwnerGprog p a g) owner_ast.f_cc_overlap_policy (actual_callback p a g).
Proof.
 intros qubit_ptr blocked_ptr;start_function1;destruct x as [[st q] enter];start_function2;start_function3.
 destruct enter.
 - forward_call (p,a,g,q,true,st);try solve [entailer!].
 - forward_call (p,a,g,q,false,st);try solve [entailer!].
Qed.
