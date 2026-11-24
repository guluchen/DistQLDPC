(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto.

(* Preserve the caller's share even when the verified inner statement
   returns an existential result such as a selected hash-table entry. *)
Lemma frame_answer {A:Type} {Espec:OracleKind} {CS:compspecs} Delta c
 (pre:list Prop) (before:list localdef) (owned:list mpred)
 (post:A->list Prop) (after:A->list localdef) (returned:A->list mpred) (frame:mpred):
 semax Delta (PROPx pre (LOCALx before (SEPx owned))) c
  (normal_ret_assert (EX a:A,PROPx (post a) (LOCALx (after a) (SEPx (returned a))))) ->
 semax Delta (PROPx pre (LOCALx before (SEPx (frame::owned)))) c
  (normal_ret_assert (EX a:A,PROPx (post a) (LOCALx (after a) (SEPx (frame::returned a))))).
Proof.
 intro checked.
 pose proof (@semax_frame CS Espec Delta _ c _ (fun _ : environ=>frame) ltac:(hnf;intros;auto) checked) as borrowed.
 rewrite frame_normal in borrowed;rewrite PROP_LOCAL_SEP_cons,sepcon_comm.
 rewrite exp_sepcon1 in borrowed.
 replace (EX a:A,PROPx (post a) (LOCALx (after a) (SEPx (frame::returned a))))%assert
   with (EX a:A,(PROPx (post a) (LOCALx (after a) (SEPx (returned a))) * (fun _ : environ=>frame))%logic)%assert.
 - exact borrowed.
 - f_equal;extensionality a;rewrite PROP_LOCAL_SEP_cons;apply sepcon_comm.
Qed.
