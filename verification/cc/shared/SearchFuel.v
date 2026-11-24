(* SPDX-License-Identifier: GPL-3.0-or-later *)
From mathcomp Require Import all_ssreflect.
From Coq Require Import Wf_nat.
Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.

(* A work item stands for one remaining DFS subtree. Pending siblings
   stay on the stack when one child expands. The proof therefore bounds
   the entire traversal, even if every row branch uses the full fanout. *)
Section Finite.
Variable fanout:nat.
Fixpoint nodes_for fuel :=
 if fuel is r.+1 then (fanout * nodes_for r).+1 else 1.
Definition pending (stack:seq nat):=\sum_(r <- stack) nodes_for r.
Inductive step:seq nat->seq nat->Prop :=
| returning r rest:step (r::rest) rest
| branching r rest count : count<=fanout ->
    step (r.+1::rest) (nseq count r ++ rest)
| stopping r rest:step (r::rest) [::].
Lemma positive r : 0<nodes_for r.
Proof. by case:r. Qed.
Lemma batch r count : pending (nseq count r) = count * nodes_for r.
Proof.
elim:count=>[|t IH];first by rewrite /pending big_nil mul0n.
change (pending (r::nseq t r)=t.+1 * nodes_for r).
rewrite /pending big_cons mulSn;congr (_ + _);exact:IH.
Qed.
Lemma strictly_decreases a b : step a b -> pending b<pending a.
Proof.
case=>r rest.
- by rewrite /pending big_cons -[X in X<_]add0n ltn_add2r positive.
- move=>count fits;rewrite /pending big_cons big_cat.
  change (pending (nseq count r)+pending rest<nodes_for r.+1+pending rest).
  rewrite batch ltn_add2r /= ltnS.
  exact:leq_mul fits (leqnn _).
- rewrite /pending big_nil big_cons;exact:leq_trans (positive _) (leq_addr _ _).
Qed.
Theorem finite_stack:well_founded (fun b a=>step a b).
Proof.
apply:(well_founded_lt_compat _ pending);move=>b a step_ab;apply/ltP;exact:strictly_decreases step_ab.
Qed.
Inductive executes:seq nat->nat->seq nat->Prop :=
| start s:executes s 0 s
| more a b c n:step a b->executes b n c->executes a n.+1 c.
Theorem run_bound a n b : executes a n b -> n+pending b <= pending a.
Proof.
elim=>[s|p q r j child prior IH];first by rewrite add0n.
rewrite addSn;exact:leq_ltn_trans IH (strictly_decreases child).
Qed.
End Finite.
