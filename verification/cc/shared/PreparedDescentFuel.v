(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.zlist.list_solver.
Require Import VerifDetected PreparedDepthSpec PreparedBudgetContract PreparedArenaContext
 PreparedRootStages PreparedSeedDispatch PreparedChildCall PreparedSiblingRestore.
Require Import PreparedRecursiveCall PreparedArenaRoot.
Require flag_level_ast.
Import flag_level_ast.
#[local] Existing Instance VerifDetected.CompSpecs.
Local Open Scope Z_scope.

(* A call outside the induction hypothesis cannot acquire its heap. The
   weight is the live C weight, the depth is the length of its stored
   prefix, and the bound is ghost state; it does not alter the solver. *)
Definition below_budget (limit:nat) (packed:node_storage) (scratch:depth_workspace):budget_heap:=
 fun w s path=>if Z.leb (w-Zlength path) (Z.of_nat limit)
              then node_heap packed scratch s path else FF.
Definition with_child_heap c (packed:node_storage) (children:budget_heap) (report:budget_report) bits:=
 prepared_calls (snd (depth_flip c packed bits)) (snd (budget_dfs c children report bits)).

Lemma child_has_one_less w depth:
 1<=depth<w-2 -> Z.to_nat (w-depth)=S (Z.to_nat (w-(depth+1))).
Proof. intros range;lia. Qed.

Lemma borrow_smaller_call limit packed scratch w s depth path:
 Zlength path=depth+1 -> w-depth<=Z.of_nat (S limit) ->
 below_budget limit packed scratch w s path=node_heap packed scratch s path.
Proof.
 intros len bound;unfold below_budget;rewrite len;destruct (Z.leb_spec (w-(depth+1)) (Z.of_nat limit));[reflexivity|lia].
Qed.

Lemma forbid_parent_at_child_limit limit packed scratch w s depth path:
 Zlength path=depth -> w-depth=Z.of_nat (S limit) ->
 below_budget limit packed scratch w s path=FF.
Proof. intros len eqn;unfold below_budget;rewrite len,eqn;destruct (Z.leb_spec (Z.of_nat (S limit)) (Z.of_nat limit));[lia|reflexivity]. Qed.

Lemma installed_child_takes_smaller_budget limit packed scratch w s depth path q:
 0<=depth<Zlength path -> w-depth<=Z.of_nat (S limit) ->
 let saved:=upd_Znth depth path (Int.repr q) in
 below_budget limit packed scratch w s (active_prefix (depth+1) saved)
  =node_heap packed scratch s (append_qubit path depth q).
Proof.
 intros room bound saved;unfold saved;rewrite stored_prefix by lia.
 apply borrow_smaller_call with (depth:=depth);[unfold append_qubit,active_prefix;rewrite Zlength_app,Zlength_sublist by lia;rewrite Zlength_cons,Zlength_nil;lia|assumption].
Qed.
