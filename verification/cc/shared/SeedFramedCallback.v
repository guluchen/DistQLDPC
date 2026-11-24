(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto SeedCallFrame.
Lemma one_call_frame {Espec:OracleKind}{CS:compspecs} Delta c
 (before after:list localdef) (P Q frame:mpred):
 semax Delta (PROPx [] (LOCALx before (SEPx [P]))) c
   (normal_ret_assert (PROPx [] (LOCALx after (SEPx [Q])))) ->
 semax Delta (PROPx [] (LOCALx before (SEPx [(P*frame)%logic]))) c
   (normal_ret_assert (PROPx [] (LOCALx after (SEPx [(Q*frame)%logic])))).
Proof.
 intro core;pose proof (@preserve_heap Espec CS Delta c [] [] before after P Q frame core) as saved.
 unfold SEPx,fold_right_sepcon in *;rewrite !sepcon_emp in *;exact saved.
Qed.
