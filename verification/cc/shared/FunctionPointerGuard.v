(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.veric.expr VST.veric.res_predicates VST.veric.seplog VST.msl.msl_standard.
Import compcert_rmaps.RML.R compcert_rmaps.RML.
Local Open Scope Z_scope.

(* A VST code resource provides a call target. At offset zero of the fresh
   one-byte CompCert function block, this resource does not itself provide
   either memory permission tested by Floyd's pointer-to-bool cast. *)
Lemma function_guard_at_entry b (phi:rmap) kind pp :
 resource_at phi (b,0)=PURE kind pp ->
 resource_at phi (b,-1)=NO Share.bot bot_unreadable ->
 ~ (predicates_hered.app_pred (expr.weak_valid_pointer (Vptr b Ptrofs.zero)) phi).
Proof.
 intros code outside;unfold expr.weak_valid_pointer,expr.valid_pointer';change (Ptrofs.unsigned Ptrofs.zero) with 0.
 unfold predicates_hered.app_pred;simpl.
 rewrite code,outside;intros [bad|nonempty];[exact bad|apply nonempty;apply bot_identity].
Qed.
