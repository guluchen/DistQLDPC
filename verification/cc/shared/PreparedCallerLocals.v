(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto.

Lemma separate_caller_env P Q R saved owned:
 PROPx P (LOCALx (Q++saved) (SEPx (R++owned))) =
 (PROPx P (LOCALx Q (SEPx R)) * LOCALx saved (SEPx owned))%logic.
Proof.
 symmetry;extensionality rho;simpl;unfold PROPx,LOCALx,local,lift1,SEPx.
 rewrite fold_right_sepcon_app;simpl;normalize;f_equal.
 rewrite map_app,fold_right_and_app;apply pred_ext;normalize.
Qed.

Lemma keep_caller_locals_for_answer {A:Type}{Espec:OracleKind}{CS:compspecs} Delta c
 (pre:list Prop) (before:list localdef) (owned:list mpred) (saved:list localdef) (extra:list mpred)
 (post:A->list Prop) (after:A->list localdef) (returned:A->list mpred):
 closed_wrt_modvars c (LOCALx saved (SEPx extra)) ->
 semax Delta (PROPx pre (LOCALx before (SEPx owned))) c
  (normal_ret_assert (EX a:A,PROPx (post a) (LOCALx (after a) (SEPx (returned a))))) ->
 semax Delta (PROPx pre (LOCALx (before++saved) (SEPx (owned++extra)))) c
  (normal_ret_assert (EX a:A,PROPx (post a) (LOCALx (after a++saved) (SEPx (returned a++extra))))).
Proof.
 intros stable checked;pose proof (@semax_frame CS Espec Delta _ c _ _ stable checked) as keep.
 rewrite frame_normal,exp_sepcon1 in keep;rewrite separate_caller_env.
 replace (EX a:A,PROPx (post a) (LOCALx (after a++saved) (SEPx (returned a++extra))))%assert with
 (EX a:A,(PROPx (post a) (LOCALx (after a) (SEPx (returned a))) * LOCALx saved (SEPx extra))%logic)%assert.
 - exact keep.
 - f_equal;extensionality a;symmetry;apply separate_caller_env.
Qed.
