(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto.
Lemma preserve_caller_store {Espec:OracleKind}{CS:compspecs} Delta c
  (pre post:list Prop) (before after saved:list localdef) (P Q frame:mpred):
 semax Delta (PROPx pre (LOCALx before (SEPx [P]))) c
   (normal_ret_assert (PROPx post (LOCALx after (SEPx [Q])))) ->
 closed_wrt_modvars c (LOCALx saved (SEPx [frame])) ->
 semax Delta (PROPx pre (LOCALx (before++saved) (SEPx [P;frame]))) c
   (normal_ret_assert (PROPx post (LOCALx (after++saved) (SEPx [Q;frame])))).
Proof.
 intros H C;exact (@semax_frame_PQR saved [frame] Espec CS Delta [P] pre before post after [Q] c C H).
Qed.
Lemma preserve_heap {Espec:OracleKind}{CS:compspecs} Delta c
  (pre post:list Prop) (before after:list localdef) (P Q frame:mpred):
 semax Delta (PROPx pre (LOCALx before (SEPx [P]))) c
   (normal_ret_assert (PROPx post (LOCALx after (SEPx [Q])))) ->
 semax Delta (PROPx pre (LOCALx before (SEPx [P;frame]))) c
   (normal_ret_assert (PROPx post (LOCALx after (SEPx [Q;frame])))).
Proof.
 intro checked;pose proof (@preserve_caller_store Espec CS Delta c pre post before after []
    P Q frame checked ltac:(unfold closed_wrt_modvars;auto 50 with closed)) as framed.
 rewrite !app_nil_r in framed;exact framed.
Qed.
Lemma equivalent_storage (P Q:mpred):P=Q -> P|--Q.
Proof. intros ->;apply derives_refl. Qed.
