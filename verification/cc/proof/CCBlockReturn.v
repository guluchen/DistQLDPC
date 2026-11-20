(* A normally returning checked block can preserve an enclosing return post. *)
Require Import VST.floyd.proofauto.
Section Proof.
Context{CS:compspecs}{Espec:OracleKind}.
Lemma normal_block_enclosing_return Delta P Q c R:
 semax Delta P c(normal_ret_assert Q) ->
 semax Delta P c(overridePost Q R).
Proof.
 intros Body;destruct R as[RN RB RC RR];eapply semax_post with(R':=normal_ret_assert Q).
 - cbn[RA_normal overridePost normal_ret_assert];apply andp_left2;apply derives_refl.
 - cbn[RA_break overridePost normal_ret_assert];normalize.
 - cbn[RA_continue overridePost normal_ret_assert];normalize.
 - intros vl;cbn[RA_return overridePost normal_ret_assert];normalize.
 - exact Body.
Qed.
End Proof.
Print Assumptions normal_block_enclosing_return.
